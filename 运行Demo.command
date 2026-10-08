#!/bin/zsh
set -eu
cd -- "$(dirname -- "$0")"
exec /usr/bin/open -n -a /Applications/Godot.app --args --path "$PWD"
