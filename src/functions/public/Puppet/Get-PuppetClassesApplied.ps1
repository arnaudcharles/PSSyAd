function Get-PuppetClassesApplied (){
    <#
    .SYNOPSIS
        Get the puppet classes that have been applied to the current machine.

    .DESCRIPTION
        Get the puppet classes that have been applied to the current machine.

    .EXAMPLE
        Get-PuppetClassesApplied
    #>

    [CmdletBinding()]
    param()

    Get-Content 'C:\ProgramData\puppetlabs\puppet\cache\state\classes.txt'
}