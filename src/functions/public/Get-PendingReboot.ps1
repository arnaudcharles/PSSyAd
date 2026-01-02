function Get-PendingReboot {
    <#
    .SYNOPSIS
        Determine if there is a pending reboot

    .DESCRIPTION
        This function will check different registry key to

    .EXAMPLE
        Get-PendingReboot

    .Notes
        Copied from http://ilovepowershell.com/2015/09/10/how-to-check-if-a-server-needs-a-reboot/
        Adapted from https://gist.github.com/altrive/5329377
        Based on http://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param()
    $rebootPending = $false

    if (Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { $rebootPending = $true }
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { $rebootPending = $true }
    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { $rebootPending = $true }
    try {
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if (($null -ne $status) -and $status.RebootPending) {
            $rebootPending = $true
        }
    }
    catch { Write-Output ""}

    # return result
    return $rebootPending
}