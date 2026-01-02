function Switch-Pane {
    <#
    .SYNOPSIS
        Dedicated function for Windows Terminal.
        Switches the active pane in the specified direction.

    .DESCRIPTION
        The Switch-Pane function allows you to switch the active pane in a specified direction within a multi-pane environment. This can be useful for navigating between different panes from a script perspective.
        Run the Get-Help Switch-Pane -Examples to have a better understanding of how to use this function.

    .PARAMETER Direction
        Specifies the direction to switch the active pane. Valid values are "LEFT", "RIGHT", "UP", and "DOWN".

    .EXAMPLE
        EXAMPLE 1 --> The basic switch, this example switches the active pane to the right.

        Initial situation is the following, you are on the left pane.
        +---+---+
        | X |   |
        +---+---+

        If you run the command : Switch-Pane -Direction "RIGHT"
        +---+---+
        |   | X |
        +---+---+
        You will be on the right pane.

    .EXAMPLE
        EXAMPLE 2 --> The advanced switch, this example switches the active pane to the bottom right.

        Initial situation is the following, you are on the left pane.
        +---+---+
        | X |   |
        |   |---+
        |   |   |
        +---+---+

        If you run the command : Switch-Pane -Direction "RIGHT" && Switch-Pane -Direction "DOWN"
        +---+---+
        |   |   |
        |   |---+
        |   | X |
        +---+---+
        You will be on the bottom right pane.

    .EXAMPLE
        EXAMPLE 3 --> The list of switches, this example shows all the possible switches.

            "RIGHT"             -> Alt+Right
            "LEFT"              -> Alt+Left
            "UP" {              -> Alt+Up
            "DOWN"              -> Alt+Down
            "PREVIOUS"          -> Ctrl+Shift+Home
            "PREVIOUSINORDER"   -> Ctrl+Shift+Tab
            "NEXTINORDER"       -> Ctrl+Tab
            "FIRST"             -> Ctrl+Home
            "PARENT"            -> Ctrl+PageUp
            "CHILD"             -> Ctrl+PageDown

        .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 2024-12-20
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("RIGHT", "LEFT", "UP", "DOWN", "PREVIOUS", "PREVIOUSINORDER", "NEXTINORDER", "FIRST", "PARENT", "CHILD")]
        [string]$Direction
    )

    # Make sure the settings are set correctly
    Add-WindowsTerminalSettings

    $shell = New-Object -ComObject WScript.Shell

    switch ($Direction) {
        "RIGHT" { $shell.SendKeys("%{RIGHT}") }             # Alt+Right
        "LEFT" { $shell.SendKeys("%{LEFT}") }               # Alt+Left
        "UP" { $shell.SendKeys("%{UP}") }                   # Alt+Up
        "DOWN" { $shell.SendKeys("%{DOWN}") }               # Alt+Down
        "PREVIOUS" { $shell.SendKeys("%{TAB}") }            # Ctrl+Shift+Home
        "PREVIOUSINORDER" { $shell.SendKeys("^+{TAB}") }    # Ctrl+Shift+Tab
        "NEXTINORDER" { $shell.SendKeys("^{TAB}") }         # Ctrl+Tab
        "FIRST" { $shell.SendKeys("^{HOME}") }              # Ctrl+Home
        "PARENT" { $shell.SendKeys("^{PGUP}") }             # Ctrl+PageUp
        "CHILD" { $shell.SendKeys("^{PGDN}") }              # Ctrl+PageDown
    }
}