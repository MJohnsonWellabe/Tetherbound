#requires -Version 7.0
$ErrorActionPreference = 'Stop'
# Evaluate only the pure verdict function, never the launcher or any process API.
$tokens = $null
$errors = $null
$path = Join-Path $PSScriptRoot 'run_routes_scoped_checks.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
if ($errors) { throw ($errors | Out-String) }
$timerSource = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $node.Value.Contains('public sealed class RoutesCheckDeadline') }, $true)
if ($null -eq $timerSource) { throw 'Independent deadline guard missing' }
if (-not ('RoutesCheckDeadline' -as [type])) { Add-Type -TypeDefinition $timerSource.Value }
$definition = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-RunVerdict' }, $true)
if ($null -eq $definition) { throw 'Verdict function missing' }
Invoke-Expression $definition.Extent.Text
$expected = @('test_a.gd :: test_one', 'test_b.gd :: test_two')
$good = "  ok    test_a.gd :: test_one`n  ok    test_b.gd :: test_two`n2 tests, 9 assertions, 0 failed`n"
if (-not (Get-RunVerdict $good '' $expected).passed) { throw 'Valid complete test output rejected' }
$bad = @('', ($good -replace 'test_two', 'test_other'), ($good -replace 'test_b.gd :: test_two', 'test_a.gd :: test_one'),
    ($good -replace '2 tests', '1 tests'), ($good -replace '9 assertions', '0 assertions'), ($good -replace '0 failed', '1 failed'),
    ($good + "2 tests, 9 assertions, 0 failed`n"), ($good + "SCRIPT ERROR: broken`n"),
    ($good + "ERROR: failed`n"), ($good + "WARNING: leak`n"), ($good -replace '(?m)^.*test_two.*\n', ''))
foreach ($candidate in $bad) {
    if ((Get-RunVerdict $candidate '' $expected).passed) { throw 'Incomplete/contradictory output accepted' }
}
foreach ($diagnostic in @('Parse Error: broken', 'ERROR: runtime', 'WARNING: leak')) {
    if ((Get-RunVerdict $good $diagnostic $expected).passed) { throw 'stderr diagnostic accepted' }
}
if ((Get-RunVerdict $good '' @()).passed) { throw 'Empty requested test set accepted' }
Write-Output 'PASS: PowerShell syntax, deadline C# compilation and16 synthetic verdict cases; no native execution'
