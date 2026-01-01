function Test-ExecutionHost {
    <#
    .SYNOPSIS
        Use to test where a function is running.

    .DESCRIPTION
        Use this function to test if your function is action from a local or remote host.

    .EXAMPLE
        Test-ExecutionHost  -> return "local" or "remote" or "error"

    .NOTES
        Author: Arnaud Charles
        Github: https://github.com/arnaudcharles
        Linkedin: https://www.linkedin.com/in/arnaudcharles
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
    param()

    try {
        $console = (Get-Host).Name

        switch ($console) {
            "ConsoleHost" { return "local" }
            "ServerRemoteHost" { return "remote" }
            default { return "error" }
        }
    } catch {
        WriteColor red ("The console hostname is coming from space (｡◕‿‿◕｡)")
    }
}