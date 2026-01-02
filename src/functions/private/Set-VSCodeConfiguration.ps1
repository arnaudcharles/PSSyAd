function Set-VSCodeConfiguration {
    <#
    .SYNOPSIS
        Configure VSCode to trust the RemoteEdit directory

    .DESCRIPTION
        Configures Visual Studio Code settings to trust files in the RemoteEdit temporary directory, preventing security warnings and restricted mode when editing remote files.

    .PARAMETER TempDir
        Directory path to add to VSCode trusted locations

    .EXAMPLE
        Set-VSCodeConfiguration -TempDir "C:\Temp\RemoteEdit"
        Configure VSCode to trust the RemoteEdit directory

    .NOTES
        - Modifies VSCode user settings.json file
        - Disables workspace trust prompts for better user experience
        - Creates VSCode user directory if it doesn't exist

        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions", "", Justification = "Needed to avoid bad user experience, each time the file will open and request the trust"
    )]
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Directory to add to trusted folders")]
        [ValidateNotNullOrEmpty()]
        [string]$TempDir
    )

    try {
        Write-Verbose "Configuring VSCode trusted folders..."

        # VSCode settings path
        $vscodeSettingsPath = "$env:APPDATA\Code\User\settings.json"

        # Create directory if needed
        $vscodeUserDir = Split-Path $vscodeSettingsPath -Parent
        if (-not (Test-Path $vscodeUserDir)) {
            $null = New-Item -Path $vscodeUserDir -ItemType Directory -Force
            Write-Verbose "VSCode User directory created"
        }

        # Read existing settings or create empty object
        $settings = @{}
        if (Test-Path $vscodeSettingsPath) {
            try {
                $settingsContent = Get-Content $vscodeSettingsPath -Raw -ErrorAction Stop
                if ($settingsContent.Trim()) {
                    $settings = $settingsContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                }
            }
            catch {
                Write-Warning "Error reading existing VSCode settings, creating new settings"
                $settings = @{}
            }
        }

        # Configure security settings
        $settings["security.workspace.trust.enabled"] = $false
        $settings["security.workspace.trust.startupPrompt"] = "never"
        $settings["security.workspace.trust.banner"] = "never"
        $settings["security.workspace.trust.untrustedFiles"] = "open"

        # Convert to JSON and save
        $settingsJson = $settings | ConvertTo-Json -Depth 10
        $settingsJson | Set-Content -Path $vscodeSettingsPath -Encoding UTF8 -Force

        Write-Verbose "VSCode configured to trust directory: $TempDir"
        Write-Verbose "Trusted mode enabled globally"

        return $true
    }
    catch {
        Write-Error "VSCode configuration error: $_"
        return $false
    }
}