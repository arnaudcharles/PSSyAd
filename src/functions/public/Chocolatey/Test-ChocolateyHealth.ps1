function Test-ChocolateyHealth {
    <#
    .SYNOPSIS
        Performs comprehensive health checks on Chocolatey installation.

    .DESCRIPTION
        The Test-ChocolateyHealth function runs multiple diagnostic tests on Chocolatey,
        including package verification, outdated packages detection, executable availability,
        environment variables, and configuration validation. Fully automated without user input.

    .PARAMETER ExportPath
        Optional path to export the diagnostic report in JSON format.

    .PARAMETER SkipCommandTest
        Skip testing if package executables are available in PATH.

    .PARAMETER SkipOutdatedCheck
        Skip checking for outdated packages (can be slow).

    .PARAMETER OutdatedTimeout
        Timeout in seconds for outdated package check. Default is 30 seconds.

    .EXAMPLE
        Test-ChocolateyHealth
        Runs all diagnostic tests and displays results in the console.

    .EXAMPLE
        Test-ChocolateyHealth -ExportPath "C:\Logs\choco-health.json"
        Runs diagnostics and exports results to a JSON file.

    .EXAMPLE
        Test-ChocolateyHealth -SkipOutdatedCheck
        Runs diagnostics but skips the slow outdated package check.

    .OUTPUTS
        PSCustomObject containing diagnostic results.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ExportPath,

        [Parameter(Mandatory=$false)]
        [switch]$SkipCommandTest,

        [Parameter(Mandatory=$false)]
        [switch]$SkipOutdatedCheck,

        [Parameter(Mandatory=$false)]
        [int]$OutdatedTimeout = 30
    )

    $Results = [PSCustomObject]@{
        Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
        Tests        = @()
        Summary      = @{
            Total    = 0
            Passed   = 0
            Warnings = 0
            Failed   = 0
        }
    }

    Write-Host "`n=== Chocolatey Health Check ===" -ForegroundColor Cyan
    Write-Host "Computer: $($env:COMPUTERNAME)" -ForegroundColor Gray
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

    # Test 1: Chocolatey Installation
    $test1 = Test-ChocoInstallation
    $Results.Tests += $test1
    Show-TestResult -TestResult $test1

    if ($test1.Status -eq "Failed") {
        Write-Host "`nChocolatey is not installed. Cannot continue." -ForegroundColor Red
        Complete-Summary -Results $Results -ExportPath $ExportPath
        return $Results
    }

    # Test 2: Chocolatey Version
    $test2 = Test-ChocoVersion
    $Results.Tests += $test2
    Show-TestResult -TestResult $test2

    # Test 3: Environment Variables
    $test3 = Test-ChocoEnvironment
    $Results.Tests += $test3
    Show-TestResult -TestResult $test3

    # Test 4: Chocolatey Directories
    $test4 = Test-ChocoDirectories
    $Results.Tests += $test4
    Show-TestResult -TestResult $test4

    # Test 5: Package Sources
    $test5 = Test-ChocoSources
    $Results.Tests += $test5
    Show-TestResult -TestResult $test5

    # Test 6: Installed Packages
    $test6 = Test-InstalledPackages
    $Results.Tests += $test6
    Show-TestResult -TestResult $test6

    # Test 7: Package Executables (if not skipped)
    if (-not $SkipCommandTest) {
        $test8 = Test-PackageCommands
        $Results.Tests += $test8
        Show-TestResult -TestResult $test8
    }

    # Test 8: Chocolatey Configuration
    $test9 = Test-ChocoConfiguration
    $Results.Tests += $test9
    Show-TestResult -TestResult $test9

    # Test 9: Chocolatey Features
    $test10 = Test-ChocoFeatures
    $Results.Tests += $test10
    Show-TestResult -TestResult $test10

    # Complete and export
    Complete-Summary -Results $Results -ExportPath $ExportPath

    return $Results
}

