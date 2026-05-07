#!/usr/bin/env python3
"""Propagate yendo-cowboy palette changes to all config files.

Reads config/yendo-cowboy/palette.yaml, then regenerates color sections in:
  - tmux.conf
  - config/yazi/theme.toml  (hex verification only — icons are manual)
  - config/nvim/lua/plugins/colorscheme.lua

Usage:  python3 config/yendo-cowboy/generate.py
"""

import re, sys, textwrap
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent.parent.parent


def load_palette():
    raw = (DOTFILES / "config/yendo-cowboy/palette.yaml").read_text()
    palette = {}
    for line in raw.splitlines():
        m = re.match(r'^(\w+):\s+"(#[0-9a-fA-F]{6})"', line)
        if m:
            palette[m.group(1)] = m.group(2)
    return palette


def patch_tmux(p):
    path = DOTFILES / "tmux.conf"
    content = path.read_text()

    block = textwrap.dedent(f"""\
    # ── Yendo Cowboy color scheme ──
    # Generated from config/yendo-cowboy/palette.yaml
    set -g status-left-length 52
    set -g status-right-length 451
    set -g status-fg '{p["fg"]}'
    set -g status-bg '{p["bg"]}'
    set -g pane-border-style fg='{p["muted"]}'
    set -g pane-active-border-style fg='{p["primary"]}'
    set -g message-style fg='{p["bg"]}'
    set -g message-style bg='{p["accent"]}'
    set -g message-style bold

    set -g status-left '#[fg={p["bg"]},bg={p["primary"]},bold]  #S  #[fg={p["primary"]},bg={p["bg"]}]  '
    set -g status-right '#[fg={p["muted"]},bg=default]#[fg={p["bg"]},bg={p["muted"]}] %d %b • %R '
    set -g window-status-format '#[fg={p["muted"]},bg={p["bg_mid"]}] #I • #W '
    set -g window-status-current-format '#[fg={p["bg"]},bg={p["primary"]},bold] #I • #W '
    set -g window-status-separator ''""")

    pattern = r'(# ── Yendo Cowboy color scheme ──\n).*?(?=\n# No escape time)'
    if re.search(pattern, content, re.DOTALL):
        new_content = re.sub(pattern, block + "\n", content, flags=re.DOTALL)
    else:
        print("ERROR: tmux sentinel not found", file=sys.stderr)
        return
    path.write_text(new_content)
    print(f"  tmux.conf — patched")


def patch_yazi(p):
    """Verify palette hexes exist and ensure flavor is activated.
    yazi theme has too many icons for full generation."""
    path = DOTFILES / "config/yazi/theme.toml"
    content = path.read_text()

    # Ensure [flavor] section activates yendo-cowboy
    flavor_block = "[flavor]\ndark = \"yendo-cowboy\"\n"
    if flavor_block not in content:
        # Insert after the palette comment block (after last '#' comment before [mgr])
        lines = content.splitlines(keepends=True)
        insert_at = None
        for i, line in enumerate(lines):
            if line.startswith("[mgr]"):
                insert_at = i
                break
        if insert_at is not None:
            lines.insert(insert_at, "\n" + flavor_block + "\n")
            content = "".join(lines)
            path.write_text(content)
            print(f"  yazi theme.toml — added [flavor] section")
        else:
            print(f"  yazi: WARNING — could not find [mgr] section to insert [flavor]")

    palette_hexes = set(p.values())
    found = set()
    for line in content.splitlines():
        for m in re.finditer(r'"#([0-9a-fA-F]{6})"', line):
            found.add(f"#{m.group(1)}")
    missing = palette_hexes - found
    extra = found - palette_hexes
    if missing:
        print(f"  yazi: WARNING — {len(missing)} palette hexes not in theme: {sorted(missing)}")
    print(f"  yazi theme.toml — {len(palette_hexes & found)}/{len(palette_hexes)} palette hexes found" + 
          (f" (+{len(extra)} non-palette)" if extra else ""))


