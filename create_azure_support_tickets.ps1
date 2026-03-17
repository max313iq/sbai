[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Token = $env:AZURE_BEARER_TOKEN,

    [Parameter(Mandatory = $false)]
    [int]$DelaySeconds = 23,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [int]$MaxRequests = 0,

    [Parameter(Mandatory = $false)]
    [string]$ProxyUrl,

    [Parameter(Mandatory = $false)]
    [switch]$ProxyUseDefaultCredentials,

    [Parameter(Mandatory = $false)]
    [pscredential]$ProxyCredential,

    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 6,

    [Parameter(Mandatory = $false)]
    [int]$BaseRetrySeconds = 25,

    [Parameter(Mandatory = $false)]
    [switch]$RotateFingerprint = $true,

    [Parameter(Mandatory = $false)]
    [switch]$AutoDiscoverRequests,

    [Parameter(Mandatory = $false)]
    [string[]]$SubscriptionIds,

    [Parameter(Mandatory = $false)]
    [bool]$TryAzCliToken = $true,

    [Parameter(Mandatory = $false)]
    [bool]$UseDeviceCodeLogin = $false,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 120)]
    [int]$RequestsPerMinute = 2,

    [Parameter(Mandatory = $false)]
    [string]$ResultJsonPath,

    [Parameter(Mandatory = $false)]
    [switch]$StopOnFirstFailure
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )

    $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    switch ($Level) {
        'WARN' { Write-Warning "[$stamp][$Level] $Message" }
        'ERROR' { Write-Host "[$stamp][$Level] $Message" -ForegroundColor Red }
        default { Write-Host "[$stamp][$Level] $Message" }
    }
}

function Get-EffectiveInterRequestDelaySeconds {
    param(
        [Parameter(Mandatory = $true)][int]$ConfiguredDelaySeconds,
        [Parameter(Mandatory = $true)][int]$ConfiguredRequestsPerMinute
    )

    $rateDelay = [int][math]::Ceiling(60.0 / $ConfiguredRequestsPerMinute)
    return [math]::Max($ConfiguredDelaySeconds, $rateDelay)
}

function Get-ErrorResponseBody {
    param([Parameter(Mandatory = $true)]$ErrorRecord)

    if ($ErrorRecord.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($ErrorRecord.ErrorDetails.Message)) {
        return $ErrorRecord.ErrorDetails.Message
    }

    $response = Get-ExceptionResponse -ErrorRecord $ErrorRecord
    if ($null -eq $response) {
        return $null
    }

    try {
        $stream = $response.GetResponseStream()
        if ($null -eq $stream) { return $null }

        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        $reader.Dispose()
        $stream.Dispose()
        return $body
    }
    catch {
        return $null
    }
}

function Get-ExceptionResponse {
    param([Parameter(Mandatory = $true)]$ErrorRecord)

    if ($null -eq $ErrorRecord -or $null -eq $ErrorRecord.Exception) {
        return $null
    }

    $responseProperty = $ErrorRecord.Exception.PSObject.Properties['Response']
    if ($null -eq $responseProperty) {
        return $null
    }

    return $responseProperty.Value
}

function Get-StatusCode {
    param([Parameter(Mandatory = $true)]$ErrorRecord)

    try {
        $response = Get-ExceptionResponse -ErrorRecord $ErrorRecord
        if ($null -eq $response) { return $null }
        return [int]$response.StatusCode
    }
    catch { return $null }
}

function Is-ThrottledResponse {
    param(
        [Parameter(Mandatory = $false)]$StatusCode,
        [Parameter(Mandatory = $false)][string]$ResponseBody,
        [Parameter(Mandatory = $false)][string]$Message
    )

    if ($StatusCode -eq 429) { return $true }

    $blob = "$ResponseBody $Message"
    if ($blob -match '(?i)too\s*many\s*requests|throttl') {
        return $true
    }

    return $false
}

