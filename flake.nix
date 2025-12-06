{
  description = "Roberto Selbach's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: {
    homeManagerModules.default = import ./home.nix;
  };
}
