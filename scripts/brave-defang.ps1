#Requires -Version 5.1
<#
.SYNOPSIS
  Disable all crypto, ads, and revenue-generating features in Brave Browser.
.DESCRIPTION
  Patches Default/Preferences and Local State JSON files.
  Run with Brave closed. Idempotent -- safe to re-run.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -- paths -------------------------------------------------------------------

$BraveDir   = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
$Prefs      = Join-Path $BraveDir 'Default\Preferences'
$LocalState = Join-Path $BraveDir 'Local State'

# -- helpers -----------------------------------------------------------------

function die($msg) {
  Write-Error "error: $msg"
  exit 1
}

function Ensure-Key {
  param([hashtable]$obj, [string]$key, $default)
  if (-not $obj.ContainsKey($key)) { $obj[$key] = $default }
  return $obj[$key]
}

# Recursively convert PSCustomObject to hashtable (for PS 5.1 compat)
function ConvertTo-Hashtable([psobject]$obj) {
  if ($obj -is [System.Collections.IList]) {
    return @($obj | ForEach-Object { ConvertTo-Hashtable $_ })
  }
  if ($obj -isnot [pscustomobject]) { return $obj }
  $ht = @{}
  $obj.PSObject.Properties | ForEach-Object { $ht[$_.Name] = ConvertTo-Hashtable $_.Value }
  return $ht
}

# Read JSON as nested hashtables (not PSCustomObject) so we can mutate freely.
function Read-Json([string]$path) {
  $obj = Get-Content -Raw -Path $path | ConvertFrom-Json
  return ConvertTo-Hashtable $obj
}

function Write-Json([string]$path, [hashtable]$data) {
  $tmp = "$path.tmp.$PID"
  $data | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $tmp -Encoding UTF8 -NoNewline
  Move-Item -Path $tmp -Destination $path -Force
}

# -- preflight ---------------------------------------------------------------

$braveProc = Get-Process -Name 'brave' -ErrorAction SilentlyContinue
if ($braveProc) { die 'Brave is running -- quit it first' }

if (-not (Test-Path $Prefs))      { die "Preferences not found at $Prefs" }
if (-not (Test-Path $LocalState)) { die "Local State not found at $LocalState" }

# -- backup ------------------------------------------------------------------

$ts     = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$backup = "$Prefs.bak.$ts"
Copy-Item -Path $Prefs -Destination $backup
Write-Host "backed up Preferences to $backup"

# -- Default/Preferences -----------------------------------------------------

#
#  +-----------+-----+---------------------------------------------+
#  | Section   | Key | Target value                                |
#  +-----------+-----+---------------------------------------------+
#
#  Wallet      default_wallet2              = 1  (None / no injection)
#              default_solana_wallet        = 1
#              show_wallet_icon_on_toolbar  = false
#
#  Rewards     show_brave_rewards_button_in_location_bar = false
#
#  NTP         show_sponsored_images_enabled = false
#              show_background_image         = false
#              show_rewards                  = false
#              show_stats                    = false
#              show_together                 = false
#              show_brave_vpn                = false
#
#  Leo         show_toolbar_button           = false
#              context_menu_enabled          = false
#              storage_enabled               = false
#              tab_organization_enabled      = false
#              autocomplete_provider_enabled = false
#
#  News        today.opted_in                = false
#              today.show_on_ntp             = false
#
#  Sidebar     hide wallet (7) and Leo (4); remove Leo from items
#
#  VPN         show_button                   = false
#

$prefs = Read-Json $Prefs

$brave   = Ensure-Key $prefs    'brave'      @{}
$wallet  = Ensure-Key $brave    'wallet'     @{}
$rewards = Ensure-Key $brave    'rewards'    @{}
$ntp     = Ensure-Key $brave    'new_tab_page' @{}
$aiChat  = Ensure-Key $brave    'ai_chat'    @{}
$today   = Ensure-Key $brave    'today'      @{}
$vpn     = Ensure-Key $brave    'brave_vpn'  @{}
$sidebar = Ensure-Key $brave    'sidebar'    @{}

# -- wallet
$wallet['default_wallet2']             = 1
$wallet['default_solana_wallet']       = 1
$wallet['show_wallet_icon_on_toolbar'] = $false

# -- rewards
$rewards['show_brave_rewards_button_in_location_bar'] = $false

# -- new tab page
$ntp['show_sponsored_images_enabled'] = $false
$ntp['show_background_image']         = $false
$ntp['show_rewards']                  = $false
$ntp['show_stats']                    = $false
$ntp['show_together']                 = $false
$ntp['show_brave_vpn']                = $false

# -- leo / ai chat
$aiChat['show_toolbar_button']           = $false
$aiChat['context_menu_enabled']          = $false
$aiChat['storage_enabled']               = $false
$aiChat['tab_organization_enabled']      = $false
$aiChat['autocomplete_provider_enabled'] = $false

# -- brave news / today
$today['opted_in']    = $false
$today['show_on_ntp'] = $false

# -- vpn
$vpn['show_button'] = $false

# -- sidebar: hide wallet (7) and Leo (4), remove Leo from items
if (-not $sidebar.ContainsKey('hidden_built_in_items')) {
  $sidebar['hidden_built_in_items'] = @()
}
$hidden = [System.Collections.Generic.HashSet[int]]::new([int[]]$sidebar['hidden_built_in_items'])
[void]$hidden.Add(4)
[void]$hidden.Add(7)
$sidebar['hidden_built_in_items'] = @($hidden | Sort-Object)

if ($sidebar.ContainsKey('sidebar_items')) {
  $sidebar['sidebar_items'] = @(
    $sidebar['sidebar_items'] | Where-Object { $_['built_in_item_type'] -ne 4 }
  )
}

Write-Json $Prefs $prefs
Write-Host 'patched Default/Preferences'

# -- Local State --------------------------------------------------------------

#  ENS / SNS / Unstoppable Domains resolve_method = 1 (disabled)

$ls    = Read-Json $LocalState
$lsBrave = Ensure-Key $ls 'brave' @{}

$ens = Ensure-Key $lsBrave 'ens'                @{}
$sns = Ensure-Key $lsBrave 'sns'                @{}
$ud  = Ensure-Key $lsBrave 'unstoppable_domains' @{}

$ens['resolve_method'] = 1
$sns['resolve_method'] = 1
$ud['resolve_method']  = 1

Write-Json $LocalState $ls
Write-Host 'patched Local State'

Write-Host 'done -- launch Brave and verify at brave://settings/wallet'