function Get-RetryAfterSeconds {
    param([Parameter(Mandatory = $true)]$ErrorRecord)

    try {
        $response = Get-ExceptionResponse -ErrorRecord $ErrorRecord
        if ($null -eq $response) { return $null }
        $retryAfter = $response.Headers["Retry-After"]
        if ([string]::IsNullOrWhiteSpace($retryAfter)) { return $null }

        $secs = 0
        if ([int]::TryParse($retryAfter, [ref]$secs)) {
            return $secs
        }

        $dt = [datetime]::MinValue
        if ([datetime]::TryParse($retryAfter, [ref]$dt)) {
            $delta = [math]::Ceiling(($dt.ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds)
            return [math]::Max(1, $delta)
        }

        return $null
    }
    catch { return $null }
}

function Invoke-AzCommand {
    param([Parameter(Mandatory = $true)][string[]]$Args)

    $azPath = Get-Command az -ErrorAction SilentlyContinue
    if (-not $azPath) {
        throw "Azure CLI (az) was not found in PATH."
    }

    $output = & az @Args 2>&1

    if ($azPath.CommandType -eq "Application" -and $LASTEXITCODE -ne 0) {
        throw "az $($Args -join ' ') failed: $output"
    }

    return $output
}

function Invoke-AzDeviceCodeLogin {
    param([Parameter(Mandatory = $false)][string]$TenantId)

    Write-Host "Running Azure device-code login..."
    Write-Host "Azure CLI will print a login URL and one-time code below."

    $args = @("login", "--use-device-code")
    if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
        $args += @("--tenant", $TenantId)
        Write-Host "Tenant-scoped login requested for tenant: $TenantId"
    }

    $output = Invoke-AzCommand -Args $args
    if ($output) {
        foreach ($line in ($output -split "`r?`n")) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-Host $line
            }
        }
    }
}

function Get-AccessTokenFromAzCli {
    param(
        [Parameter(Mandatory = $false)][string]$SubscriptionId,
        [Parameter(Mandatory = $false)][string]$TenantId,
        [Parameter(Mandatory = $false)][bool]$ThrowOnError = $false
    )

    try {
        $args = @("account", "get-access-token", "--resource", "https://management.azure.com/", "-o", "json")
        if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
            $args += @("--subscription", $SubscriptionId)
        }
        if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
            $args += @("--tenant", $TenantId)
        }

        $raw = Invoke-AzCommand -Args $args
        $tokenObj = $raw | ConvertFrom-Json
        if ($null -eq $tokenObj -or [string]::IsNullOrWhiteSpace($tokenObj.accessToken)) {
            if ($ThrowOnError) { throw "Azure CLI returned no access token." }
            return $null
        }

        return $tokenObj.accessToken
    }
    catch {
        if ($ThrowOnError) {
            throw
        }
        return $null
    }
}

function Get-SubscriptionTenantMapFromAzCli {
    param([string[]]$FilterSubscriptionIds)

    $raw = Invoke-AzCommand -Args @("account", "list", "--all", "-o", "json")
    $accounts = $raw | ConvertFrom-Json

    $map = @{}
    foreach ($acct in $accounts) {
        if ([string]::IsNullOrWhiteSpace($acct.id) -or [string]::IsNullOrWhiteSpace($acct.tenantId)) {
            continue
        }

        if ($FilterSubscriptionIds -and $FilterSubscriptionIds.Count -gt 0 -and ($FilterSubscriptionIds -notcontains $acct.id)) {
            continue
        }

        $map[$acct.id] = $acct.tenantId
    }

    return $map
}

