function Add-WindowsTerminalSettings {
    <#
    .SYNOPSIS
        Dedicated function for Windows Terminal.
        Add the missing moveFocus configurations to the settings.json file.

    .DESCRIPTION
        The Add-WindowsTerminalSettings function allows you to add the missing moveFocus configurations to the settings.json file. This can be useful for navigating between different panes using the keyboard shortcuts.

    .EXAMPLE
        Add-WindowsTerminalSettings
        This will edit the file settings.json. If the configurations are already present, nothing will be done and if the configurations are missing, they will be added.
        You can manually check the file settings.json to see the changes with --> code "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

        For debug use: Add-WindowsTerminalSettings -debugcode

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 2024-12-20
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope='Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    param(
        [switch]$debugcode
    )

    $settingsPath   = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    $backupPath     = "$settingsPath.backup"

    function Test-MoveFocusConfigurations {
        param(
            [switch]$Debug
        )

        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

            # Default missing operations
            $requiredDirections = @(
                "nextInOrder",
                "previous",
                "previousInOrder",
                "first",
                "parent",
                "child"
            )

            # Get the configs
            $moveFocusConfigs = $settings.actions | Where-Object {
                $_ -and
                ($_ | Get-Member -Name "command") -and
                ($_.command | Get-Member -Name "action") -and
                $_.command.action -eq "moveFocus"
            }

            # Display the actual config in settings if DEBUG arg is set.
            if ($debugcode) {
                Write-Host "Active MoveFocus config :" -ForegroundColor Cyan
                if ($moveFocusConfigs) {
                    $moveFocusConfigs | ForEach-Object {
                        Write-Host "Found -> $($_.command.direction)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "No config found" -ForegroundColor Red
                    return $false
                }
            }

            # Check for all required directions
            $existingDirections = $moveFocusConfigs | Select-Object -ExpandProperty command | Select-Object -ExpandProperty direction -Unique
            foreach ($direction in $requiredDirections) {
                if ($direction -notin $existingDirections) {
                    return $false
                }
            }
            return $true
        }
        catch {
            Write-Host "Error : $_" -ForegroundColor Red
            return $false
        }
    }

    # Check if all configurations are already present
    if (Test-MoveFocusConfigurations -Debug:$debugcode) {
        if ($debugcode){ Write-Host "Configuration set" -ForegroundColor Green }
        return
    }

    # If previous check failed, add the missing configurations
    if ($debugcode){ Write-Host "Add missing config..." -ForegroundColor Yellow }
    $newActions = @(
        @{
            command = @{
                action    = "moveFocus"
                direction = "nextInOrder"
            }
            keys          = "ctrl+tab"
        },
        @{
            command = @{
                action    = "moveFocus"
                direction = "previousInOrder"
            }
            keys          = "ctrl+shift+tab"
        },
        @{
            command = @{
                action  = "moveFocus"
                direction = "previous"
            }
            keys          = "ctrl+shift+home"
        },
        @{
            command = @{
                action  = "moveFocus"
                direction = "first"
            }
            keys          = "ctrl+home"
        },
        @{
            command = @{
                action  = "moveFocus"
                direction = "parent"
            }
            keys          = "ctrl+pageup"
        },
        @{
            command = @{
                action    = "moveFocus"
                direction = "child"
            }
            keys          = "ctrl+pagedown"
        }
    )

    # Check if the settings file exists
    if (-not (Test-Path $settingsPath)) {
        Write-Error "The file settings.json doesn't exist in : $settingsPath"
        exit 1
    }

    try {
        # Get the settings
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

        # Create a backup file
        Copy-Item -Path $settingsPath -Destination $backupPath -Force
        if ($debugcode){ Write-Host "Backup file: $backupPath" -ForegroundColor Green }

        # Delete any existing moveFocus configurations
        $settings.actions = @($settings.actions | Where-Object {
            -not ($_ -and
                ($_ | Get-Member -Name "command") -and
                ($_.command | Get-Member -Name "action") -and
                $_.command.action -eq "moveFocus")
        })

        # Add back all configurations
        foreach ($newAction in $newActions) {
            $settings.actions += $newAction
            if ($debugcode){ Write-Host "Config add for $($newAction.command.direction)" -ForegroundColor Green }
        }

        # Push the new settings
        $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath
        if ($debugcode){ Write-Host "All config are now pushed to the settings file" -ForegroundColor Green }

    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $settingsPath -Force
            if ($debugcode){ Write-Host "Restore the backup..." -ForegroundColor Yellow }
        }
    }
}