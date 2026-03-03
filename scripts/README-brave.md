# brave-defang

Disable all crypto, ads, and revenue-generating features in Brave Browser.

Two scripts are provided:
- `brave-defang.sh` — macOS/Linux (requires `jq`)
- `brave-defang.ps1` — Windows (PowerShell 5.1+, no external dependencies)

Both are idempotent and safe to re-run. They back up `Preferences` before each run.

## Usage

Quit Brave first, then:

```bash
# macOS / Linux
./brave-defang.sh

# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File brave-defang.ps1
```

Verify after launching Brave at `brave://settings/wallet` and `brave://settings/web3`.

## What it disables

### Wallet (crypto provider injection)

| Setting | Value | Effect |
|---------|-------|--------|
| `default_wallet2` | `1` (None) | Stops Brave from injecting `window.ethereum` into every web page. When enabled, websites can detect you have a wallet and prompt transactions. |
| `default_solana_wallet` | `1` (None) | Same but for `window.solana` / `window.braveSolana`. Solana dApps use this to initiate wallet connections. |
| `show_wallet_icon_on_toolbar` | `false` | Hides the wallet icon from the toolbar. |

### Rewards / BAT

| Setting | Value | Effect |
|---------|-------|--------|
| `show_brave_rewards_button_in_location_bar` | `false` | Hides the BAT triangle icon from the URL bar. Brave Rewards pays you in BAT tokens for viewing ads — this removes the button that nags you to enable it. |

### New Tab Page

| Setting | Value | Effect |
|---------|-------|--------|
| `show_sponsored_images_enabled` | `false` | Brave sells sponsored background images on new tabs (their primary revenue source for non-Rewards users). This disables them. |
| `show_background_image` | `false` | Disables all background images on the new tab page, sponsored or not. |
| `show_rewards` | `false` | Hides the Rewards widget on the new tab page. |
| `show_stats` | `false` | Hides the "trackers blocked / bandwidth saved" stats banner. Not revenue-generating, but it's Brave marketing itself to you on every new tab. |
| `show_together` | `false` | Hides the Brave Together (video calling) widget. Was a revenue experiment, mostly dead now. |
| `show_brave_vpn` | `false` | Hides the VPN upsell widget on the new tab page. |

### Leo / AI Chat

| Setting | Value | Effect |
|---------|-------|--------|
| `show_toolbar_button` | `false` | Hides the Leo AI button from the toolbar. Leo is Brave's AI assistant — the free tier exists to funnel you into the paid plan. |
| `context_menu_enabled` | `false` | Removes "Ask Leo" from right-click menus. Without this, every text selection offers to send your content to Brave's AI. |
| `storage_enabled` | `false` | Prevents Leo from persisting conversation history locally. |
| `tab_organization_enabled` | `false` | Disables Leo's AI-powered tab grouping suggestions. |
| `autocomplete_provider_enabled` | `false` | Stops Leo from injecting AI-generated suggestions into the URL bar autocomplete. |

### Brave News

| Setting | Value | Effect |
|---------|-------|--------|
| `today.opted_in` | `false` | Disables Brave News (formerly Brave Today), a news feed on the new tab page with ads mixed in. |
| `today.show_on_ntp` | `false` | Hides the News section from the new tab page. |

### VPN

| Setting | Value | Effect |
|---------|-------|--------|
| `brave_vpn.show_button` | `false` | Hides the VPN button from the toolbar. Brave VPN is a paid subscription (~$10/month), so this button is a persistent ad. |

### Sidebar

| Setting | Value | Effect |
|---------|-------|--------|
| `hidden_built_in_items` | `[4, 7]` | Hides Leo (type 4) and Wallet (type 7) from the sidebar panel. |
| Remove type 4 from `sidebar_items` | — | Strips Leo from the sidebar item list entirely. |

### Decentralized DNS (browser-wide, in Local State)

These disable Brave's built-in resolution of blockchain-based domain names. Traditional DNS can't resolve these domains because they aren't real TLDs — they're entries in smart contracts on Ethereum or Solana. When enabled, Brave intercepts navigation to these domains and makes JSON-RPC calls to blockchain nodes (via Infura) to resolve them.

| Setting | Value | Effect |
|---------|-------|--------|
| `ens.resolve_method` | `1` (Disabled) | Disables Ethereum Name Service resolution (`.eth` domains). |
| `sns.resolve_method` | `1` (Disabled) | Disables Solana Name Service resolution (`.sol` domains). |
| `unstoppable_domains.resolve_method` | `1` (Disabled) | Disables Unstoppable Domains resolution (`.crypto`, `.x`, `.nft`, `.wallet`, `.blockchain`, `.bitcoin`, etc). |

## Preference enum values

For reference, the numeric values used in Brave's JSON preferences:

**Default wallet** (`default_wallet2`, `default_solana_wallet`):

| Value | Meaning |
|-------|---------|
| 0 | Ask (deprecated) |
| 1 | None — no provider injection |
| 2 | CryptoWallets (deprecated legacy wallet) |
| 3 | BraveWalletPreferExtension (default) — Brave Wallet injects provider, extensions can override |
| 4 | BraveWallet — Brave Wallet injects provider, blocks extensions from overriding |

**Decentralized DNS resolve method** (`ens`, `sns`, `unstoppable_domains`):

| Value | Meaning |
|-------|---------|
| 0 | Ask (default) |
| 1 | Disabled |
| 2 | DNS over HTTPS (removed in v1.40) |
| 3 | Enabled — uses Infura for Ethereum RPC calls |

## File locations

| OS | Preferences | Local State |
|----|-------------|-------------|
| macOS | `~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Preferences` | `~/Library/Application Support/BraveSoftware/Brave-Browser/Local State` |
| Windows | `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Preferences` | `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Local State` |
| Linux | `~/.config/BraveSoftware/Brave-Browser/Default/Preferences` | `~/.config/BraveSoftware/Brave-Browser/Local State` |