function Get-SubscriptionTenantIdFromAzCli {
    param([Parameter(Mandatory = $true)][string]$SubscriptionId)

    try {
        $raw = Invoke-AzCommand -Args @("account", "show", "--subscription", $SubscriptionId, "-o", "json")
        $acct = $raw | ConvertFrom-Json
        if ($null -ne $acct -and -not [string]::IsNullOrWhiteSpace($acct.tenantId)) {
            return $acct.tenantId
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-TenantIdFromUnauthorizedBody {
    param([Parameter(Mandatory = $false)][string]$ResponseBody)

    if ([string]::IsNullOrWhiteSpace($ResponseBody)) {
        return $null
    }

    $mustMatch = [regex]::Match($ResponseBody, 'must match.*?sts\.windows\.net/([0-9a-fA-F-]{36})/', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($mustMatch.Success) { return $mustMatch.Groups[1].Value }

    $mustMatchLogin = [regex]::Match($ResponseBody, 'authority.*?login\.windows\.net/([0-9a-fA-F-]{36})', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($mustMatchLogin.Success) { return $mustMatchLogin.Groups[1].Value }

    $allMatches = [regex]::Matches($ResponseBody, 'sts\.windows\.net/([0-9a-fA-F-]{36})/')
    if ($allMatches.Count -gt 0) {
        return $allMatches[$allMatches.Count - 1].Groups[1].Value
    }

    $m = [regex]::Match($ResponseBody, 'login\.windows\.net/([0-9a-fA-F-]{36})')
    if ($m.Success) { return $m.Groups[1].Value }

    return $null
}

function Resolve-AzCliTokenForSubscription {
    param(
        [Parameter(Mandatory = $true)][string]$SubscriptionId,
        [Parameter(Mandatory = $false)][string]$KnownTenantId,
        [Parameter(Mandatory = $false)][bool]$AllowDeviceCodeLogin = $false
    )

    $candidateTenants = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($KnownTenantId)) {
        $candidateTenants.Add($KnownTenantId)
    }

    if ($candidateTenants.Count -eq 0) {
        $tenantFromAz = Get-SubscriptionTenantIdFromAzCli -SubscriptionId $SubscriptionId
        if (-not [string]::IsNullOrWhiteSpace($tenantFromAz)) {
            $candidateTenants.Add($tenantFromAz)
        }
    }

    foreach ($tenant in $candidateTenants) {
        $token = Get-AccessTokenFromAzCli -SubscriptionId $SubscriptionId -TenantId $tenant
        if (-not [string]::IsNullOrWhiteSpace($token)) {
            return @{ token = $token; tenant = $tenant }
        }

        if ($AllowDeviceCodeLogin) {
            Write-Warning "Unable to get token for subscription '$SubscriptionId' and tenant '$tenant'. Trying device-code login for that tenant."
            try {
                Invoke-AzDeviceCodeLogin -TenantId $tenant
                $token = Get-AccessTokenFromAzCli -SubscriptionId $SubscriptionId -TenantId $tenant -ThrowOnError $true
                return @{ token = $token; tenant = $tenant }
            }
            catch {
                Write-Warning "Tenant-scoped device-code login/token retrieval failed for tenant '$tenant': $($_.Exception.Message)"
            }
        }
    }

    $subToken = Get-AccessTokenFromAzCli -SubscriptionId $SubscriptionId
    if (-not [string]::IsNullOrWhiteSpace($subToken)) {
        return @{ token = $subToken; tenant = $null }
    }

    if ($AllowDeviceCodeLogin) {
        Write-Warning "Unable to acquire token for subscription '$SubscriptionId' from current Azure CLI context. Trying generic device-code login and retrying once."
        try {
            Invoke-AzDeviceCodeLogin
            $subToken = Get-AccessTokenFromAzCli -SubscriptionId $SubscriptionId -ThrowOnError $true
            if (-not [string]::IsNullOrWhiteSpace($subToken)) {
                return @{ token = $subToken; tenant = $null }
            }
        }
        catch {
            Write-Warning "Generic device-code login/token retrieval failed for subscription '$SubscriptionId': $($_.Exception.Message)"
        }
    }

    return $null
}

function Get-SubscriptionsFromAzCli {
    param([string[]]$RequestedIds)

    if ($RequestedIds -and $RequestedIds.Count -gt 0) {
        return $RequestedIds
    }

    $raw = Invoke-AzCommand -Args @("account", "list", "--query", "[].id", "-o", "tsv")
    $subs = @()
    foreach ($line in ($raw -split "`r?`n")) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $subs += $line.Trim()
        }
    }
    return $subs
}

function Get-BatchRequestsFromAzCli {
    param([string[]]$SubscriptionList)

    $discovered = @()
    foreach ($sub in $SubscriptionList) {
        $raw = Invoke-AzCommand -Args @("batch", "account", "list", "--subscription", $sub, "-o", "json")
        $accounts = $raw | ConvertFrom-Json

        foreach ($a in $accounts) {
            $region = $a.location
            if ([string]::IsNullOrWhiteSpace($region)) {
                $region = "eastus"
            }

            $discovered += @{
                sub = $sub
                account = $a.name
                region = $region
            }
        }
    }

    return $discovered
}

if ($UseDeviceCodeLogin -and -not $TryAzCliToken) {
    Write-Warning "-UseDeviceCodeLogin requires Azure CLI token retrieval. Enabling -TryAzCliToken automatically."
    $TryAzCliToken = $true
}

if ($MaxRequests -lt 0) { throw "MaxRequests cannot be negative." }
if ($MaxRetries -lt 0) { throw "MaxRetries cannot be negative." }
if ($BaseRetrySeconds -lt 1) { throw "BaseRetrySeconds must be >= 1." }

$effectiveDelaySeconds = Get-EffectiveInterRequestDelaySeconds -ConfiguredDelaySeconds $DelaySeconds -ConfiguredRequestsPerMinute $RequestsPerMinute
Write-Log -Message "Using effective inter-request delay of $effectiveDelaySeconds second(s) (DelaySeconds=$DelaySeconds, RequestsPerMinute=$RequestsPerMinute)."

$tokenFromAzCli = $false
if ([string]::IsNullOrWhiteSpace($Token) -and $TryAzCliToken) {
    if ($UseDeviceCodeLogin) {
        try { Invoke-AzDeviceCodeLogin } catch { Write-Warning "Device-code login failed: $($_.Exception.Message)" }
    }

    $Token = Get-AccessTokenFromAzCli
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $tokenFromAzCli = $true
        Write-Host "Using access token from Azure CLI."
    }
}

if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Warning "Token is required. Pass -Token, set AZURE_BEARER_TOKEN, or enable Azure CLI token retrieval."
    Write-Host "Example: ./create_azure_support_tickets.ps1 -TryAzCliToken `$true -UseDeviceCodeLogin"
    if ($MyInvocation.InvocationName -eq '.') { return }
    exit 1
}

