{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "earthnuker";
        email = "earthnuker@gmail.com";
      };
      ui = {
        default-command = "status";
        diff.format = "git";
      };
      snapshot = {
        auto-update-stale = true;
      };
      aliases = {
        mr = ["util" "exec" "--" "jj-vine"];
        tug = ["bookmark" "move" "--from" "heads(::@- & bookmarks())" "--to" "@-"];
        rebase-all = ["rebase" "-s" "all:roots(trunk()..mutable())" "-d" "trunk()"];
      };
      revset-aliases = {
        "stack()" = "ancestors(reachable(@, mutable()), 2)";
        "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
        "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
      };
      colors = {
        "diff removed token" = {
          fg = "bright red";
          bg = "#400000";
          underline = false;
        };
        "diff added token" = {
          fg = "bright green";
          bg = "#003000";
          underline = false;
        };
      };
      templates = {
        log_node = ''
          if(self && !current_working_copy && !immutable && !conflict && in_branch(self),
            "◇",
            builtin_log_node
          )
        '';
      };
      template-aliases = {
        "in_branch(commit)" = "commit.contained_in(\"immutable_heads()..bookmarks()\")";
      };
    };
  };

  programs.jjui = {
    enable = true;
    settings = {
      ui = {
        tracer.enabled = true;
      };

      actions = [
        {
          name = "append-ancestors-to-revset";
          desc = "append ancestors of current revision to revset";
          lua = ''
            local change_id = revisions.current()
            if not change_id then return end

            local current = revset.current()
            local bumped = false
            local updated = current:gsub("ancestors%(" .. change_id .. "%s*,%s*(%d+)%)", function(n)
              bumped = true
              return "ancestors(" .. change_id .. ", " .. (tonumber(n) + 1) .. ")"
            end, 1)

            if not bumped then
              updated = current .. " | ancestors(" .. change_id .. ", 2)"
            end

            revset.set(updated)
          '';
        }
      ];

      bindings = [
        {
          action = "append-ancestors-to-revset";
          key = "+";
          scope = "revisions";
          desc = "append ancestors to revset";
        }
      ];
    };
  };

  # JJUI config.lua - needs to be written separately as home-manager's
  # jjui module only supports TOML via settings
  home.file.".config/jjui/config.lua" = {
    text = ''
      function setup(config)
        config.action("new + inline describe loop", function()
          while true do
            revisions.open_inline_describe()
            if not wait_close() then
              break
            end
            wait_refresh()
            revisions.new()
            wait_refresh()
            revisions.jump_to_working_copy()
          end
        end, { key = "N", scope = "revisions" })
      end
    '';
  };
}
