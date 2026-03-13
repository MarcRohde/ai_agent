# Test-WorkIQMailMcp.ps1
# Mail-specific wrapper around the generic Work IQ MCP smoke test.

[CmdletBinding()]
param(
    [string]$Endpoint = 'https://agent365.svc.cloud.microsoft/agents/servers/mcp_MailTools/',
    [int]$PreviewToolCount = 5,
    [switch]$SkipToolCall,
    [switch]$TryToolCall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$testArgs = @{
    Endpoint           = $Endpoint
    TokenEnvVar        = 'WORKIQ_MAIL_TOKEN'
    ExpectedToolPrefix = '*'
    ServerAlias        = 'workiq-mail'
    PreviewToolCount   = $PreviewToolCount
}

# Tool discovery is the stable baseline check for preview servers.
if ($TryToolCall.IsPresent -and -not $SkipToolCall.IsPresent) {
    $testArgs.ReadOnlyToolName = 'SearchMessages'
    $testArgs.ReadOnlyToolArguments = @{ message = 'my last 10 emails in my inbox, sorted by most recent first' }
}
else {
    $testArgs.SkipToolCall = $true
}

& "$PSScriptRoot\Test-WorkIQMcpServer.ps1" @testArgs
