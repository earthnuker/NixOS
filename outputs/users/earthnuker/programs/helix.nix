{lib, ...}: {
  enable = true;
  defaultEditor = true;
  settings = {
    theme = lib.mkForce "dark_plus";
    editor = {
      true-color = true;
      color-modes = true;
      cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
      gutters = [
        "diagnostics"
        "line-numbers"
        "spacer"
        "diff"
      ];
      file-picker = {
        hidden = false;
      };
      indent-guides = {
        render = false;
        character = "│";
      };
      lsp = {
        display-messages = true;
        display-inlay-hints = true;
      };
      end-of-line-diagnostics = "hint";
      inline-diagnostics = {
        cursor-line = "hint";
        other-lines = "error";
      };
      statusline = {
        left = [
          "mode"
          "spinner"
          "file-name"
          "file-type"
          "total-line-numbers"
          "file-encoding"
        ];
        center = [];
        right = [
          "selections"
          "primary-selection-length"
          "position"
          "position-percentage"
          "spacer"
          "diagnostics"
          "workspace-diagnostics"
          "version-control"
        ];
      };
      mouse = true;
    };
  };
}
