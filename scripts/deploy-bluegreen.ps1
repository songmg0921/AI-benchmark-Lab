$ErrorActionPreference = 'Stop'
$root=$env:GITHUB_WORKSPACE; $art=Join-Path $root 'deployment-artifacts'; New-Item -ItemType Directory -Force $art|Out-Null
$log=Join-Path $art 'service-monitor.jsonl'; $phase=Join-Path $art 'phase.txt'; New-Item -ItemType File -Force $log|Out-Null; Set-Content $phase 'pre' -Encoding UTF8
$monitor=Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$root\scripts\monitor-service.ps1`" -Url `"http://127.0.0.1:8000/api/health`" -DurationSeconds 150 -IntervalSeconds 1 -LogPath `"$log`" -PhasePath `"$phase`"" -PassThru -WindowStyle Hidden
try {
  $network='ai-benchmark-net'; $proxy='ai-benchmark-proxy'; $blue='ai-benchmark-blue'; $green='ai-benchmark-green'; $username=[string]$env:DOCKERHUB_USERNAME; $username=$username.Trim().ToLowerInvariant(); if([string]::IsNullOrWhiteSpace($username)){throw 'DOCKERHUB_USERNAME is empty'}; $image='{0}/{1}:latest' -f $username,$env:IMAGE_NAME
  try { docker network create $network 2>$null } catch { }
  $active=(docker ps --filter "name=^$blue$" --filter status=running --format '{{.Names}}'); if(-not $active){$active=(docker ps --filter "name=^$green$" --filter status=running --format '{{.Names}}')}
  $candidate=if($active -eq $blue){$green}else{$blue}; $port=if($candidate -eq $blue){18001}else{18002}; Set-Content $phase 'deploying' -Encoding UTF8
  docker pull $image; if($LASTEXITCODE){throw "docker pull failed for image $image"}; try { docker rm -f $candidate 2>$null } catch { }; docker run -d --name $candidate --network $network -p "${port}:8000" --env "APP_VERSION=$env:GITHUB_SHA" --restart unless-stopped $image; if($LASTEXITCODE){throw 'candidate container failed'}
  $ready=$false; for($i=0;$i -lt 30;$i++){try{$r=Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$port/api/health" -TimeoutSec 3;if($r.StatusCode -eq 200){$ready=$true;break}}catch{};Start-Sleep 2}; if(-not $ready){throw 'candidate health check failed'}
  $conf=Join-Path $art 'nginx.conf'; $confLines=@('server {','  listen 80;','  location / {',"    proxy_pass http://host.docker.internal:$port;",'    proxy_set_header Host $host;','    proxy_set_header X-Real-IP $remote_addr;','  }','}'); [IO.File]::WriteAllText($conf,($confLines -join "`n"),(New-Object Text.UTF8Encoding($false)))
  $running=(docker ps --filter "name=^$proxy$" --filter status=running --format '{{.Names}}'); if(-not $running){
    # One-time migration: the legacy app container may still own port 8000.
    $legacy=(docker ps --filter "name=^$env:CONTAINER_NAME$" --filter status=running --format '{{.Names}}'); if($legacy){docker rm -f $legacy 2>$null}
    try{docker rm -f $proxy 2>$null}catch{}; docker run -d --name $proxy --network $network -p 8000:80 --add-host host.docker.internal:host-gateway --mount "type=bind,source=$conf,target=/etc/nginx/conf.d/default.conf,readonly" nginx:1.27-alpine
  }else{docker cp $conf "$proxy`:/etc/nginx/conf.d/default.conf";docker exec $proxy nginx -s reload}
  Start-Sleep 5; $check=Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/api/health -TimeoutSec 5;if($check.StatusCode -ne 200){throw 'proxy health check failed'}; Set-Content $phase 'post' -Encoding UTF8; if($active){docker rm -f $active 2>$null}; Start-Sleep 30
} catch {docker ps -a;try{docker logs $proxy 2>&1}catch{};try{docker logs $candidate 2>$null}catch{};throw} finally {if($monitor -and -not $monitor.HasExited){Stop-Process $monitor.Id -Force}}
