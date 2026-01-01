function Connect() {
    <#
    .SYNOPSIS
        Connect to a remote host using PowerShell remoting.

    .DESCRIPTION
        Connect to a remote host using PowerShell remoting.

    .EXAMPLE
        connect -hostname 'server1'

    .EXAMPLE
        connect -protocol 'rdp' 'opendatwindows.domain.com'

    .EXAMPLE
        connect -protocol 'ssh' 'mylovelylinux.domain.com'

    .EXAMPLE
        connect -protocol 'ps' -user 'vador' -hostname 'darthvadercastle.domain.com'

    .EXAMPLE
        connect -protocol 'ssh' -user 'anakin' -hostname 'tatooine.domain.com'

    .PARAMETER hostname
        The hostname or FQDN of the server to connect to. (Mandatory)
        Use -hostname or -h.

    .PARAMETER protocol
        The protocol you want to use to connect. Can be 'ps','rdp','ssh' (Optional)
        Use -protocol or -p.

    .PARAMETER user
        The user you desire to use, reserved for the SSH protocol. (Optional)
        Use -user or -u.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('h')]
        [string]$hostname,
        [Parameter()]
        [Alias('p')]
        [string]$protocol = $null,
        [Parameter()]
        [Alias('u')]
        [string]$user
    )

    if ($PSBoundParameters.ContainsKey('protocol')) {
        switch ($protocol) {
            'ps' {
                if ($PSBoundParameters.ContainsKey('user')) {
                    Enter-PSSession -Computername $hostname -Credential $user -UseSSL
                }
                else {
                    Enter-PSSession $hostname -UseSSL
                }
            }
            'ssh' {
                if ($PSBoundParameters.ContainsKey('user')) {
                    ssh -m hmac-sha2-512-etm@openssh.com "${user}@$hostname"
                }
                else {
                    $user = (whoami).split("\")[1]
                    ssh -m hmac-sha2-512-etm@openssh.com "${user}@$hostname"
                }
            }
            'rdp' {
                mstsc /v:$hostname /prompt
            }
            'srdp' {
                mstsc /v:$hostname /remoteGuard
            }
            default {
                Throw "Protocol not defined in PSSyAd module"
            }
        }
    }
    else {
        # Using PS Remote as default
        Enter-PSSession $hostname -UseSSL
    }
}