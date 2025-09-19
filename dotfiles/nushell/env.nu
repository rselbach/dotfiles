# env.nu
#
# Environment configuration file for Nushell
# This file is loaded before config.nu
# See https://www.nushell.sh/book/configuration.html

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# Environment variables
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship" "starship.toml")

# PATH configuration
use std "path add"

# System paths
path add /run/current-system/sw/bin
path add /Users/rselbach/.local/bin
path add /Users/rselbach/bin

# Homebrew paths (macOS)
if ("/opt/homebrew/bin" | path exists) {
  path add /opt/homebrew/bin
  path add /opt/homebrew/sbin
  path add /opt/homebrew/opt/ruby/bin
}

# Homebrew paths (Linux)
if ("/home/linuxbrew/.linuxbrew/bin" | path exists) {
  path add /home/linuxbrew/.linuxbrew/bin
  path add /home/linuxbrew/.linuxbrew/sbin
}

# Hook configuration for direnv
$env.config.hooks.pre_prompt = (
	$env.config.hooks.pre_prompt | append (source nu-hooks/direnv/config.nu)
)

# Initialize zoxide
zoxide init nushell | save -f ~/.zoxide.nu

# Default prompt configuration (will be overridden by Starship if available)
# These are fallbacks in case Starship fails to load
def create_left_prompt [] {
    let dir = match (do --ignore-errors { $env.PWD | path relative-to $nu.home-path }) {
        null => $env.PWD
        '' => '~'
        $relative_pwd => ([~ $relative_pwd] | path join)
    }

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
    let path_segment = $"($path_color)($dir)"

    $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
}

def create_right_prompt [] {
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment = ([
        (ansi reset)
        (ansi magenta)
        (date now | format date '%x %X') # try to respect user's locale
    ] | str join | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
        str replace --regex --all "([AP]M)" $"(ansi magenta_underline)${1}")

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
        (ansi rb)
        ($env.LAST_EXIT_CODE)
    ] | str join)
    } else { "" }

    ([$last_exit_code, (char space), $time_segment] | str join)
}

$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }