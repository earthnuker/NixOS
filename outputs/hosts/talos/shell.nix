{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    iay
  ];
  programs.iay = {
    enable = true;
    minimalPrompt = true;
  };
}
