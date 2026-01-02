Function Get-MemoryStat {
    <#
    .SYNOPSIS
        This function retrieves memory statistics for each process running on the system.

    .DESCRIPTION
        This function retrieves memory statistics for each process running on the system. It groups the processes by name and displays the total memory used by each process.

    .EXAMPLE
        Get-MemoryStat

    .NOTES
        Author: Marnix Van Lint
        Github: https://github.com/coatico
    #>

    [CmdletBinding()]
    param ()

    get-process | Sort-Object WorkingSet64 | Group-Object -Property ProcessName | Format-Table Name, @{n='Mem (KB)';e={'{0:N0}' -f (($_.Group|Measure-Object WorkingSet64 -Sum).Sum / 1KB)};a='right'} -AutoSize
}