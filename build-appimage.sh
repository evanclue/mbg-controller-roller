#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
portable_dir=${MBG_PORTABLE_DIR:-$project_dir/dist/MBHaxe-Gold-Linux}
output=${MBG_APPIMAGE_OUTPUT:-$project_dir/dist/MBG-Controller-Roller-x86_64.AppImage}
appimagetool=${APPIMAGETOOL:-appimagetool}

command -v sha256sum >/dev/null || {
	echo "ERROR: sha256sum is required to version the writable data cache" >&2
	exit 1
}

[[ -x "$portable_dir/marblegame" ]] || {
	echo "ERROR: portable Linux bundle not found: $portable_dir" >&2
	exit 1
}
[[ -f "$portable_dir/ui.hdll" ]] || {
	echo "ERROR: portable bundle is incomplete: ui.hdll is missing" >&2
	exit 1
}

if [[ "$appimagetool" == */* ]]; then
	[[ -x "$appimagetool" ]] || {
		echo "ERROR: appimagetool is not executable: $appimagetool" >&2
		exit 1
	}
else
	command -v "$appimagetool" >/dev/null || {
		echo "ERROR: appimagetool is required (set APPIMAGETOOL=/path/to/appimagetool)" >&2
		exit 1
	}
fi

output_parent=$(dirname -- "$output")
mkdir -p -- "$output_parent"
output_parent=$(cd -- "$output_parent" && pwd)
output="$output_parent/$(basename -- "$output")"
stage_dir=$(mktemp -d "$output_parent/.mbg-appimage.XXXXXX")
trap 'rm -rf -- "$stage_dir"' EXIT
appdir="$stage_dir/Controller-Roller.AppDir"
payload="$appdir/usr/lib/controller-roller"

mkdir -p "$payload" \
	"$appdir/usr/bin" \
	"$appdir/usr/share/applications" \
	"$appdir/usr/share/icons/hicolor/512x512/apps"
cp -a "$portable_dir/." "$payload/"
sha256sum "$portable_dir/data/filesystem.manifest" | awk '{ print $1 }' > "$payload/data-version"

cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
set -eu
HERE=${APPDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}
PAYLOAD="$HERE/usr/lib/controller-roller"
CACHE_HOME=${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}
DATA_VERSION=$(cat "$PAYLOAD/data-version")
DATA_ROOT="$CACHE_HOME/controller-roller/$DATA_VERSION"
if [ ! -d "$DATA_ROOT/data" ]; then
    mkdir -p "$DATA_ROOT"
    TEMP_DATA="$DATA_ROOT/data.new.$$"
    rm -rf "$TEMP_DATA"
    cp -a "$PAYLOAD/data" "$TEMP_DATA"
    mv "$TEMP_DATA" "$DATA_ROOT/data"
fi
export LD_LIBRARY_PATH="$PAYLOAD${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export MBG_DATA_ROOT="$DATA_ROOT"
cd "$DATA_ROOT"
exec "$PAYLOAD/marblegame" "$@"
EOF
chmod +x "$appdir/AppRun"

cat > "$appdir/usr/bin/controller-roller" <<'EOF'
#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PAYLOAD="$HERE/usr/lib/controller-roller"
CACHE_HOME=${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}
DATA_VERSION=$(cat "$PAYLOAD/data-version")
DATA_ROOT="$CACHE_HOME/controller-roller/$DATA_VERSION"
if [ ! -d "$DATA_ROOT/data" ]; then
    mkdir -p "$DATA_ROOT"
    TEMP_DATA="$DATA_ROOT/data.new.$$"
    rm -rf "$TEMP_DATA"
    cp -a "$PAYLOAD/data" "$TEMP_DATA"
    mv "$TEMP_DATA" "$DATA_ROOT/data"
fi
export LD_LIBRARY_PATH="$PAYLOAD${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export MBG_DATA_ROOT="$DATA_ROOT"
cd "$DATA_ROOT"
exec "$PAYLOAD/marblegame" "$@"
EOF
chmod +x "$appdir/usr/bin/controller-roller"

cat > "$appdir/controller-roller.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Controller Roller
Comment=Controller-first Marble Blast Gold port
Exec=controller-roller
Icon=controller-roller
Terminal=false
Categories=Game;
EOF
cp "$appdir/controller-roller.desktop" "$appdir/usr/share/applications/"
cp "$project_dir/data/icons/icon-512.png" "$appdir/controller-roller.png"
cp "$project_dir/data/icons/icon-512.png" \
	"$appdir/usr/share/icons/hicolor/512x512/apps/controller-roller.png"
ln -s controller-roller.png "$appdir/.DirIcon"

temp_output="$stage_dir/$(basename -- "$output")"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 \
	"$appimagetool" --no-appstream "$appdir" "$temp_output"
[[ -x "$temp_output" ]] || {
	echo "ERROR: appimagetool did not create an executable AppImage" >&2
	exit 1
}

mv -f -- "$temp_output" "$output"
echo "AppImage created: $output"
