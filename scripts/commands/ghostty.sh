#!/bin/sh
# Ghostty launcher — nix-installed ghostty needs nixGL to get a working
# EGL/GLX context on Ubuntu (host Mesa drivers aren't in the nix closure).
# Without this: "Unable to acquire an OpenGL context for rendering."
# Used by sway's $term binding; see docs/omarchy-integration.md.
exec "$HOME/.nix-profile/bin/nixGLIntel" "$HOME/.nix-profile/bin/ghostty" "$@"
