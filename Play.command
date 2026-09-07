#!/bin/zsh
set -e
hollowmere_dir="${0:A:h}"
exec /Applications/Godot.app/Contents/MacOS/Godot --main-pack "$hollowmere_dir/builds/Hollowmere.pck" "$@"
