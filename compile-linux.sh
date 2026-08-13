#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
toolchain_dir=${MBHAXE_TOOLCHAIN:-/home/cachy/mbhaxe-toolchain}
deploy_dir=${MBG_DEPLOY_DIR:-/home/cachy/Desktop/mrbl/gold}

haxe_dir="$toolchain_dir/haxe"
haxelib_dir="$toolchain_dir/haxelib"
prefix_dir="$toolchain_dir/prefix"
hashlink_src="$toolchain_dir/deps/hashlink/src"

export PATH="$haxe_dir:$PATH"
export HAXELIB_PATH="$haxelib_dir"
export LD_LIBRARY_PATH="$toolchain_dir/neko${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$project_dir"

echo "Generating Linux C sources..."
"$haxe_dir/haxe" compile-linux.hxml

echo "Linking marblegame..."
gcc -o marblegame -g \
	-I native \
	-I "$prefix_dir/include" \
	-I "$hashlink_src" \
	-L "$prefix_dir/lib" \
	-Wl,-rpath,"\$ORIGIN:$prefix_dir/lib" \
	native/marblegame.c \
	"$prefix_dir/lib/ui.hdll" \
	"$prefix_dir/lib/openal.hdll" \
	"$prefix_dir/lib/fmt.hdll" \
	"$prefix_dir/lib/sdl.hdll" \
	"$prefix_dir/lib/uv.hdll" \
	"$prefix_dir/lib/ssl.hdll" \
	"$prefix_dir/lib/datachannel.hdll" \
	-lSDL2 -lhl -luv -lm

echo "Deploying to $deploy_dir/marblegame..."
mkdir -p "$deploy_dir"
install -m 755 marblegame "$deploy_dir/marblegame"

echo "Build complete: $deploy_dir/marblegame"
