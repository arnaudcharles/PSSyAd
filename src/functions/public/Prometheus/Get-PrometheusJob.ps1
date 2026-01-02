function Get-PrometheusJob {
    <#
    .SYNOPSIS
        Get the jobs from the prometheus agent on the current machine.

    .DESCRIPTION
        Get the jobs from the prometheus agent on the current machine.

    .PARAMETER jobname
        The name of the job to get the targets for.

    .PARAMETER port
        The port number of the Prometheus agent (default: 9292)

    .EXAMPLE
        Get-PrometheusJob -jobname 'node'

    .EXAMPLE
        Get-PrometheusJob -jobname 'node' -port 9090
    #>

    [CmdletBinding()]
    param(
        [String]$jobname,
        [int]$port = 9292
    )
    if ((get-service 'Grafana Agent').status -eq 'Running') {
        $query = (Invoke-RestMethod https://$(([System.Net.Dns]::GetHostByName($env:computerName)).hostname):$port/agent/api/v1/metrics/targets).data | Where-Object target_group -match "$jobname"
    }
    else {
        Write-Output "ERROR :: Grafana agent not running..."
    }
    return $query
}
