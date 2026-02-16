<#
.SYNOPSIS
    Interact with Outlook mailbox via Microsoft Graph PowerShell SDK.

.DESCRIPTION
    Provides read, search, send, reply, summarize, and list-folders operations
    against the authenticated user's Outlook mailbox. Requires the Microsoft.Graph
    module and an active connection (Connect-MgGraph).

.PARAMETER Operation
    The operation to perform: Read, Search, Send, Reply, Summarize, ListFolders.

.PARAMETER Count
    Number of messages to retrieve (default: 10, max: 50).

.PARAMETER Folder
    Mail folder name (default: Inbox).

.PARAMETER Query
    Search query string (for Search operation).

.PARAMETER MessageId
    Specific message ID (for Reply or single-message read).

.PARAMETER To
    Recipient email address (for Send).

.PARAMETER Subject
    Email subject (for Send).

.PARAMETER Body
    Email body text (for Send / Reply).

.PARAMETER SummaryScope
    Scope for Summarize: "today", "unread", "last-week" (default: "today").

.EXAMPLE
    .\outlook_mailbox.ps1 -Operation Read -Count 5
    .\outlook_mailbox.ps1 -Operation Search -Query "budget report"
    .\outlook_mailbox.ps1 -Operation Send -To "user@example.com" -Subject "Hello" -Body "Test message"
    .\outlook_mailbox.ps1 -Operation Summarize -SummaryScope "unread"
    .\outlook_mailbox.ps1 -Operation ListFolders
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Read", "Search", "Send", "Reply", "Summarize", "ListFolders")]
    [string]$Operation,

    [int]$Count = 10,
    [string]$Folder = "Inbox",
    [string]$Query = "",
    [string]$MessageId = "",
    [string]$To = "",
    [string]$Subject = "",
    [string]$Body = "",
    [string]$SummaryScope = "today"
)

$ErrorActionPreference = "Stop"

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Assert-GraphConnection {
    try {
        $ctx = Get-MgContext
        if (-not $ctx) { throw "No context" }
        Write-Verbose "Connected as $($ctx.Account)"
    }
    catch {
        Write-Error @"
Not connected to Microsoft Graph.
Run:  Connect-MgGraph -Scopes "Mail.Read","Mail.Send","Mail.ReadWrite"
"@
        exit 1
    }
}

function Get-FolderId {
    param([string]$FolderName)

    # Well-known folder names map directly
    $wellKnown = @{
        "Inbox"      = "Inbox"
        "SentItems"  = "SentItems"
        "Sent Items" = "SentItems"
        "Drafts"     = "Drafts"
        "Archive"    = "Archive"
        "DeletedItems" = "DeletedItems"
        "Deleted Items" = "DeletedItems"
        "JunkEmail"  = "JunkEmail"
        "Junk"       = "JunkEmail"
    }

    if ($wellKnown.ContainsKey($FolderName)) {
        return $wellKnown[$FolderName]
    }

    # Try to find by display name
    $folders = Get-MgUserMailFolder -UserId "me" -Filter "displayName eq '$FolderName'"
    if ($folders) {
        return $folders[0].Id
    }

    Write-Warning "Folder '$FolderName' not found. Falling back to Inbox."
    return "Inbox"
}

function Format-EmailTable {
    param([array]$Messages)

    $results = @()
    $i = 1
    foreach ($msg in $Messages) {
        $unread = if ($msg.IsRead -eq $false) { [char]0x2709 } else { "" }
        $results += [PSCustomObject]@{
            "#"       = $i
            From      = $msg.From.EmailAddress.Address
            Subject   = $msg.Subject
            Date      = $msg.ReceivedDateTime.ToString("yyyy-MM-dd HH:mm")
            Unread    = $unread
            MessageId = $msg.Id
        }
        $i++
    }
    return $results
}

# ─── Operations ───────────────────────────────────────────────────────────────

function Invoke-ReadMail {
    $folderId = Get-FolderId -FolderName $Folder
    $clampedCount = [Math]::Min($Count, 50)

    $messages = Get-MgUserMailFolderMessage -UserId "me" -MailFolderId $folderId `
        -Top $clampedCount -OrderBy "receivedDateTime desc" `
        -Property "id,subject,from,receivedDateTime,isRead,bodyPreview"

    if (-not $messages -or $messages.Count -eq 0) {
        Write-Host "No messages found in $Folder."
        return
    }

    $table = Format-EmailTable -Messages $messages
    $table | Format-Table "#", From, Subject, Date, Unread -AutoSize | Out-String | Write-Host

    # Show preview of the first message
    Write-Host "`n--- Preview: Message #1 ---"
    Write-Host "From:    $($messages[0].From.EmailAddress.Address)"
    Write-Host "Subject: $($messages[0].Subject)"
    Write-Host "Date:    $($messages[0].ReceivedDateTime)"
    Write-Host ""
    Write-Host ($messages[0].BodyPreview | Select-Object -First 1)
}

function Invoke-SearchMail {
    if (-not $Query) {
        Write-Error "Search requires -Query parameter."
        exit 1
    }

    $folderId = Get-FolderId -FolderName $Folder
    $clampedCount = [Math]::Min($Count, 50)

    # Use $search for full-text search across subject, body, sender
    $messages = Get-MgUserMailFolderMessage -UserId "me" -MailFolderId $folderId `
        -Search "`"$Query`"" -Top $clampedCount `
        -Property "id,subject,from,receivedDateTime,isRead,bodyPreview"

    if (-not $messages -or $messages.Count -eq 0) {
        Write-Host "No messages matching '$Query' in $Folder."
        return
    }

    Write-Host "Search results for: '$Query'"
    $table = Format-EmailTable -Messages $messages
    $table | Format-Table "#", From, Subject, Date, Unread -AutoSize | Out-String | Write-Host
}

