{
  pkgs,
  lib,
  ...
}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      format = "$all\${custom.jj}$character";
      git_branch.disabled = true;
      git_status.disabled = true;
      git_state.disabled = true;
      git_commit.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
      custom.jj = {
        symbol = "";
        style = "bg:color_aqua";
        format = "\n[$output]($style)";
        when = "${lib.getExe pkgs.jj-starship} detect";
        shell = ["${lib.getExe pkgs.jj-starship}" "--no-color" "--no-symbol" "--no-jj-prefix" "--no-git-prefix"];
      };
      nix_shell = {
        impure_msg = "[impure](bold red)";
        pure_msg = "[pure](bold green)";
        unknown_msg = "[shell](bold yellow)";
        heuristic = false;
      };
    };
    presets = [
      "nerd-font-symbols"
      "pure-preset"
    ];
  };
}
