
function Split-Pane {
    <#
    .SYNOPSIS
        This function is used for opening WT tabs with multiple panes.

    .DESCRIPTION
        This function is used for SRE to open one terminal with 3 panes that automatically connect to servers based on the service.

    .COMPONENT
        This function requires the Private function Switch-Pane to work properly.

    .EXAMPLE
        Example 1.
        --> Open a new tab called My awsesome terminal with a blue color that will split the screen in 3 horizontal panes.
        Split-Pane -tabTitle "My awesome terminal" -tabColor "#3256a8"

        Example 2.
        --> Open a new tab called My terminal with an orange color that will split the screen in 3 vertical panes.
        Split-Pane -tabTitle "My terminal" -tabColor "#f59218" -config 2

        Example 3.
        --> Open a new window called Test with a red color that will split the screen in 3 vertical panes.
        Split-Pane -tabTitle "Test" -tabColor "#a83244" -config 2 -newWindow

    .PARAMETER tabTitle
        The tabTitle parameter is used as input for the function to set the title of the tab.

    .PARAMETER tabColor
        The tabColor parameter is used as input for the function to set the color of the tab.

    .PARAMETER config
        The config parameter is used as input for the function to set the configuration of the panes.

        CONFIG 1 --> Split the terminal in 3 horizontal panes. (Default)
        CONFIG 2 --> Split the terminal in 3 vertical panes.
        CONFIG 3 --> Split the terminal in 2 horizontal panes, the first is full and the second is split in 2 vertical panes.
        CONFIG 4 --> Split the terminal in 2 vertical panes, each split in 2 horizontal panes.
        CONFIF 5 --> Split the terminal in 6 panes, 2 rows and 3 columns.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 30/12/24
    #>

    [CmdletBinding()]
    param (
        [string]$tabTitle,

        [ValidateRange(1,5)]
        [int]$config = 1,

        [string]$tabColor = "#46bda9",

        [switch]$newWindow = $false
    )

    $WarningPreference = 'SilentlyContinue'

    switch ($config) {
        1 {
            if ($NewWindow) {
                wt nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --horizontal --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
            else {
                wt -w 0 nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --horizontal --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
        }
        2 {
            if ($NewWindow) {
                wt nt -NoProfile  --title $tabTitle --tabColor $tabColor `; `
                split-pane --vertical --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
            else {
                wt -w 0 nt -NoProfile  --title $tabTitle --tabColor $tabColor `; `
                split-pane --vertical --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
        }
        3 {
            if ($NewWindow) {
                wt nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
            else {
                wt -w 0 nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
        }
        4 {
            if ($NewWindow) {
                wt nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor `; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; move-focus left `; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
            else {
                wt -w 0 nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; move-focus left `; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
        }
        5 {
            if ($NewWindow) {
                wt nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; move-focus up `; `
                split-pane --vertical --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
            else {
                wt -w 0 nt -NoProfile --title $tabTitle --tabColor $tabColor `; `
                split-pane --horizontal --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; move-focus up `; `
                split-pane --vertical --size 0.66 --title $tabTitle --tabColor $tabColor`; `
                split-pane --vertical --size 0.5 --title $tabTitle --tabColor $tabColor`; `
                move-focus first
            }
        }
    }
}