def _nvim_on_colors(p):
    """Build the on_colors callback block as a plain string."""
    lines = []
    L = lines.append
    L("        -- Generated from config/yendo-cowboy/palette.yaml")
    L(f'        c.bg = "{p["bg"]}"')
    L(f'        c.bg_dark = "{p["bg_darker"]}"')
    L(f'        c.bg_dark1 = "#080302"')
    L(f'        c.bg_float = "{p["bg"]}"')
    L(f'        c.bg_highlight = "{p["bg_mid"]}"')
    L(f'        c.bg_popup = "{p["bg"]}"')
    L(f'        c.bg_search = "{p["bg_tertiary"]}"')
    L(f'        c.bg_sidebar = "{p["bg"]}"')
    L(f'        c.bg_statusline = "{p["bg"]}"')
    L(f'        c.bg_visual = "{p["bg_mid"]}"')
    L(f'        c.black = "{p["bg_darker"]}"')
    L(f'        c.blue = "{p["primary"]}"')
    L(f'        c.blue0 = "{p["dim"]}"')
    L(f'        c.blue1 = "{p["border"]}"')
    L(f'        c.blue2 = "{p["border"]}"')
    L(f'        c.blue5 = "{p["accent"]}"')
    L(f'        c.blue6 = "{p["fg"]}"')
    L(f'        c.blue7 = "{p["bg_tertiary"]}"')
    L(f'        c.border = "{p["muted"]}"')
    L(f'        c.border_highlight = "{p["primary"]}"')
    L(f'        c.comment = "{p["dim"]}"')
    L(f'        c.cyan = "{p["accent"]}"')
    L(f'        c.dark3 = "{p["muted"]}"')
    L(f'        c.dark5 = "{p["dim"]}"')
    L(f'        c.diff = {{')
    L(f'          add = "#1a3d20",')
    L(f'          change = "{p["bg_mid"]}",')
    L(f'          delete = "#3d1515",')
    L(f'          text = "{p["bg_tertiary"]}",')
    L(f'        }}')
    L(f'        c.error = "{p["error"]}"')
    L(f'        c.fg = "{p["fg"]}"')
    L(f'        c.fg_dark = "{p["muted"]}"')
    L(f'        c.fg_float = "{p["fg"]}"')
    L(f'        c.fg_gutter = "{p["bg_mid"]}"')
    L(f'        c.fg_sidebar = "{p["muted"]}"')
    L(f'        c.git = {{')
    L(f'          add = "{p["ok"]}",')
    L(f'          change = "{p["accent"]}",')
    L(f'          delete = "{p["error"]}",')
    L(f'          ignore = "{p["dim"]}",')
    L(f'        }}')
    L(f'        c.green = "{p["ok"]}"')
    L(f'        c.green1 = "{p["ok"]}"')
    L(f'        c.green2 = "#3d8a40"')
    L(f'        c.hint = "{p["ok"]}"')
    L(f'        c.info = "{p["accent"]}"')
    L(f'        c.magenta = "{p["muted"]}"')
    L(f'        c.magenta2 = "{p["error"]}"')
    L(f'        c.orange = "{p["primary"]}"')
    L(f'        c.purple = "{p["border"]}"')
    L(f'        c.rainbow = {{')
    L(f'          "{p["primary"]}", "{p["accent"]}", "{p["ok"]}", "{p["border"]}",')
    L(f'          "{p["muted"]}", "{p["fg"]}", "{p["dim"]}", "{p["error"]}",')
    L(f'        }}')
    L(f'        c.red = "{p["error"]}"')
    L(f'        c.red1 = "{p["border"]}"')
    L(f'        c.teal = "{p["ok"]}"')
    L(f'        c.terminal = {{')
    L(f'          black = "{p["bg_darker"]}",')
    L(f'          black_bright = "{p["bg_mid"]}",')
    L(f'          blue = "{p["primary"]}",')
    L(f'          blue_bright = "{p["accent"]}",')
    L(f'          cyan = "{p["accent"]}",')
    L(f'          cyan_bright = "{p["fg"]}",')
    L(f'          green = "{p["ok"]}",')
    L(f'          green_bright = "{p["ok"]}",')
    L(f'          magenta = "{p["muted"]}",')
    L(f'          magenta_bright = "{p["border"]}",')
    L(f'          red = "{p["error"]}",')
    L(f'          red_bright = "{p["error"]}",')
    L(f'          white = "{p["muted"]}",')
    L(f'          white_bright = "{p["fg"]}",')
    L(f'          yellow = "{p["accent"]}",')
    L(f'          yellow_bright = "{p["accent"]}",')
    L(f'        }}')
    L(f'        c.terminal_black = "{p["bg_mid"]}"')
    L(f'        c.todo = "{p["primary"]}"')
    L(f'        c.warning = "{p["accent"]}"')
    return "\n".join(lines)


