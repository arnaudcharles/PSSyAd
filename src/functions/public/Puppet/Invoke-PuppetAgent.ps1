function Invoke-PuppetAgent {
    <#
    .SYNOPSIS
        This function is a wrapper around the Puppet agent commands, providing a simplified interface for common tasks.
    .DESCRIPTION
        This function allows you to invoke the Puppet agent with different commands such as enabling/disabling the agent, changing the environment, and checking various statuses.
    .EXAMPLE
        We have an alias pat for this function.

        > ACTIONS <
        pat              --> Run puppet manually.
        pat env <env>    --> Run Puppet agent on specified environment <env>.
        pat ds <reason>  --> Disable Puppet agent with reason <reason>.
        pat en           --> Enable Puppet agent.


        > INFO <
        pat config       --> Show Puppet configuration.
        pat srv          --> Get Puppet service status.
        pat state        --> Get Puppet agent state (enabled/disabled).
        pat getenv       --> Get Puppet environment.
        pat lr           --> Get last Puppet run time.
        pat og           --> Check if a Puppet run is ongoing.

    .EXAMPLE
        Invoke-PuppetAgent --disable "Testing some stuff"
        >> Disables the Puppet agent with the reason 'Testing some stuff' and create an event log entry in the Application log with ID 210.

        Invoke-PuppetAgent --enable
        >> Enables the Puppet agent and create an event log entry in the Application log with ID 200.

        Invoke-PuppetAgent --environment dev
        >> Runs the Puppet agent on the 'dev' environment and create an event log entry in the Application log with ID 300.
    .NOTES
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateSet(
            # Disable
            'ds', 'disable', '--disable',
            # Enable
            'en', 'enable', '--enable',
            # Change environment
            'env', 'environment', '--environment',
            # Others commands
            'config', 'lr', 'getenv', 'srv', 'state', 'og',
            IgnoreCase=$true
        )]
        [string]$Command,

        [Parameter(Position=1)]
        [string]$Complement
    )
    $agent_disabled_lockfile = "C:/ProgramData/PuppetLabs/puppet/cache/state/agent_disabled.lock"

    switch ($Command) {
        # Enable Puppet agent
        {$_ -in @('en', 'enable', '--enable')} {
            try {
                puppet agent --enable
                WriteColor Green ("-> Puppet agent enabled successfully")
                Write-EventLog -LogName "Application" -Source "Puppet" -EventId 200 -EntryType Information -Message "Puppet Agent - Enabled by $env:USERNAME"
            }
            catch {
                WriteColor Red ("!! Failed to enable puppet agent: $_")
            }
        }
        # Disable Puppet agent
        {$_ -in @('ds', 'disable', '--disable')} {

            if ([string]::IsNullOrWhiteSpace($Complement)) {
                Write-Host "Error: Should be following by a reason in String to disable Puppet." -ForegroundColor Red
                return
            }
            try {
                WriteColor Cyan (">> Disabling puppet agent")
                puppet agent --disable "$Complement"

                # Check if agent is disabled
                if (Test-Path $agent_disabled_lockfile){
                    WriteColor Green (">> Puppet agent disabled successfully")
                    Write-EventLog -LogName "Application" -Source "Puppet" -EventId 210 -EntryType Information -Message "Puppet Agent - Disabled by $env:USERNAME"
                }
            }
            catch {
                WriteColor Red ("!! Failed to disable puppet agent: $_")
            }
        }
        # Run Puppet agent on specified environment
        {$_ -in @('env', 'environment', '--environment')} {
            try {
                puppet agent -t --environment $Complement
                WriteColor Green ("-> Puppet agent running on specified environment '$Complement'")
                Write-EventLog -LogName "Application" -Source "Puppet" -EventId 300 -EntryType Information -Message "Puppet Agent manually triggered by $env:USERNAME using environment '$Complement'"
            }
            catch {
                WriteColor Red ("!! Failed to run puppet in env '$Complement': $_")
            }
        }
        # Show Puppet configuration
        'config' {
            WriteColor Cyan (">> Showing Puppet configuration")
            puppet config print
        }
        # Show last Puppet run time
        'lr' {
            Get-PuppetLastRuntime
        }
        # Show Puppet environment
        'getenv' {
            Get-PuppetEnvironment
        }
        # Show Puppet service status
        'srv' {
            Get-PuppetServiceStatus
        }
        # Show Puppet state
        'state' {
            Get-PuppetState
        }
        # Show if Puppet run is ongoing
        'og' {
            Get-PuppetRunStatus
        }
        '' {
            WriteColor Cyan (">> Starting Puppet agent run")
            Write-EventLog -LogName "Application" -Source "Puppet" -EventId 250 -EntryType Information -Message "Puppet Agent manually triggered by $env:USERNAME"
            puppet agent -t
        }
        default {
            Write-Host "Command not found using pat: $_" -ForegroundColor Red
        }
    }
}