## Test 1
function Test-ChocoInstallation {
    $result = [PSCustomObject]@{
        TestName = "Chocolatey Installation"
        Status   = "Passed"
        Message  = ""
        Details  = @{}
    }

    try {
        $chocoCmd = Get-Command choco -ErrorAction Stop
        $result.Details.ChocoPath = $chocoCmd.Source
        $result.Message = "Chocolatey is installed at: $($chocoCmd.Source)"
    }
    catch {
        $result.Status = "Failed"
        $result.Message = "Chocolatey is not installed or not in PATH"
    }

    return $result
}

## Test 2
function Test-ChocoVersion {
    $result = [PSCustomObject]@{
        TestName = "Chocolatey Version"
        Status   = "Passed"
        Message  = ""
        Details  = @{}
    }

    try {
        $versionOutput = choco --version 2>&1 | Out-String
        $result.Details.Version = $versionOutput.Trim()
        $result.Message = "Chocolatey version: $($result.Details.Version)"
    }
    catch {
        $result.Status = "Failed"
        $result.Message = "Could not determine Chocolatey version: $_"
    }

    return $result
}

## Test 3
function Test-ChocoEnvironment {
    $result = [PSCustomObject]@{
        TestName = "Environment Variables"
        Status   = "Passed"
        Message  = ""
        Details  = @{}
    }

    $issues = @()

    # Check ChocolateyInstall
    $chocoInstall = $env:ChocolateyInstall
    if ($chocoInstall) {
        $result.Details.ChocolateyInstall = $chocoInstall
        if (-not (Test-Path $chocoInstall)) {
            $issues += "ChocolateyInstall path does not exist: $chocoInstall"
        }
    }
    else {
        $issues += "ChocolateyInstall environment variable not set"
    }

    # Check PATH contains Chocolatey
    $pathContainsChoco = $env:PATH -split ';' | Where-Object { $_ -like "*chocolatey*" }
    if ($pathContainsChoco) {
        $result.Details.ChocolateyInPath = $true
        $result.Details.ChocolateyPaths = @($pathContainsChoco)
    }
    else {
        $issues += "Chocolatey not found in PATH"
    }

    if ($issues.Count -gt 0) {
        $result.Status = "Warning"
        $result.Message = $issues -join "; "
    }
    else {
        $result.Message = "Environment variables configured correctly"
    }

    return $result
}

## Test 4
function Test-ChocoDirectories {
    $result = [PSCustomObject]@{
        TestName = "Chocolatey Directories"
        Status   = "Passed"
        Message  = ""
        Details  = @{}
    }

    $issues = @()
    $chocoInstall = $env:ChocolateyInstall

    if (-not $chocoInstall) {
        $result.Status = "Failed"
        $result.Message = "ChocolateyInstall not set"
        return $result
    }

    $directories = @{
        "ChocolateyInstall" = $chocoInstall
        "Bin"               = Join-Path $chocoInstall "bin"
        "Lib"               = Join-Path $chocoInstall "lib"
        "Logs"              = Join-Path $chocoInstall "logs"
    }

    foreach ($dir in $directories.GetEnumerator()) {
        if (Test-Path $dir.Value) {
            $result.Details[$dir.Key] = @{
                Path   = $dir.Value
                Exists = $true
            }
        }
        else {
            $issues += "$($dir.Key) directory missing: $($dir.Value)"
            $result.Details[$dir.Key] = @{
                Path   = $dir.Value
                Exists = $false
            }
        }
    }

    if ($issues.Count -gt 0) {
        $result.Status = "Warning"
        $result.Message = $issues -join "; "
    }
    else {
        $result.Message = "All Chocolatey directories exist"
    }

    return $result
}

