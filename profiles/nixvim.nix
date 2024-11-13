{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ripgrep
  ];

  environment.interactiveShellInit = ''
    alias vi='nvim'
    alias vim='nvim'
  '';

  programs.nixvim = {
    enable = true;

    ## ------------------------------------------------
    ## Options
    ## ------------------------------------------------

    globals = {
       mapleader = " ";      # global
       maplocalleader = " "; # per buffer, e.g. can change behavior per filetype
    };

    opts = {
      number = true;         # Show line numbers
      relativenumber = true; # Show relative line numbers
      ruler = true;          # displays line, column, and cursor position at bottom
      wrap = false;          # don't wrap lines
      signcolumn = "yes";    # always show two column sign column on left
      cursorline = true;     # Highlight line cursor sits on

      undodir.__raw = "vim.fs.normalize('~/.local/share/nvim/undo/')";
      undofile = true;


      # -----------------------------------------------------
      # Backspace settings
      #   indent  allow backspacing over autoindent
      #   eol     allow backspacing over line breaks (join lines)
      #   start   allow backspacing over the start of insert; CTRL-W and CTRL-U
      #   0     same as ":set backspace=" (Vi compatible)
      #   1     same as ":set backspace=indent,eol"
      #   2     same as ":set backspace=indent,eol,start"
      # -----------------------------------------------------

      bs = "2";

      # -----------------------------------------------------
      # Indentation  settings
      # -----------------------------------------------------

      tabstop = 4;          # number of spaces a tab counts for
      shiftwidth = 4;       # control how many columns text is indented with the reindent operations (<< and >>) and automatic C-style indentation.
      expandtab = true;     # Insert spaces when entering <Tab>
      softtabstop = 4;      # Number of spaces that a <Tab> counts for while performing editing operations, like inserting a <Tab> or using <BS>.  It "feels" like a tab though
      ai = true;            # auto indent
    };

    keymaps = [
      # -----------------------------------------------------
      # nvim-tree
      # -----------------------------------------------------

      ## Go to current buffer's file in nvim-tree
      {
        mode = [ "n" ];
        key = ",n";
        action = ":NvimTreeFindFile<CR>";
      }
      ## Toggle nvim-tree visibility
      {
        mode = [ "n" ];
        key = ",m";
        action = ":NvimTreeToggle<CR>";
      }

      # -----------------------------------------------------
      # buffer manipulation
      # -----------------------------------------------------

      ## Next Buffer
      {
        key = "<Tab>";
        action = ":bn<CR>";
        options = { noremap = true; };
      }
      ## Previous Buffer
      {
        key = "<S-Tab>";
        action = ":bp<CR>";
        options = { noremap = true; };
      }
      ## Close Buffer
      {
        key = "<leader><Tab>";
        action = ":bd<CR>";
        options = { noremap = true; };
      }
      ## Force Close Buffer
      {
        key = "<leader><S-Tab>";
        action = ":bd!<CR>";
        options = { noremap = true; };
      }
      ## New Tab
      {
        key = "<leader>t";
        action = ":tabnew split<CR>";
        options = { noremap = true; };
      }

      # -----------------------------------------------------
      # Telescope
      # -----------------------------------------------------

      ## Lists files in your current working directory, respects .gitignore
      {
        mode = [ "n" ];
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        options = { noremap = true; };
      }
      ## Finds files by filename
      {
        mode = [ "n" ];
        key = "<c-p>";
        action = "<cmd>Telescope find_files<cr>";
        options = { noremap = true; };
      }
      ## Search for a string in your current working directory and get results live as you type, respects .gitignore. (Requires ripgrep)
      {
        mode = [ "n" ];
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        options = { noremap = true; };
      }
      ## Search file contents
      {
        mode = [ "n" ];
        key = "<c-s>";
        action = "<cmd>Telescope live_grep<cr>";
        options = { noremap = true; };
      }
      ## Lists open buffers in current neovim instance
      {
        mode = [ "n" ];
        key = "<leader>db";
        action = "<cmd>Telescope buffers<cr>";
        options = { noremap = true; };
      }
      ## Lists available help tags and opens a new window with the relevant help info on <cr>
      {
        mode = [ "n" ];
        key = "<leader>fh";
        action = "<cmd>Telescope help_tags<cr>";
        options = { noremap = true; };
      }
      ## Lists manpage entries, opens them in a help window on <cr>
      {
        mode = [ "n" ];
        key = "<leader>fm";
        action = "<cmd>Telescope man_pages<cr>";
        options = { noremap = true; };
      }
      ## Lists previously open files
      {
        mode = [ "n" ];
        key = "<leader>fp";
        action = "<cmd>Telescope oldfiles<cr>";
        options = { noremap = true; };
      }
      ## Lists previously open files, Maps to ctrl-/
      {
        mode = [ "n" ];
        key = "<c-_>";
        action = "<cmd>Telescope oldfiles<cr>";
        options = { noremap = true; };
      }
      ## Lists spelling suggestions for the current word under the cursor, replaces word with selected suggestion on <cr>
      {
        mode = [ "n" ];
        key = "<leader>fs";
        action = "<cmd>Telescope spell_suggest<cr>";
        options = { noremap = true; };
      }
      ## Lists LSP references for iword under the cursor
      {
        mode = [ "n" ];
        key = "<leader>fr";
        action = "<cmd>Telescope lsp_references<cr>";
        options = { noremap = true; };
      }
      ## Lists LSP incoming calls for word under the cursor
      {
        mode = [ "n" ];
        key = "<leader>fi";
        action = "<cmd>Telescope lsp_incoming_calls<cr>";
        options = { noremap = true; };
      }
      ## Lists LSP outgoing calls for word under the cursor
      {
        mode = [ "n" ];
        key = "<leader>fo";
        action = "<cmd>Telescope lsp_outgoing_calls<cr>";
        options = { noremap = true; };
      }
      ## Dynamically Lists LSP for all workspace symbols
      {
        mode = [ "n" ];
        key = "<leader>fw";
        action = "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>";
        options = { noremap = true; };
      }
      ## Goto the definition of the word under the cursor, if there's only one, otherwise show all options in Telescope
      {
        mode = [ "n" ];
        key = "<leader>fd";
        action = "<cmd>Telescope lsp_definitions<cr>";
        options = { noremap = true; };
      }
      ## Other Telescope options:
      ## git_files     search only files in git, respects .gitignore
      ## oldfiles      previously opened files
      ## command_history
      ## search_history
      ## man_pages
      ## resume        lists the results including multi-selections of the previous
      ## picker

      # -----------------------------------------------------
      # Diff
      # -----------------------------------------------------

      {
        mode = [ "n" ];
        key = ",d";
        ## @TODO: This doesn't work
        action = ''
          function()
            if next(require('diffview.lib').views) == nil then
              vim.cmd('DiffviewOpen origin')
            else
              vim.cmd('DiffviewClose')
            end
          end
        '';
        options = { noremap = true; };
      }

      # -----------------------------------------------------
      # Bufferline
      # -----------------------------------------------------

      {
        mode = [ "n" ];
        key = "<A-h>";
        action = ":BufferLineCyclePrev<CR>";
        options = { noremap = true; silent = true; };
      }
      {
        mode = [ "n" ];
        key = "<A-l>";
        action = ":BufferLineCycleNex<CR>";
        options = { noremap = true; silent = true; };
      }
      {
        mode = [ "n" ];
        key = "<A-c>";
        action = ":bdelete!<CR>";
        options = { noremap = true; silent = true; };
      }
    ];

    autoCmd = [
      ## Close nvim on last buffer closed, not leaving neovim-tree open
      {
        event = [ "BufEnter" ];
        pattern = [ "NvimTree_*" ];
        callback = {
          __raw = ''
            function()
              local layout = vim.api.nvim_call_function("winlayout", {})
              if layout[1] == "leaf" and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(layout[2]), "filetype") == "NvimTree" and layout[3] == nil then vim.cmd("confirm quit") end
            end
          '';
        };
      }
      ## Go to same line in file next time it is open
      {
        event = [ "BufReadPost" ];
        pattern = [ "*" ];
        callback = {
          __raw = ''
            function()
              if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
                vim.api.nvim_exec("normal! g'\"",false)
              end
            end
          '';
        };
      }
      ## Highlight tabs and trailing whitespace
      {
        event = [ "BufEnter" ];
        pattern = [ "*" ];
        callback = {
          __raw = ''
            function()
              vim.cmd([[
                if exists('w:extratabs')
                  call matchdelete(w:extratabs)
                  unlet w:extratabs
                endif
                if exists('w:trailingwhitespace')
                  call matchdelete(w:trailingwhitespace)
                  unlet w:trailingwhitespace
                endif
                highlight ExtraTabs ctermbg=red guibg=red
                highlight TrailingWhitespace ctermbg=red guibg=red
                if &ft != 'help'
                  let w:extratabs=matchadd('ExtraTabs', '\t\+')
                  let w:trailingwhitespace=matchadd('TrailingWhitespace', '\s\+$')
                endif
              ]])
            end
          '';
        };
      }
      ## Trim tailing whitespace on save
      {
        event = [ "BufWritePre" ];
        pattern = [ "*" ];
        callback = {
          __raw = ''
            function()
              vim.cmd([[
                if &ft =~ 'javascript\|html\|jade\|json\|css\|less\|php\|python\|sh\|c\|cpp\|markdown\|yaml\|vim\|nix'
                  :%s/\s\+$//e
                elseif expand('%:t') =~ '\.gltf$' || expand('%:t') =~ '\.glsl$'
                  :%s/\s\+$//e
                endif
              ]])
            end
          '';
        };
      }
    ];

    ## ------------------------------------------------
    ## Theme
    ## ------------------------------------------------

    colorschemes.tokyonight.enable = true;

    # colorschemes.gruvbox.enable = true;
    ## Or:
    # extraPlugins = [ pkgs.vimPlugins.gruvbox ];
    # colorscheme = "gruvbox";

    ## ------------------------------------------------
    ## Included Plugins
    ## ------------------------------------------------

    plugins.bufferline = {
      enable = true;
      # extraOptions = {
      settings = {
        options = {
          tabpages = true;
          sidebar_filetypes = {
            NvimTree = true;
          };
          diagnostics = "nvim_lsp";
          always_show_bufferline = true;
        };
        highlights = {
          buffer_selected = {
            # fg = "#ffffff";
            bold = true;
          };
        };
      };
    };

    plugins.comment.enable = true;

    plugins.diffview = {
      enable = true;
    };

    plugins.fugitive.enable = true;

    plugins.gitsigns.enable = true;

    plugins.lightline.enable = true;

    plugins.lualine.enable = true;

    plugins.nvim-autopairs.enable = true;

    plugins.nvim-tree = {
      enable = true;
      extraOptions = {
        actions = {
          remove_file = {
            close_window = false;
          };
        };
        ## Keep tree open if already open when opening a tab
        tab = {
          sync = {
            open = true;
            close = true;
          };
        };
        view = {
          width = 30;
        };
        renderer = {
          group_empty = true;
        };
        git = {
          enable = true;
          ignore = false;
          timeout = 500;
        };
      };
    };

    plugins.rainbow-delimiters.enable = true;

    plugins.sleuth.enable = true;

    plugins.telescope = {
      enable = true;
      extensions.ui-select.enable = true;
      settings = {
        defaults = {
          mappings = {
            i = {
              # One instead of two esc taps to exit telescope
              "<esc>" = {
                __raw = "require('telescope.actions').close";
              };
              # Ctrl-space is used by Tmux, so remap to Ctrl-e
              "<c-e>" = {
                __raw = "require('telescope.actions').to_fuzzy_refine";
              };
              # "<c-o>" = {
              #   __raw = "require('trouble.sources.telescope').open";
              # };
            };
            n = {
              # "<c-o>" = {
              #   __raw = "require('trouble.sources.telescope').open";
              # };
            };
          };
        };
      };
    };

    plugins.treesitter.enable = true;

    plugins.tmux-navigator.enable = true;

    plugins.trouble.enable = true;

    # ## Needed for telescope, nvim-tree, trouble, diffview, bufferline, and other plugins
    # ## Only on unstable at the moment
    plugins.web-devicons.enable = true;

    ## ------------------------------------------------
    ## Extra Plugins
    ## ------------------------------------------------

    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
      {
        plugin = vim-signify;
        config = ''
          let g:signify_vcs_cmds = { 'git': 'git diff --no-color --no-ext-diff -U0 master -- %f' }
          let g:signify_priority = 1
          highlight SignColumn ctermbg=237
        '';
      }
      vim-surround

      ## focus-nvim only in unstable
      # (pkgs.vimUtils.buildVimPlugin {
      #   name = "focus-nvim";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "nvim-focus";
      #     repo = "focus.nvim";
      #     rev = "3841a38df972534567e85840d7ead20d3a26faa6";
      #     sha256 = "sha256-mgHk4u0ab2uSUNE+7DU22IO/xS5uop9iATfFRk6l6hs=";
      #   };
      # })
    ];
  };
}