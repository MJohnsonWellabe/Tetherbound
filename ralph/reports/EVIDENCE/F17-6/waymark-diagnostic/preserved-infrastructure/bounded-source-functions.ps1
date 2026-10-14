function Initialize-PreflightReader {
 if (-not ('HallCappedReader' -as [type])) {
 Add-Type -TypeDefinition @"
using System; using System.IO; using System.Text; using System.Threading.Tasks;
public static class HallCappedReader {
 public static async Task<string> Read(StreamReader reader, int cap) {
  var text = new StringBuilder(); var buffer = new char[4096]; int n;
  while ((n = await reader.ReadAsync(buffer,0,buffer.Length).ConfigureAwait(false)) != 0) {
   if (text.Length+n > cap) throw new IOException("Preflight output cap exceeded");
   text.Append(buffer,0,n);
  }
  return text.ToString();
 }
}
"@
 }
}
function Invoke-BoundedSourceProcess([string]$Program,[string[]]$Arguments,[int]$WallMs=120000) {
 Initialize-PreflightReader
 $Info=[Diagnostics.ProcessStartInfo]::new();$Info.FileName=$Program;$Info.UseShellExecute=$false;$Info.CreateNoWindow=$true
 $Info.RedirectStandardOutput=$true;$Info.RedirectStandardError=$true
 foreach($Arg in $Arguments){$Info.ArgumentList.Add($Arg)}
 $P=[Diagnostics.Process]::new();$P.StartInfo=$Info;$Clock=[Diagnostics.Stopwatch]::StartNew();$Out=$null;$Err=$null
 try {
  if(-not $P.Start()){throw 'Preflight process start failed'}
  $Out=[HallCappedReader]::Read($P.StandardOutput,1048576);$Err=[HallCappedReader]::Read($P.StandardError,1048576)
  while(-not $P.HasExited){
   if($Clock.ElapsedMilliseconds -ge $WallMs){throw 'Source preflight deadline exceeded'}
   if($Out.IsFaulted -or $Err.IsFaulted){throw 'Preflight output reader failed or cap exceeded'}
   [Threading.Thread]::Sleep(20)
  }
  $Remaining=[int]($WallMs-$Clock.ElapsedMilliseconds)
  if($Remaining -le 0){throw 'Source preflight deadline exceeded'}
  if(-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($Out,$Err),[Math]::Min(2000,$Remaining))){throw 'Source preflight drain timeout'}
  if($Clock.ElapsedMilliseconds -ge $WallMs){throw 'Source preflight deadline exceeded'}
  $Stdout=$Out.GetAwaiter().GetResult();$Stderr=$Err.GetAwaiter().GetResult()
  if($P.ExitCode -ne 0){throw ('Source preflight failed: '+$Stderr)}
  return $Stdout
 } finally {
  if($P.Id -and -not $P.HasExited){$P.Kill($true);$null=$P.WaitForExit(1000)}
  if($null -ne $Out -and $null -ne $Err){try{$null=[Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($Out,$Err),250)}catch{}}
  if($null -ne $Out){$P.StandardOutput.Close();$P.StandardError.Close()}
  $P.Dispose()
 }
}
function Assert-Source {
 Assert-Hash (Join-Path $ArtifactDir 'source_preflight.py') $Job.source_preflight.helper_sha256
 Assert-Hash (Join-Path $ArtifactDir 'source-contract.json') $Job.source_preflight.contract_sha256
 $Text=Invoke-BoundedSourceProcess 'C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' @((Join-Path $ArtifactDir 'source_preflight.py'),$Stage,$JobPath,(Join-Path $ArtifactDir 'source-contract.json'))
 $Result=$Text|ConvertFrom-Json
 if($Result.status -cne 'PASS' -or $Result.source -cne $ExpectedSource -or $Result.index_paths -ne 49363 -or $Result.bindings -ne 105 -or $Result.materialized_files -lt 12911){throw 'Incomplete bounded source audit'}
 $script:LastSourceAudit=$Result
}
