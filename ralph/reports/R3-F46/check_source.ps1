param([string]$Root = (Resolve-Path "$PSScriptRoot/../../..").Path)
$ErrorActionPreference = 'Stop'
function Assert-Contract($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Read-Json([string]$Path) {
    Get-Content -LiteralPath (Join-Path $Root $Path) -Raw | ConvertFrom-Json
}
$config = Read-Json 'data/config/onboarding.json'
Assert-Contract ($config.enabled -eq $false) 'Candidate must remain off until runtime proof.'
$contexts = Read-Json 'data/config/input_contexts.json'
Assert-Contract (($contexts.contexts.lesson.actions -join ',') -eq 'ui_accept,menu_confirm,menu_cancel') 'Lesson must own only confirm/cancel.'
$scopes = Read-Json 'data/progression/flag_scopes.json'
Assert-Contract ($scopes.player.prefixes -contains 'opening:') 'Lesson receipts must resolve to existing personal scope.'
$ids = @($config.lessons.id)
Assert-Contract (($ids | Select-Object -Unique).Count -eq $ids.Count) 'Duplicate lessons.'
foreach ($required in @('home_key','homestead','altar','masters','portals','shrines')) {
    Assert-Contract ($ids -contains $required) "Missing lesson $required"
}
$villagers = Read-Json 'data/config/village_npcs.json'
foreach ($row in $config.lessons) {
    Assert-Contract ($row.teacher_node -eq 'Grandpa' -or $villagers.villagers.name -contains $row.teacher_node) "Uninstalled teacher $($row.id)"
    $dialogue = Read-Json ($row.dialogue_path -replace '^res://','')
    $conversation = $dialogue.conversations.PSObject.Properties[$row.conversation].Value
    Assert-Contract ($null -ne $conversation -and $conversation.lines.Count -ge 1 -and $conversation.lines.Count -le 3) "Missing/long exchange $($row.id)"
    Assert-Contract ($conversation.lines.Where({ $_ -isnot [string] }).Count -eq 0) "Lesson may not execute progression effects: $($row.id)"
    Assert-Contract (-not [string]::IsNullOrWhiteSpace($row.goal)) "Missing next goal $($row.id)"
}
# Preserve the original opening's effects exactly; textual clarification may change.
$baselineText = & git -C $Root show '84c24d285490153626c3d94e4a810c761a2d5a15:data/dialogue/opening.json'
Assert-Contract ($LASTEXITCODE -eq 0) 'Cannot inspect assigned baseline.'
$baseline = ($baselineText -join "`n") | ConvertFrom-Json
$opening = Read-Json 'data/dialogue/opening.json'
foreach ($property in $baseline.conversations.PSObject.Properties) {
    $after = $opening.conversations.PSObject.Properties[$property.Name].Value
    $beforeEffects = @($property.Value.lines | Where-Object { $_.effect } | ForEach-Object { $_.effect })
    $afterEffects = @($after.lines | Where-Object { $_.effect } | ForEach-Object { $_.effect })
    Assert-Contract (($beforeEffects -join '|') -eq ($afterEffects -join '|')) "Opening effects altered: $($property.Name)"
}
$panel = Get-Content (Join-Path $Root 'scripts/onboarding/lesson_panel.gd') -Raw
foreach ($guard in @('add_to_group(OWNER.GROUP)','OWNER.current(get_tree()) != null','OWNER.suppress_pause_reopen(get_tree())','_closing','event.is_action_pressed("menu_cancel")')) {
    Assert-Contract ($panel.Contains($guard)) "Missing modal guard $guard"
}
$service = Get-Content (Join-Path $Root 'scripts/onboarding/lesson_service.gd') -Raw
foreach ($guard in @('get_tree().paused','HOLD.active(get_tree())','"is_fighting"','"snapshot_ready"','"grant_player_flag"','"arrival_applied"','"durable"','character_id')) {
    Assert-Contract ($service.Contains($guard)) "Missing service contract $guard"
}
Assert-Contract (-not ($service -match '"peers"\s*:|\.set_flag\(|save_game\(|inventory\.add|party\.add')) 'Lesson service bypasses existing authority.'
$rules = Get-Content (Join-Path $Root 'scripts/onboarding/lesson_rules.gd') -Raw
Assert-Contract (-not ($rules -match 'regional_credits|homecoming_seen|world\.flags')) 'Lesson availability may not infer earned progression from ending/world state.'
$settings = Get-Content (Join-Path $Root 'scripts/ui/tab_settings.gd') -Raw
Assert-Contract ($settings.Contains('_wire_lesson_graph()') -and $settings.Contains('menu.call("close")')) 'Help must join controller focus and release the menu before replay.'
& git -C $Root diff --check
Assert-Contract ($LASTEXITCODE -eq 0) 'Whitespace/source diff errors.'
Write-Output 'PASS F46 non-engine content, opening-effect, personal-scope and input-owner contracts. No runtime, syntax parser, durability or acceptance claim.'
