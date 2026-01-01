function Get-PSPrivateDeps {
    <#
    .SYNOPSIS
        Analyze the private dependencies of a PowerShell module's public functions.

    .DESCRIPTION
        Interacting with a PowerShell module is easy using private and public functions but it can be hard to track which public function depends on which private function.
        This function analyzes a specified PowerShell module to identify dependencies between its public (exported) and private (internal) functions.
        It generates a Mermaid diagram illustrating these dependencies and saves it to a Markdown file.

    .PARAMETER ModuleName
        The module to analyze for private dependencies.

    .PARAMETER OutputPath
        The path of the output file (default: PSPrivateDeps.md)

    .PARAMETER IncludePrivateToPrivate
        Include dependencies between private functions (Private → Private)

    .EXAMPLE
        Get-PSPrivateDeps -ModuleName PSWEE

    .EXAMPLE
        Get-PSPrivateDeps -ModuleName PSWEE -OutputPath "C:\Reports\PSWEE-deps.md"

    .EXAMPLE
        Get-PSPrivateDeps -ModuleName PSbite -IncludePrivateToPrivate

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 2026-01-01
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "PSPrivateDeps.md",

        [Parameter(Mandatory = $false)]
        [switch]$IncludePrivateToPrivate
    )

    # Check if module is loaded, if not try to import it
    Write-Verbose "Checking $ModuleName..."
    if (-not (Get-Module -Name $ModuleName)) {
        try {
            Import-Module $ModuleName -ErrorAction Stop
            Write-Host "Module $ModuleName loaded." -ForegroundColor Green
        }
        catch {
            Write-Error "Error when loading module $ModuleName : $_"
            return
        }
    }
    else {
        Write-Host "Module $ModuleName already loaded." -ForegroundColor Cyan
    }

    # Retrieve the module and its path
    $module = Get-Module -Name $ModuleName
    $modulePath = $module.Path

    if (-not (Test-Path $modulePath)) {
        Write-Error "Not able to find the module : $modulePath"
        return
    }

    Write-Verbose "Module path : $modulePath"

    # Read PSM1 file content
    $moduleContent = Get-Content -Path $modulePath -Raw

    # Parse all functions in the module
    $functionPattern = '(?m)^function\s+([\w-]+)\s*\{'
    $allFunctionMatches = [regex]::Matches($moduleContent, $functionPattern)

    Write-Verbose "Total of functions found in the file : $($allFunctionMatches.Count)"

    # Identify private functions
    # Pattern: #region [functions] - [private] - [FunctionName]
    $privateFunctions = @()
    $privateRegionPattern = '#region\s+\[functions\]\s+-\s+\[private\]\s+-\s+\[([^\]]+)\]'
    $privateRegionMatches = [regex]::Matches($moduleContent, $privateRegionPattern)

    if ($privateRegionMatches.Count -gt 0) {
        $privateFunctions = $privateRegionMatches | ForEach-Object { $_.Groups[1].Value }
        Write-Verbose "Fonctions privées trouvées : $($privateFunctions.Count)"
        $privateFunctions | ForEach-Object { Write-Verbose "  - $_" }
    }
    else {
        Write-Warning "No [private] region found in the module"
    }

    # Retrieve the public functions (exported)
    $publicFunctions = $module.ExportedCommands.Keys
    Write-Verbose "Public functions found : $($publicFunctions.Count)"
    $publicFunctions | ForEach-Object { Write-Verbose "  - $_" }

    if ($privateFunctions.Count -eq 0) {
        Write-Warning "No private function detected. The module may not be using the [private]/[public] structure."
    }

    # Analyze dependencies - Public → Private
    $publicToPrivateDeps = @()

    foreach ($publicFunc in $publicFunctions) {
        Write-Verbose "Analyze of $publicFunc..."

        # Extract the function definition
        $funcPattern = "(?s)function\s+$([regex]::Escape($publicFunc))\s*\{.*?\n(?=function\s+|\z|#endregion)"
        $funcMatch = [regex]::Match($moduleContent, $funcPattern)

        if ($funcMatch.Success) {
            $funcDef = $funcMatch.Value

            foreach ($privateFunc in $privateFunctions) {
                # Search for calls to the private function
                $callPattern = "(?:^|\s|;|\||`n)$([regex]::Escape($privateFunc))(?:\s+|-[A-Za-z]|\()"

                if ($funcDef -match $callPattern) {
                    $publicToPrivateDeps += [PSCustomObject]@{
                        Source = $publicFunc
                        Target = $privateFunc
                        Type   = "PublicToPrivate"
                    }
                    Write-Verbose "  -> Depends on $privateFunc"
                }
            }
        }
        else {
            Write-Warning "Impossible to find the definition of $publicFunc"
        }
    }

    # Analyze dependencies - Private → Private (if requested)
    $privateToPrivateDeps = @()

    if ($IncludePrivateToPrivate) {
        Write-Verbose "`nAnalyzing Private → Private dependencies..."

        foreach ($privateFunc in $privateFunctions) {
            Write-Verbose "Analyze of $privateFunc..."

            # Extract the function definition
            $funcPattern = "(?s)function\s+$([regex]::Escape($privateFunc))\s*\{.*?\n(?=function\s+|\z|#endregion)"
            $funcMatch = [regex]::Match($moduleContent, $funcPattern)

            if ($funcMatch.Success) {
                $funcDef = $funcMatch.Value

                foreach ($targetPrivateFunc in $privateFunctions) {
                    # Skip self-reference
                    if ($privateFunc -eq $targetPrivateFunc) { continue }

                    # Search for calls to the other private function
                    $callPattern = "(?:^|\s|;|\||`n)$([regex]::Escape($targetPrivateFunc))(?:\s+|-[A-Za-z]|\()"

                    if ($funcDef -match $callPattern) {
                        $privateToPrivateDeps += [PSCustomObject]@{
                            Source = $privateFunc
                            Target = $targetPrivateFunc
                            Type   = "PrivateToPrivate"
                        }
                        Write-Verbose "  -> Depends on $targetPrivateFunc"
                    }
                }
            }
        }
    }

    # Combine all dependencies
    $allDependencies = @($publicToPrivateDeps) + @($privateToPrivateDeps)

    # Generate the Mermaid diagram
    Write-Host "`nGenerating the Mermaid diagram..." -ForegroundColor Yellow

    $mermaidContent = @"
