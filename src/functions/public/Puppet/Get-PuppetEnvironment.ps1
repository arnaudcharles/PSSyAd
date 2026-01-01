function Get-PuppetEnvironment{
    <#
        .SYNOPSIS
            Get the current Puppet environment.
        .DESCRIPTION
            This function retrieves the current Puppet environment from the Puppet configuration.
        .NOTES
            Author: Arnaud Charles
            Github: https://github.com/arnaudcharles
            Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>
    [CmdletBinding()]
    param()
    try {
        $puppet_environment = (puppet config print environment)
        $simplified_puppet_environment = $puppet_environment -replace 'core_', ''

        Write-Host "Puppet environment is set to " -NoNewline
        if ($simplified_puppet_environment -match 'sandbox|preprod|prod') {
            WriteColor Cyan ("'$simplified_puppet_environment'")
        }
        elseif ($simplified_puppet_environment -match 'dev') {
            WriteColor Magenta ("'$simplified_puppet_environment'")
        }
        else {
            WriteColor White ("'$puppet_environment'")
        }
    }
    catch {
        Write-Error "Failed to retrieve Puppet environment: $($_.Exception.Message)"
        Write-Verbose "Error details: $($_.Exception)"
    }
}