function Get-HotfixAll {
    <#
    .SYNOPSIS
        Get all installed hotfixes on the system

    .DESCRIPTION
        Get all installed hotfixes on the system

    .EXAMPLE
        Get-HotfixAll
    #>

    [CmdletBinding()]
    param()
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $HistoryCount = $Searcher.GetTotalHistoryCount()
    # http://msdn.microsoft.com/en-us/library/windows/desktop/aa386532%28v=vs.85%29.aspx
    $Searcher.QueryHistory(0, $HistoryCount) | ForEach-Object -Process {
        $Title = $_.Title
        if ($_.Title -match "(KB\d{6,7})") {
            # Split returns an array of strings
            $KB = ($_.Title -split '(KB\d{6,7})')[1]
        }
        else {
            $KB = $_.Title
        }
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa387095%28v=vs.85%29.aspx
        $Result = $null
        Switch ($_.ResultCode) {
            0 { $Result = 'NotStarted' }
            1 { $Result = 'InProgress' }
            2 { $Result = 'Succeeded' }
            3 { $Result = 'SucceededWithErrors' }
            4 { $Result = 'Failed' }
            5 { $Result = 'Aborted' }
            default { $Result = $_ }
        }
        New-Object -TypeName PSObject -Property @{
            InstalledOn = Get-Date -Date $_.Date
            Title       = $Title
            KB          = $KB
            Name        = $KB
            Status      = $Result
        }

    } | Sort-Object -Descending:$true -Property InstalledOn |
    Select-Object -Property * -ExcludeProperty Name | Format-Table -AutoSize -Wrap
}