# $ModuleName Module Dependencies

This diagram shows dependencies between public (exported) and private (internal) functions in the module.

- **Green rounded rectangles**: Public functions (exported)
- **Blue rectangles**: Private functions (internal)
"@

    if ($IncludePrivateToPrivate) {
        $mermaidContent += "`n- **Solid arrows**: Public → Private dependencies"
        $mermaidContent += "`n- **Dashed arrows**: Private → Private dependencies"
    }
    else {
        $mermaidContent += "`n- **Arrows**: Dependency relationship (public function calls private function)"
    }

    $mermaidContent += "`n`n``````mermaid`ngraph TD"

    if ($allDependencies.Count -eq 0) {
        $mermaidContent += "`n    NoDepFound[No dependencies detected]"
        $mermaidContent += "`n    style NoDepFound fill:#FFA500,stroke:#FF8C00,stroke-width:2px,color:#000"
    }
    else {
        # Create valid identifiers for Mermaid (no dashes)
        $nodeIds = @{}
        $counter = 0

        # Identify all unique functions
        $allFuncs = @($allDependencies.Source) + @($allDependencies.Target) | Select-Object -Unique
        foreach ($func in $allFuncs) {
            $nodeIds[$func] = "N$counter"
            $counter++
        }

        # Define all nodes with their labels first
        # Public nodes (rounded)
        foreach ($publicFunc in $publicFunctions) {
            if ($nodeIds.ContainsKey($publicFunc)) {
                $publicId = $nodeIds[$publicFunc]
                $mermaidContent += "`n    $publicId([$publicFunc])"
            }
        }

        # Private nodes (rectangles)
        foreach ($privateFunc in $privateFunctions) {
            if ($nodeIds.ContainsKey($privateFunc)) {
                $privateId = $nodeIds[$privateFunc]
                $mermaidContent += "`n    $privateId[$privateFunc]"
            }
        }

        # Add all connections
        foreach ($dep in $allDependencies) {
            $sourceId = $nodeIds[$dep.Source]
            $targetId = $nodeIds[$dep.Target]

            # Use dashed arrows for Private → Private, solid for Public → Private
            if ($dep.Type -eq "PrivateToPrivate") {
                $mermaidContent += "`n    $sourceId -.-> $targetId"
            }
            else {
                $mermaidContent += "`n    $sourceId --> $targetId"
            }
        }

        # Add styles
        $mermaidContent += "`n"

        # Style for public functions (only those in the diagram)
        foreach ($publicFunc in $publicFunctions) {
            if ($nodeIds.ContainsKey($publicFunc)) {
                $publicId = $nodeIds[$publicFunc]
                $mermaidContent += "`n    style $publicId fill:#4CAF50,stroke:#2E7D32,stroke-width:3px,color:#fff"
            }
        }

        # Style for private functions (only those in the diagram)
        foreach ($privateFunc in $privateFunctions) {
            if ($nodeIds.ContainsKey($privateFunc)) {
                $privateId = $nodeIds[$privateFunc]
                $mermaidContent += "`n    style $privateId fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff"
            }
        }
    }

    $mermaidContent += "`n``````"

    # Add summary
    $mermaidContent += "`n`n## 📊 Summary"
    $mermaidContent += "`n- **Public functions**: $($publicFunctions.Count)"
    $mermaidContent += "`n- **Private functions**: $($privateFunctions.Count)"

    if ($IncludePrivateToPrivate) {
        $mermaidContent += "`n- **Public → Private dependencies**: $($publicToPrivateDeps.Count)"
        $mermaidContent += "`n- **Private → Private dependencies**: $($privateToPrivateDeps.Count)"
        $mermaidContent += "`n- **Total dependencies detected**: $($allDependencies.Count)"
    }
    else {
        $mermaidContent += "`n- **Dependencies detected**: $($publicToPrivateDeps.Count)"
    }

    # Public → Private Dependencies
    if ($publicToPrivateDeps.Count -gt 0) {
        $mermaidContent += "`n`n## 📋 Public → Private Dependencies"
        $mermaidContent += "`n"

        $grouped = $publicToPrivateDeps | Group-Object -Property Source

        foreach ($group in $grouped) {
            $mermaidContent += "`n### 🔹 ``$($group.Name)``"
            $mermaidContent += "`nDepends on:"
            foreach ($dep in $group.Group) {
                $mermaidContent += "`n- ``$($dep.Target)``"
            }
            $mermaidContent += "`n"
        }
    }

    # Private → Private Dependencies
    if ($IncludePrivateToPrivate -and $privateToPrivateDeps.Count -gt 0) {
        $mermaidContent += "`n## 🔗 Private → Private Dependencies"
        $mermaidContent += "`n"

        $grouped = $privateToPrivateDeps | Group-Object -Property Source

        foreach ($group in $grouped) {
            $mermaidContent += "`n### 🔸 ``$($group.Name)``"
            $mermaidContent += "`nDepends on:"
            foreach ($dep in $group.Group) {
                $mermaidContent += "`n- ``$($dep.Target)``"
            }
            $mermaidContent += "`n"
        }
    }

    # Additional statistics
    if ($allDependencies.Count -gt 0) {
        $mermaidContent += "`n## 📈 Statistics"

        # Top most used private functions
        $topPrivate = $allDependencies | Group-Object -Property Target |
            Sort-Object Count -Descending |
            Select-Object -First 5

        $mermaidContent += "`n`n### Most Used Private Functions"
        foreach ($item in $topPrivate) {
            $mermaidContent += "`n- ``$($item.Name)``: referenced $($item.Count) time(s)"
        }

        # Additional stats for Private → Private
        if ($IncludePrivateToPrivate -and $privateToPrivateDeps.Count -gt 0) {
            # Find leaf private functions (no dependencies)
            $privateFuncsWithDeps = $privateToPrivateDeps.Source | Select-Object -Unique
            $leafPrivateFuncs = $privateFunctions | Where-Object { $_ -notin $privateFuncsWithDeps }

            $mermaidContent += "`n`n### Dependency Chain Analysis"
            $mermaidContent += "`n- **Private functions with dependencies**: $($privateFuncsWithDeps.Count)"
            $mermaidContent += "`n- **Leaf private functions** (no dependencies): $($leafPrivateFuncs.Count)"
        }
    }

    # Write file
    try {
        $mermaidContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        Write-Host "`nFile created successfully: $OutputPath" -ForegroundColor Green
        Write-Host "Total dependencies found: $($allDependencies.Count)" -ForegroundColor Cyan

        if ($IncludePrivateToPrivate) {
            Write-Host "   * Public → Private: $($publicToPrivateDeps.Count)" -ForegroundColor Cyan
            Write-Host "   * Private → Private: $($privateToPrivateDeps.Count)" -ForegroundColor Cyan
        }

        if ($allDependencies.Count -gt 0) {
            Write-Host "Open the file with a Markdown viewer (VS Code, GitHub, etc.) to see the diagram" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Unable to create file $OutputPath : $_"
    }
}