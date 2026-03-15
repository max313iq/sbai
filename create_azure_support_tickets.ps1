[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Token = $env:AZURE_BEARER_TOKEN,

    [Parameter(Mandatory = $false)]
    [int]$DelaySeconds = 23,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [int]$MaxRequests = 0
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

$headers = @{
    Accept = "*/*"
    "Accept-Language" = "en"
    Authorization = "Bearer $normalizedToken"
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
            }
            description = "Spot vCPU quota request"
            problemClassificationId = "/providers/microsoft.support/services/06bfd9d3-516b-d5c6-5802-169c800dec89/problemclassifications/831b2fb3-4db3-3d32-af35-bbb3d3eaeba2"
            serviceId = "/providers/microsoft.support/services/06bfd9d3-516b-d5c6-5802-169c800dec89"
            severity = "minimal"
            title = "Quota request for Batch"
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
    }
    else {
        try {
            $null = Invoke-RestMethod -Method Put -Uri $url -Headers $headers -Body $body
            Write-Host "Submitted quota request -> $($r.account)"
        }
        catch {
            throw "REST request failed for account '$($r.account)' in subscription '$($r.sub)'. $($_.Exception.Message)"
        }
    }

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Seconds $DelaySeconds
    }
}
