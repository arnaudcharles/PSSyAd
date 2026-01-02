Function Start-QualysScan {
    <#
    .SYNOPSIS
        Lunch Qualys scan

    .DESCRIPTION
        Lunch Qualys scan

    .EXAMPLE
        Start-QualysScan
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions",
        "",
        Justification = "Registry Key specific to Qualys"
    )]
    [CmdletBinding(
        ConfirmImpact = 'None'
    )]
    param()

    $Path = "HKLM:\software\Qualys\QualysAgent\ScanOnDemand\Vulnerability"
    $scanStatus = Get-ItemProperty -Path $Path -Name 'ScanOnDemand'

    if ($scanStatus.ScanOnDemand -eq 2) {
        Write-Output "A Qualys scan is already in progress"
        return
    }

    $qualysPath = "HKLM:\software\Qualys\QualysAgent\ScanOnDemand"
    Set-ItemProperty -Path "$qualysPath\Inventory" -Name ScanOnDemand -Value 1
    Set-ItemProperty -Path "$qualysPath\Vulnerability" -Name ScanOnDemand -Value 1
    Write-Output "Qualys scan has been initiated"
}
