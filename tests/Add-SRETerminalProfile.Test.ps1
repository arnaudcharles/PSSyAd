[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Required for Pester tests'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Required for Pester tests'
)]
[CmdletBinding()]
param()

Describe "Test Add-SRETerminalProfile" {
    It "Should not throw when called" {
        { Add-SRETerminalProfile } | Should -Not -Throw
    }
}