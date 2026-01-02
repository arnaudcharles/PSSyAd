function Get-PrometheusJobOutput {
    <#
    .SYNOPSIS
        Get the output of a job from the prometheus agent on the current machine.

    .DESCRIPTION
        Get the output of a job from the prometheus agent on the current machine.

    .PARAMETER jobname
        The name of the job to get the output for.

    .EXAMPLE
        Get-PrometheusJob -jobname 'nodeJob1'
    #>

    [CmdletBinding()]
    param(
        [String]$jobname
    )
    $endpointUrl = (Get-PrometheusJob -jobname $jobname).endpoint
    if((get-service 'Grafana Agent').status -eq 'Running'){
        $query = @()
        foreach($url in $endpointUrl){
            $query = $query + $(Invoke-RestMethod $url)
        }
    }else{
        Write-Output "ERROR :: Grafana agent not running..."
    }
    return $query
}