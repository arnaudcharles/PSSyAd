function Get-PuppetRunStatus{
    <#
        .SYNOPSIS
            Retrieves the status of a Puppet run.

        .DESCRIPTION
            The Get-PuppetRunStatus function is used to retrieve the status of a Puppet run. It provides information about whether the run was successful or encountered any errors.

        .NOTES
            Author: Arnaud Charles
            Github: https://github.com/arnaudcharles
            Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>
    [CmdletBinding()]
    Param()
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $s = 0

    while (Test-Path -Path 'C:/ProgramData/PuppetLabs/puppet/cache/state/agent_catalog_run.lock') {
        Write-Host -ForegroundColor Cyan -Object "Puppet run ongoing $($spinner[$s % $spinner.Count])" -NoNewline
        Start-Sleep -Seconds 1
        Write-Host -Object "`r" -NoNewline
        $s++
    }

    Write-Host ""
    Write-Host -ForegroundColor Green -Object "No Puppet run ongoing"
}