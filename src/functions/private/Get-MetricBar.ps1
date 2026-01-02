function Get-MetricBar {
    <#
    .SYNOPSIS
        This command is a helper function used to draw metric bars in your powershell session. Used by Show-PerformanceMetrics.
        Based on the code reddit user u\rossiusyves wrote, this got me started when i was looking on how to get a nice graphic representation. link-> https://www.reddit.com/r/PowerShell/comments/cy9lyq/top_alternative_for_powershell/

    .PARAMETER Key
        The name of the metric to be displayed i.e. CPU, Memory ...

    .PARAMETER Refreshrate
        The numeric value of the metric to be shown (value between 0-100) i.e. if the cpu is 43.3 % this would be 43.3 in the int data type.

    .NOTES
        Author: Marnix Van Lint
        Github: https://github.com/coatico
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, Position=0, ValueFromPipelineByPropertyName)]
        [Alias('Key')]
        $Metric,
        [Parameter(Mandatory=$True, Position=1, ValueFromPipelineByPropertyName)]
        [Alias('Value')]
        $MetricValue
    )
    Process {
        # Generate string respresenting metric bar for the metric in the pipeline.
        -join @(
            $Metric.toUpper()
            ': '
            ' ' * (20 - $Metric.Length)
            '['
            '#' * $MetricValue
            '-' * (100 - $MetricValue)
            ']'
        )
    }
}