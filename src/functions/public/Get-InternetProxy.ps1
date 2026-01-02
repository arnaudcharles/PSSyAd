function Get-InternetProxy {
  <#
    .SYNOPSIS
      Determine the internet proxy address

    .DESCRIPTION
      This function allows you to determine the the internet proxy address used by your computer

    .EXAMPLE
      Get-InternetProxy

    .Notes
      Author : Antoine DELRUE
      WebSite: http://obilan.be
  #>

  [CmdletBinding()]
  param()
  $proxies = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').proxyServer

  if ($proxies) {
    if ($proxies -ilike "*=*") {
      $proxies -replace "=", "://" -split (';') | Select-Object -First 1
    }

    else {
      "http://" + $proxies
    }
  }
}