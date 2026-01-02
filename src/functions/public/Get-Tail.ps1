Function Get-Tail {
    <#
    .SYNOPSIS
        quivalent of NIX tail -f

    .DESCRIPTION
        Will monitor any kind of text readable log and show changes in real time

    .EXAMPLE
        Get-Tail c:\somelog.log

    .NOTES
        Author: Marnix Van Lint
        Github: https://github.com/coatico
    #>

    [CmdletBinding()]Param(
        [String]$FilePath
    )

    if (![string]::IsNullOrEmpty($FilePath)) {
        Get-Content -Path "$FilePath" -Wait
    }
    else {
        write-output 'You did not select a file.'
    }
}
