{ ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      username = {
        format = "[$user]($style) ";
        show_always = true;
      };
      shlvl = {
        disabled = false;
        format = "$shlvl ▼ ";
        threshold = 4;
      };
      command_timeout = 1000;
      character = {
        disabled = false;
      };
      hostname = {
        ssh_only = false;
        format = "@ [$hostname](bold yellow) ";
        disabled = false;
      };
      directory = {
        home_symbol = "🏠 ~";
        read_only_style = "197";
        read_only = " 🔒 ";
        format = "at [$path]($style)[$read_only]($read_only_style) ";
      };
      git_branch = {
        symbol = "📦";
        format = "via [$symbol$branch]($style) ";
        style = "bold green";
      };
      git_status = {
        format = "[\($all_status$ahead_behind\)]($style) ";
        style = "bold green";
        conflicted = "🏳";
        up_to_date = "✓ ";
        untracked = "? ";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        stashed = "⊡ ";
        modified = "✎ ";
        staged = "[++\($count\)](green)";
        renamed = "→ ";
        deleted = "✖ ";
      };
    };
  };
}
