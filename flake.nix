{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux"; # Adjust for your architecture if needed
    pkgs = import nixpkgs {inherit system;};
    mpvSource = pkgs.fetchFromGitHub {
      owner = "mpv-player";
      repo = "mpv";
      rev = "v0.40.0";
      hash = "sha256-x8cDczKIX4+KrvRxZ+72TGlEQHd4Kx7naq0CSoOZGHA=";
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      env.MPV_LUA_SOURCE = "${mpvSource}/player/lua";
    };
  };
}
