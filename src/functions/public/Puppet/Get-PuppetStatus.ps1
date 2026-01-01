function Get-PuppetStatus{
    <#
        .SYNOPSIS
            Get an overall status of the Puppet agent on the local machine.
        .DESCRIPTION
            This function runs a series of checks to provide an overall status of the Puppet agent on the local machine. It checks the Puppet service status, Puppet state, Puppet environment, and the last Puppet run status.
        .NOTES
            Author: Arnaud Charles
            Github: https://github.com/arnaudcharles
            Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    Param()

    # Check 1: Puppet service status
    Write-Host ">> Checking Puppet service status"
    Get-PuppetServiceStatus
    Write-Host ""

    # Check 2: Puppet state
    Write-Host ">> Checking Puppet state"
    Get-PuppetState
    Write-Host ""

    # Check 3: Environment
    Write-Host ">> Checking Puppet environment"
    Get-PuppetEnvironment
    Write-Host ""

    # Check 4: Last Puppet run
    Write-Host ">> Checking last Puppet run"
    Get-PuppetLastRuntime -eventviewer
}