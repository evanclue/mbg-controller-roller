#!/usr/bin/env bash

# Cross-compiles the Windows release from Linux and packages it as a portable
# directory holding marblegame.exe and the game data, with every library the
# game needs linked into the executable.
#
# Run ./setup-windows-toolchain.sh once before this.

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
toolchain_dir=${MBHAXE_TOOLCHAIN:-/home/cachy/mbhaxe-toolchain}
win_dir=${MBG_WIN_TOOLCHAIN:-$toolchain_dir/windows}
deploy_dir=${MBG_WIN_DEPLOY_DIR:-$project_dir/dist/MBG-Controller-Roller-Windows}

case "$deploy_dir" in
	""|/) echo "ERROR: refusing unsafe output directory: ${deploy_dir:-<empty>}" >&2; exit 1 ;;
esac

[[ -f "$win_dir/toolchain.env" ]] || {
	echo "ERROR: Windows toolchain not found: $win_dir" >&2
	echo "Run ./setup-windows-toolchain.sh first." >&2
	exit 1
}
# shellcheck disable=SC1090
source "$win_dir/toolchain.env"

sysroot=$MBG_WIN_SYSROOT
lib=$MBG_WIN_LIB
redist=$MBG_WIN_REDIST
hashlink_src=$MBG_WIN_HASHLINK_SRC

[[ -f "$redist/OpenAL32.dll" ]] || {
	echo "ERROR: OpenAL32.dll is missing from $redist" >&2
	echo "Re-run ./setup-windows-toolchain.sh." >&2
	exit 1
}

haxe_dir="$toolchain_dir/haxe"
export PATH="$MBG_WIN_MINGW_BIN:$haxe_dir:$PATH"
export HAXELIB_PATH="$toolchain_dir/haxelib"
export LD_LIBRARY_PATH="$toolchain_dir/neko${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

CC=x86_64-w64-mingw32-gcc

cd "$project_dir"

echo "Generating Windows C sources..."
"$haxe_dir/haxe" compile-windows.hxml

# The generated HL/C code is only built without optimization: at -O1 and above
# the game starts but renders nothing.
echo "Compiling marblegame.exe..."
$CC -c native-win/marblegame.c -o native-win/marblegame.o \
	-O0 -std=gnu11 -DNDEBUG -march=x86-64 -mtune=generic \
	-DLIBHL_STATIC -DUNICODE -D_UNICODE -municode -w \
	-I native-win -I "$hashlink_src/src"

# -mwindows keeps a console window from opening alongside the game.
echo "Linking marblegame.exe..."
$CC -o "$project_dir/marblegame.exe" \
	native-win/marblegame.o \
	-municode -mwindows \
	-static -static-libgcc -static-libstdc++ \
	"$lib/libhlsdl.a" "$lib/libhlopenal.a" "$lib/libhlfmt.a" "$lib/libhluv.a" \
	"$lib/hlssl.o" "$lib/libhlui.a" "$lib/libhldc.a" \
	"$lib/libhl.a" \
	"$lib/libdatachannel-static.a" "$lib/libjuice-static.a" \
	"$lib/libusrsctp.a" "$lib/libMbedTLS.a" \
	-L"$sysroot/lib" -lSDL2 "$lib/libOpenAL32.dll.a" \
	-lopengl32 -lglu32 -lwinmm -lole32 -loleaut32 -limm32 -lversion -lsetupapi -ldinput8 \
	-lgdi32 -luser32 -lshell32 -lcomdlg32 -ladvapi32 -luuid -lws2_32 -liphlpapi -lpsapi \
	-luserenv -lcrypt32 -lbcrypt -ldbghelp -lavrt -lksuser -lmfplat -lmfuuid -lwmcodecdspuuid \
	-lstdc++ -lpthread -lm
x86_64-w64-mingw32-strip --strip-unneeded "$project_dir/marblegame.exe"

# Everything except the Windows API and the OpenAL DLL shipped alongside has to
# be inside the executable, or the build is not portable.
echo "Verifying that the executable is self-contained..."
while IFS= read -r dll; do
	case "${dll,,}" in
		openal32.dll) ;;
		api-ms-win-*|kernel32.dll|user32.dll|gdi32.dll|shell32.dll|advapi32.dll|ole32.dll| \
		oleaut32.dll|comdlg32.dll|imm32.dll|version.dll|winmm.dll|ws2_32.dll|crypt32.dll| \
		bcrypt.dll|setupapi.dll|iphlpapi.dll|psapi.dll|userenv.dll|dbghelp.dll|avrt.dll| \
		opengl32.dll|glu32.dll|dinput8.dll|ksuser.dll|mfplat.dll|uuid.dll|msvcrt.dll) ;;
		*)
			echo "ERROR: marblegame.exe depends on a non-system library: $dll" >&2
			exit 1
			;;
	esac
done < <(x86_64-w64-mingw32-objdump -p "$project_dir/marblegame.exe" |
	sed -n 's/.*DLL Name: *//p' | sort -u)

echo "Creating portable build in $deploy_dir..."
deploy_parent=$(dirname -- "$deploy_dir")
mkdir -p -- "$deploy_parent"
staging=$(mktemp -d "$deploy_parent/.mbg-windows.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT
mkdir -p "$staging/build"
install -m 755 "$project_dir/marblegame.exe" "$staging/build/marblegame.exe"
install -m 755 "$redist/OpenAL32.dll" "$staging/build/OpenAL32.dll"
cp -a "$project_dir/data" "$staging/build/data"
rm -rf -- "$deploy_dir"
mv -- "$staging/build" "$deploy_dir"
rmdir -- "$staging"
trap - EXIT

echo "Build complete: $deploy_dir"
