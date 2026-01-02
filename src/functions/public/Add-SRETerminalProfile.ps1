function Add-SRETerminalProfile {
    <#
    .SYNOPSIS
        Specific to SRE.
        Dedicated function for Windows Terminal.
        Add a new profile on Windows Terminal for splitted pane.

    .DESCRIPTION
        The Add-SRETerminalProfile function allows you to add a new profile on Windows Terminal for multiple pane work.

    .EXAMPLE
        Add-SRETerminalProfile

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 2024-12-20
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope='Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '')]
    param ()

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    # Check if the settings file exists
    if (-not (Test-Path $settingsPath)) {
        Write-Error "No file settings.json found"
        return
    }

    # Get the actual content
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Error when reading the settings: $_"
        return
    }

    # Define profile
    $newProfile = @{
        guid        = "{8fbabef5-1d88-408a-b3e3-dd1ed4724809}"
        name        = "SplitTerm"
        commandline = "pwsh.exe -NoExit -Command `"Set-Location -Path '$env:USERPROFILE'; Import-Module PSSyAd;& Invoke-SplitTerminal`""
        icon        = "✂️"
    }

    # Check if profile already exists
    $profileExists = $settings.profiles.list | Where-Object {
        $_.guid -eq $newProfile.guid -or $_.name -eq $newProfile.name
    }

    if ($profileExists) {
        Write-Warning "A profil with the same GUID or same name already exists"
        return
    }

    # Add new profile
    $settings.profiles.list += $newProfile

    # Push the new settings
    try {
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        Write-Host "Profile 'SRE SplitTerm' Added" -ForegroundColor Green
    }
    catch {
        Write-Error "Error: $_"
    }
}