function Get-PuppetState{
    <#
        .SYNOPSIS
            Get the current state of the Puppet agent.
        .DESCRIPTION
            This function retrieves the current state of the Puppet agent from the Puppet configuration.
        .NOTES
            Author: Arnaud Charles
            Github: https://github.com/arnaudcharles
            Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    Param()
    try {
        $agent_disabled_lockfile = "C:/ProgramData/PuppetLabs/puppet/cache/state/agent_disabled.lock"

        # Check if agent is disabled
        if (Test-Path $agent_disabled_lockfile){
            $agent_disabled_reason = (Get-Content -Path 'C:/ProgramData/PuppetLabs/puppet/cache/state/agent_disabled.lock' | ConvertFrom-Json).disabled_message
            WriteColor DarkYellow ("Puppet agent is disabled.")
            WriteColor Cyan ("$agent_disabled_reason")
        }
        else {
            WriteColor Green ("Puppet agent is enabled.")
        }
    }
    catch {
        Write-Error "Failed to retrieve Puppet runtime information: $($_.Exception.Message)"
        Write-Verbose "Exception details: $($_.Exception)"
    }
}
