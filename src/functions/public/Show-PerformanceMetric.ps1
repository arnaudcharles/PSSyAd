function Show-PerformanceMetric {
    <#
    .SYNOPSIS
        This command aims to mimic what the top command does on linux systems. Display the relevant resource monitoring statistics of the machine it's run on.
        Resource monitoring statistics include: CPU Load in %, Memory usage (in GB, %, virtual/swap/physical), Disk space usage of the available inialised disks and processes running.
        Based on the code reddit user u\rossiusyves wrote, this got me started when i was looking on how to get a nice graphic representation. link-> https://www.reddit.com/r/PowerShell/comments/cy9lyq/top_alternative_for_powershell/

    .PARAMETER Refreshrate
        Int value that represents the rate at which the data shown is updated

    .PARAMETER ProcessSort
        String value of a validated set ('CPU','Id','ProcessName','WorkingSet64','StartTime','PriorityClass','VirtualMemorySize64','Description'),
        which will be the Sorting filter for the process (process' with highest ...). Some of the parameters are renamed and reformatted (from bytes to MB) for easier reading:
        ProcessName = Name | WorkingSet64 = Physical Memory (MB) | VirtualMemorySize64 = Virtual Memory (MB)

    .PARAMETER ProcessCount
        Int value that represents the amount of process' shown.

    .EXAMPLE
        Show-PerformanceMetric # there should be an alias 'top'
        top -refreshrate 10 (will show the pefromancemetrics and refresh each 10 seconds)
        top -Refreshrate 10 -ProcessSort WorkingSet64 -ProcessCount 15 (will show the process using the most physical memory, display 15 process at a refresh interval of 10 seconds)

    .NOTES
        Author: Marnix Van Lint
        Github: https://github.com/coatico
    #>

    [CmdletBinding()]
    param(
        [int]$Refreshrate = 4,
        [ValidateSet('CPU','Id','ProcessName','WorkingSet64','StartTime','PriorityClass','VirtualMemorySize64','Description')]
        [String]$ProcessSort = 'CPU',
        [int32]$ProcessCount = 10
    )
    Clear-Host

    $LoadHistory     = @()

    while (1) {
        # Calculate different metrics. Can be updated by editing the value-key pairs in $Currentload.
        $OS        = Get-Ciminstance Win32_OperatingSystem
        #CPU LOAD
        $cpuDetail = Get-CimInstance -ClassName Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,LoadPercentage
        $raw       = $cpuDetail.LoadPercentage | Measure-Object -Sum
        $cpuLoad   = $raw.sum / $raw.Count

        #MEMORY LOAD
        $memoryStat = Get-Ciminstance Win32_OperatingSystem | Select-Object @{Name='FreePhysicalMemory (GB)';Expression={ ([math]::Round(($_.FreePhysicalMemory / 1024KB),2))}},
        @{ Name = 'UsedPhysicalMemory (GB)';Expression={[math]::Round((($_.TotalVisibleMemorySize / 1024KB) - ($_.FreePhysicalMemory / 1024KB)),2)}},
        @{ Name = 'TotalPhyiscalMemorySize (GB)';Expression={[math]::Round(($_.TotalVisibleMemorySize / 1024KB))}},
        @{ Name = 'TotalPhyiscalMemoryUsage (%)';Expression={[math]::Round((((($_.TotalVisibleMemorySize / 1024KB) - ($_.FreePhysicalMemory / 1024KB)) /($_.TotalVisibleMemorySize / 1024KB)  )*100))}},
        @{ Name = 'FreeVirtualMemory (GB)';Expression={[math]::Round(($_.FreeVirtualMemory / 1024KB),2)}},
        @{ Name = 'TotalVirtualMemorySize (GB)';Expression={[math]::Round(($_.TotalVirtualMemorySize / 1024KB),2)}}
        $ramLoad = [math]::round((100 - ($OS.FreePhysicalMemory/$OS.TotalVisibleMemorySize)*100))
        $pagefileLoad = [math]::round((($OS.FreeVirtualMemory/$OS.TotalVirtualMemorySize)*100))
        # DISKS
        $diskUsage = @{}
        get-psdrive | Where-Object Name -in $(Get-Volume).DriveLetter | ForEach-Object{
            $diskUsage += @{
                    "Drive $($_.name) " = [math]::Round(( $_.Used  / ($_.Free + $_.Used ))*100, 2)
                }
            }
        $diskDetail = @{}
            get-psdrive | Where-Object Name -in $(Get-Volume).DriveLetter | ForEach-Object{
                $diskDetail+= @{
                    "Drive $($_.name)" = "$([math]::Round(( $_.Used  / ($_.Free + $_.Used ))*100, 2))% Full ($([math]::Round(($_.Used / 1gb),2)) GB of $([math]::Round(($_.Free / 1gb + $_.Used / 1gb),2)) GB used ) || "
                    }
                }

        #Process
        $CurrentLoad = [ordered]@{
                                    "CPU Load ($cpuLoad%)"            = $cpuLoad
                                    "RAM Usage ($ramLoad%)"           = $ramLoad
                                    "Pagefile Usage ($pagefileLoad%)" = $pagefileLoad
                        }
        $LoadHistory += $CurrentLoad
        # Reset cursor and overwrite prior output

        Clear-Host
        $host.UI.RawUI.CursorPosition = @{x=0; y=1}

        # Output on screen
        #Get-Graph -Datapoints ($LoadHistory."CPU Load" | select -Last $BufferSizeWidth)

        Write-host ""
        $CurrentLoad.GetEnumerator() | Get-MetricBar | Write-Host -ForegroundColor "DarkCyan"
        Write-host ""
        $diskUsage.GetEnumerator() | Get-MetricBar | Write-Host -ForegroundColor "Green"
        Write-host ""
        write-host "CPU Details    : $($cpuDetail | Select-Object -Unique | ForEach-Object{$_} )" -ForegroundColor DarkYellow
        write-host "Memory Details : $($memoryStat | ForEach-Object{$_} )" -ForegroundColor DarkYellow
        write-host "Disk Details   : $($diskDetail.Keys | ForEach-Object { write-output "$($_) - $($diskdetail."$($_)")"})" -ForegroundColor DarkYellow
        Write-host ""
        Get-Process | Sort-Object $ProcessSort -desc | Select-Object -first $ProcessCount | Format-Table @{Name='PID';Expression={$_.Id}},
                                                        @{Name='Name';Expression={$_.ProcessName}},
                                                        @{Name='CPU';Expression={[math]::Round($_.CPU,2)}},
                                                        @{Name='Physical Memory(MB)';Expression={[math]::Round($_.WorkingSet64/ 1mb,2)}},
                                                        @{Name='Virtual Memory(MB)';Expression={[math]::Round($_.VirtualMemorySize64/1024mb,2)}},
                                                        PriorityClass,
                                                        Description  -AutoSize | Out-Host
        Write-host ""
        Start-Sleep $Refreshrate
    }
}



