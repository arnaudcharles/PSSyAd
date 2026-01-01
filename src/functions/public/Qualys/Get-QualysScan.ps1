Function Get-QualysScan {
    <#
    .SYNOPSIS
        Check Qualys scan status

    .DESCRIPTION
        Check Qualys scan status

    .EXAMPLE
        Check-QualysScan

    .NOTES
        Author : Ivica Agatunovic
        WebSite: https://github.com/ivicaagatunovic
        Linkedin: www.linkedin.com/in/ivica-agatunovic-96090024
    #>

    [CmdletBinding()]
    param()
    $Path = "HKLM:\software\Qualys\QualysAgent\ScanOnDemand\Vulnerability"
    $scanStatus = Get-ItemProperty -Path $Path -Name 'ScanOnDemand'
    switch ($scanStatus.ScanOnDemand) {
        0 { Write-Output "The Qualys scan has completed." }
        1 { Write-Output "The Qualys scan is starting." }
        2 { Write-Output "The Qualys scan is currently in progress." }
        default { Write-Output "Unknown scan status." }
    }
}
