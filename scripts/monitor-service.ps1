param(
  [string]$Url = 'http://127.0.0.1:8000/api/health',
  [int]$DurationSeconds = 120,
  [int]$IntervalSeconds = 1,
  [Parameter(Mandatory=$true)][string]$PhasePath,
  [Parameter(Mandatory=$true)][string]$LogPath
)
$ErrorActionPreference = 'Continue'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$writer = New-Object System.IO.StreamWriter($LogPath, $false, $utf8)
$start = Get-Date
try {
  while (((Get-Date) - $start).TotalSeconds -lt $DurationSeconds) {
    $requestStart = Get-Date
    $errorText = ''
    try {
      $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5
      $body = $response.Content | ConvertFrom-Json
      $status = [int]$response.StatusCode
      $ok = $body.status -eq 'ok'
      $version = [string]$body.version
    } catch {
      $status = 0; $ok = $false; $version = ''; $errorText = $_.Exception.Message.Replace("`r", ' ').Replace("`n", ' ')
    }
    $requestEnd = Get-Date
    $latency = [math]::Round(($requestEnd - $requestStart).TotalMilliseconds, 2)
    $phase = if (Test-Path $PhasePath) { (Get-Content $PhasePath -Raw).Trim() } else { 'unknown' }
    $line = [ordered]@{start=$requestStart.ToUniversalTime().ToString('o'); end=$requestEnd.ToUniversalTime().ToString('o'); responseMs=$latency; status=$status; analysisOk=$ok; version=$version; phase=$phase; error=$errorText} | ConvertTo-Json -Compress
    $writer.WriteLine($line); $writer.Flush(); Start-Sleep -Seconds $IntervalSeconds
  }
} finally { $writer.Dispose() }
