function Copy-InputAccrossPanes {
    <#
    .SYNOPSIS
        This function allow you to send the same input to multiple panes in Windows Terminal.

    .DESCRIPTION
        The function is taking as arguments the number of panes and the command to execute and will switch from panes to pane to send the input.

    .PARAMETER Panes
        This parameter is used to specify the number of panes to send the input to. It need to be correct as for now there is no way to know on which panes the user is.
        This parameter is mandatory and can be shorted with -p.

    .EXAMPLE
        Copy-InputAccrossPanes -p 3 pwd

        With the use of the alias
        ciap -p 4 shutdown -y

    .COMPONENT
        This function requires the Private function Switch-Pane to work properly.
        Better to have an alias for it like "ciap" for easy use.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 30/12/24
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    param (
        [Parameter(Mandatory=$true)]
        [Alias('p')]
        [ValidateRange(2, 6)]
        [int]$Panes,

        [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
        [string[]]$Command
    )

    # Combine all command parts into a single string
    $fullCommand = $Command -join ' '

    # Create shell object for sending keystrokes
    $shell = New-Object -ComObject WScript.Shell

    # Go to the first pane and execute the command
    Switch-Pane -Direction "FIRST"
    Start-Sleep -Milliseconds 250
    $shell.SendKeys($fullCommand)
    Start-Sleep -Milliseconds 250
    $shell.SendKeys("{ENTER}")
    Start-Sleep -Milliseconds 250

    # Execute on the other panes
    for ($i = 1; $i -lt $Panes; $i++) {
        Switch-Pane -Direction "NEXTINORDER"
        Start-Sleep -Milliseconds 250

        $shell.SendKeys($fullCommand)
        Start-Sleep -Milliseconds 250
        $shell.SendKeys("{ENTER}")
        Start-Sleep -Milliseconds 250
    }

    # Go back to the initial pane
    Switch-Pane -Direction "FIRST"
    Start-Sleep -Milliseconds 250
}