function WriteColor(){
    <#
    .SYNOPSIS
        This function writes text to the console with a specified color.

    .DESCRIPTION
        This function is there to help us write colored output to the console without using Write-Host as it is not recommended.
        See https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/avoidusingwritehost?view=ps-modules for more information.

    .EXAMPLE
        Example 1:
        WriteColor blue (MyCommand)
        WriteColor blue (pwd)

        Example 2:
        WriteColor blue ("MyText")

    .EXAMPLE
        Available colors are:
        - Black
        - DarkBlue
        - DarkGreen
        - DarkCyan
        - DarkRed
        - DarkMagenta
        - DarkYellow
        - Gray
        - DarkGray
        - Blue
        - Green
        - Cyan
        - Red
        - Magenta
        - Yellow
        - White

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ForegroundColor,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputText
    )

    process {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    $InputText | Write-Output
    $host.UI.RawUI.ForegroundColor = $fc
    }
}