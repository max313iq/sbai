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
    [switch]$RotateFingerprint = $true
)

if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Warning "Token is required. Pass -Token or set AZURE_BEARER_TOKEN."
    Write-Host "Example: ./create_azure_support_tickets.ps1 -Token '<bearer-token-or-jwt>'"
    if ($MyInvocation.InvocationName -eq '.') {
        return
    }
    exit 1
}

$normalizedToken = $Token.Trim()
if ($normalizedToken -match '^[Bb]earer\s+') {
    $normalizedToken = $normalizedToken -replace '^[Bb]earer\s+', ''
}

if ($MaxRequests -lt 0) {
    throw "MaxRequests cannot be negative."
}
if ($MaxRetries -lt 0) {
    throw "MaxRetries cannot be negative."
}
if ($BaseRetrySeconds -lt 1) {
    throw "BaseRetrySeconds must be >= 1."
}

$baseHeaders = @{
    Accept = "*/*"
    "Accept-Language" = "en"
    Authorization = "Bearer $normalizedToken"
    "Content-Type" = "application/json"
}

function Get-ErrorResponseBody {
    param([Parameter(Mandatory = $true)]$ErrorRecord)

    if ($ErrorRecord.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($ErrorRecord.ErrorDetails.Message)) {
        return $ErrorRecord.ErrorDetails.Message
    }

    $response = $ErrorRecord.Exception.Response
    if ($null -eq $response) {
        return $null
    }

    try {
        $stream = $response.GetResponseStream()
        if ($null -eq $stream) {
            return $null
        }

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

function Get-StatusCode {
    param([Parameter(Mandatory = $true)]$ErrorRecord)

    try {
        $response = $ErrorRecord.Exception.Response
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
        $response = $ErrorRecord.Exception.Response
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

$requests = @(
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodeus01"; region="eastus"}
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodscus01"; region="southcentralus"}
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodweu01"; region="westeurope"}
    @{sub="7eabeee6-a6a4-42b0-8c77-92ccc6253c4e"; account="aiprodwus201"; region="westus2"}

    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2eastus"; region="eastus"}
    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2scus"; region="southcentralus"}
    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2weu"; region="westeurope"}
    @{sub="8b6fd537-31d0-4897-b77b-13159df7a605"; account="neuroaiprod2wus2"; region="westus2"}

    @{sub="24c03f54-dfbb-4fad-b6b6-12b6b5bc14b7"; account="neuroaiprod3eastus"; region="eastus"}
    @{sub="24c03f54-dfbb-4fad-b6b6-12b6b5bc14b7"; account="neuroaiprod3scus"; region="southcentralus"}
    @{sub="24c03f54-dfbb-4fad-b6b6-12b6b5bc14b7"; account="neuroaiprod3weu"; region="westeurope"}
    @{sub="24c03f54-dfbb-4fad-b6b6-12b6b5bc14b7"; account="neuroaiprod3wus2"; region="westus2"}

    @{sub="17437925-db95-462c-9591-89985d33faee"; account="neuroaiprod4eastus"; region="eastus"}
    @{sub="17437925-db95-462c-9591-89985d33faee"; account="neuroaiprod4scus"; region="southcentralus"}
    @{sub="17437925-db95-462c-9591-89985d33faee"; account="neuroaiprod4weu"; region="westeurope"}
    @{sub="17437925-db95-462c-9591-89985d33faee"; account="neuroaiprod4wus2"; region="westus2"}

    @{sub="8b58b82d-031b-4162-abd9-4a5adcb02183"; account="neuroaiprod5eastus"; region="eastus"}
    @{sub="8b58b82d-031b-4162-abd9-4a5adcb02183"; account="neuroaiprod5scus"; region="southcentralus"}
    @{sub="8b58b82d-031b-4162-abd9-4a5adcb02183"; account="neuroaiprod5weu"; region="westeurope"}
    @{sub="8b58b82d-031b-4162-abd9-4a5adcb02183"; account="neuroaiprod5wus2"; region="westus2"}

    @{sub="21484e8d-5bab-4c23-9889-65527382bca7"; account="neuroaiprod6eastus"; region="eastus"}
    @{sub="21484e8d-5bab-4c23-9889-65527382bca7"; account="neuroaiprod6scus"; region="southcentralus"}
    @{sub="21484e8d-5bab-4c23-9889-65527382bca7"; account="neuroaiprod6weu"; region="westeurope"}
    @{sub="21484e8d-5bab-4c23-9889-65527382bca7"; account="neuroaiprod6wus2"; region="westus2"}

    @{sub="747e2bff-0f10-478f-bb65-4c6fb7256293"; account="neuroaiprod7eastus"; region="eastus"}
    @{sub="747e2bff-0f10-478f-bb65-4c6fb7256293"; account="neuroaiprod7scus"; region="southcentralus"}
    @{sub="747e2bff-0f10-478f-bb65-4c6fb7256293"; account="neuroaiprod7weu"; region="westeurope"}
    @{sub="747e2bff-0f10-478f-bb65-4c6fb7256293"; account="neuroaiprod7wus2"; region="westus2"}

    @{sub="f0b243b4-c073-4a44-b32b-cdd657927d40"; account="neuroaiprod8eastus"; region="eastus"}
    @{sub="f0b243b4-c073-4a44-b32b-cdd657927d40"; account="neuroaiprod8scus"; region="southcentralus"}
    @{sub="f0b243b4-c073-4a44-b32b-cdd657927d40"; account="neuroaiprod8weu"; region="westeurope"}
    @{sub="f0b243b4-c073-4a44-b32b-cdd657927d40"; account="neuroaiprod8wus2"; region="westus2"}

    @{sub="c86b0811-57f5-4266-9d0c-71afb8ccc216"; account="neuroaiprod9eastus"; region="eastus"}
    @{sub="c86b0811-57f5-4266-9d0c-71afb8ccc216"; account="neuroaiprod9scus"; region="southcentralus"}
    @{sub="c86b0811-57f5-4266-9d0c-71afb8ccc216"; account="neuroaiprod9weu"; region="westeurope"}
    @{sub="c86b0811-57f5-4266-9d0c-71afb8ccc216"; account="neuroaiprod9wus2"; region="westus2"}
)

if ($MaxRequests -gt 0) {
    $requests = $requests | Select-Object -First $MaxRequests
}

foreach ($r in $requests) {
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
        if ($DelaySeconds -gt 0) { Start-Sleep -Seconds $DelaySeconds }
        continue
    }

    for ($attempt = 0; $attempt -le $MaxRetries; $attempt++) {
        $requestHeaders = @{}
        foreach ($k in $baseHeaders.Keys) { $requestHeaders[$k] = $baseHeaders[$k] }

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
            break
        }
        catch {
            $status = Get-StatusCode -ErrorRecord $_
            $responseBody = Get-ErrorResponseBody -ErrorRecord $_

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
                throw "REST request failed for account '$($r.account)' in subscription '$($r.sub)'. HTTP $status. $($_.Exception.Message) ResponseBody: $responseBody"
            }

            throw "REST request failed for account '$($r.account)' in subscription '$($r.sub)'. HTTP $status. $($_.Exception.Message)"
        }
    }

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Seconds $DelaySeconds
    }
}
