Function Get-FQDNSubDomain {
    <#
    .SYNOPSIS
        Returns the subdomain of the current FQDN

    .DESCRIPTION
        Returns the subdomain of the current FQDN

    .EXAMPLE
        Get-FQDNSubDomain

    .NOTES
        Author: Marnix Van Lint
        Github: https://github.com/coatico
    #>

    [CmdletBinding()]
    param()
    return $([System.Net.Dns]::GetHostEntry("$env:computername").HostName.Split('.'))[1..$(([System.Net.Dns]::GetHostEntry("$env:computername").HostName.Split('.')).count-1)] -join '.'
}