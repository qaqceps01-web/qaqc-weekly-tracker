# QA/QC Weekly Tracker - one-shot data backup
# Read-only: downloads all rows from weeks + items via the Supabase REST API
# and saves them as dated JSON files in ./backup/

$ErrorActionPreference = 'Stop'

$SUPABASE_URL = 'https://grtrpbnccqbtpaoovmoa.supabase.co'
$API_KEY = 'sb_publishable_7dJcpcsVd9PJ5GgVhlKbvQ_rrCzwWsq'

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outDir = Join-Path $PSScriptRoot ('..\backup\' + $stamp)
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Fetch-All($table) {
  # Paginate through every row of the table
  $all = @()
  $from = 0
  $pageSize = 1000
  while ($true) {
    $uri = "$SUPABASE_URL/rest/v1/$table" +
           "?select=*&limit=$pageSize&offset=$from"
    $resp = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
      apikey        = $API_KEY
      Authorization = "Bearer $API_KEY"
    }
    if ($null -eq $resp -or $resp.Count -eq 0) { break }
    $all += $resp
    if ($resp.Count -lt $pageSize) { break }
    $from += $pageSize
  }
  return $all
}

$weeks = Fetch-All 'weeks'
$items = Fetch-All 'items'

$weeks | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outDir 'weeks.json') -Encoding UTF8
$items | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outDir 'items.json') -Encoding UTF8

# Also write one combined file so the whole snapshot lives in a single artifact
$combined = [ordered]@{
  backed_up_at = (Get-Date).ToString('o')
  weeks_rows   = $weeks.Count
  items_rows   = $items.Count
  weeks        = $weeks
  items        = $items
}
$combined | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outDir 'full_snapshot.json') -Encoding UTF8

Write-Host "Backup OK"
Write-Host ("  weeks: {0} rows" -f $weeks.Count)
Write-Host ("  items: {0} rows" -f $items.Count)
Write-Host ("  saved to: {0}" -f $outDir)
