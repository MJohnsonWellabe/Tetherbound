function Identity-Field($Row,[string]$Name) {
 if($null -eq $Row){return $null}
 if($Row -is [Collections.IDictionary]){if($Row.Contains($Name)){return $Row[$Name]};return $null}
 $property=$Row.PSObject.Properties[$Name]
 if($null -eq $property){return $null};return $property.Value
}
function New-IdentityObservation([object[]]$Rows,[int]$ChildPid,[DateTime]$Started,[int]$ParentPid,[string[]]$Arguments,[string]$QueryError='',[bool]$ProcessHasExited=$false) {
 $tail=' '+($Arguments -join ' ')
 $expected=@{pid=$ChildPid;parent_pid=$ParentPid;created_utc=$Started.ToUniversalTime().ToString('o');executable=$Engine;arguments=$Arguments;accepted_command_lines=@(('"'+$Engine+'"'+$tail),($Engine+$tail));creation_tolerance_ms=1000;image_comparison='OrdinalIgnoreCase';command_comparison='Ordinal'}
 $actual=@();$reasons=[Collections.Generic.List[string]]::new()
 if($QueryError){$reasons.Add('CIM_query_error')}
 if(@($Rows).Count -eq 0){$reasons.Add('missing_CIM_row')}
 if(@($Rows).Count -gt 1){$reasons.Add('multiple_CIM_rows')}
 if($ProcessHasExited){$reasons.Add('process_has_exited')}
 foreach($row in $Rows){
  $values=@{};$types=@{}
  foreach($field in @('ProcessId','ParentProcessId','CreationDate','ExecutablePath','CommandLine')){
   $value=Identity-Field $row $field
   $values[$field]=$value
   $types[$field]=if($null -eq $value){$null}else{$value.GetType().FullName}
  }
  $raw=@{pid=$values.ProcessId;parent_pid=$values.ParentProcessId;creation_date_raw=[string]$values.CreationDate;created_utc=$null;start_delta_ms=$null;executable=$values.ExecutablePath;command_line=$values.CommandLine;field_types=$types}
  if($null -eq $values.ProcessId){$reasons.Add('pid_missing')}else{
   try{if([int]$values.ProcessId -ne $ChildPid){$reasons.Add('pid')}}catch{$reasons.Add('pid_invalid')}
  }
  if($null -eq $values.ParentProcessId){$reasons.Add('parent_pid_missing')}else{
   try{if([int]$values.ParentProcessId -ne $ParentPid){$reasons.Add('parent_pid')}}catch{$reasons.Add('parent_pid_invalid')}
  }
  if([string]::IsNullOrWhiteSpace([string]$values.ExecutablePath)){$reasons.Add('executable_missing')}elseif($values.ExecutablePath -ine $Engine){$reasons.Add('executable')}
  if($null -eq $values.CreationDate){$reasons.Add('creation_time_missing')}else{
   try{
    $creation=$values.CreationDate.ToUniversalTime()
    $raw.created_utc=$creation.ToString('o')
    $raw.start_delta_ms=($creation-$Started).TotalMilliseconds
    if([math]::Abs($raw.start_delta_ms) -gt 1000){$reasons.Add('creation_time')}
   }catch{$reasons.Add('creation_time_invalid')}
  }
  if([string]::IsNullOrWhiteSpace([string]$values.CommandLine)){$reasons.Add('command_line_missing')}elseif($values.CommandLine -cne $expected.accepted_command_lines[0] -and $values.CommandLine -cne $expected.accepted_command_lines[1]){$reasons.Add('command_line')}
  $actual+=,$raw
 }
 return @{observed_utc=[DateTime]::UtcNow.ToString('o');expected=$expected;actual_rows=$actual;row_count=@($Rows).Count;query_error=$QueryError;process_has_exited=$ProcessHasExited;mismatches=@($reasons);passed=($reasons.Count -eq 0)}
}
function Assert-IdentityObservation($Observation) {
 if($Observation.passed -ne $true -or $Observation.mismatches.Count -ne 0){throw ('Owned process identity rejected: '+($Observation.mismatches -join ','))}
}
# Existing pure guard callers get the same strict comparisons, with more detail.
function Assert-Identity($Row,[int]$ChildPid,[DateTime]$Started,[int]$ParentPid,[string[]]$Arguments) {
 $rows=if($null -eq $Row){@()}else{@($Row)}
 Assert-IdentityObservation (New-IdentityObservation $rows $ChildPid $Started $ParentPid $Arguments)
}
function Save-IdentityObservation($Observation,[string]$Directory,$Receipt,[string]$ReceiptPath) {
 if($Receipt.identity_observations.Count -ge 2048){throw 'Identity observation count cap'}
 $path=Join-Path $Directory ('{0:0000}.json' -f $Receipt.identity_observations.Count)
 Write-AtomicJson $path $Observation
 $Receipt.last_identity_observation=$Observation
 $Receipt.identity_observations+=,@{path=$path;sha256=(Hash $path)}
 # Persist before rejecting: failure evidence does not depend on final cleanup.
 Replace-AtomicJson $ReceiptPath $Receipt
 Assert-IdentityObservation $Observation
}
