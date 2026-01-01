function Get-PuppetServiceStatus{
    <#
        .SYNOPSIS
            Get the current status of the Puppet agent service.
        .DESCRIPTION
            This function checks if the Puppet agent service is running and returns its status.
        .NOTES
            Author: Arnaud Charles
            Github: https://github.com/arnaudcharles
            Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    param ()
    try {
        $puppet_service_status = Get-Service -Name "Puppet agent" -ErrorAction SilentlyContinue

        # Check if the service exists
        if ($null -eq $puppet_service_status) {
            WriteColor Red ("Puppet service not found.")
            return "Not Found"
        }

        # Check Status
        if($puppet_service_status.Status -eq "Running"){
            WriteColor green ("Puppet service is running.")
        }
        else {
            WriteColor orange ("Puppet service is not running.")
        }
    }
    catch {
        Write-Error "Failed to get Puppet service status: $($_.Exception.Message)"
        Write-Verbose "Error details: $($_.Exception)"
    }
}