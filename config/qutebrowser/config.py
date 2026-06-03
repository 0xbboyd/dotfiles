# qutebrowser config managed by Hermes.
# Keep UI-written settings if qutebrowser creates autoconfig.yml later.
config.load_autoconfig()

# Fill Yendo Okta login fields from 1Password CLI.
# Item refs are resolved by ~/.local/share/qutebrowser/userscripts/qute-1password-okta
config.bind('<Ctrl-Alt-o>', 'spawn --userscript qute-1password-okta')