function Invoke-SendMail {
    if (-not $To) { Write-Error "Send requires -To parameter."; exit 1 }
    if (-not $Subject) { Write-Error "Send requires -Subject parameter."; exit 1 }
    if (-not $Body) { Write-Error "Send requires -Body parameter."; exit 1 }

    $params = @{
        Message = @{
            Subject = $Subject
            Body = @{
                ContentType = "Text"
                Content = $Body
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = $To
                    }
                }
            )
        }
        SaveToSentItems = $true
    }

    Send-MgUserMessage -UserId "me" -BodyParameter $params
    Write-Host "Email sent successfully."
    Write-Host "  To:      $To"
    Write-Host "  Subject: $Subject"
    Write-Host "  Time:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

function Invoke-ReplyMail {
    if (-not $MessageId) { Write-Error "Reply requires -MessageId parameter."; exit 1 }
    if (-not $Body) { Write-Error "Reply requires -Body parameter."; exit 1 }

    $params = @{
        Message = @{
            Body = @{
                ContentType = "Text"
                Content = $Body
            }
        }
        Comment = $Body
    }

    # Show original message for context
    $original = Get-MgUserMessage -UserId "me" -MessageId $MessageId `
        -Property "subject,from,receivedDateTime,bodyPreview"

    Write-Host "Replying to:"
    Write-Host "  From:    $($original.From.EmailAddress.Address)"
    Write-Host "  Subject: $($original.Subject)"
    Write-Host "  Date:    $($original.ReceivedDateTime)"
    Write-Host ""

    Invoke-MgReplyUserMessage -UserId "me" -MessageId $MessageId -BodyParameter $params
    Write-Host "Reply sent successfully."
}

function Invoke-SummarizeMail {
    $folderId = Get-FolderId -FolderName $Folder

    $filter = switch ($SummaryScope) {
        "today" {
            $todayStart = (Get-Date).Date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "receivedDateTime ge $todayStart"
        }
        "unread" {
            "isRead eq false"
        }
        "last-week" {
            $weekAgo = (Get-Date).AddDays(-7).Date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "receivedDateTime ge $weekAgo"
        }
        default {
            "isRead eq false"
        }
    }

    $messages = Get-MgUserMailFolderMessage -UserId "me" -MailFolderId $folderId `
        -Filter $filter -Top 50 -OrderBy "receivedDateTime desc" `
        -Property "id,subject,from,receivedDateTime,isRead,bodyPreview,importance"

    if (-not $messages -or $messages.Count -eq 0) {
        Write-Host "No messages found for scope: $SummaryScope"
        return
    }

    $total = $messages.Count
    $unread = ($messages | Where-Object { $_.IsRead -eq $false }).Count
    $highImportance = ($messages | Where-Object { $_.Importance -eq "High" })

    Write-Host "=== Email Summary ($SummaryScope) ==="
    Write-Host "Total: $total | Unread: $unread | High importance: $($highImportance.Count)"
    Write-Host ""

    if ($highImportance.Count -gt 0) {
        Write-Host "--- High Importance ---"
        foreach ($msg in $highImportance) {
            Write-Host "  ! $($msg.From.EmailAddress.Address) — $($msg.Subject)"
        }
        Write-Host ""
    }

    # Group by sender
    $grouped = $messages | Group-Object { $_.From.EmailAddress.Address }
    foreach ($group in ($grouped | Sort-Object Count -Descending)) {
        Write-Host "--- $($group.Name) ($($group.Count) emails) ---"
        foreach ($msg in $group.Group) {
            $readMark = if ($msg.IsRead -eq $false) { "[UNREAD] " } else { "" }
            $preview = ($msg.BodyPreview -replace '\s+', ' ').Substring(0, [Math]::Min(100, $msg.BodyPreview.Length))
            Write-Host "  ${readMark}$($msg.Subject)"
            Write-Host "    $preview..."
        }
        Write-Host ""
    }

    # Output structured JSON for the agent to parse
    $summary = @{
        Scope = $SummaryScope
        Total = $total
        Unread = $unread
        HighImportance = $highImportance.Count
        Messages = $messages | ForEach-Object {
            @{
                Id = $_.Id
                From = $_.From.EmailAddress.Address
                Subject = $_.Subject
                Date = $_.ReceivedDateTime.ToString("yyyy-MM-dd HH:mm")
                IsRead = $_.IsRead
                Importance = $_.Importance
                Preview = $_.BodyPreview
            }
        }
    }
    Write-Host "`n=== JSON ==="
    $summary | ConvertTo-Json -Depth 4
}

function Invoke-ListFolders {
    $folders = Get-MgUserMailFolder -UserId "me" -Top 50 `
        -Property "displayName,totalItemCount,unreadItemCount"

    if (-not $folders -or $folders.Count -eq 0) {
        Write-Host "No mail folders found."
        return
    }

    $folders | Sort-Object -Property TotalItemCount -Descending |
        Select-Object @{N="Folder";E={$_.DisplayName}},
                      @{N="Total";E={$_.TotalItemCount}},
                      @{N="Unread";E={$_.UnreadItemCount}} |
        Format-Table -AutoSize | Out-String | Write-Host
}

# ─── Main ─────────────────────────────────────────────────────────────────────

Assert-GraphConnection

switch ($Operation) {
    "Read"        { Invoke-ReadMail }
    "Search"      { Invoke-SearchMail }
    "Send"        { Invoke-SendMail }
    "Reply"       { Invoke-ReplyMail }
    "Summarize"   { Invoke-SummarizeMail }
    "ListFolders" { Invoke-ListFolders }
}