def _nvim_lualine(p):
    """Build the lualine theme table as a plain string."""
    def mode_block(mode, bg):
        return textwrap.dedent(f"""\
          {mode} = {{
            a = {{ fg = "{p["bg"]}", bg = "{bg}", gui = "bold" }},
            b = {{ fg = "{p["fg"]}", bg = "{p["bg_mid"]}" }},
            c = {{ fg = "{p["muted"]}", bg = "{p["bg"]}" }},
          }},""")

    lines = ["        theme = {"]
    lines.append(mode_block("normal", p["primary"]))
    lines.append(mode_block("insert", p["ok"]))
    lines.append(mode_block("visual", p["border"]))
    lines.append(mode_block("replace", p["error"]))
    lines.append(mode_block("command", p["accent"]))
    lines.append(mode_block("terminal", p["dim"]))
    lines.append(textwrap.dedent(f"""\
          inactive = {{
            a = {{ fg = "{p["dim"]}", bg = "{p["bg"]}", gui = "bold" }},
            b = {{ fg = "{p["dim"]}", bg = "{p["bg"]}" }},
            c = {{ fg = "{p["dim"]}", bg = "{p["bg"]}" }},
          }},"""))
    lines.append("        },")
    return "\n".join(lines)


def patch_nvim(p):
    path = DOTFILES / "config/nvim/lua/plugins/colorscheme.lua"
    lines = path.read_text().splitlines(keepends=True)

    # Replace on_colors body between sentinel markers (line-based, can't compound)
    on_colors_block = _nvim_on_colors(p)
    begin_oc, end_oc = None, None
    for i, line in enumerate(lines):
        if "BEGIN_ON_COLORS" in line:
            begin_oc = i
        elif "END_ON_COLORS" in line:
            end_oc = i
    if begin_oc is None or end_oc is None:
        print("ERROR: nvim sentinel markers for on_colors not found", file=sys.stderr)
        return
    lines[begin_oc + 1 : end_oc] = [on_colors_block + "\n"]

    # Replace lualine theme body between sentinel markers
    lualine_block = _nvim_lualine(p)
    begin_ll, end_ll = None, None
    for i, line in enumerate(lines):
        if "BEGIN_LUALINE" in line:
            begin_ll = i
        elif "END_LUALINE" in line:
            end_ll = i
    if begin_ll is None or end_ll is None:
        print("ERROR: nvim sentinel markers for lualine not found", file=sys.stderr)
        return
    lines[begin_ll + 1 : end_ll] = [lualine_block + "\n"]

    path.write_text("".join(lines))
    print(f"  nvim colorscheme.lua — regenerated on_colors + lualine theme")


