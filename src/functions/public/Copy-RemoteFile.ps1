function Copy-RemoteFile {
    <#
        .SYNOPSIS
            Copies files between a local and a remote machine.

        .DESCRIPTION
            This function facilitates the copying of files from a local machine to a remote machine or vice versa. It establishes a PowerShell session with the remote machine, performs necessary checks, and executes the file transfer while providing progress feedback.

        .PARAMETER ComputerName
            The name or IP address of the remote computer.

        .PARAMETER Direction
            The direction of the copy operation. Use "ToRemote" to copy from local to remote, and "FromRemote" to copy from remote to local.

        .PARAMETER LocalPath
            The path of the file or folder on the local machine.

        .PARAMETER RemotePath
            The path of the file or folder on the remote machine.

        .PARAMETER User
            The username for authentication on the remote machine. Defaults to the current user.

        .PARAMETER Overwrite
            A switch indicating whether to overwrite existing files at the destination.
        .EXAMPLE
            >> Copy a file to a remote machine.      [__]  -->   [|||]

            Copy-RemoteFile -ComputerName myRemoteMachine.network.ok -Direction ToRemote -LocalPath .\Downloads\SuperCoolFunction.ps1 -RemotePath C:\temp -Overwrite

        .EXAMPLE
            >> Copy a file from a remote machine.    [|||]  -->   [__]

            Copy-RemoteFile -ComputerName myRemoteMachine.network.ok -Direction FromRemote -LocalPath .\Downloads\ -RemotePath C:\temp\test1.pp
        .NOTES
            Author: Arnaud Charles
            Github: https://github.com/arnaudcharles
            Linkedin: https://www.linkedin.com/in/arnaudcharles
        #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [ValidateSet("ToRemote", "To", "FromRemote", "From")]
        [string]$Direction,

        [Parameter(Mandatory=$true)]
        [string]$LocalPath,

        [Parameter(Mandatory=$true)]
        [string]$RemotePath,

        [Alias("u")]
        [string]$User = $env:USERNAME,

        [Alias("o")]
        [switch]$Overwrite
    )

    # Normalize Direction parameter
    if ($Direction -eq "To") {
        $Direction = "ToRemote"
    } elseif ($Direction -eq "From") {
        $Direction = "FromRemote"
    }

    try {
        # Authentication
        $anotherUser = $PSBoundParameters.ContainsKey('User')

        if ($anotherUser) {
            $credential = Get-Credential -UserName $User -Message "Enter password for $User"
        } else {
            $credential = Get-Credential -UserName $env:USERNAME -Message "Enter your password"
        }

        if ($null -eq $credential) {
            WriteColor DarkRed ("Authentication cancelled")
            return
        }

        # Connection
        WriteColor Cyan (">> Connecting to $ComputerName")
        $session = New-PSSession -ComputerName $ComputerName -Credential $credential -UseSSL -ErrorAction Stop

        # Show copy information
        if ($Direction -eq "ToRemote") {
            WriteColor Blue (">> Copy LOCAL → REMOTE")
            WriteColor DarkCyan ("   Source: $LocalPath")
            WriteColor DarkCyan ("   Destination: $RemotePath")
        }
        else {
            WriteColor Blue (">> Copy REMOTE → LOCAL")
            WriteColor DarkCyan ("   Source: $RemotePath")
            WriteColor DarkCyan ("   Destination: $LocalPath")
        }

        Write-Host ""

        # Check if remote folder exists
        if ($Direction -eq "ToRemote") {

            # Check if local source folder exists
            WriteColor Cyan (">> Checking local source folder existence...")
            if (-not (Test-Path -Path $LocalPath)) {
                WriteColor Red ("!  Local source path does not exist: $LocalPath")
                return
            } else {
                WriteColor DarkCyan ("   Local source path exists")
            }

            $remoteFolderExists = Invoke-Command -Session $session -ScriptBlock {
                param($path)
                Test-Path -Path $path -PathType Container
            } -ArgumentList $RemotePath

            if (-not $remoteFolderExists) {
                WriteColor DarkYellow ("!! Remote folder does not exist: $RemotePath")
                $createFolder = Read-Host "Do you want to create it? (Y/N)"

                if ($createFolder -eq "Y" -or $createFolder -eq "y") {
                    try {
                        Invoke-Command -Session $session -ScriptBlock {
                            param($path)
                            $null = New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop
                        } -ArgumentList $RemotePath -ErrorAction Stop

                        # Verify creation
                        $verifyCreate = Invoke-Command -Session $session -ScriptBlock {
                            param($path)
                            Test-Path -Path $path -PathType Container
                        } -ArgumentList $RemotePath

                        if ($verifyCreate) {
                            WriteColor Green ("   Remote folder created successfully")
                        } else {
                            WriteColor Red ("!  Failed to create remote folder (verification failed)")
                            return
                        }
                    }
                    catch {
                        WriteColor Red ("!  Failed to create remote folder: $($_.Exception.Message)")
                        return
                    }
                } else {
                    WriteColor Red ("   Remote folder creation cancelled")
                    return
                }
            } else {
                WriteColor DarkCyan ("   Remote folder exists")
            }

            Write-Host ""

            # Check if destination file/folder already exists
            $destFileName = Split-Path -Leaf $LocalPath
            $fullRemotePath = Join-Path $RemotePath $destFileName

            $remoteFileExists = Invoke-Command -Session $session -ScriptBlock {
                param($path)
                Test-Path -Path $path
            } -ArgumentList $fullRemotePath

            if ($remoteFileExists) {
                WriteColor DarkYellow ("   Destination file/folder already exists: $fullRemotePath")

                if ($Overwrite) {
                    WriteColor Cyan ("~> Overwriting (due to -Overwrite flag)...")
                    try {
                        Invoke-Command -Session $session -ScriptBlock {
                            param($path)
                            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                        } -ArgumentList $fullRemotePath -ErrorAction Stop
                        WriteColor Green ("   Existing file removed")
                    }
                    catch {
                        WriteColor Red ("!  Failed to remove existing file: $($_.Exception.Message)")
                        return
                    }
                } else {
                    $overwriteChoice = Read-Host "Do you want to overwrite it? (Y/N)"

                    if ($overwriteChoice -eq "Y" -or $overwriteChoice -eq "y") {
                        try {
                            Invoke-Command -Session $session -ScriptBlock {
                                param($path)
                                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                            } -ArgumentList $fullRemotePath -ErrorAction Stop
                            WriteColor Green ("   Existing file removed")
                        }
                        catch {
                            WriteColor Red ("!  Failed to remove existing file: $($_.Exception.Message)")
                            return
                        }
                    } else {
                        WriteColor Red ("   Operation cancelled")
                        return
                    }
                }
            } else {
                WriteColor DarkCyan ("   Destination is clear")
            }

            Write-Host ""
        }

        # Check if local folder exists (only for FromRemote)
        if ($Direction -eq "FromRemote") {

            # Check if remote source folder exists
            WriteColor Cyan (">> Checking remote source folder existence...")
            $remoteSourceExists = Invoke-Command -Session $session -ScriptBlock {
                param($path)
                Test-Path -Path $path
            } -ArgumentList $RemotePath

            if (-not $remoteSourceExists) {
                WriteColor Red ("!  Remote source path does not exist: $RemotePath")
                return
            } else {
                WriteColor DarkCyan ("   Remote source path exists")
            }

            Write-Host ""

            WriteColor Cyan (">> Checking local folder existence...")

            $localFolderExists = Test-Path -Path $LocalPath -PathType Container

            if (-not $localFolderExists) {
                WriteColor DarkYellow ("   Local folder does not exist: $LocalPath")
                $createFolder = Read-Host "Do you want to create it? (Y/N)"

                if ($createFolder -eq "Y" -or $createFolder -eq "y") {
                    try {
                        $null = New-Item -Path $LocalPath -ItemType Directory -Force -ErrorAction Stop

                        # Verify creation
                        if (Test-Path -Path $LocalPath -PathType Container) {
                            WriteColor Green ("   Local folder created successfully")
                        } else {
                            WriteColor Red ("!  Failed to create local folder (verification failed)")
                            return
                        }
                    }
                    catch {
                        WriteColor Red ("!  Failed to create local folder: $($_.Exception.Message)")
                        return
                    }
                } else {
                    WriteColor Red ("   Operation cancelled")
                    return
                }
            } else {
                WriteColor DarkCyan ("   Local folder exists")
            }

            Write-Host ""

            # Check if destination file/folder already exists
            WriteColor Cyan (">> Checking if destination file exists...")

            $destFileName = Split-Path -Leaf $RemotePath
            $fullLocalPath = Join-Path $LocalPath $destFileName

            $localFileExists = Test-Path -Path $fullLocalPath

            if ($localFileExists) {
                WriteColor DarkYellow ("   Destination file/folder already exists: $fullLocalPath")

                if ($Overwrite) {
                    WriteColor Cyan ("~> Overwriting (due to -Overwrite flag)...")
                    try {
                        Remove-Item -Path $fullLocalPath -Recurse -Force -ErrorAction Stop
                        WriteColor Green ("   Existing file removed")
                    }
                    catch {
                        WriteColor Red ("!  Failed to remove existing file: $($_.Exception.Message)")
                        return
                    }
                } else {
                    $overwriteChoice = Read-Host "Do you want to overwrite it? (Y/N)"

                    if ($overwriteChoice -eq "Y" -or $overwriteChoice -eq "y") {
                        try {
                            Remove-Item -Path $fullLocalPath -Recurse -Force -ErrorAction Stop
                            WriteColor Green ("   Existing file removed")
                        }
                        catch {
                            WriteColor Red ("!  Failed to remove existing file: $($_.Exception.Message)")
                            return
                        }
                    } else {
                        WriteColor Red ("   Operation cancelled")
                        return
                    }
                }
            } else {
                WriteColor DarkCyan ("   Destination is clear")
            }

            Write-Host ""
        }

        # Start copy
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        Write-Host ""

        if ($Direction -eq "ToRemote") {
            Copy-Item -Path $LocalPath -Destination $RemotePath -ToSession $session -Recurse -Force -ErrorAction Stop
        }
        else {
            Copy-Item -Path $RemotePath -Destination $LocalPath -FromSession $session -Recurse -Force -ErrorAction Stop
        }

        $stopwatch.Stop()

        WriteColor Green (">> Copy completed in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) seconds")
        Write-Host ""
    }
    catch {
        WriteColor Red (":-/ Error: $($_.Exception.Message)")
    }
    finally {
        if ($null -ne $session) {
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }
}