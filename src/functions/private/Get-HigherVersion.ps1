Function Get-HighestVersion{
    <#
    .SYNOPSIS
        Compare & return higher version between 2 arguments

    .DESCRIPTION
        Compare & return higher version between 2 arguments
        Versions have to fit the format ([0-9]+.)*[0-9]+ (ex: 2 | 2.11 | 2.0.1)

    .PARAMETER Vers1
        First version to compare
        Has to fit the format ([0-9]+.)*[0-9]+ (ex: 2 | 2.11 | 2.0.1)

    .PARAMETER Vers2
        Second version to compare
        Has to fit the format ([0-9]+.)*[0-9]+ (ex: 2 | 2.11 | 2.0.1)

    .OUTPUTS
        String of the highest version

    .EXAMPLE
        Get-HighestVersion -Vers1 1.1.0 -Vers 1

        Returns 1.1.0

    .EXAMPLE
        Get-HighestVersion 2.1.1 2.1.2

    Returns 2.1.2
    #>

    [OutputType('System.String')]
    [CmdletBinding()]
    param(
        [String]$Vers1,
        [String]$Vers2
    )

    if(-not(Test-IsValidVersion -version $vers1)){Throw "Vers1 [$vers1] is not a valid, expectig format ([0-9]+.)*[0-9]+"}
    if(-not(Test-IsValidVersion -version $vers2)){Throw "Vers2 [$vers2] is not a valid, expectig format ([0-9]+.)*[0-9]+"}
    if($vers1 -eq $vers2){return $vers1}

    $V1Arr = $vers1.Split(".")
    $V2Arr = $vers2.Split(".")

    $MaxInd = ($V1Arr.count,$V2Arr.count | Measure-Object -Maximum).Maximum - 1

    foreach($index in 0..$MaxInd){
        # If last digit does not exist => return version with more digits
        if($Null -eq $V1Arr[$index]){return $vers2}
        if($Null -eq $V2Arr[$index]){return $vers1}

        if([int]$V1Arr[$index] -gt [int]$V2Arr[$index]){return $vers1}
        if([int]$V1Arr[$index] -lt [int]$V2Arr[$index]){return $vers2}
    }
}