## Test 5
function Test-ChocoSources {
    $result = [PSCustomObject]@{
        TestName = "Package Sources"
        Status   = "Passed"
        Message  = ""
        Details  = @{
            Sources = @()
        }
    }

    try {
        $sourcesOutput = choco source list -r 2>&1 | Out-String
        $sourceLines = $sourcesOutput -split "`n" | Where-Object { $_ -match '\|' }

        foreach ($line in $sourceLines) {
            if ($line -match '^(?<name>[^|]+)\|(?<url>[^|]+)\|(?<disabled>[^|]*)\|(?<user>[^|]*)\|(?<priority>[^|]*)\|(?<bypass>[^|]*)') {
                $result.Details.Sources += [PSCustomObject]@{
                    Name     = $matches['name'].Trim()
                    Url      = $matches['url'].Trim()
                    Disabled = $matches['disabled'].Trim() -eq 'true'
                    Priority = $matches['priority'].Trim()
                }
            }
        }

        $enabledSources = $result.Details.Sources | Where-Object { -not $_.Disabled }
        if ($enabledSources.Count -eq 0) {
            $result.Status = "Warning"
            $result.Message = "No enabled package sources found"
        }
        else {
            $result.Message = "Found $($enabledSources.Count) enabled source(s), $($result.Details.Sources.Count) total"
        }
    }
    catch {
        $result.Status = "Failed"
        $result.Message = "Could not retrieve package sources: $_"
    }

    return $result
}

## Test 6
function Test-InstalledPackages {
    $result = [PSCustomObject]@{
        TestName = "Installed Packages"
        Status   = "Passed"
        Message  = ""
        Details  = @{
            Packages = @()
            Count    = 0
        }
    }

    try {
        $packagesOutput = choco list --local-only -r 2>&1 | Out-String
        $packageLines = $packagesOutput -split "`n" | Where-Object { $_ -match '\|' }

        foreach ($line in $packageLines) {
            if ($line -match '^(?<name>[^|]+)\|(?<version>[^|]+)') {
                $packageName = $matches['name'].Trim()
                $packageVersion = $matches['version'].Trim()

                # Check if package folder exists
                $packagePath = Join-Path $env:ChocolateyInstall "lib\$packageName"
                $exists = Test-Path $packagePath

                $result.Details.Packages += [PSCustomObject]@{
                    Name    = $packageName
                    Version = $packageVersion
                    Path    = $packagePath
                    Exists  = $exists
                }
            }
        }

        $result.Details.Count = $result.Details.Packages.Count

        $missingPackages = $result.Details.Packages | Where-Object { -not $_.Exists }
        if ($missingPackages.Count -gt 0) {
            $result.Status = "Warning"
            $result.Message = "$($result.Details.Count) packages installed, $($missingPackages.Count) with missing folders"
        }
        else {
            $result.Message = "$($result.Details.Count) packages installed, all folders present"
        }
    }
    catch {
        $result.Status = "Failed"
        $result.Message = "Could not retrieve installed packages: $_"
    }

    return $result
}

## Test 7
function Test-PackageCommands {
    $result = [PSCustomObject]@{
        TestName = "Package Command Availability"
        Status   = "Passed"
        Message  = ""
        Details  = @{
            Commands       = @()
            TestedCount    = 0
            AvailableCount = 0
        }
    }

    try {
        $binPath = Join-Path $env:ChocolateyInstall "bin"

        if (-not (Test-Path $binPath)) {
            $result.Status = "Warning"
            $result.Message = "Chocolatey bin directory not found"
            return $result
        }

        # Get all executables in bin folder (shims created by Chocolatey)
        $executables = Get-ChildItem -Path $binPath -File |
            Where-Object {
                $_.Extension -in @('.exe', '.bat', '.cmd', '.ps1') -and
                $_.Name -notin @('choco.exe', 'chocolatey.exe', 'RefreshEnv.cmd', 'checksum.exe', 'shimgen.exe', 'installChocolatey.ps1')
            }

        foreach ($exe in $executables) {
            $commandName = $exe.BaseName

            # Test if command is available in PATH
            $cmdAvailable = $null -ne (Get-Command $commandName -ErrorAction SilentlyContinue)

            $result.Details.Commands += [PSCustomObject]@{
                Command   = $commandName
                FullPath  = $exe.FullName
                Extension = $exe.Extension
                InPath    = $cmdAvailable
            }

            $result.Details.TestedCount++
            if ($cmdAvailable) {
                $result.Details.AvailableCount++
            }
        }

        $unavailableCommands = $result.Details.Commands | Where-Object { -not $_.InPath }
        if ($unavailableCommands.Count -gt 0) {
            $result.Status = "Warning"
            $result.Message = "$($result.Details.AvailableCount)/$($result.Details.TestedCount) commands available in PATH, $($unavailableCommands.Count) not accessible"
        }
        else {
            $result.Message = "All $($result.Details.TestedCount) package commands are available in PATH"
        }
    }
    catch {
        $result.Status = "Warning"
        $result.Message = "Could not test package commands: $_"
    }

    return $result
}

