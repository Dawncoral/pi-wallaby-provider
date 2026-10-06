<#
.SYNOPSIS
  Wallaby Pi one-click installer (Windows, no admin required).

.DESCRIPTION
  Installs everything under %LOCALAPPDATA%\wallaby and %USERPROFILE%\.pi only:
    1. Node.js 22 (portable zip, SHA256-verified) — skipped if system Node >= 22.19
    2. pi coding agent (npm global into the private prefix)
    3. pi-wallaby-provider (pi package from npm)
    4. WALLABY_API_KEY as a user-level environment variable
    5. Portable Git Bash (best effort; pi works without it, bash tool degraded)

  Nothing touches Program Files, the registry hives outside HKCU\Environment,
  or system services. Uninstall with uninstall.ps1.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1 -ApiKey "sk-xxx"
#>
[CmdletBinding()]
param(
  [string]$ApiKey = "",
  [string]$Registry = "https://registry.npmjs.org",
  [switch]$SkipGit
)

$ErrorActionPreference = "Stop"
$Root = Join-Path $env:LOCALAPPDATA "wallaby"
$NodeDir = Join-Path $Root "node"
$NpmPrefix = Join-Path $Root "npm"
$GitDir = Join-Path $Root "git"
$LogFile = Join-Path $Root "install.log"
$NodeMinimum = [version]"22.19.0"

New-Item -ItemType Directory -Force -Path $Root | Out-Null
Start-Transcript -Path $LogFile -Append | Out-Null

function Log([string]$msg) { Write-Host "[wallaby] $msg" }
function Fail([string]$msg) { Write-Host "[wallaby][ERROR] $msg" -ForegroundColor Red; Stop-Transcript | Out-Null; exit 1 }

