function Get-Metrics {
    <#
    .SYNOPSIS
        Retrieves Prometheus metrics from a local metrics endpoint.

    .DESCRIPTION
        The Get-Metrics function connects to a local Prometheus metrics endpoint (http://LocalIP:Port/metrics) and retrieves metrics data. It automatically detects the local IP address from the first Ethernet adapter and excludes loopback and link-local addresses. The function supports specifying a custom port (default is 9182) and optionally filters metrics by name.

    .PARAMETER Name
        Optional parameter to filter metrics by name. Only metrics starting with the specified name will be returned.
        Alias: n

    .PARAMETER Port
        Optional parameter to specify the port of the metrics endpoint. Default is 9182.
        Alias: p

    .EXAMPLE
        Get-Metrics
        Retrieves and displays all available metrics from the local endpoint.

    .EXAMPLE
        Get-Metrics -Name "windows_service"
        Retrieves only metrics that start with "uptime".

    .EXAMPLE
        Get-Metrics -Name "windows_time" -Port 9190
        Retrieves only metrics that start with "windows_time" on port 9190.

    .OUTPUTS
        System.String
        Returns the metrics data as text, either all metrics or filtered by the specified name.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [Alias("n")]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [Alias("p")]
        [int]$Port = 9182
    )

    # Get the local IP address from the first Ethernet adapter
    $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 |
                Where-Object {
                    $_.InterfaceAlias -match '^Ethernet\d+' -and
                    $_.IPAddress -notlike "127.*" -and
                    $_.IPAddress -notlike "169.254.*"
                } |
                Sort-Object InterfaceAlias, InterfaceIndex |
                Select-Object -First 1).IPAddress

    if (-not $LocalIP) {
        Write-Error "Unable to determine local IP address from Ethernet adapter"
        return
    }

    # Define the metrics endpoint URI
    $Uri = "http://${LocalIP}:${Port}/metrics"

    # Get and filter metrics
    try {
        $metrics = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction Stop).Content

        if ($Name) {
            $metrics -split "`n" | Where-Object { $_ -match "^$Name" }
        }
        else {
            $metrics
        }
    }
    catch {
        Write-Error "Failed to retrieve metrics from ${Uri}: $_"
    }
}