$normalizedToken = $Token.Trim()
if ($normalizedToken -match '^[Bb]earer\s+') {
    $normalizedToken = $normalizedToken -replace '^[Bb]earer\s+', ''
}

$baseHeaders = @{
    Accept = "*/*"
    "Accept-Language" = "en"
    "Content-Type" = "application/json"
}

$requests = @(
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodeus01"; region="eastus"}
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodscus01"; region="southcentralus"}
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodweu01"; region="westeurope"}
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodwus201"; region="westus2"}

    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2eastus"; region="eastus"}
    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2scus"; region="southcentralus"}
    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2weu"; region="westeurope"}
    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2wus2"; region="westus2"}
)

if ($AutoDiscoverRequests) {
    $subs = Get-SubscriptionsFromAzCli -RequestedIds $SubscriptionIds
    $requests = Get-BatchRequestsFromAzCli -SubscriptionList $subs

    if (-not $requests -or $requests.Count -eq 0) {
        throw "No Batch accounts were discovered from Azure CLI."
    }

    Write-Host "Discovered $($requests.Count) Batch accounts from Azure."
}

if ($MaxRequests -gt 0) {
    $requests = $requests | Select-Object -First $MaxRequests
}

$subscriptionTenantMap = @{}
if ($tokenFromAzCli) {
    try {
        $subscriptionTenantMap = Get-SubscriptionTenantMapFromAzCli -FilterSubscriptionIds ($requests | ForEach-Object { $_.sub } | Select-Object -Unique)
        if ($subscriptionTenantMap.Count -gt 0) {
            Write-Host "Resolved tenant IDs for $($subscriptionTenantMap.Count) subscriptions."
        }
    }
    catch {
        Write-Warning "Unable to resolve subscription -> tenant mapping from Azure CLI: $($_.Exception.Message)"
    }
}

$results = New-Object System.Collections.Generic.List[object]
$scriptStart = Get-Date

