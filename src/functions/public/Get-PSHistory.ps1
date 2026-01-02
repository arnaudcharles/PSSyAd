function Get-PSHistory {
    <#
    .SYNOPSIS
        Get the history of the current PowerShell session.

    .DESCRIPTION
        Get the history of the current PowerShell session.

    .EXAMPLE
        Get-PSHistory
    #>

    [CmdletBinding()]
    param()
    Get-Content (Get-PSReadLineOption).HistorySavePath
}