# --- PATH helpers (user scope only, broadcast so new terminals see it) -------
function Get-UserEnv([string]$Key) {
  (Get-Item "HKCU:\Environment").GetValue($Key, $null,
    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
}
function Publish-EnvChange {
  if (-not ("Win32.Env" -as [Type])) {
    Add-Type -Namespace Win32 -Name Env -MemberDefinition @"
[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr h, uint m, System.UIntPtr w, string l, uint f, uint t, out System.UIntPtr r);
"@
  }
  $r = [UIntPtr]::Zero
  [Win32.Env]::SendMessageTimeout([IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, "Environment", 2, 5000, [ref]$r) | Out-Null
}
function Add-UserPath([string]$Dir) {
  $cur = (Get-UserEnv "Path") -split ";" | Where-Object { $_ -and ($_ -ne $Dir) }
  $new = ($cur + $Dir) -join ";"
  $rk = Get-Item "HKCU:\Environment"
  $kind = if ($new.Contains("%")) { [Microsoft.Win32.RegistryValueKind]::ExpandString } else { [Microsoft.Win32.RegistryValueKind]::String }
  $rk.SetValue("Path", $new, $kind)
  $env:PATH = "$env:PATH;$Dir"
  Publish-EnvChange
}

# --- 1. Node.js ---------------------------------------------------------------
$nodeOk = $false
$node = Get-Command node.exe -ErrorAction SilentlyContinue
if ($node) {
  try { if ([version]((& node.exe --version).Trim().TrimStart("v")) -ge $NodeMinimum) { $nodeOk = $true } } catch {}
}
if ($nodeOk) {
  Log "Node.js >= 22.19 already present: $((& node.exe --version).Trim())"
} else {
  $localNode = Join-Path $NodeDir "current\node.exe"
  if (Test-Path $localNode) {
    Log "Using existing portable Node at $NodeDir"
    $env:PATH = "$(Join-Path $NodeDir 'current');$env:PATH"
  } else {
    $arch = if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
    Log "Downloading portable Node.js 22 (win-$arch) ..."
    $tmp = Join-Path $env:TEMP "wallaby-node-$PID"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $base = "https://nodejs.org/dist/latest-v22.x"
    curl.exe -#SfLo (Join-Path $tmp "SHASUMS256.txt") "$base/SHASUMS256.txt"
    if ($LASTEXITCODE -ne 0) { Fail "Cannot reach nodejs.org. Check the network/proxy and retry." }
    $file = (Get-Content (Join-Path $tmp "SHASUMS256.txt") | Where-Object { $_ -match "\s+(node-v.+-win-$arch\.zip)$" } | Select-Object -First 1) -replace '^.*\s+(node-v.+)$', '$1'
    if (-not $file) { Fail "No Node.js binary found for win-$arch." }
    $zip = Join-Path $tmp $file
    curl.exe -#SfLo $zip "$base/$file"
    if ($LASTEXITCODE -ne 0) { Fail "Node.js download failed." }
    $expected = ((Get-Content (Join-Path $tmp "SHASUMS256.txt") | Where-Object { $_ -match [regex]::Escape($file) } | Select-Object -First 1) -split "\s+")[0].ToLower()
    $actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) { Fail "Node.js checksum mismatch (expected $expected, got $actual)." }
    Log "Checksum OK. Extracting ..."
    Expand-Archive $zip $tmp -Force
    New-Item -ItemType Directory -Force -Path $NodeDir | Out-Null
    $cur = Join-Path $NodeDir "current"
    Remove-Item $cur -Recurse -Force -ErrorAction SilentlyContinue
    Move-Item (Join-Path $tmp ($file -replace '\.zip$', '')) $cur -Force
    Remove-Item $tmp -Recurse -Force
    Add-UserPath $cur
    Log "Node.js installed at $cur"
  }
}

$nodeBin = if ($nodeOk) { (Get-Command node.exe).Source | Split-Path -Parent } else { Join-Path $NodeDir "current" }
$npmCmd = Join-Path $nodeBin "npm.cmd"
if (-not (Test-Path $npmCmd)) { $npmCmd = "npm.cmd" }

# --- 2. pi coding agent (private npm prefix) ----------------------------------
New-Item -ItemType Directory -Force -Path $NpmPrefix | Out-Null
Log "Installing pi coding agent ..."
& $npmCmd install -g --ignore-scripts --no-fund --no-audit --prefix "$NpmPrefix" --registry=$Registry "@earendil-works/pi-coding-agent"
if ($LASTEXITCODE -ne 0 -and $Registry -eq "https://registry.npmjs.org") {
  Log "npmjs.org failed; retrying via npmmirror.com ..."
  & $npmCmd install -g --ignore-scripts --no-fund --no-audit --prefix "$NpmPrefix" --registry=https://registry.npmmirror.com "@earendil-works/pi-coding-agent"
}
if ($LASTEXITCODE -ne 0) { Fail "pi installation failed. See $LogFile" }
Add-UserPath $NpmPrefix
$piCmd = Join-Path $NpmPrefix "pi.cmd"
if (-not (Test-Path $piCmd)) { Fail "pi.cmd not found after install at $NpmPrefix" }
Log "pi installed: $((& $piCmd --version).Trim())"

# --- 3. pi-wallaby-provider ----------------------------------------------------
Log "Installing pi-wallaby-provider ..."
& $piCmd install "npm:pi-wallaby-provider" 
if ($LASTEXITCODE -ne 0) { Fail "pi-wallaby-provider install failed. See $LogFile" }

# --- 4. API key (user env var) -------------------------------------------------
if (-not $ApiKey) {
  $ApiKey = Read-Host "Paste the Wallaby API key for this machine (sk-...)"
}
if ($ApiKey -notmatch "^sk-\S{10,}$") { Fail "API key looks invalid: '$ApiKey'" }
$rk = Get-Item "HKCU:\Environment"
$rk.SetValue("WALLABY_API_KEY", $ApiKey, [Microsoft.Win32.RegistryValueKind]::String)
Publish-EnvChange
$env:WALLABY_API_KEY = $ApiKey
Log "WALLABY_API_KEY set (user scope)"

# --- 5. Portable Git Bash (best effort) ---------------------------------------
if (-not $SkipGit) {
  $bashExe = Join-Path $GitDir "bin\bash.exe"
  $candidates = @()
  if ($env:ProgramFiles) { $candidates += Join-Path $env:ProgramFiles "Git\bin\bash.exe" }
  if (${env:ProgramFiles(x86)}) { $candidates += Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe" }
  $existingBash = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($existingBash) {
    Log "Git Bash already present: $existingBash"
  } elseif (Test-Path $bashExe) {
    Log "Portable Git Bash already present: $bashExe"
  } else {
    try {
      Log "Downloading Portable Git (for pi's bash tool) ..."
      $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -Headers @{ "User-Agent" = "wallaby-installer" } -TimeoutSec 30
      $asset = $rel.assets | Where-Object { $_.name -like "PortableGit-*64-bit.7z.exe" } | Select-Object -First 1
      if ($asset) {
        $m = [regex]::Match($rel.body, "(?m)^$([regex]::Escape($asset.name))\s+\|\s+([a-fA-F0-9]{64})\s*$")
        $tmpG = Join-Path $env:TEMP "wallaby-git-$PID"
        New-Item -ItemType Directory -Force -Path $tmpG | Out-Null
        $pg = Join-Path $tmpG $asset.name
        curl.exe -#SfLo $pg $asset.browser_download_url
        if ($LASTEXITCODE -eq 0 -and $m.Success) {
          if ((Get-FileHash $pg -Algorithm SHA256).Hash.ToLower() -eq $m.Groups[1].Value.ToLower()) {
            $p = Start-Process -FilePath $pg -ArgumentList @("-y", "-o`"$tmpG\extract`"") -PassThru -Wait -WindowStyle Hidden
            if ($p.ExitCode -eq 0 -and (Test-Path "$tmpG\extract\bin\bash.exe")) {
              Remove-Item $GitDir -Recurse -Force -ErrorAction SilentlyContinue
              Move-Item "$tmpG\extract" $GitDir -Force
              # point pi at it
              $settingsDir = Join-Path $env:USERPROFILE ".pi\agent"
              New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
              $settingsPath = Join-Path $settingsDir "settings.json"
              $settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
              $settings | Add-Member -NotePropertyName "shellPath" -NotePropertyValue (Join-Path $GitDir "bin\bash.exe") -Force
              [System.IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding $false))
              Log "Portable Git Bash installed at $GitDir"
            }
          }
        }
        Remove-Item $tmpG -Recurse -Force -ErrorAction SilentlyContinue
      }
    } catch {
      Log "WARNING: Git Bash install failed ($($_.Exception.Message)). pi still works; the bash tool stays unavailable."
    }
    if (-not (Test-Path $bashExe)) { Log "WARNING: no Git Bash; pi's bash tool will be unavailable. Everything else works." }
  }
}

# --- 6. Verify -----------------------------------------------------------------
Log "Verifying ..."
$models = & $piCmd --list-models 2>&1 | Out-String
if ($models -match "wallaby\s+kimi-k3") {
  Log "OK: 'wallaby kimi-k3' is visible in pi --list-models"
} else {
  Fail "wallaby model not visible in pi --list-models. Output:`n$models"
}
try {
  $null = Invoke-WebRequest -Uri "https://api.wallabytoken.com/v1/models" -Method Head -TimeoutSec 15 -UseBasicParsing
  Log "OK: api.wallabytoken.com reachable"
} catch {
  if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -in 401, 403, 404, 405) {
    Log "OK: api.wallabytoken.com reachable (auth-gated response)"
  } else {
    Log "WARNING: api.wallabytoken.com NOT reachable from this machine. If this network needs a proxy, configure it before using pi."
  }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " Done. Open a NEW terminal, cd into a project, run: pi" -ForegroundColor Green
Write-Host " Then: /model  ->  choose 'Kimi K3 (Wallaby)'" -ForegroundColor Green
Write-Host " Uninstall:    uninstall.ps1  (same folder)" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Stop-Transcript | Out-Null
