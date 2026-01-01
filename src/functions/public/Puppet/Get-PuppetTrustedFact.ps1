function Get-PuppetTrustedFact (){
  <#
    .SYNOPSIS
    Get the puppet trusted facts that have been applied to the current machine.

    .DESCRIPTION
    Get the puppet trusted facts that have been applied to the current machine.

    .EXAMPLE
    Get-PuppetTrustedFact
    #>
  [CmdletBinding()]
  param()

  return (Get-Content C:\ProgramData\PuppetLabs\facter\facts.d\ingenico.json | ConvertFrom-Json ).ingenico
}