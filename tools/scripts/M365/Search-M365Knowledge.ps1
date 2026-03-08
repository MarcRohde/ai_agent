<#
.SYNOPSIS
    Query Microsoft 365 knowledge sources through Microsoft Graph search.

.DESCRIPTION
    Runs Microsoft Graph search against selected entity types (for example,
    OneDrive files, SharePoint items, and Sites) and returns normalized results
    with citation-friendly paths and URLs.

.PARAMETER Query
    The search query text.

.PARAMETER EntityTypes
    Graph entity types to query. Common values: driveItem, listItem, site,
    message, event, chatMessage, externalItem.

.PARAMETER Top
    Maximum number of results requested from Graph.

.PARAMETER AccessToken
    Optional Graph bearer token. If omitted, script uses M365_GRAPH_ACCESS_TOKEN
    or falls back to Azure CLI token retrieval and browser login.

.PARAMETER TenantId
    Optional tenant for Azure CLI browser login. Defaults to EXO_TENANT_ID,
    then 'organizations'.

.PARAMETER EndpointVersion
    Graph endpoint version: v1.0 or beta.

.PARAMETER Scope
    Optional preset scope to append entity types. Supported values:
    all, work, personal, mail, chat, communications.

.PARAMETER OutputPath
    Optional path to write normalized result JSON.

.PARAMETER IncludeMail
    Adds Microsoft Graph `message` entity type to the search request.

.PARAMETER IncludeChat
    Adds Microsoft Graph `chatMessage` entity type to the search request.

.PARAMETER IncludeMailAndChat
    Convenience switch that enables both mail and chat entity types.

.PARAMETER SkipAzureCliLogin
    Skip automatic browser-based `az login` attempt when Azure CLI is available
    but no token is currently present.

.PARAMETER IncludeRawResponse
    Include raw Graph response in output object.

.EXAMPLE
    .\tools\scripts\M365\Search-M365Knowledge.ps1 -Query "Andis ODS dimCustomer" -EntityTypes driveItem,listItem,site

.EXAMPLE
    .\tools\scripts\M365\Search-M365Knowledge.ps1 -Query "Q4 forecast" -EntityTypes externalItem -EndpointVersion beta

.EXAMPLE
    .\tools\scripts\M365\Search-M365Knowledge.ps1 -Query "release notes" -IncludeMailAndChat

.EXAMPLE
    .\tools\scripts\M365\Search-M365Knowledge.ps1 -Query "weekly updates" -Scope communications -EndpointVersion beta

.EXAMPLE
    .\tools\scripts\M365\Search-M365Knowledge.ps1 -Query "quarterly review" -Scope communications -SkipAzureCliLogin

.NOTES
    Author: AI Agent
    Date: 2026-03-08
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Query,

    [Parameter(Mandatory = $false)]
    [string[]]$EntityTypes = @('driveItem', 'listItem', 'site'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 50)]
    [int]$Top = 10,

    [Parameter(Mandatory = $false)]
    [string]$AccessToken = '',

    [Parameter(Mandatory = $false)]
    [string]$TenantId = $env:EXO_TENANT_ID,

    [Parameter(Mandatory = $false)]
    [ValidateSet('v1.0', 'beta')]
    [string]$EndpointVersion = 'v1.0',

    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'work', 'personal', 'mail', 'chat', 'communications')]
    [string]$Scope = 'all',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = '',

    [Parameter(Mandatory = $false)]
    [switch]$IncludeMail,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeChat,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeMailAndChat,

    [Parameter(Mandatory = $false)]
    [switch]$SkipAzureCliLogin,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRawResponse
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:AzureCliErrorCode = ''

if ([string]::IsNullOrWhiteSpace($TenantId)) {
    if (-not [string]::IsNullOrWhiteSpace($env:M365_TENANT_ID)) {
        $TenantId = $env:M365_TENANT_ID
    }
    else {
        $TenantId = 'organizations'
    }
}

