function Get-FW {
    <#
    .SYNOPSIS
        Function to get FW rules on an host either locally or remotely.

    .DESCRIPTION
        This function is capable of running from any location It will check if you are on a local or remote host and act accordingly.
        Two views are available: human and table.

    .EXAMPLE
        CASE 1. You are on a remote host and want to get the FW rules of this host.

        -->    Get-FW -view human           (Full command)
        -->    Get-FW -view table           (Full command)
        -->    Get-FW -v h                  (Short command)
        -->    Get-FW -v t                  (Short command)

        CASE 2. You are on a local host and want to get the FW rules of a remote host.

        -->    Get-FW -hostname server1 -view human          (Full command)
        -->    Get-FW -hostname server1 -view table          (Full command)
        -->    Get-FW -h server1 -v h                        (Short command)
        -->    Get-FW -h server1 -v t                        (Short command)


    .PARAMETER hostname
        Should be the remote host address. Alias is -h.

    .PARAMETER view
        Should be :
        - 'h' or 'human' for human readable output
        - 't' or 'table' for table output.
        Alias is -v.

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingWriteHost", "", Justification = "Common if you can play with color without Write-Output on this one feel free to edit, color doesn't kill anyone ♥"
    )]
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('h')]
        [ValidateNotNullOrEmpty()]
        [string]$hostname,
        [Parameter()]
        [Alias('v')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('h', 'human', 't', 'table', IgnoreCase = $true)]
        [string]$view
    )

    function Get-FirewallRule {
        param (
            [switch]$tab,
            [switch]$human,
            [string]$location = "local",
            [string]$hostname,
            [switch]$useSSL
        )

        # If location is remote, require to create a CIM session
        if ($location -eq "remote") {
            $seop = New-CimSessionOption -UseSSL:$useSSL
            $session = New-CimSession -CN $hostname -SessionOption $seop

            # Checking in case the session is not created or timeout
            if (-not $session) {
                Write-Output "Failed to create CIM session."
                return
            }

            # Defining how the rules will be retrieved
            $rules = Get-NetFirewallRule -CimSession $session | Where-Object { $_.Enabled -eq $true }
        } else {
            $rules = Get-NetFirewallRule | Where-Object { $_.Enabled -eq $true }
        }

        # Splitting the rules inbound and outbound
        $inboundRules = $rules | Where-Object { $_.Direction -eq 'Inbound' }
        $outboundRules = $rules | Where-Object { $_.Direction -eq 'Outbound' }

        # Function for the table view
        function Show-FirewallRulesTable($ruleSet, $direction) {
            if ($ruleSet) {
                Write-Host "`n----- $direction -----" -ForegroundColor Blue
                Write-Host ("Action".PadRight(15) + " | " +
                            "Protocol".PadRight(15) + " | " +
                            "LocalPort".PadRight(15) + " | " +
                            "RemotePort".PadRight(15) + " | " +
                            "DisplayName".PadRight(30)) -ForegroundColor Gray

                Write-Host ("-" * 80)

                $ruleSet | ForEach-Object {
                    $rule = $_
                    $protocol = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule).Protocol -join ', '
                    $localPorts = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule).LocalPort -join ', '
                    $remotePorts = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule).RemotePort -join ', '
                    #$remoteAddress = (Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule).RemoteAddress -join ', '
                    $displayName = $rule.DisplayName
                    $action = $rule.Action

                    # Building the array
                    #? Note that the remoteAddress is not displayed in the table view because it would make the table too wide and not readable
                    #? If needed the variable exist, it can be added it in the Write-Host line below
                    Write-Host (
                        "$action".PadRight(15) + " | " +
                        "$($protocol.PadRight(15)) | " +
                        "$($localPorts.PadRight(15)) | " +
                        "$($remotePorts.PadRight(15)) | " +
                        "$($displayName.PadRight(30))"
                    )
                }
            }
        }

        # Function for the human view
        function Show-FirewallRulesHuman($ruleSet, $direction) {
            if ($ruleSet) {
                Write-Host "`n----- $direction -----" -ForegroundColor Blue
                $ruleSet | ForEach-Object {
                    $rule = $_
                    $protocol = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule).Protocol -join ', '
                    $localPorts = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule).LocalPort -join ', '
                    $remotePorts = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule).RemotePort -join ', '
                    $remoteAddress = (Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule).RemoteAddress -join ', '
                    $displayName = $rule.DisplayName
                    $action = $rule.Action

                    # Color selection
                    $protocolColor = 'Cyan'
                    $portColor = 'Magenta'
                    $displayNameColor = 'Gray'
                    $actionColor = switch ($action) {
                        'Allow' { 'Green' }
                        'AllowBypass' { 'Yellow' }
                        'Block' { 'Red' }
                        default { 'White' }
                    }

                    # Build the view
                    Write-Host -ForegroundColor $protocolColor "$protocol | " -NoNewline
                    Write-Host -ForegroundColor $portColor "$localPorts -> $remotePorts | " -NoNewline
                    Write-Host -ForegroundColor $displayNameColor "$displayName | " -NoNewline
                    Write-Host -ForegroundColor $actionColor "$action"

                    # Display the remote address under the rest as it take sometime space
                    Write-Host "  → $remoteAddress"
                }
            }
        }

        # View selector
        if ($tab) {
            Show-FirewallRulesTable $inboundRules 'INBOUND'
            Show-FirewallRulesTable $outboundRules 'OUTBOUND'
        }
        elseif ($human) {
            Show-FirewallRulesHuman $inboundRules 'INBOUND'
            Show-FirewallRulesHuman $outboundRules 'OUTBOUND'
        }
    }

# ----------------------------------------------------------------------------------------------------------------- #
    #! CODE
    # Checking if we are on a local session and argument remote hostname is correctly set
    if (((Test-ExecutionHost) -eq "local") -and ($PSBoundParameters.ContainsKey('hostname'))){
        try {
            # Checking if the remote host is reachable
            Test-RemoteHost -Hostname $hostname -ErrorAction Stop
            # Then get the firewall rules based on the view choice
            if ($view -eq "h" -or $view -eq "human") {
                Get-FirewallRule -human -location remote -hostname $hostname -useSSL
            } elseif ($view -eq "t" -or $view -eq "table") {
                Get-FirewallRule -tab -location remote -hostname $hostname -useSSL
            } else {
                Get-FirewallRule -tab -location remote -hostname $hostname -useSSL
            }
        }
        catch {
            WriteColor red ("The host $hostname is not reachable")
        }
    }
    # Checking if we are on a local session and argument remote hostname is not defined
    elseif (((Test-ExecutionHost) -eq "local") -and -not ($PSBoundParameters.ContainsKey('hostname'))){
        WriteColor red ("As you are not connected to an host you need to specify one with -hostname servername")
    }
    # Checking if we are on a remote host and hostname is defined
    elseif ((Test-ExecutionHost) -eq "remote"){
        WriteColor yellow ("You are on a remote host, the -hostname parameter will be ignored")
        # Get the firewall rules based on the view choice
        if ($view -eq "h" -or $view -eq "human") {
            Get-FirewallRule -human
        } elseif ($view -eq "t" -or $view -eq "table") {
            Get-FirewallRule -tab
        } else {
            Get-FirewallRule -tab
        }
        Get-FirewallRule
    }
}