def patch_p10k(p):
    """Rewrite all yendo-cowboy color tokens in ~/.p10k.zsh."""
    import re
    path = Path.home() / ".p10k.zsh"
    if not path.exists():
        print("  ~/.p10k.zsh not found — skipping")
        return
    content = path.read_text()

    # ── Multiline frame chars ────────────────────────────────────────────────
    for sym in ['╭─', '├─', '╰─', '─╮', '─┤', '─╯']:
        content = re.sub(
            r"'%[0-9A-Fa-f]{3,6}F" + re.escape(sym) + r"(%f)?'",
            f"'%F{{{p['muted']}}}{sym}%f'",
            content)

    content = re.sub(
        r"(POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=)'?[^'\n]+'?",
        rf"\g<1>'{p['muted']}'", content)

    # ── Segment-to-palette map ────────────────────────────────────────────────
    mapping = {
        "OS_ICON_FOREGROUND":                           p['bg'],
        "OS_ICON_BACKGROUND":                           p['primary'],
        "PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND": p['ok'],
        "PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND": p['error'],
        "DIR_BACKGROUND":                               p['primary'],
        "DIR_FOREGROUND":                               p['bg'],
        "DIR_SHORTENED_FOREGROUND":                     p['fg'],
        "DIR_ANCHOR_FOREGROUND":                        p['fg'],
        "VCS_CLEAN_BACKGROUND":                         p['ok'],
        "VCS_MODIFIED_BACKGROUND":                      p['accent'],
        "VCS_UNTRACKED_BACKGROUND":                     p['ok'],
        "VCS_CONFLICTED_BACKGROUND":                    p['accent'],
        "VCS_LOADING_BACKGROUND":                       p['dim'],
        "STATUS_OK_FOREGROUND":                         p['ok'],
        "STATUS_OK_BACKGROUND":                         p['bg'],
        "STATUS_OK_PIPE_FOREGROUND":                    p['ok'],
        "STATUS_OK_PIPE_BACKGROUND":                    p['bg'],
        "STATUS_ERROR_FOREGROUND":                      p['fg'],
        "STATUS_ERROR_BACKGROUND":                      p['error'],
        "STATUS_ERROR_SIGNAL_FOREGROUND":               p['fg'],
        "STATUS_ERROR_SIGNAL_BACKGROUND":               p['error'],
        "STATUS_ERROR_PIPE_FOREGROUND":                 p['fg'],
        "STATUS_ERROR_PIPE_BACKGROUND":                 p['error'],
        "COMMAND_EXECUTION_TIME_FOREGROUND":            p['bg'],
        "COMMAND_EXECUTION_TIME_BACKGROUND":            p['accent'],
        "BACKGROUND_JOBS_FOREGROUND":                   p['accent'],
        "BACKGROUND_JOBS_BACKGROUND":                   p['bg'],
        "DIRENV_FOREGROUND":                            p['accent'],
        "DIRENV_BACKGROUND":                            p['bg'],
        "ASDF_FOREGROUND":                              p['bg'],
        "ASDF_BACKGROUND":                              p['border'],
        "ASDF_RUBY_FOREGROUND":                         p['bg'],
        "ASDF_RUBY_BACKGROUND":                         p['error'],
        "ASDF_PYTHON_FOREGROUND":                       p['bg'],
        "ASDF_PYTHON_BACKGROUND":                       p['primary'],
        "ASDF_GOLANG_FOREGROUND":                       p['bg'],
        "ASDF_GOLANG_BACKGROUND":                       p['primary'],
        "ASDF_NODEJS_FOREGROUND":                       p['bg'],
        "ASDF_NODEJS_BACKGROUND":                       p['ok'],
        "ASDF_RUST_FOREGROUND":                         p['bg'],
        "ASDF_RUST_BACKGROUND":                         p['border'],
        "ASDF_DOTNET_CORE_FOREGROUND":                  p['bg'],
        "ASDF_DOTNET_CORE_BACKGROUND":                  p['muted'],
        "ASDF_FLUTTER_FOREGROUND":                      p['bg'],
        "ASDF_FLUTTER_BACKGROUND":                      p['primary'],
        "ASDF_LUA_FOREGROUND":                          p['bg'],
        "ASDF_LUA_BACKGROUND":                          p['primary'],
        "ASDF_JAVA_FOREGROUND":                         p['bg'],
        "ASDF_JAVA_BACKGROUND":                         p['accent'],
        "ASDF_PERL_FOREGROUND":                         p['bg'],
        "ASDF_PERL_BACKGROUND":                         p['dim'],
        "ASDF_ERLANG_FOREGROUND":                       p['bg'],
        "ASDF_ERLANG_BACKGROUND":                       p['error'],
        "ASDF_ELIXIR_FOREGROUND":                       p['bg'],
        "ASDF_ELIXIR_BACKGROUND":                       p['border'],
        "ASDF_POSTGRES_FOREGROUND":                     p['bg'],
        "ASDF_POSTGRES_BACKGROUND":                     p['muted'],
        "ASDF_PHP_FOREGROUND":                          p['bg'],
        "ASDF_PHP_BACKGROUND":                          p['border'],
        "ASDF_HASKELL_FOREGROUND":                      p['bg'],
        "ASDF_HASKELL_BACKGROUND":                      p['accent'],
        "ASDF_JULIA_FOREGROUND":                        p['bg'],
        "ASDF_JULIA_BACKGROUND":                        p['ok'],
        "NORDVPN_FOREGROUND":                           p['fg'],
        "NORDVPN_BACKGROUND":                           p['primary'],
        "RANGER_FOREGROUND":                            p['accent'],
        "RANGER_BACKGROUND":                            p['bg'],
        "YAZI_FOREGROUND":                              p['accent'],
        "YAZI_BACKGROUND":                              p['bg'],
        "NNN_FOREGROUND":                               p['bg'],
        "NNN_BACKGROUND":                               p['muted'],
        "LF_FOREGROUND":                                p['bg'],
        "LF_BACKGROUND":                                p['muted'],
        "XPLR_FOREGROUND":                              p['bg'],
        "XPLR_BACKGROUND":                              p['muted'],
        "VIM_SHELL_FOREGROUND":                         p['bg'],
        "VIM_SHELL_BACKGROUND":                         p['ok'],
        "MIDNIGHT_COMMANDER_FOREGROUND":                p['accent'],
        "MIDNIGHT_COMMANDER_BACKGROUND":                p['bg'],
        "NIX_SHELL_FOREGROUND":                         p['bg'],
        "NIX_SHELL_BACKGROUND":                         p['primary'],
        "CHEZMOI_SHELL_FOREGROUND":                     p['bg'],
        "CHEZMOI_SHELL_BACKGROUND":                     p['primary'],
        "DISK_USAGE_NORMAL_FOREGROUND":                 p['accent'],
        "DISK_USAGE_NORMAL_BACKGROUND":                 p['bg'],
        "DISK_USAGE_WARNING_FOREGROUND":                p['bg'],
        "DISK_USAGE_WARNING_BACKGROUND":                p['accent'],
        "DISK_USAGE_CRITICAL_FOREGROUND":               p['fg'],
        "DISK_USAGE_CRITICAL_BACKGROUND":               p['error'],
        "VI_MODE_FOREGROUND":                           p['bg'],
        "VI_MODE_NORMAL_BACKGROUND":                    p['ok'],
        "VI_MODE_VISUAL_BACKGROUND":                    p['primary'],
        "VI_MODE_OVERWRITE_BACKGROUND":                 p['accent'],
        "VI_MODE_INSERT_FOREGROUND":                    p['dim'],
        "RAM_FOREGROUND":                               p['bg'],
        "RAM_BACKGROUND":                               p['accent'],
        "SWAP_FOREGROUND":                              p['bg'],
        "SWAP_BACKGROUND":                              p['accent'],
        "LOAD_NORMAL_FOREGROUND":                       p['bg'],
        "LOAD_NORMAL_BACKGROUND":                       p['ok'],
        "LOAD_WARNING_FOREGROUND":                      p['bg'],
        "LOAD_WARNING_BACKGROUND":                      p['accent'],
        "LOAD_CRITICAL_FOREGROUND":                     p['bg'],
        "LOAD_CRITICAL_BACKGROUND":                     p['error'],
        "TODO_FOREGROUND":                              p['bg'],
        "TODO_BACKGROUND":                              p['dim'],
        "TIMEWARRIOR_FOREGROUND":                       p['fg'],
        "TIMEWARRIOR_BACKGROUND":                       p['dim'],
        "TASKWARRIOR_FOREGROUND":                       p['bg'],
        "TASKWARRIOR_BACKGROUND":                       p['muted'],
        "PER_DIRECTORY_HISTORY_LOCAL_FOREGROUND":       p['bg'],
        "PER_DIRECTORY_HISTORY_LOCAL_BACKGROUND":       p['border'],
        "PER_DIRECTORY_HISTORY_GLOBAL_FOREGROUND":      p['bg'],
        "PER_DIRECTORY_HISTORY_GLOBAL_BACKGROUND":      p['accent'],
        "CPU_ARCH_FOREGROUND":                          p['bg'],
        "CPU_ARCH_BACKGROUND":                          p['accent'],
        "CONTEXT_ROOT_FOREGROUND":                      p['error'],
        "CONTEXT_ROOT_BACKGROUND":                      p['bg'],
        "CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND":      p['accent'],
        "CONTEXT_{REMOTE,REMOTE_SUDO}_BACKGROUND":      p['bg'],
        "CONTEXT_FOREGROUND":                           p['accent'],
        "CONTEXT_BACKGROUND":                           p['bg'],
    }
    for var, val in mapping.items():
        content = re.sub(
            rf"(  typeset -g POWERLEVEL9K_{re.escape(var)}=)'?[^'\n]+'?",
            rf"\g<1>'{val}'",
            content)

    # ── Git formatter local vars ─────────────────────────────────────────────
    content = re.sub(
        r"(    local\s+meta=)'[^']*'(\s*#.*)?",
        rf"\g<1>'%F{{{p['fg']}}}' # yendo-cowboy fg",
        content)
    content = re.sub(
        r"(    local\s+clean=)'[^']*'(\s*#.*)?",
        rf"\g<1>'%F{{{p['bg']}}}' # yendo-cowboy bg",
        content)
    content = re.sub(
        r"(    local\s+modified=)'[^']*'(\s*#.*)?",
        rf"\g<1>'%F{{{p['bg']}}}' # yendo-cowboy bg",
        content)
    content = re.sub(
        r"(    local\s+untracked=)'[^']*'(\s*#.*)?",
        rf"\g<1>'%F{{{p['bg']}}}' # yendo-cowboy bg",
        content)
    content = re.sub(
        r"(    local\s+conflicted=)'[^']*'(\s*#.*)?",
        rf"\g<1>'%F{{{p['error']}}}' # yendo-cowboy error",
        content)

    path.write_text(content)
    print(f"  ~/.p10k.zsh — patched")


