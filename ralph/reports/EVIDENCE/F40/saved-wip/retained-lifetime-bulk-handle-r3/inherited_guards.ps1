# Guard functions adapted verbatim from the prior storage supervisor.
function Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
function BytesHash([byte[]]$Bytes){[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()}
function WriteJson([string]$Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 20)+"`n",[Text.UTF8Encoding]::new($false))}
function NoReparse([string]$Path){
 $p=[IO.Path]::GetFullPath($Path)
 while($p){if(Test-Path -LiteralPath $p){if((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw "Reparse path: $p"}};$p=[IO.Path]::GetDirectoryName($p)}
}
function SafeChild([string]$Root,[string]$Relative){
 if([IO.Path]::IsPathRooted($Relative) -or $Relative.Contains(':')){throw 'Absolute archive entry'}
 $p=[IO.Path]::GetFullPath((Join-Path $Root $Relative)); $prefix=[IO.Path]::GetFullPath($Root).TrimEnd('\')+'\'
 if(-not $p.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Archive traversal'};NoReparse $p;return $p
}
function ReadLiveLog([string]$Path){
 $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite);$reader=[IO.StreamReader]::new($stream)
 try{return $reader.ReadToEnd()}finally{$reader.Dispose();$stream.Dispose()}
}
function Metrics {
 $os=Get-CimInstance Win32_OperatingSystem; $m=Get-CimInstance Win32_PerfRawData_PerfOS_Memory
 return @{utc=[DateTime]::UtcNow.ToString('o'); C=[long](Get-PSDrive C).Free;D=[long](Get-PSDrive D).Free;physical=[long]$os.FreePhysicalMemory*1024;commit=[long]$m.CommitLimit-[long]$m.CommittedBytes}
}
function AssertMetrics($M,[bool]$Admission){
 $c=if($Admission){10.5GB}else{10GB};$d=if($Admission){21GB}else{20GB}
 if($M.C -lt $c -or $M.D -lt $d -or $M.physical -lt 2GB -or $M.commit -lt 2GB){throw 'Disk/physical/commit resource floor'}
}
function AssertIdle($Owner){
 if($Owner.thread -cne $RootThread -or -not $Owner.reserved -or -not $Owner.allow_native_launch -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count){throw 'Root lease not idle'}
 if(@(Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(Godot.*|Blender.*)\.exe$'}).Count){throw 'Native engine already active'}
}
function AssertFresh($Value){
 $t=if($Value -is [DateTimeOffset]){$Value.ToUniversalTime()}elseif($Value -is [DateTime]){[DateTimeOffset]$Value.ToUniversalTime()}else{[DateTimeOffset]::Parse([string]$Value,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime()}
 $age=([DateTimeOffset]::UtcNow-$t).TotalSeconds;if($age -lt 0 -or $age -gt 300){throw 'Admission stale/future'}
}
function AssertNoReservedAssignments([string]$Source){
 $tokens=$null;$parseErrors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($Source,[ref]$tokens,[ref]$parseErrors)
 if($parseErrors.Count){throw 'PowerShell parse failure'}
 $reserved=@('HOME','CODEX_HOME','PID','PSHOME','PSVERSIONTABLE','PSCOMMANDPATH','PSSCRIPTROOT','HOST','PROFILE','EXECUTIONCONTEXT','INPUT','ARGS','ERROR','MATCHES','LASTEXITCODE','PSBOUNDPARAMETERS','PWD','PSITEM','_')
 foreach($node in $ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -or $n -is [Management.Automation.Language.ForEachStatementAst] -or $n -is [Management.Automation.Language.ParameterAst]},$true)){
  $variable=if($node -is [Management.Automation.Language.AssignmentStatementAst]){$node.Left}elseif($node -is [Management.Automation.Language.ForEachStatementAst]){$node.Variable}else{$node.Name}
  if($variable -is [Management.Automation.Language.VariableExpressionAst] -and $variable.VariablePath.UserPath.Split(':')[-1] -in $reserved){throw "Reserved variable assignment: $($variable.VariablePath.UserPath)"}
 }
}
