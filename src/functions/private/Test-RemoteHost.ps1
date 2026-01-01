function Test-RemoteHost {
    <#
    .SYNOPSIS
        Use to test if a remote host is reachable.

    .DESCRIPTION
        Use this function to test if your host is reachable before acting on anything else like CIMsession

    .EXAMPLE
        Test-RemoteHost -hostname 'server1'
        Test-RemoteHost -h 'server1'

    .PARAMETER hostname
        The hostname or FQDN of the server to connect to. (Mandatory)
        Use -hostname or -h.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory)]
        [Alias('h')]
        [string]$hostname
    )

    try {
        $test = Test-WSMan -ComputerName $hostname -UseSSL -ErrorAction Stop
        if ($test) {
            return $True
        }
    } catch {
        throw $False
    }
}
