function Invoke-DBAPatching {

    <#
    .SYNOPSIS
        This function is used for DBA patching.

    .DESCRIPTION
        This function is used for DBA to open one terminal with 6 panes that automatically connect to 6 servers.
        Use "get-help Invoke-DBAPatching -Examples" to have a complete how to.

    .PARAMETER Hosts
        The Hosts parameter is used as input for the function to connect to the servers. This parameter need to be an array of strings.

    .PARAMETER Vertical
        The Vertical parameter is used to split the panes vertically. Only applicable when 3 hosts are provided.
        You can use also -v for short.

    .EXAMPLE
        Step 1 : Prerequisite

            The function is made to work with 3 or 6 nodes. That mean you need to define an array of 3 or 6 nodes to use the function.
            On this example I'm defining 6 of them. The variable $Hosts can be anything else, the only important part is to call the argument -Hosts.
                $Hosts = @(
                    "dba1",
                    "dba2",
                    "dba3",
                    "dba4",
                    "dba5",
                    "dba6"
                )

            This example show how to prepare the $Hosts array to be used as input for the function.

        Step 2 : Run the function
            Invoke-DBAPatching -Hosts $Hosts

            This example shows how to use the basic functionality of the function.

        Advice :
        You can also add to your $PROFILE some registed list using name you like and you can easily remind to facilitate the usage of the function.
        Like $SB_CUSTOMER_XXX = @("OG1", "OG2", "OG3", "OG4", "OG5", "OG6")
        Invoke-DBAPatching -Hosts $SB_OG_XXX

        or

        Like $PR_DB_XXX = @("DB1", "DB2", "DB3")
        Invoke-DBAPatching -Hosts $PR_DB_XXX      --> Will open 3 panes with 3 servers vertically
        Invoke-DBAPatching -Hosts $PR_DB_XXX -h   --> Will open 3 panes with 3 servers horizontally

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
        Date: 09/09/24
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Hosts,

        [Parameter()]
        [Alias('h')]
        [switch]$Horizontal
    )

    # Check the count of hosts
    if ($Hosts.Count -ne 3 -and $Hosts.Count -ne 6) {
        throw "Please provide either 3 or 6 hostnames. You provided $($Hosts.Count) hostnames."
    }

    $tabColors = @("#b8413b", "#b85e3b", "#b8803b", "#b89d3b", "#b2b83b", "#86b83b")

    if ($Hosts.Count -eq 6) {
        # Open 6 panes with 6 servers
        wt -w 0 nt --title  $($Hosts[0]) --tabColor $tabColors[0] pwsh -wd ~ -noexit -command "connect $($Hosts[0])"  `; `
        split-pane --horizontal --size 0.5  --title $($Hosts[3]) --tabColor $tabColors[3] pwsh -wd ~ -noexit -command "connect $($Hosts[3])"  `; `
        split-pane --vertical --size 0.66 --title $($Hosts[4]) --tabColor $tabColors[4] pwsh -wd ~ -noexit -command "connect $($Hosts[4])"  `; `
        split-pane --vertical --size 0.5 --title $($Hosts[5]) --tabColor $tabColors[5] pwsh -wd ~ -noexit -command "connect $($Hosts[5])"  `; `
        move-focus up `; `
        split-pane --vertical --size 0.66 --title $($Hosts[1]) --tabColor $tabColors[1] pwsh -wd ~ -noexit -command "connect $($Hosts[1])"  `; `
        split-pane --vertical --size 0.5 --title $($Hosts[2]) --tabColor $tabColors[2] pwsh -wd ~ -noexit -command "connect $($Hosts[2])"  `; `
        move-focus first
    } elseif ($Hosts.Count -eq 3) {
        if ($Horizontal) {
            wt -w 0 nt --title $($Hosts[0]) --tabColor $tabColors[0] pwsh -wd ~ -noexit -command "connect $($Hosts[0])" `; `
            split-pane --horizontal --size 0.66 --title $($Hosts[1]) --tabColor $tabColors[1] pwsh -wd ~ -noexit -command "connect $($Hosts[1])" `; `
            split-pane --horizontal --size 0.5 --title $($Hosts[2]) --tabColor $tabColors[2] pwsh -wd ~ -noexit -command "connect $($Hosts[2])" `; `
            move-focus first
        } else {
            # Open 3 Vertical panes by default
            wt -w 0 nt --title $($Hosts[0]) --tabColor $tabColors[0] pwsh -wd ~ -noexit -command "connect $($Hosts[0])" `; `
            split-pane --vertical --size 0.66 --title $($Hosts[1]) --tabColor $tabColors[1] pwsh -wd ~ -noexit -command "connect $($Hosts[1])" `; `
            split-pane --vertical --size 0.5 --title $($Hosts[2]) --tabColor $tabColors[2] pwsh -wd ~ -noexit -command "connect $($Hosts[2])" `; `
            move-focus first
        }
    }
}