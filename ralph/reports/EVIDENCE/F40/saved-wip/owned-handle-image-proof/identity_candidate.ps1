function Identity-Field($Row,[string]$Name) {
 if($null -eq $Row){return $null}
 if($Row -is [Collections.IDictionary]){if($Row.Contains($Name)){return $Row[$Name]};return $null}
 $property=$Row.PSObject.Properties[$Name]
 if($null -eq $property){return $null};return $property.Value
}
function New-OwnedIdentityObservation([object[]]$Rows,[int]$ChildPid,[DateTime]$Started,[int]$ParentPid,[string[]]$Arguments,[string]$QueryError='',[bool]$ProcessHasExited=$false,$ImageProof=$null) {
 $tail=' '+($Arguments -join ' ')
 $expected=@{pid=$ChildPid;parent_pid=$ParentPid;created_utc=$Started.ToUniversalTime().ToString('o');executable=$Engine;arguments=$Arguments;accepted_command_lines=@(('"'+$Engine+'"'+$tail),($Engine+$tail));creation_tolerance_ms=1000;image_comparison='OrdinalIgnoreCase';command_comparison='Ordinal'}
 $actual=@();$reasons=[Collections.Generic.List[string]]::new()
 if($null -eq $ImageProof -or $ImageProof -isnot [CloudreachOwnedImage.Proof]){
  $reasons.Add('owned_image_proof_missing')
 }elseif(-not $ImageProof.Passed -or $ImageProof.Failure -or -not $ImageProof.FileLeaseActive -or $ImageProof.ExpectedPid -ne $ChildPid -or $ImageProof.Actual.Pid -ne $ChildPid -or $ImageProof.ExpectedPath -ine $Engine -or $ImageProof.Actual.Path -ine $Engine -or $ImageProof.ExpectedSha256 -cne $EngineHash -or $ImageProof.LockedFileSha256 -cne $EngineHash){
  $reasons.Add('owned_image_proof_failed')
 }
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
  if(-not [string]::IsNullOrWhiteSpace([string]$values.ExecutablePath) -and $values.ExecutablePath -ine $Engine){$reasons.Add('CIM_executable_disagrees')}
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
 return @{observed_utc=[DateTime]::UtcNow.ToString('o');expected=$expected;actual_rows=$actual;row_count=@($Rows).Count;query_error=$QueryError;image_authority='owned_handle_QueryFullProcessImageNameW_plus_prelaunch_executable_lease';owned_image_proof=$ImageProof;process_has_exited=$ProcessHasExited;mismatches=@($reasons);passed=($reasons.Count -eq 0)}
}