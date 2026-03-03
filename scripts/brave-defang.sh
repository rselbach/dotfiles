#!/bin/bash
# Disable all crypto, ads, and revenue-generating features in Brave Browser.
# Run with Brave closed. Edits Default/Preferences and Local State via jq.
# Supports macOS and Linux. Idempotent -- safe to re-run.

set -euo pipefail

# -- helpers ----------------------------------------------------------------

die() { echo "error: $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed"
}

# Apply a jq filter to a file in-place (via temp file for atomicity).
jq_edit() {
  local file="$1"; shift
  local tmp="${file}.tmp.$$"
  jq "$@" "${file}" > "${tmp}" && mv "${tmp}" "${file}"
}

# -- platform detection -----------------------------------------------------
#
#   macOS:  ~/Library/Application Support/BraveSoftware/Brave-Browser
#   Linux:  ~/.config/BraveSoftware/Brave-Browser
#
case "$(uname -s)" in
  Darwin)
    BRAVE_DIR="${HOME}/Library/Application Support/BraveSoftware/Brave-Browser"
    BRAVE_PGREP="Brave Browser"
    ;;
  Linux)
    BRAVE_DIR="${HOME}/.config/BraveSoftware/Brave-Browser"
    BRAVE_PGREP="brave"
    ;;
  *)
    die "unsupported OS: $(uname -s)"
    ;;
esac

PREFS="${BRAVE_DIR}/Default/Preferences"
LOCAL_STATE="${BRAVE_DIR}/Local State"

# -- preflight --------------------------------------------------------------

require_cmd jq

if pgrep -x "${BRAVE_PGREP}" >/dev/null 2>&1; then
  die "Brave is running -- quit it first"
fi

[[ -f "${PREFS}" ]]       || die "Preferences not found at ${PREFS}"
[[ -f "${LOCAL_STATE}" ]] || die "Local State not found at ${LOCAL_STATE}"

# -- backup -----------------------------------------------------------------

backup="${PREFS}.bak.$(date +%s)"
cp "${PREFS}" "${backup}"
echo "backed up Preferences to ${backup}"

# -- Default/Preferences ----------------------------------------------------

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

jq_edit "${PREFS}" '
  # -- wallet ---------------------------------------------------------------
  .brave.wallet.default_wallet2             = 1     |
  .brave.wallet.default_solana_wallet       = 1     |
  .brave.wallet.show_wallet_icon_on_toolbar = false |

  # -- rewards --------------------------------------------------------------
  .brave.rewards.show_brave_rewards_button_in_location_bar = false |

  # -- new tab page ---------------------------------------------------------
  .brave.new_tab_page.show_sponsored_images_enabled = false |
  .brave.new_tab_page.show_background_image         = false |
  .brave.new_tab_page.show_rewards                  = false |
  .brave.new_tab_page.show_stats                    = false |
  .brave.new_tab_page.show_together                 = false |
  .brave.new_tab_page.show_brave_vpn                = false |

  # -- leo / ai chat --------------------------------------------------------
  .brave.ai_chat.show_toolbar_button           = false |
  .brave.ai_chat.context_menu_enabled          = false |
  .brave.ai_chat.storage_enabled               = false |
  .brave.ai_chat.tab_organization_enabled      = false |
  .brave.ai_chat.autocomplete_provider_enabled = false |

  # -- brave news / today ---------------------------------------------------
  .brave.today.opted_in   = false |
  .brave.today.show_on_ntp = false |

  # -- vpn ------------------------------------------------------------------
  .brave.brave_vpn.show_button = false |

  # -- sidebar: hide wallet (7) and Leo (4) ---------------------------------
  .brave.sidebar.hidden_built_in_items = (
    (.brave.sidebar.hidden_built_in_items // []) + [4, 7] | unique
  ) |
  .brave.sidebar.sidebar_items = [
    .brave.sidebar.sidebar_items[]?
    | select(.built_in_item_type != 4)
  ]
'

echo "patched Default/Preferences"

# -- Local State -------------------------------------------------------------

#  ENS / SNS / Unstoppable Domains resolve_method = 1 (disabled)

jq_edit "${LOCAL_STATE}" '
  .brave.ens.resolve_method                = 1 |
  .brave.sns.resolve_method                = 1 |
  .brave.unstoppable_domains.resolve_method = 1
'

echo "patched Local State"
echo "done -- launch Brave and verify at brave://settings/wallet"
