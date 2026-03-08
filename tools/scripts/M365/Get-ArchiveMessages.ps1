<#
.SYNOPSIS
    Retrieve the last 10 messages from the Archive folder.
#>

param(
    [ValidateRange(1, 100)]
    [int]$Top = 10,
    [string]$AccessTokenEnvVar = 'M365_GRAPH_ACCESS_TOKEN'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Get token from cache
$token = [Environment]::GetEnvironmentVariable($AccessTokenEnvVar, 'User')
if ([string]::IsNullOrWhiteSpace($token)) {
    $token = [Environment]::GetEnvironmentVariable($AccessTokenEnvVar, 'Process')
}

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error "No cached token found. Run tools/scripts/M365/Get-M365GraphAccessToken.ps1 first."
    exit 1
}

$headers = @{ Authorization = "Bearer $token" }

# Resolve archive folder via well-known folder name first (locale-safe).
$archiveFolder = $null
try {
    $archiveFolder = Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/me/mailFolders/archive' -Headers $headers -Method Get -ErrorAction Stop
}
catch {
    Write-Verbose "Well-known archive endpoint failed. Falling back to folder list lookup."
}

if ($null -eq $archiveFolder) {
    Write-Verbose "Retrieving mail folders..."
    $foldersUri = "https://graph.microsoft.com/v1.0/me/mailFolders"
    $foldersResponse = Invoke-RestMethod -Uri $foldersUri -Headers $headers -Method Get -ErrorAction Stop

    foreach ($folder in $foldersResponse.value) {
        if ($folder.displayName -ieq 'Archive') {
            $archiveFolder = $folder
            break
        }
    }

    if ($null -eq $archiveFolder) {
        Write-Host "Archive folder not found. Available folders:" -ForegroundColor Yellow
        $foldersResponse.value | ForEach-Object {
            Write-Host "  - $($_.displayName)"
        }
        exit 1
    }
}

Write-Host "Found Archive folder. Retrieving messages..." -ForegroundColor Green

# Get messages from archive folder
$messagesUri = "https://graph.microsoft.com/v1.0/me/mailFolders/$($archiveFolder.id)/messages?`$top=$Top&`$orderby=receivedDateTime desc&`$select=subject,from,receivedDateTime,bodyPreview"
$messagesResponse = Invoke-RestMethod -Uri $messagesUri -Headers $headers -Method Get -ErrorAction Stop

if ($messagesResponse.value -and $messagesResponse.value.Count -gt 0) {
    Write-Host "`nLast $($messagesResponse.value.Count) messages in Archive:`n" -ForegroundColor Green

    $messagesResponse.value | ForEach-Object {
        $fromEmail = if ($_.from.emailAddress) { $_.from.emailAddress.address } else { "Unknown" }
        $received = [DateTime]::Parse($_.receivedDateTime).ToString("MMM dd, yyyy HH:mm")
        $preview = if ($_.bodyPreview) { $_.bodyPreview.Substring(0, [Math]::Min(80, $_.bodyPreview.Length)) } else { "(no preview)" }

        Write-Host "📧 $($_.subject)" -ForegroundColor Yellow
        Write-Host "   From: $fromEmail"
        Write-Host "   Received: $received"
        Write-Host "   Preview: $preview..."
        Write-Host ""
    }
}
else {
    Write-Host "No messages found in Archive folder." -ForegroundColor Yellow
}
