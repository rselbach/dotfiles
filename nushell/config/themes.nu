# Nushell color themes

export def catppuccin_mocha [] {
    source catppuccin-mocha.nu
    $env.config.color_config
}

export def catppuccin_latte [] {
    source catppuccin-latte.nu
    $env.config.color_config
}
