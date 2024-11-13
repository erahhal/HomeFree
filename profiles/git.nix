{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      checkout = {
        defaultRemote = "origin";
      };
      color = {
        ui = "auto";
      };
      core = {
        # Can't specify "${pkgs.neovim}/bin/nvim" because programs.neovim
        # wraps neovim-unwrapped in a special way to load plugins, so must
        # expect nvim to be in $PATH here
        editor = "nvim";
        excludesfile = "~/.gitignore_global";
      };
      delta = {
        enable = true;
      };
      # filter = {
      #   lfs = {
      #     clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
      #     smudge = "${pkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
      #     process = "${pkgs.git-lfs}/bin/git-lfs filter-process --skip";
      #     required = true;
      #   };
      # };
      push = {
        default = "simple";
      };
      rerere = {
        enabled = true;
      };
      include = {
        path = "~/.gitconfig.local";
      };

      #==========================
      # Diff settings
      #==========================

      pager = {
        difftool = true;
      };

      #-------------------
      ## nvim
      # - text-based
      #------------------
      diff = {
        tool = "nvimdiff";
      };
      difftool = {
        prompt = true;
      };
      merge = {
        tool = "nvimdiff";
        trustExitCode = false;
      };
      mergetool = {
        trustExitCode = false;
      };
    };
  };
}

