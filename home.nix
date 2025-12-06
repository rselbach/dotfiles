{...}: let
  # path to this dotfiles repo
  dotfilesPath = ./.;

  # directories that go to ~/.config/<name>
  configDirs = [
    "aerospace"
    "alacritty"
    "eza"
    "ghostty"
    "i3"
    "jj"
    "nvim"
    "opencode"
    "starship"
    "tmux"
    "zellij"
  ];

  # create xdg.configFile entries for each config dir
  configFileEntries = builtins.listToAttrs (map (name: {
      name = name;
      value = {
        source = dotfilesPath + "/${name}";
        recursive = true;
      };
    })
    configDirs);
in {
  # symlink config directories to ~/.config/
  xdg.configFile = configFileEntries;

  # special cases
  home.file = {
    # ~/.zshrc
    ".zshrc".source = dotfilesPath + "/zsh/zshrc";

    # ~/.claude
    ".claude".source = dotfilesPath + "/claude";

    # fish config
    ".config/fish".source = dotfilesPath + "/fish";
  };
}
