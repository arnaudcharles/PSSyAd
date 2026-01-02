Function Test-IsValidVersion{
    <#
    .SYNOPSIS
        Check if the version given in argument fit with the format ([0-9]+.)*[0-9]+

    .DESCRIPTION
        Check if the version given in argument fit with the format ([0-9]+.)*[0-9]+
        ex:
        - 2 : $True
        - 2.11 : $True
        - 2.1c : $False

    .PARAMETER Version
        Has to fit the format ([0-9]+.)*[0-9]+ (ex: 2 | 2.11 | 2.0.1)

    .OUTPUTS
        Boolean status of the valid format of the version

    .EXAMPLE
        Test-IsValidVersion 2

        Returns $True

    .EXAMPLE
        Test-IsValidVersion 2.1c

        Returns $False
    #>

    [OutputType('System.Boolean')]
    [CmdletBinding()]
    param(
        [String]$version
    )

    return $version -match "^\d+(\.\d+)*$"
}