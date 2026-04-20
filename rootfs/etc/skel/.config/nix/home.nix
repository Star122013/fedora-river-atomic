{ pkgs, ... }:

{
  home.username = "YOUR_USERNAME";
  home.homeDirectory = "/var/home/YOUR_USERNAME";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    git
    wget
    curl
  ];

  programs.home-manager.enable = true;
}