function Get-GraphToken {
    param(
        [Parameter(Mandatory = $false)]
        [string]$CurrentToken,

        [Parameter(Mandatory = $false)]
        [bool]$TryInteractiveLogin = $true,

        [Parameter(Mandatory = $false)]
        [string]$LoginTenant = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($CurrentToken)) {
        return $CurrentToken
    }

    $envToken = [Environment]::GetEnvironmentVariable('M365_GRAPH_ACCESS_TOKEN', 'Process')
    if ([string]::IsNullOrWhiteSpace($envToken)) {
        $envToken = [Environment]::GetEnvironmentVariable('M365_GRAPH_ACCESS_TOKEN', 'User')
    }
    if (-not [string]::IsNullOrWhiteSpace($envToken)) {
        return $envToken
    }

    $hasAzureCli = [bool](Get-Command az -ErrorAction SilentlyContinue)
    if ($hasAzureCli) {
        try {
            $azToken = az account get-access-token --resource-type ms-graph --query accessToken -o tsv 2>$null
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($azToken)) {
                return $azToken.Trim()
            }
        }
        catch {
            if ($_.Exception.Message -match 'AADSTS65002') {
                $script:AzureCliErrorCode = 'AADSTS65002'
            }
            # Continue to optional interactive login.
        }

        if ($TryInteractiveLogin) {
            $loginArgs = @('login')
            if (-not [string]::IsNullOrWhiteSpace($LoginTenant) -and $LoginTenant -ne 'organizations') {
                $loginArgs += @('--tenant', $LoginTenant)
            }

            Write-Host 'No Azure CLI Graph token found. Launching browser login (az login)...' -ForegroundColor Yellow
            try {
                $loginOutput = (& az @loginArgs 2>&1 | Out-String)
                if ($loginOutput -match 'AADSTS65002') {
                    $script:AzureCliErrorCode = 'AADSTS65002'
                }

                if ($LASTEXITCODE -eq 0) {
                    $azToken = az account get-access-token --resource-type ms-graph --query accessToken -o tsv 2>$null
                    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($azToken)) {
                        return $azToken.Trim()
                    }
                }
            }
            catch {
                # Continue to final error.
            }
        }
    }
    elseif ($TryInteractiveLogin) {
        throw 'Unable to resolve Graph token. Azure CLI is not installed. Install Azure CLI for browser OAuth login, or provide M365_GRAPH_ACCESS_TOKEN.'
    }

    if ($TryInteractiveLogin) {
        if ($script:AzureCliErrorCode -eq 'AADSTS65002') {
            throw 'Azure CLI OAuth is blocked by tenant policy (AADSTS65002) for Microsoft first-party app consent. Create a custom Entra app registration with Graph delegated permissions, grant admin consent, then acquire a token with tools/scripts/M365/Get-M365GraphAccessToken.ps1 -UseDeviceCode -ClientId <your-app-id>.'
        }

        throw 'Unable to resolve Graph token. Set M365_GRAPH_ACCESS_TOKEN or complete Azure CLI browser login.'
    }

    throw 'Unable to resolve Graph token. Set M365_GRAPH_ACCESS_TOKEN or run tools/scripts/M365/Get-M365GraphAccessToken.ps1 first.'
}

function Get-ResourceCitationPath {
    param(
        [Parameter(Mandatory = $false)]
        [object]$Resource
    )

    if ($null -eq $Resource) {
        return ''
    }

    if ($Resource.PSObject.Properties.Name -contains 'parentReference' -and
        $Resource.parentReference -and
        $Resource.parentReference.PSObject.Properties.Name -contains 'path' -and
        $Resource.parentReference.path) {
        $name = if ($Resource.PSObject.Properties.Name -contains 'name') { $Resource.name } else { '' }
        return ($Resource.parentReference.path + '/' + $name).TrimEnd('/')
    }

    if ($Resource.PSObject.Properties.Name -contains 'webUrl' -and $Resource.webUrl) {
        return $Resource.webUrl
    }

    return ''
}

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$DefaultValue = ''
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Add-EntityTypeIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$EntityTypeList,

        [Parameter(Mandatory = $true)]
        [string]$EntityType
    )

    if ([string]::IsNullOrWhiteSpace($EntityType)) {
        return
    }

    if (-not $EntityTypeList.Contains($EntityType)) {
        [void]$EntityTypeList.Add($EntityType)
    }
}

