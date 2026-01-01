function Get-PuppetLastRuntime () {
  <#
  .SYNOPSIS
    Read the last puppet run.

  .DESCRIPTION
    This function reads the last Puppet run report and displays the last time Puppet ran and its status.

  .PARAMETER eventviewer
    If specified, the function will also check the event viewer for the last time Puppet ran successfully < 30 days ago.
    Alias 'e'.

  .EXAMPLE
    Example 1:
    PS> Get-PuppetLastRuntime
    This example is retrieving the last Puppet run report time and status. It can be unchanged, changed or failed.

    Example 2:
    PS> Get-PuppetLastRuntime eventviewer
    This example is retrieving the last time puppet ran successfully from the event viewer (max 30 days) then show the latest Puppet run report time and status. It can be unchanged, changed or failed.

  .NOTES
      Author: Arnaud Charles
      Github: https://github.com/arnaudcharles
      Linkedin: https://www.linkedin.com/in/arnaudcharles
  #>

  [CmdletBinding()]
    param(
      [Parameter()]
      [Alias('e')]
      [string]$eventviewer
  )

  # Scrap the event viewer for the last time Puppet ran successfully < 30 days ago
  if ($eventviewer) {
    $thirtyDaysAgo = (Get-Date).AddDays(-30)
    $query = (Get-WinEvent -LogName 'Application' |
        Where-Object {
            $_.TimeCreated -ge $thirtyDaysAgo -and
            $_.ProviderName -eq 'Puppet' -and
            $_.LevelDisplayName -eq 'Information' -and
            $_.Message -like '*Applied catalog in*'
        } |
        Sort-Object TimeCreated -Descending |
        Select-Object -First 1).TimeCreated
    $query = $query.ToString().Trim()

    if ($query) {
      WriteColor green ("Last time Puppet ran successfully: $query")
    }
    else {
      WriteColor red ("Puppet has never run successfully in the last 30 days")
    }
  }

  # Read the last run report
  $filePath = 'C:\ProgramData\PuppetLabs\puppet\cache\state\last_run_report.yaml'
  $content = Get-Content -Path $filePath -Raw

  $timePattern = 'time:\s*''([^'']+)'''
  $timeMatch = [regex]::Match($content, $timePattern)
  $statusPattern = 'status:\s*([^ \r\n]+)'
  $statusMatch = [regex]::Match($content, $statusPattern)

  $LRTime = [datetime]::Parse($timeMatch.Groups[1].Value).ToString('yyyy-MM-dd HH:mm:ss')
  $LRStatus = $statusMatch.Groups[1].Value

  WriteColor blue ("Last time Puppet run: $LRTime")
  switch ($LRStatus) {
    'failed' {
      WriteColor red ("Puppet run status: $LRStatus")
    }
    'changed' {
      WriteColor yellow ("Puppet run status: $LRStatus")
    }
    'unchanged' {
      WriteColor green ("Puppet run status: $LRStatus")
    }
    default {}
  }
}