def patch_lazygit(p):
    """Generate config/lazygit/config.yml from the yendo-cowboy palette."""
    path = DOTFILES / "config/lazygit/config.yml"
    path.parent.mkdir(parents=True, exist_ok=True)
    content = textwrap.dedent(f"""\
    # Yendo Cowboy lazygit theme
    # Generated from config/yendo-cowboy/palette.yaml — do not edit by hand.
    gui:
      theme:
        activeBorderColor:
          - '{p["primary"]}'
          - bold
        inactiveBorderColor:
          - '{p["muted"]}'
        searchingActiveBorderColor:
          - '{p["accent"]}'
          - bold
        optionsTextColor:
          - '{p["accent"]}'
        selectedLineBgColor:
          - '{p["bg_mid"]}'
        inactiveViewSelectedLineBgColor:
          - '{p["bg_mid"]}'
        cherryPickedCommitFgColor:
          - '{p["fg"]}'
        cherryPickedCommitBgColor:
          - '{p["border"]}'
        markedBaseCommitFgColor:
          - '{p["fg"]}'
        markedBaseCommitBgColor:
          - '{p["accent"]}'
        unstagedChangesColor:
          - '{p["error"]}'
        defaultFgColor:
          - '{p["fg"]}'
    """)
    path.write_text(content)
    print(f"  config/lazygit/config.yml — generated")


if __name__ == "__main__":
    p = load_palette()
    print(f"Palette: {len(p)} colors from config/yendo-cowboy/palette.yaml")
    print(f"  bg={p['bg']} primary={p['primary']} fg={p['fg']}")
    print()
    patch_tmux(p)
    patch_yazi(p)
    patch_nvim(p)
    patch_p10k(p)
    patch_lazygit(p)
    print(f"\nDone. Restart tmux/yazi/nvim/p10k/lazygit to see changes.")
