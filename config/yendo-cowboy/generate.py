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


def patch_nvim_colors(p):
    """Generate config/nvim/colors/yendo-cowboy.lua — standalone colorscheme.

    Defines all highlight groups directly, zero dependency on tokyonight or any
    other plugin.  LazyVim/tokyonight updates cannot break this.
    """
    path = DOTFILES / "config/nvim/colors/yendo-cowboy.lua"
    path.parent.mkdir(parents=True, exist_ok=True)

    bg          = p["bg"]
    bg_d        = p["bg_darker"]
    bg_m        = p["bg_mid"]
    bg_t        = p["bg_tertiary"]
    fg          = p["fg"]
    pri         = p["primary"]
    acc         = p["accent"]
    bor         = p["border"]
    ok          = p["ok"]
    err         = p["error"]
    dim         = p["dim"]
    mut         = p["muted"]

    def hi(group, fg=None, bg=None, sp=None, bold=False, italic=False,
            underline=False, undercurl=False, nocombine=False, link=None):
        if link:
            return f'vim.api.nvim_set_hl(0, "{group}", {{ link = "{link}" }})'
        parts = {}
        if fg:   parts["fg"]   = f'"{fg}"'
        if bg:   parts["bg"]   = f'"{bg}"'
        if sp:   parts["sp"]   = f'"{sp}"'
        if bold:      parts["bold"]      = "true"
        if italic:    parts["italic"]    = "true"
        if underline: parts["underline"] = "true"
        if undercurl: parts["undercurl"] = "true"
        if nocombine: parts["nocombine"] = "true"
        inner = ", ".join(f"{k} = {v}" for k, v in parts.items())
        return f'vim.api.nvim_set_hl(0, "{group}", {{ {inner} }})'

    lines = [
        "-- Yendo Cowboy colorscheme",
        "-- Generated from config/yendo-cowboy/palette.yaml — do not edit by hand.",
        "-- Run:  python3 config/yendo-cowboy/generate.py",
        "",
        'if vim.g.colors_name then vim.cmd("hi clear") end',
        'vim.g.colors_name = "yendo-cowboy"',
        'vim.o.background = "dark"',
        "",
        "-- ── Editor UI ──────────────────────────────────────────────────────────",
        hi("Normal",         fg=fg,  bg=bg),
        hi("NormalNC",       fg=fg,  bg=bg),
        hi("NormalFloat",    fg=fg,  bg=bg),
        hi("NormalSB",       fg=mut, bg=bg),
        hi("FloatBorder",    fg=pri, bg=bg),
        hi("FloatTitle",     fg=pri, bg=bg, bold=True),
        hi("ColorColumn",    bg=bg_d),
        hi("Conceal",        fg=dim),
        hi("Cursor",         fg=bg,  bg=fg),
        hi("lCursor",        fg=bg,  bg=fg),
        hi("CursorIM",       fg=bg,  bg=fg),
        hi("CursorLine",     bg=bg_m),
        hi("CursorColumn",   bg=bg_m),
        hi("CursorLineNr",   fg=pri, bold=True),
        hi("LineNr",         fg=bg_m),
        hi("LineNrAbove",    fg=bg_m),
        hi("LineNrBelow",    fg=bg_m),
        hi("SignColumn",     fg=bg_m, bg=bg),
        hi("SignColumnSB",   fg=bg_m, bg=bg),
        hi("FoldColumn",     fg=dim, bg=bg),
        hi("Folded",         fg=pri, bg=bg_m),
        hi("EndOfBuffer",    fg=bg),
        hi("VertSplit",      fg=mut),
        hi("WinSeparator",   fg=mut, bold=True),
        hi("WinBar",         link="StatusLine"),
        hi("WinBarNC",       link="StatusLineNC"),
        hi("StatusLine",     fg=mut, bg=bg),
        hi("StatusLineNC",   fg=bg_m, bg=bg),
        hi("TabLine",        fg=bg_m, bg=bg),
        hi("TabLineFill",    bg=bg_d),
        hi("TabLineSel",     fg=bg_d, bg=pri),
        hi("Visual",         bg=bg_m),
        hi("VisualNOS",      bg=bg_m),
        hi("Whitespace",     fg=bg_m),
        hi("WildMenu",       bg=bg_m),
        hi("Search",         fg=fg,  bg=bg_t),
        hi("IncSearch",      fg=bg_d, bg=pri),
        hi("CurSearch",      link="IncSearch"),
        hi("Substitute",     fg=bg_d, bg=err),
        hi("MatchParen",     fg=pri, bold=True),
        hi("NonText",        fg=mut),
        hi("SpecialKey",     fg=mut),
        hi("Pmenu",          fg=fg,  bg=bg),
        hi("PmenuSel",       bg=bg_t),
        hi("PmenuSbar",      bg=bg_m),
        hi("PmenuThumb",     bg=bg_m),
        hi("PmenuMatch",     fg=bor, bg=bg),
        hi("PmenuMatchSel",  fg=bor, bg=bg_t),
        hi("Question",       fg=pri),
        hi("QuickFixLine",   bg=bg_m, bold=True),
        hi("ModeMsg",        fg=mut, bold=True),
        hi("MsgArea",        fg=mut),
        hi("MoreMsg",        fg=pri),
        hi("ErrorMsg",       fg=err),
        hi("WarningMsg",     fg=acc),
        hi("Directory",      fg=pri),
        hi("Title",          fg=pri, bold=True),
        hi("Bold",           fg=fg,  bold=True),
        hi("Italic",         fg=fg,  italic=True),
        hi("Underlined",     underline=True),
        hi("debugPC",        bg=bg),
        hi("debugBreakpoint",fg=acc, bg=bg_m),
        "",
        "-- ── Syntax ─────────────────────────────────────────────────────────────",
        hi("Comment",        fg=dim, italic=True),
        hi("Constant",       fg=pri),
        hi("String",         fg=ok),
        hi("Character",      fg=ok),
        hi("Number",         fg=acc),
        hi("Float",          fg=acc),
        hi("Boolean",        fg=pri),
        hi("Identifier",     fg=mut),
        hi("Function",       fg=pri),
        hi("Statement",      fg=mut),
        hi("Conditional",    fg=bor, italic=True),
        hi("Repeat",         fg=bor, italic=True),
        hi("Label",          fg=pri),
        hi("Operator",       fg=acc),
        hi("Keyword",        fg=acc, italic=True),
        hi("Exception",      fg=err),
        hi("PreProc",        fg=acc),
        hi("Include",        fg=bor),
        hi("Define",         fg=acc),
        hi("Macro",          fg=acc),
        hi("PreCondit",      fg=acc),
        hi("Type",           fg=bor),
        hi("StorageClass",   fg=bor),
        hi("Structure",      fg=bor),
        hi("Typedef",        fg=bor),
        hi("Special",        fg=bor),
        hi("SpecialChar",    fg=bor),
        hi("Delimiter",      link="Special"),
        hi("Debug",          fg=pri),
        hi("Todo",           fg=bg, bg=acc),
        hi("Error",          fg=err),
        "",
        "-- ── Diff ───────────────────────────────────────────────────────────────",
        hi("DiffAdd",        bg="#1a3d20"),
        hi("DiffChange",     bg=bg_m),
        hi("DiffDelete",     bg="#3d1515"),
        hi("DiffText",       bg=bg_t),
        hi("diffAdded",      fg=ok,  bg="#1a3d20"),
        hi("diffRemoved",    fg=err, bg="#3d1515"),
        hi("diffChanged",    fg=acc, bg=bg_m),
        hi("diffOldFile",    fg=bor, bg="#3d1515"),
        hi("diffNewFile",    fg=bor, bg="#1a3d20"),
        hi("diffFile",       fg=pri),
        hi("diffLine",       fg=dim),
        hi("diffIndexLine",  fg=mut),
        "",
        "-- ── Spell ──────────────────────────────────────────────────────────────",
        hi("SpellBad",   undercurl=True, sp=err),
        hi("SpellCap",   undercurl=True, sp=acc),
        hi("SpellLocal", undercurl=True, sp=acc),
        hi("SpellRare",  undercurl=True, sp=ok),
        "",
        "-- ── LSP Diagnostics ────────────────────────────────────────────────────",
        hi("DiagnosticError",               fg=err),
        hi("DiagnosticWarn",                fg=acc),
        hi("DiagnosticInfo",                fg=acc),
        hi("DiagnosticHint",                fg=ok),
        hi("DiagnosticUnnecessary",         fg=bg_m),
        hi("DiagnosticUnderlineError",      undercurl=True, sp=err),
        hi("DiagnosticUnderlineWarn",       undercurl=True, sp=acc),
        hi("DiagnosticUnderlineInfo",       undercurl=True, sp=acc),
        hi("DiagnosticUnderlineHint",       undercurl=True, sp=ok),
        hi("DiagnosticVirtualTextError",    fg=err, bg="#2f212a"),
        hi("DiagnosticVirtualTextWarn",     fg=acc, bg="#302926"),
        hi("DiagnosticVirtualTextInfo",     fg=acc, bg="#302926"),
        hi("DiagnosticVirtualTextHint",     fg=ok,  bg="#1f2a2a"),
        hi("LspReferenceText",              bg=bg_m),
        hi("LspReferenceRead",              bg=bg_m),
        hi("LspReferenceWrite",             bg=bg_m),
        hi("LspCodeLens",                   fg=dim),
        hi("LspSignatureActiveParameter",   bg="#221a1d", bold=True),
        hi("LspInlayHint",                  fg=mut, bg="#1e1b24"),
        hi("LspInfoBorder",                 fg=pri, bg=bg),
        hi("healthError",                   fg=err),
        hi("healthSuccess",                 fg=ok),
        hi("healthWarning",                 fg=acc),
        "",
        "-- ── Git Signs ──────────────────────────────────────────────────────────",
        hi("GitSignsAdd",    fg=ok),
        hi("GitSignsChange", fg=acc),
        hi("GitSignsDelete", fg=err),
        "",
        "-- ── Treesitter ─────────────────────────────────────────────────────────",
        hi("@comment",                  link="Comment"),
        hi("@comment.todo",             fg=pri),
        hi("@comment.note",             fg=ok),
        hi("@comment.warning",          fg=acc),
        hi("@comment.error",            fg=err),
        hi("@comment.info",             fg=acc),
        hi("@comment.hint",             fg=ok),
        hi("@boolean",                  link="Boolean"),
        hi("@number",                   link="Number"),
        hi("@number.float",             link="Float"),
        hi("@string",                   link="String"),
        hi("@string.regexp",            fg=fg),
        hi("@string.escape",            fg=mut),
        hi("@string.documentation",     fg="#e0af68"),
        hi("@character",                link="Character"),
        hi("@character.special",        link="SpecialChar"),
        hi("@character.printf",         link="SpecialChar"),
        hi("@type",                     link="Type"),
        hi("@type.builtin",             fg="#a24729"),
        hi("@type.definition",          link="Typedef"),
        hi("@type.qualifier",           link="Keyword"),
        hi("@attribute",                link="PreProc"),
        hi("@annotation",               link="PreProc"),
        hi("@namespace",                link="Include"),
        hi("@module",                   link="Include"),
        hi("@module.builtin",           fg=err),
        hi("@namespace.builtin",        link="@variable.builtin"),
        hi("@keyword",                  fg=bor, italic=True),
        hi("@keyword.function",         fg=mut),
        hi("@keyword.operator",         link="@operator"),
        hi("@keyword.import",           link="Include"),
        hi("@keyword.storage",          link="StorageClass"),
        hi("@keyword.repeat",           link="Repeat"),
        hi("@keyword.return",           link="Keyword"),
        hi("@keyword.exception",        link="Exception"),
        hi("@keyword.conditional",      link="Conditional"),
        hi("@keyword.coroutine",        link="Keyword"),
        hi("@keyword.directive",        link="PreProc"),
        hi("@keyword.directive.define", link="Define"),
        hi("@keyword.debug",            link="Debug"),
        hi("@variable",                 fg=fg),
        hi("@variable.builtin",         fg=err),
        hi("@variable.parameter",       fg="#e0af68"),
        hi("@variable.parameter.builtin", fg="#dab484"),
        hi("@variable.member",          fg=ok),
        hi("@function",                 link="Function"),
        hi("@function.builtin",         link="Special"),
        hi("@function.call",            link="@function"),
        hi("@function.method",          link="Function"),
        hi("@function.method.call",     link="@function.method"),
        hi("@function.macro",           link="Macro"),
        hi("@constructor",              fg=mut),
        hi("@constructor.tsx",          fg=bor),
        hi("@operator",                 fg=acc),
        hi("@property",                 fg=ok),
        hi("@constant",                 link="Constant"),
        hi("@constant.builtin",         link="Special"),
        hi("@constant.macro",           link="Define"),
        hi("@label",                    fg=pri),
        hi("@tag",                      link="Label"),
        hi("@tag.javascript",           fg=err),
        hi("@tag.tsx",                  fg=err),
        hi("@tag.attribute",            link="@property"),
        hi("@tag.delimiter",            link="Delimiter"),
        hi("@tag.delimiter.tsx",        fg="#aa5a2d"),
        hi("@punctuation.delimiter",    fg=acc),
        hi("@punctuation.bracket",      fg=mut),
        hi("@punctuation.special",      fg=acc),
        hi("@punctuation.special.markdown", fg=pri),
        hi("@none",                     fg=fg),
        hi("@diff.plus",                link="DiffAdd"),
        hi("@diff.minus",               link="DiffDelete"),
        hi("@diff.delta",               link="DiffChange"),
        "",
        "-- ── Markup ─────────────────────────────────────────────────────────────",
        hi("@markup",                   fg=fg),
        hi("@markup.strong",            bold=True),
        hi("@markup.italic",            italic=True),
        hi("@markup.underline",         underline=True),
        hi("@markup.strikethrough",     fg=fg),
        hi("@markup.raw",               link="String"),
        hi("@markup.raw.markdown_inline", fg=pri, bg=bg_m),
        hi("@markup.math",              link="Special"),
        hi("@markup.environment",       link="Macro"),
        hi("@markup.environment.name",  link="Type"),
        hi("@markup.link",              fg=ok),
        hi("@markup.link.label",        link="SpecialChar"),
        hi("@markup.link.label.symbol", link="Identifier"),
        hi("@markup.link.url",          link="Underlined"),
        hi("@markup.list",              fg=acc),
        hi("@markup.list.markdown",     fg=pri, bold=True),
        hi("@markup.list.checked",      fg=ok),
        hi("@markup.list.unchecked",    fg=pri),
        hi("@markup.emphasis",          italic=True),
        hi("@markup.heading",           link="Title"),
        hi("@markup.heading.1.markdown", fg=pri, bg="#2f2427", bold=True),
        hi("@markup.heading.2.markdown", fg=acc, bg="#302926", bold=True),
        hi("@markup.heading.3.markdown", fg=ok,  bg="#1f2a2a", bold=True),
        hi("@markup.heading.4.markdown", fg=bor, bg="#2b2126", bold=True),
        hi("@markup.heading.5.markdown", fg=mut, bg="#272127", bold=True),
        hi("@markup.heading.6.markdown", fg=fg,  bg="#313139", bold=True),
        hi("@markup.heading.7.markdown", fg=dim, bg="#251f24", bold=True),
        hi("@markup.heading.8.markdown", fg=err, bg="#2f212a", bold=True),
        hi("htmlH1",                    fg=mut, bold=True),
        hi("htmlH2",                    fg=pri, bold=True),
        hi("helpExample",               fg=dim),
        hi("helpCommand",               fg=pri, bg=bg_m),
        hi("qfFileName",                fg=pri),
        hi("qfLineNr",                  fg=dim),
        hi("dosIniLabel",               link="@property"),
        "",
        "-- ── LSP Semantic Tokens ────────────────────────────────────────────────",
        hi("@lsp.type.boolean",         link="@boolean"),
        hi("@lsp.type.builtinType",     link="@type.builtin"),
        hi("@lsp.type.comment",         link="@comment"),
        hi("@lsp.type.decorator",       link="@attribute"),
        hi("@lsp.type.enum",            link="@type"),
        hi("@lsp.type.enumMember",      link="@constant"),
        hi("@lsp.type.escapeSequence",  link="@string.escape"),
        hi("@lsp.type.formatSpecifier", link="@markup.list"),
        hi("@lsp.type.generic",         link="@variable"),
        hi("@lsp.type.interface",       fg="#c37667"),
        hi("@lsp.type.keyword",         link="@keyword"),
        hi("@lsp.type.lifetime",        link="@keyword.storage"),
        hi("@lsp.type.namespace",       link="@module"),
        hi("@lsp.type.namespace.python", link="@variable"),
        hi("@lsp.type.number",          link="@number"),
        hi("@lsp.type.operator",        link="@operator"),
        hi("@lsp.type.parameter",       link="@variable.parameter"),
        hi("@lsp.type.property",        link="@property"),
        hi("@lsp.type.selfKeyword",     link="@variable.builtin"),
        hi("@lsp.type.selfTypeKeyword", link="@variable.builtin"),
        hi("@lsp.type.string",          link="@string"),
        hi("@lsp.type.struct",          link="@type"),
        hi("@lsp.type.typeAlias",       link="@type.definition"),
        hi("@lsp.type.unresolvedReference", undercurl=True, sp=err),
        hi("@lsp.type.variable"),
        hi("@lsp.type.deriveHelper",    link="@attribute"),
        hi("@lsp.typemod.class.defaultLibrary",    link="@type.builtin"),
        hi("@lsp.typemod.enum.defaultLibrary",     link="@type.builtin"),
        hi("@lsp.typemod.enumMember.defaultLibrary", link="@constant.builtin"),
        hi("@lsp.typemod.function.defaultLibrary", link="@function.builtin"),
        hi("@lsp.typemod.keyword.async",            link="@keyword.coroutine"),
        hi("@lsp.typemod.keyword.injected",         link="@keyword"),
        hi("@lsp.typemod.macro.defaultLibrary",     link="@function.builtin"),
        hi("@lsp.typemod.method.defaultLibrary",    link="@function.builtin"),
        hi("@lsp.typemod.operator.injected",        link="@operator"),
        hi("@lsp.typemod.string.injected",          link="@string"),
        hi("@lsp.typemod.struct.defaultLibrary",    link="@type.builtin"),
        hi("@lsp.typemod.type.defaultLibrary",      fg="#a24729"),
        hi("@lsp.typemod.typeAlias.defaultLibrary", fg="#a24729"),
        hi("@lsp.typemod.variable.callable",        link="@function"),
        hi("@lsp.typemod.variable.defaultLibrary",  link="@variable.builtin"),
        hi("@lsp.typemod.variable.injected",        link="@variable"),
        hi("@lsp.typemod.variable.static",          link="@constant"),
        "",
        "-- ── Plugin: Blink / Completion ─────────────────────────────────────────",
        hi("BlinkCmpDoc",           fg=fg,  bg=bg),
        hi("BlinkCmpDocBorder",     fg=pri, bg=bg),
        hi("BlinkCmpGhostText",     fg=bg_m),
        hi("BlinkCmpLabel",         fg=fg,  bg="NONE"),
        hi("BlinkCmpLabelDeprecated", fg=bg_m, bg="NONE"),
        hi("BlinkCmpLabelMatch",    fg=bor, bg="NONE"),
        hi("BlinkCmpMenu",          fg=fg,  bg=bg),
        hi("BlinkCmpMenuBorder",    fg=pri, bg=bg),
        hi("BlinkCmpSignatureHelp", fg=fg,  bg=bg),
        hi("BlinkCmpSignatureHelpBorder", fg=pri, bg=bg),
        hi("BlinkCmpKindDefault",   fg=mut, bg="NONE"),
        hi("BlinkCmpKindCodeium",   fg=ok,  bg="NONE"),
        hi("BlinkCmpKindCopilot",   fg=ok,  bg="NONE"),
        hi("BlinkCmpKindSupermaven",fg=ok,  bg="NONE"),
        hi("BlinkCmpKindTabNine",   fg=ok,  bg="NONE"),
        hi("BlinkCmpKindText",      link="LspKindText"),
        hi("BlinkCmpKindFunction",  link="LspKindFunction"),
        hi("BlinkCmpKindKeyword",   link="LspKindKeyword"),
        hi("BlinkCmpKindField",     link="LspKindField"),
        hi("BlinkCmpKindVariable",  link="LspKindVariable"),
        hi("BlinkCmpKindClass",     link="LspKindClass"),
        hi("BlinkCmpKindInterface", link="LspKindInterface"),
        hi("BlinkCmpKindModule",    link="LspKindModule"),
        hi("BlinkCmpKindProperty",  link="LspKindProperty"),
        hi("BlinkCmpKindUnit",      link="LspKindUnit"),
        hi("BlinkCmpKindValue",     link="LspKindValue"),
        hi("BlinkCmpKindEnum",      link="LspKindEnum"),
        hi("BlinkCmpKindColor",     link="LspKindColor"),
        hi("BlinkCmpKindConstant",  link="LspKindConstant"),
        hi("BlinkCmpKindConstructor", link="LspKindConstructor"),
        hi("BlinkCmpKindEnumMember",  link="LspKindEnumMember"),
        hi("BlinkCmpKindEvent",       link="LspKindEvent"),
        hi("BlinkCmpKindFile",        link="LspKindFile"),
        hi("BlinkCmpKindFolder",      link="LspKindFolder"),
        hi("BlinkCmpKindMethod",      link="LspKindMethod"),
        hi("BlinkCmpKindNamespace",   link="LspKindNamespace"),
        hi("BlinkCmpKindNull",        link="LspKindNull"),
        hi("BlinkCmpKindNumber",      link="LspKindNumber"),
        hi("BlinkCmpKindObject",      link="LspKindObject"),
        hi("BlinkCmpKindOperator",    link="LspKindOperator"),
        hi("BlinkCmpKindPackage",     link="LspKindPackage"),
        hi("BlinkCmpKindReference",   link="LspKindReference"),
        hi("BlinkCmpKindSnippet",     link="LspKindSnippet"),
        hi("BlinkCmpKindString",      link="LspKindString"),
        hi("BlinkCmpKindStruct",      link="LspKindStruct"),
        hi("BlinkCmpKindTypeParameter", link="LspKindTypeParameter"),
        hi("BlinkCmpKindArray",       link="LspKindArray"),
        hi("BlinkCmpKindBoolean",     link="LspKindBoolean"),
        "",
        "-- ── Plugin: LspKind icons ──────────────────────────────────────────────",
        hi("LspKindText",            link="@markup"),
        hi("LspKindFunction",        link="@function"),
        hi("LspKindKeyword",         link="@lsp.type.keyword"),
        hi("LspKindField",           link="@variable.member"),
        hi("LspKindVariable",        link="@variable"),
        hi("LspKindClass",           link="@type"),
        hi("LspKindInterface",       link="@lsp.type.interface"),
        hi("LspKindModule",          link="@module"),
        hi("LspKindProperty",        link="@property"),
        hi("LspKindUnit",            link="@lsp.type.struct"),
        hi("LspKindValue",           link="@string"),
        hi("LspKindEnum",            link="@lsp.type.enum"),
        hi("LspKindColor",           link="Special"),
        hi("LspKindConstant",        link="@constant"),
        hi("LspKindConstructor",     link="@constructor"),
        hi("LspKindEnumMember",      link="@lsp.type.enumMember"),
        hi("LspKindEvent",           link="Special"),
        hi("LspKindFile",            link="Normal"),
        hi("LspKindFolder",          link="Directory"),
        hi("LspKindMethod",          link="@function.method"),
        hi("LspKindNamespace",       link="@module"),
        hi("LspKindNull",            link="@constant.builtin"),
        hi("LspKindNumber",          link="@number"),
        hi("LspKindObject",          link="@constant"),
        hi("LspKindOperator",        link="@operator"),
        hi("LspKindPackage",         link="@module"),
        hi("LspKindReference",       link="@markup.link"),
        hi("LspKindSnippet",         link="Conceal"),
        hi("LspKindString",          link="@string"),
        hi("LspKindStruct",          link="@lsp.type.struct"),
        hi("LspKindTypeParameter",   link="@lsp.type.typeParameter"),
        hi("LspKindArray",           link="@punctuation.bracket"),
        hi("LspKindBoolean",         link="@boolean"),
        "",
        "-- ── Plugin: Noice ──────────────────────────────────────────────────────",
        hi("NoiceCmdlineIconInput",         fg="#e0af68"),
        hi("NoiceCmdlineIconLua",           fg=bor),
        hi("NoiceCmdlinePopupBorderInput",  fg="#e0af68"),
        hi("NoiceCmdlinePopupBorderLua",    fg=bor),
        hi("NoiceCmdlinePopupTitleInput",   fg="#e0af68"),
        hi("NoiceCmdlinePopupTitleLua",     fg=bor),
        hi("NoiceCompletionItemKindDefault", fg=mut, bg="NONE"),
        hi("NoiceCompletionItemKindArray",   link="LspKindArray"),
        hi("NoiceCompletionItemKindBoolean", link="LspKindBoolean"),
        hi("NoiceCompletionItemKindClass",   link="LspKindClass"),
        hi("NoiceCompletionItemKindColor",   link="LspKindColor"),
        hi("NoiceCompletionItemKindConstant",link="LspKindConstant"),
        hi("NoiceCompletionItemKindConstructor", link="LspKindConstructor"),
        hi("NoiceCompletionItemKindEnum",    link="LspKindEnum"),
        hi("NoiceCompletionItemKindEnumMember", link="LspKindEnumMember"),
        hi("NoiceCompletionItemKindEvent",   link="LspKindEvent"),
        hi("NoiceCompletionItemKindField",   link="LspKindField"),
        hi("NoiceCompletionItemKindFile",    link="LspKindFile"),
        hi("NoiceCompletionItemKindFolder",  link="LspKindFolder"),
        hi("NoiceCompletionItemKindFunction",link="LspKindFunction"),
        hi("NoiceCompletionItemKindInterface", link="LspKindInterface"),
        hi("NoiceCompletionItemKindKey",     link="LspKindKey"),
        hi("NoiceCompletionItemKindKeyword", link="LspKindKeyword"),
        hi("NoiceCompletionItemKindMethod",  link="LspKindMethod"),
        hi("NoiceCompletionItemKindModule",  link="LspKindModule"),
        hi("NoiceCompletionItemKindNamespace",link="LspKindNamespace"),
        hi("NoiceCompletionItemKindNull",    link="LspKindNull"),
        hi("NoiceCompletionItemKindNumber",  link="LspKindNumber"),
        hi("NoiceCompletionItemKindObject",  link="LspKindObject"),
        hi("NoiceCompletionItemKindOperator",link="LspKindOperator"),
        hi("NoiceCompletionItemKindPackage", link="LspKindPackage"),
        hi("NoiceCompletionItemKindProperty",link="LspKindProperty"),
        hi("NoiceCompletionItemKindReference",link="LspKindReference"),
        hi("NoiceCompletionItemKindSnippet", link="LspKindSnippet"),
        hi("NoiceCompletionItemKindString",  link="LspKindString"),
        hi("NoiceCompletionItemKindStruct",  link="LspKindStruct"),
        hi("NoiceCompletionItemKindText",    link="LspKindText"),
        hi("NoiceCompletionItemKindTypeParameter", link="LspKindTypeParameter"),
        hi("NoiceCompletionItemKindUnit",    link="LspKindUnit"),
        hi("NoiceCompletionItemKindValue",   link="LspKindValue"),
        hi("NoiceCompletionItemKindVariable",link="LspKindVariable"),
        "",
        "-- ── Plugin: Snacks ─────────────────────────────────────────────────────",
        hi("SnacksDashboardDesc",    fg=acc),
        hi("SnacksDashboardDir",     fg=mut),
        hi("SnacksDashboardFooter",  fg=bor),
        hi("SnacksDashboardHeader",  fg=pri),
        hi("SnacksDashboardIcon",    fg=bor),
        hi("SnacksDashboardKey",     fg=pri),
        hi("SnacksDashboardSpecial", fg=bor),
        hi("SnacksIndent",           fg=bg_m, nocombine=True),
        hi("SnacksIndent1",          fg=pri,  nocombine=True),
        hi("SnacksIndent2",          fg=acc,  nocombine=True),
        hi("SnacksIndent3",          fg=ok,   nocombine=True),
        hi("SnacksIndent4",          fg=bor,  nocombine=True),
        hi("SnacksIndent5",          fg=mut,  nocombine=True),
        hi("SnacksIndent6",          fg=fg,   nocombine=True),
        hi("SnacksIndent7",          fg=dim,  nocombine=True),
        hi("SnacksIndent8",          fg=err,  nocombine=True),
        hi("SnacksIndentScope",      fg=bor,  nocombine=True),
        hi("SnacksZenIcon",          fg=bor),
        hi("SnacksInputIcon",        fg=bor),
        hi("SnacksInputBorder",      fg="#e0af68"),
        hi("SnacksInputTitle",       fg="#e0af68"),
        hi("SnacksGhLabel",          fg=bor,  bold=True),
        hi("SnacksDiffLabel",        fg=bor,  bold=True),
        hi("SnacksGhDiffHeader",     fg=bor,  bg="#2b2126"),
        hi("SnacksPickerBoxTitle",   fg=pri,  bg=bg),
        hi("SnacksPickerInputBorder",fg=pri,  bg=bg),
        hi("SnacksPickerInputTitle", fg=pri,  bg=bg),
        hi("SnacksPickerSelected",   fg=err),
        hi("SnacksPickerToggle",     link="SnacksProfilerBadgeInfo"),
        hi("SnacksPickerPickWin",    fg=fg,  bg=bg_t, bold=True),
        hi("SnacksPickerPickWinCurrent", fg=fg, bg=err, bold=True),
        hi("SnacksProfilerIconInfo", fg=bor, bg="#4d2c27"),
        hi("SnacksProfilerBadgeInfo",fg=bor, bg="#2b2126"),
        hi("SnacksFooterKey",        link="SnacksProfilerIconInfo"),
        hi("SnacksFooterDesc",       link="SnacksProfilerBadgeInfo"),
        hi("SnacksProfilerIconTrace",fg=mut, bg="#251c1f"),
        hi("SnacksProfilerBadgeTrace",fg=mut,bg="#1e1b24"),
        hi("SnacksNotifierDebug",    fg=fg,  bg=bg),
        hi("SnacksNotifierBorderDebug", fg="#472c1e", bg=bg),
        hi("SnacksNotifierIconDebug",fg=dim),
        hi("SnacksNotifierTitleDebug",fg=dim),
        hi("SnacksNotifierError",    fg=fg,  bg=bg),
        hi("SnacksNotifierBorderError", fg="#6f3137", bg=bg),
        hi("SnacksNotifierIconError",fg=err),
        hi("SnacksNotifierTitleError",fg=err),
        hi("SnacksNotifierInfo",     fg=fg,  bg=bg),
        hi("SnacksNotifierBorderInfo", fg="#725325", bg=bg),
        hi("SnacksNotifierIconInfo", fg=acc),
        hi("SnacksNotifierTitleInfo",fg=acc),
        hi("SnacksNotifierTrace",    fg=fg,  bg=bg),
        hi("SnacksNotifierBorderTrace", fg="#5e3128", bg=bg),
        hi("SnacksNotifierIconTrace",fg=bor),
        hi("SnacksNotifierTitleTrace",fg=bor),
        hi("SnacksNotifierWarn",     fg=fg,  bg=bg),
        hi("SnacksNotifierBorderWarn", fg="#725325", bg=bg),
        hi("SnacksNotifierIconWarn", fg=acc),
        hi("SnacksNotifierTitleWarn",fg=acc),
        "",
        "-- ── Plugin: Which-key ───────────────────────────────────────────────────",
        hi("WhichKey",          fg=acc),
        hi("WhichKeyGroup",     fg=pri),
        hi("WhichKeyDesc",      fg=mut),
        hi("WhichKeySeparator", fg=dim),
        hi("WhichKeyNormal",    bg=bg),
        hi("WhichKeyValue",     fg=dim),
        "",
        "-- ── Plugin: Trouble ────────────────────────────────────────────────────",
        hi("TroubleText",   fg=mut),
        hi("TroubleCount",  fg=mut, bg=bg_m),
        hi("TroubleNormal", fg=fg,  bg=bg),
        "",
        "-- ── Plugin: Flash ──────────────────────────────────────────────────────",
        hi("FlashBackdrop", fg=mut),
        hi("FlashLabel",    fg=fg,  bg=err, bold=True),
        "",
        "-- ── Plugin: Grug-Far ───────────────────────────────────────────────────",
        hi("GrugFarHelpHeader",        fg=dim),
        hi("GrugFarHelpHeaderKey",     fg=acc),
        hi("GrugFarInputLabel",        fg=bor),
        hi("GrugFarInputPlaceholder",  fg=mut),
        hi("GrugFarResultsHeader",     fg=pri),
        hi("GrugFarResultsMatch",      fg=bg_d, bg=err),
        hi("GrugFarResultsStats",      fg=pri),
        hi("GrugFarResultsLineNo",     fg=mut),
        hi("GrugFarResultsLineColumn", fg=mut),
        hi("GrugFarResultsChangeIndicator", fg=acc),
        "",
        "-- ── Plugin: Bufferline ─────────────────────────────────────────────────",
        hi("BufferLineIndicatorSelected", fg=acc),
        "",
        "-- ── Plugin: Lazy ───────────────────────────────────────────────────────",
        hi("LazyProgressDone", fg=err, bold=True),
        hi("LazyProgressTodo", fg=bg_m, bold=True),
        "",
        "-- ── Plugin: Mini Icons ─────────────────────────────────────────────────",
        hi("MiniIconsAzure",  fg=acc),
        hi("MiniIconsBlue",   fg=pri),
        hi("MiniIconsCyan",   fg=ok),
        hi("MiniIconsGreen",  fg=ok),
        hi("MiniIconsGrey",   fg=fg),
        hi("MiniIconsOrange", fg=pri),
        hi("MiniIconsPurple", fg=bor),
        hi("MiniIconsRed",    fg=err),
        hi("MiniIconsYellow", fg="#e0af68"),
        "",
        "-- ── Terminal colors (vim.g.terminal_color_*) ────────────────────────────",
        f'vim.g.terminal_color_0  = "{bg_d}"',
        f'vim.g.terminal_color_1  = "{err}"',
        f'vim.g.terminal_color_2  = "{ok}"',
        f'vim.g.terminal_color_3  = "{acc}"',
        f'vim.g.terminal_color_4  = "{pri}"',
        f'vim.g.terminal_color_5  = "{mut}"',
        f'vim.g.terminal_color_6  = "{acc}"',
        f'vim.g.terminal_color_7  = "{mut}"',
        f'vim.g.terminal_color_8  = "{bg_m}"',
        f'vim.g.terminal_color_9  = "{err}"',
        f'vim.g.terminal_color_10 = "{ok}"',
        f'vim.g.terminal_color_11 = "{acc}"',
        f'vim.g.terminal_color_12 = "{pri}"',
        f'vim.g.terminal_color_13 = "{bor}"',
        f'vim.g.terminal_color_14 = "{fg}"',
        f'vim.g.terminal_color_15 = "{fg}"',
    ]

    path.write_text("\n".join(lines) + "\n")
    print(f"  config/nvim/colors/yendo-cowboy.lua — generated ({len(lines)} lines)")


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
    """Regenerate the lualine theme in colorscheme.lua between sentinel markers.

    The on_colors tokyonight block is gone — the colorscheme is now standalone.
    Only the BEGIN_LUALINE / END_LUALINE block is auto-generated here.
    """
    path = DOTFILES / "config/nvim/lua/plugins/colorscheme.lua"
    lines = path.read_text().splitlines(keepends=True)

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
    print(f"  nvim colorscheme.lua — regenerated lualine theme")


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
    patch_nvim_colors(p)
    patch_nvim(p)
    patch_p10k(p)
    patch_lazygit(p)
    print(f"\nDone. Restart tmux/yazi/nvim/p10k/lazygit to see changes.")
