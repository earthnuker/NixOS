_: {
  enable = true;
  enableZshIntegration = true;
  enableFishIntegration = true;
  settings = {
    add_newline = true;
    aws.disabled = true;
    gcloud.disabled = true;
    line_break.disabled = true;
    nix_shell = {
      impure_msg = "[impure shell](bold red)";
      pure_msg = "[pure shell](bold green)";
      unknown_msg = "[shell](bold yellow)";
      heuristic = false;
    };
  };
}