foreach ($r in $requests) {
    $requestStart = Get-Date
    $succeeded = $false
    $failureMessage = $null
    $attemptCount = 0

    $ticket = [guid]::NewGuid().ToString()
    $payload = (@{ AccountName = $r.account; NewLimit = 680; Type = "LowPriority" } | ConvertTo-Json -Compress)

    $bodyObject = @{
        properties = @{
            contactDetails = @{
                firstName = "Pedro Eduardo"
                lastName = "Velazquez Gomez"
                preferredContactMethod = "email"
                primaryEmailAddress = "pedrovelazquez@misionquerendarooutlook.onmicro"
                preferredTimeZone = "Russian Standard Time"
                country = "MEX"
                preferredSupportLanguage = "en-us"
                additionalEmailAddresses = @()
            }
            description = "Request Summary / New Limit: `nSpot/low-priority vCPUs (all Series), $($r.region) / 680`n"
            problemClassificationId = "/providers/microsoft.support/services/06bfd9d3-516b-d5c6-5802-169c800dec89/problemclassifications/831b2fb3-4db3-3d32-af35-bbb3d3eaeba2"
            serviceId = "/providers/microsoft.support/services/06bfd9d3-516b-d5c6-5802-169c800dec89"
            severity = "minimal"
            title = "Quota request for Batch"
            advancedDiagnosticConsent = "Yes"
            require24X7Response = $false
            supportPlanId = "U291cmNlOkZyZWUsRnJlZUlkOjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwOSw%3d"
            quotaTicketDetails = @{
                quotaChangeRequestVersion = "1.0"
                quotaChangeRequestSubType = "Account"
                quotaChangeRequests = @(
                    @{
                        region = $r.region
                        payload = $payload
                    }
                )
            }
        }
    }

    $body = $bodyObject | ConvertTo-Json -Depth 10 -Compress
    $url = "https://management.azure.com/subscriptions/$($r.sub)/providers/Microsoft.Support/supportTickets/${ticket}?api-version=2025-06-01-preview"

    if ($DryRun) {
        Write-Host "[DRY RUN] Invoke-RestMethod -Method Put -Uri $url -Headers <redacted> -Body $body"
        Write-Host "[DRY RUN] Prepared quota request -> $($r.account)"
        $results.Add([pscustomobject]@{
            account = $r.account
            subscription = $r.sub
            region = $r.region
            ticket = $ticket
            status = 'DryRun'
            attempts = 0
            durationSeconds = [math]::Round(((Get-Date) - $requestStart).TotalSeconds, 2)
            error = $null
        })
        if ($effectiveDelaySeconds -gt 0) { Start-Sleep -Seconds $effectiveDelaySeconds }
        continue
    }

    for ($attempt = 0; $attempt -le $MaxRetries; $attempt++) {
        $attemptCount = $attempt + 1
        $requestHeaders = @{}
        foreach ($k in $baseHeaders.Keys) { $requestHeaders[$k] = $baseHeaders[$k] }

        if ($tokenFromAzCli) {
            $tenantForSub = $null
            if ($subscriptionTenantMap.ContainsKey($r.sub)) {
                $tenantForSub = $subscriptionTenantMap[$r.sub]
            }

            $tokenResolution = Resolve-AzCliTokenForSubscription -SubscriptionId $r.sub -KnownTenantId $tenantForSub -AllowDeviceCodeLogin:$UseDeviceCodeLogin
            if ($null -eq $tokenResolution -or [string]::IsNullOrWhiteSpace($tokenResolution.token)) {
                $failureMessage = "Unable to acquire an Azure CLI token for subscription '$($r.sub)'. Ensure your account has access to that subscription tenant or run with -UseDeviceCodeLogin:`$true and authenticate for the required tenant."
                break
            }

            if (-not [string]::IsNullOrWhiteSpace($tokenResolution.tenant)) {
                $subscriptionTenantMap[$r.sub] = $tokenResolution.tenant
            }

            $normalizedToken = $tokenResolution.token.Trim()
        }

        $requestHeaders["Authorization"] = "Bearer $normalizedToken"

        if ($RotateFingerprint) {
            $requestHeaders["User-Agent"] = "AzureQuotaBot/1.0 fp-$([guid]::NewGuid().ToString('N'))"
            $requestHeaders["x-ms-client-request-id"] = [guid]::NewGuid().ToString()
            $requestHeaders["x-ms-correlation-request-id"] = [guid]::NewGuid().ToString()
        }

        $invokeParams = @{
            Method = "Put"
            Uri = $url
            Headers = $requestHeaders
            Body = [System.Text.Encoding]::UTF8.GetBytes($body)
            ContentType = "application/json; charset=utf-8"
            ErrorAction = "Stop"
        }

        if (-not [string]::IsNullOrWhiteSpace($ProxyUrl)) {
            $invokeParams["Proxy"] = $ProxyUrl
            if ($ProxyUseDefaultCredentials) {
                $invokeParams["ProxyUseDefaultCredentials"] = $true
            }
            elseif ($ProxyCredential) {
                $invokeParams["ProxyCredential"] = $ProxyCredential
            }
        }

        try {
            $null = Invoke-RestMethod @invokeParams
            Write-Host "Submitted quota request -> $($r.account)"
            $succeeded = $true
            break
        }
        catch {
            $status = Get-StatusCode -ErrorRecord $_
            $responseBody = Get-ErrorResponseBody -ErrorRecord $_

            $tenantMismatch = $false
            if ($status -eq 401) { $tenantMismatch = $true }
            if ($responseBody -match '(?i)InvalidAuthenticationTokenTenant|wrong issuer|must match the tenant') { $tenantMismatch = $true }

            if ($tokenFromAzCli -and $tenantMismatch -and $attempt -lt $MaxRetries) {
                $tenantFromBody = Get-TenantIdFromUnauthorizedBody -ResponseBody $responseBody
                if (-not [string]::IsNullOrWhiteSpace($tenantFromBody)) {
                    $subscriptionTenantMap[$r.sub] = $tenantFromBody
                    $tenantResolution = Resolve-AzCliTokenForSubscription -SubscriptionId $r.sub -KnownTenantId $tenantFromBody -AllowDeviceCodeLogin:$UseDeviceCodeLogin
                    if ($tenantResolution -and -not [string]::IsNullOrWhiteSpace($tenantResolution.token)) {
                        $normalizedToken = $tenantResolution.token.Trim()
                        Write-Warning "401 tenant mismatch for $($r.sub). Refreshed token for tenant $tenantFromBody and retrying."
                        continue
                    }
                }
            }

            if ((Is-ThrottledResponse -StatusCode $status -ResponseBody $responseBody -Message $_.Exception.Message) -and $attempt -lt $MaxRetries) {
                $retryAfter = Get-RetryAfterSeconds -ErrorRecord $_
                $backoff = [math]::Min(300, $BaseRetrySeconds * [math]::Pow(2, $attempt))
                $jitter = Get-Random -Minimum 0 -Maximum 12
                $sleepSeconds = if ($retryAfter) { [math]::Max($retryAfter, $backoff + $jitter) } else { $backoff + $jitter }

                Write-Warning "429 throttled for $($r.account). Retry $($attempt + 1)/$MaxRetries in ${sleepSeconds}s."
                Start-Sleep -Seconds $sleepSeconds
                continue
            }

            if (-not [string]::IsNullOrWhiteSpace($responseBody)) {
                $failureMessage = "REST request failed for account '$($r.account)' in subscription '$($r.sub)'. HTTP $status. $($_.Exception.Message) ResponseBody: $responseBody"
                break
            }

            $failureMessage = "REST request failed for account '$($r.account)' in subscription '$($r.sub)'. HTTP $status. $($_.Exception.Message)"
            break
        }
    }

    $results.Add([pscustomobject]@{
        account = $r.account
        subscription = $r.sub
        region = $r.region
        ticket = $ticket
        status = if ($succeeded) { 'Submitted' } else { 'Failed' }
        attempts = $attemptCount
        durationSeconds = [math]::Round(((Get-Date) - $requestStart).TotalSeconds, 2)
        error = $failureMessage
    })

    if (-not $succeeded) {
        Write-Log -Level ERROR -Message $failureMessage
        if ($StopOnFirstFailure) {
            throw "Stopping early because -StopOnFirstFailure is enabled."
        }
    }

    if ($effectiveDelaySeconds -gt 0) {
        Start-Sleep -Seconds $effectiveDelaySeconds
    }
}

$submittedCount = @($results | Where-Object { $_.status -eq 'Submitted' }).Count
$failedCount = @($results | Where-Object { $_.status -eq 'Failed' }).Count
$dryRunCount = @($results | Where-Object { $_.status -eq 'DryRun' }).Count
$elapsedSeconds = [math]::Round(((Get-Date) - $scriptStart).TotalSeconds, 2)

Write-Log -Message "Run completed. Submitted=$submittedCount Failed=$failedCount DryRun=$dryRunCount Total=$($results.Count) Duration=${elapsedSeconds}s"

if (-not [string]::IsNullOrWhiteSpace($ResultJsonPath)) {
    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $ResultJsonPath -Encoding UTF8
    Write-Log -Message "Saved request results to $ResultJsonPath"
}

if ($failedCount -gt 0 -and -not $DryRun) {
    exit 1
}
