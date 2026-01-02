function Add-DBATerminalProfile {
    <#
    .SYNOPSIS
        Specific to DBA.
        Dedicated function for Windows Terminal.
        Add a new profile on Windows Terminal for DBA Patching.

    .DESCRIPTION
        The Add-DBATerminalProfile function allows you to add a new profile on Windows Terminal for DBA Patching.
        Take care that the hosts need to be defined before running the profile, it's the same as calling the Invoke-DBAPatching function.

    .EXAMPLE
        >> CASE 1 <<
        You simply call this function without any argument. This case will simply create the default profile for DBA Patching.
        When you clic on this profile, it will trigger the DBA Patching function and ask for a list of hosts that you need to type manually!

        Add-DBATerminalProfile

        It will ask for the hosts (same rules, 3 or 6 hosts) and will open the terminal with the DBA Patching function.

        Enter hosts (comma-separated): "host1", "host2", "host3"

        >> CASE 2 <<
        You want to define you own profile using your own variables list.
        /!\ MAKE SURE TO USE A VARIABLE THAT IS ---NOT--- ALREADY DEFINE NEITHER IN YOUR TERMINAL NEITHER YOUR PROFILE /!\

        >> STEP 1 <<
            You need to provide some arguments to the function to create your own profile.
            - name (or -n) : The name of the profile that will be displayed in the terminal
            - guid (or -g) : The GUID of the profile. You can generate a new one using the New-Guid cmdlet
            - list (or -l) : The list of hosts that you want to use for the DBA Patching function.
            - icon (or -i) : The icon that will be displayed in the terminal (OPTIONAL)

            Add-DBATerminalProfile -name "SB_CORE_SRV_XX" -guid "11854acc-7e83-4998-b60e-0dc0521b7d66"  -l '$SB_CORE_SRV_XX_List' -i 🔨

            TIPS :
            - To create a GUID --> PS:> New-Guid
            - To find an icon  --> https://emojipedia.org/

        When it's run, it will create a new profile with the name "SB_CORE_SRV_XX" and the icon 🔨.
        You list isn't defined yet, so it will not work.

        >> STEP 2 <<
            You need to define the list of hosts that you want to use for the DBA Patching function.
            Simply create it in your $PROFILE and reload it.
            notepad $PROFILE
            $SB_CORE_SRV_XX_List = @("host1", "host2", "host3", "host4", "host5", "host6")
            . $PROFILE

            Voila, you can now use the profile "SB_CORE_SRV_XX" in your terminal.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 2024-12-20
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope='Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '')]
    param (
        [Alias("g")]
        [string]$guid = "9b4e3055-85d5-4d5a-9a48-dc27710a2f67",

        [Alias("n")]
        [string]$name = "DBA Patching",

        [Alias("l")]
        [string]$list = '$HostList',

        [Alias("i")]
        [string]$icon = "🩹"
    )

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
        guid        = "{${guid}}"
        name        = $name
        commandline = "pwsh.exe -NoExit -Command `"Set-Location -Path '$env:USERPROFILE'; Import-Module PSSyAd; & Invoke-DBAPatching -Hosts `$($list)`""
        icon        = $icon
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
        Write-Host "Profile 'DBA Patching' Added" -ForegroundColor Green
    }
    catch {
        Write-Error "Error: $_"
    }
}