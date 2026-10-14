$ErrorActionPreference='Stop'
$Tokens=$null;$Errors=$null
$Ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'native-supervisor/run_validation.ps1'),[ref]$Tokens,[ref]$Errors)
if($Errors.Count){throw ($Errors|Out-String)}
foreach($Name in @('New-OperationBudget','Get-OperationRemaining','Start-OperationCleanup','Assert-OperationBudget','Get-OperationWaitMs','Invoke-Git','Get-GitBlobId')){
 $Definition=$Ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $Name},$true)
 Invoke-Expression $Definition.Extent.Text
}
$SourceDefinition=$Ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-Source'},$true).Extent.Text
$GitDefinition=$Ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Invoke-Git'},$true).Extent.Text
if(([regex]::Matches($SourceDefinition,'New-OperationBudget')).Count -ne 1 -or $GitDefinition -match 'StartNew|New-OperationBudget'){throw 'Source budget resets inside Git child'}
$script:SourceBudget=[pscustomobject]@{Timer=[pscustomobject]@{Elapsed=[pscustomobject]@{TotalSeconds=115.0}};WorkSeconds=115.0;TotalSeconds=120.0;CleanupDeadline=$null}
$Rejected=$false
try{$null=Invoke-Git @('CPU-MUST-NOT-START')}catch{if($_.Exception.Message -notlike '*Aggregate operation*'){throw};$Rejected=$true}
if(-not $Rejected){throw 'Child accepted after shared deadline'}
$Path=Join-Path $PSScriptRoot ('cpu-source-deadline-'+[Guid]::NewGuid().ToString('N')+'.bin')
[IO.File]::WriteAllBytes($Path,[byte[]]::new(4MB))
$script:SourceBudget.Timer.Elapsed.TotalSeconds=0.0
$OriginalAssert=(Get-Command Assert-OperationBudget).ScriptBlock
function Assert-OperationBudget($Budget,[switch]$Cleanup){$Budget.Timer.Elapsed.TotalSeconds+=40.0;& $OriginalAssert $Budget -Cleanup:$Cleanup}
$Rejected=$false
try{$null=Get-GitBlobId $Path}catch{if($_.Exception.Message -notlike '*Aggregate operation*'){throw};$Rejected=$true}
if(-not $Rejected){throw 'File hashing ignored shared deadline'}
@{status='PASS_CPU_ONLY';expired_child_refused_before_launch=$true;actual_file_hash_loop_refused=$true;single_source_budget_verified=$true;stage_access=$false;engine_launched=$false}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'cpu-source-aggregate.json') -Encoding utf8
'PASS: runtime source budget shared across Git and actual hash loop.'
