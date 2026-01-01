Function Get-NumberLine {
    <#
    .Synopsis
        Mimic Unic / Linux tool nl number lines

    .Description
        Print file content with numbered lines no original nl options supported

    .Example
        nl .\food.txt

    .NOTES
        Author: Marnix Van Lint
        Github: https://github.com/coatico
    #>

    [CmdletBinding()]
    param (
        [parameter(mandatory = $true, Position = 0)][String]$FileName
    )

    process {
        If (Test-Path $FileName) {
            Get-Content $FileName | ForEach-Object { "{0,5}  {1}" -f $_.ReadCount, $_ }
        }
    }
}