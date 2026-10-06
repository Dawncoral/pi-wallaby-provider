<#
.SYNOPSIS
  Wallaby Pi one-click uninstaller (Windows). Zero residue.

.DESCRIPTION
  Removes everything install.ps1 created:
    - pi-wallaby-provider from pi's package list (best effort)
    - %LOCALAPPDATA%\wallaby (portable Node, private npm prefix incl. pi, portable Git)
    - the matching user PATH entries
    - the WALLABY_API_KEY user environment variable
  With -All it also deletes %USERPROFILE%\.pi (sessions, settings, managed installs).

  Does NOT touch a system-wide Node.js or Git for Windows you had before.
#>
[CmdletBinding()]
param(
  [switch]$All
)

$ErrorActionPreference = "Continue"
$Root = Join-Path $env:LOCALAPPDATA "wallaby"
$NpmPrefix = Join-Path $Root "npm"
$PiCmd = Join-Path $NpmPrefix "pi.cmd"

function Log([string]$msg) { Write-Host "[wallaby] $msg" }

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

# 1. remove the provider from pi's package list (while pi still runs)
if (Test-Path $PiCmd) {
  Log "Removing pi-wallaby-provider from pi ..."
  & $PiCmd remove "npm:pi-wallaby-provider" 2>&1 | Out-Null
}

# 2. wipe the private install root (node + npm prefix incl. pi + portable git)
if (Test-Path $Root) {
  Log "Removing $Root ..."
  Remove-Item $Root -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. scrub user PATH of our entries
$rk = Get-Item "HKCU:\Environment"
$cur = $rk.GetValue("Path", $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
if ($cur) {
  $kept = $cur -split ";" | Where-Object { $_ -and ($_ -notlike "$Root*") }
  $kind = $rk.GetValueKind("Path")
  $rk.SetValue("Path", ($kept -join ";"), $kind)
}

# 4. drop the API key
try { $rk.DeleteValue("WALLABY_API_KEY") } catch {}
Publish-EnvChange
Log "WALLABY_API_KEY removed (user scope)"

# 5. optional: pi data dir
$piDir = Join-Path $env:USERPROFILE ".pi"
if ($All -and (Test-Path $piDir)) {
  Log "Removing $piDir (sessions, settings, managed installs) ..."
  Remove-Item $piDir -Recurse -Force -ErrorAction SilentlyContinue
} elseif (Test-Path $piDir) {
  Log "Kept $piDir (chat history/settings). Re-run with -All to delete it too."
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " Uninstalled. Nothing of Wallaby/pi remains outside" -ForegroundColor Green
if ($All) { Write-Host " the (now deleted) .pi folder." -ForegroundColor Green }
else { Write-Host " %USERPROFILE%\.pi (use -All to remove it)." -ForegroundColor Green }
Write-Host "==================================================" -ForegroundColor Green