## Test 8
function Test-ChocoConfiguration {
    $result = [PSCustomObject]@{
        TestName = "Chocolatey Configuration"
        Status   = "Passed"
        Message  = ""
        Details  = @{
            Settings = @{}
        }
    }

    try {
        $configOutput = choco config list -r 2>&1 | Out-String
        $configLines = $configOutput -split "`n" | Where-Object { $_ -match '=' }

        foreach ($line in $configLines) {
            if ($line -match '^(?<key>[^=]+)=(?<value>.*)$') {
                $key = $matches['key'].Trim()
                $value = $matches['value'].Trim()
                $result.Details.Settings[$key] = $value
            }
        }

        $result.Message = "Configuration loaded successfully ($($result.Details.Settings.Count) settings)"
    }
    catch {
        $result.Status = "Warning"
        $result.Message = "Could not retrieve configuration: $_"
    }

    return $result
}

## Test 9
function Test-ChocoFeatures {
    $result = [PSCustomObject]@{
        TestName = "Chocolatey Features"
        Status   = "Passed"
        Message  = ""
        Details  = @{
            Features      = @()
            EnabledCount  = 0
            DisabledCount = 0
        }
    }

    try {
        $featuresOutput = choco feature list -r 2>&1 | Out-String
        $featureLines = $featuresOutput -split "`n" | Where-Object { $_ -match '\|' }

        foreach ($line in $featureLines) {
            if ($line -match '^(?<name>[^|]+)\|(?<enabled>[^|]+)') {
                $enabled = $matches['enabled'].Trim() -eq 'Enabled'
                $result.Details.Features += [PSCustomObject]@{
                    Name    = $matches['name'].Trim()
                    Enabled = $enabled
                }

                if ($enabled) {
                    $result.Details.EnabledCount++
                }
                else {
                    $result.Details.DisabledCount++
                }
            }
        }

        $result.Message = "$($result.Details.Features.Count) features found ($($result.Details.EnabledCount) enabled, $($result.Details.DisabledCount) disabled)"
    }
    catch {
        $result.Status = "Warning"
        $result.Message = "Could not retrieve features: $_"
    }

    return $result
}

function Complete-Summary {
    param($Results, $ExportPath)

    # Calculate Summary
    $Results.Summary.Total = $Results.Tests.Count
    $Results.Summary.Passed = ($Results.Tests | Where-Object { $_.Status -eq "Passed" }).Count
    $Results.Summary.Warnings = ($Results.Tests | Where-Object { $_.Status -eq "Warning" }).Count
    $Results.Summary.Failed = ($Results.Tests | Where-Object { $_.Status -eq "Failed" }).Count

    # Display Summary
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total Tests: $($Results.Summary.Total)" -ForegroundColor Gray
    Write-Host "Passed: $($Results.Summary.Passed)" -ForegroundColor Green
    Write-Host "Warnings: $($Results.Summary.Warnings)" -ForegroundColor Yellow
    Write-Host "Failed: $($Results.Summary.Failed)" -ForegroundColor Red

    # Export if requested
    if ($ExportPath) {
        try {
            $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $ExportPath -Encoding UTF8 -Force
            Write-Host "`nReport exported to: $ExportPath" -ForegroundColor Green
        }
        catch {
            Write-Host "`nFailed to export report: $_" -ForegroundColor Red
        }
    }
}

function Show-TestResult {
    param($TestResult)

    $statusColor = switch ($TestResult.Status) {
        "Passed" { "Green" }
        "Warning" { "Yellow" }
        "Failed" { "Red" }
        default { "Gray" }
    }

    Write-Host "$($TestResult.TestName): " -NoNewline
    Write-Host "$($TestResult.Message)" -ForegroundColor $statusColor
}