function Resolve-EntityTypes {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$InitialEntityTypes,

        [Parameter(Mandatory = $true)]
        [string]$ScopeName,

        [Parameter(Mandatory = $true)]
        [bool]$AddMail,

        [Parameter(Mandatory = $true)]
        [bool]$AddChat,

        [Parameter(Mandatory = $true)]
        [bool]$AddMailAndChat
    )

    $resolved = [System.Collections.Generic.List[string]]::new()

    if ($InitialEntityTypes) {
        foreach ($entity in $InitialEntityTypes) {
            Add-EntityTypeIfMissing -EntityTypeList $resolved -EntityType $entity
        }
    }

    switch ($ScopeName) {
        'mail' {
            Add-EntityTypeIfMissing -EntityTypeList $resolved -EntityType 'message'
        }
        'chat' {
            Add-EntityTypeIfMissing -EntityTypeList $resolved -EntityType 'chatMessage'
        }
        'communications' {
            Add-EntityTypeIfMissing -EntityTypeList $resolved -EntityType 'message'
            Add-EntityTypeIfMissing -EntityTypeList $resolved -EntityType 'chatMessage'
        }
        default {
            # all/work/personal are already represented by default entity types.
        }
    }

    if ($AddMailAndChat) {
        $AddMail = $true
        $AddChat = $true
    }

    if ($AddMail) {
        Add-EntityTypeIfMissing -EntityTypeList $resolved -EntityType 'message'
    }
    if ($AddChat) {
        Add-EntityTypeIfMissing -EntityTypeList $resolved -EntityType 'chatMessage'
    }

    return $resolved.ToArray()
}

$resolvedEntityTypes = Resolve-EntityTypes -InitialEntityTypes $EntityTypes -ScopeName $Scope -AddMail $IncludeMail.IsPresent -AddChat $IncludeChat.IsPresent -AddMailAndChat $IncludeMailAndChat.IsPresent

$tryAzureCliInteractiveLogin = -not $SkipAzureCliLogin.IsPresent
$token = Get-GraphToken -CurrentToken $AccessToken -TryInteractiveLogin $tryAzureCliInteractiveLogin -LoginTenant $TenantId
$headers = @{ Authorization = "Bearer $token" }
$searchEndpoint = "https://graph.microsoft.com/$EndpointVersion/search/query"

$requestBody = @{
    requests = @(
        @{
            entityTypes = $resolvedEntityTypes
            query       = @{
                queryString = $Query
            }
            from        = 0
            size        = $Top
        }
    )
}

$response = Invoke-RestMethod -Method Post -Uri $searchEndpoint -Headers $headers -ContentType 'application/json' -Body ($requestBody | ConvertTo-Json -Depth 8)

$results = @()
$rank = 1

if ($response.value) {
    foreach ($requestResult in $response.value) {
        if (-not $requestResult.hitsContainers) {
            continue
        }

        foreach ($container in $requestResult.hitsContainers) {
            if (-not $container.hits) {
                continue
            }

            foreach ($hit in $container.hits) {
                $resource = $hit.resource
                $odataType = Get-PropertyValue -InputObject $resource -PropertyName '@odata.type' -DefaultValue ''

                $entityType = 'unknown'
                if (-not [string]::IsNullOrWhiteSpace([string]$container.type)) {
                    $entityType = $container.type
                }
                elseif (-not [string]::IsNullOrWhiteSpace([string]$odataType)) {
                    $entityType = $odataType
                }

                $summaryValue = Get-PropertyValue -InputObject $hit -PropertyName 'summary' -DefaultValue ''
                $nameValue = Get-PropertyValue -InputObject $resource -PropertyName 'name' -DefaultValue ''

                $title = ''
                if (-not [string]::IsNullOrWhiteSpace([string]$summaryValue)) {
                    $title = $summaryValue
                }
                elseif (-not [string]::IsNullOrWhiteSpace([string]$nameValue)) {
                    $title = $nameValue
                }

                $webUrl = Get-PropertyValue -InputObject $resource -PropertyName 'webUrl' -DefaultValue ''
                $citationPath = Get-ResourceCitationPath -Resource $resource
                $lastModified = Get-PropertyValue -InputObject $resource -PropertyName 'lastModifiedDateTime' -DefaultValue ''
                $resourceId = Get-PropertyValue -InputObject $resource -PropertyName 'id' -DefaultValue ''
                $hitId = Get-PropertyValue -InputObject $hit -PropertyName 'hitId' -DefaultValue ''

                $results += [PSCustomObject]@{
                    Rank                 = $rank
                    EntityType           = $entityType
                    Title                = $title
                    WebUrl               = $webUrl
                    CitationPath         = $citationPath
                    LastModifiedDateTime = $lastModified
                    ResourceId           = $resourceId
                    HitId                = $hitId
                }

                $rank++
            }
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $outputDirectory = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path $outputDirectory)) {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    }

    $results | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
}

if ($IncludeRawResponse) {
    [PSCustomObject]@{
        Query       = $Query
        EntityTypes = $resolvedEntityTypes
        ResultCount = $results.Count
        Results     = $results
        RawResponse = $response
    }
}
else {
    $results
}
