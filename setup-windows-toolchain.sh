#!/usr/bin/env bash

# Builds the cross-compilation toolchain that compile-windows.sh consumes:
# a MinGW-w64 compiler, a Windows sysroot with SDL2 and OpenAL, and static
# builds of HashLink, its native modules, and libdatachannel.
#
# This only has to be run when the toolchain does not exist yet or when the
# MBHaxe dependencies change.

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
toolchain_dir=${MBHAXE_TOOLCHAIN:-/home/cachy/mbhaxe-toolchain}
win_dir=${MBG_WIN_TOOLCHAIN:-$toolchain_dir/windows}
hashlink_src=${MBG_HASHLINK_SRC:-$toolchain_dir/deps/hashlink}
datachannel_src=${MBG_DATACHANNEL_SRC:-$toolchain_dir/deps/hxDatachannel}
job_count=${MBG_JOBS:-$(nproc)}

# MSYS2 ships the only maintained prebuilt Windows SDL2 that is static, built
# for the UCRT, and matches the compiler's ABI.
sdl2_pkg=${MBG_SDL2_PKG:-mingw-w64-ucrt-x86_64-SDL2-2.32.10-1-any.pkg.tar.zst}
msys_url=${MBG_MSYS_URL:-https://repo.msys2.org/mingw/ucrt64}

# OpenAL Soft is LGPL, so it ships beside the game as a DLL rather than being
# linked into the executable. It is built here instead of taken from MSYS2,
# whose build pulls in three more GCC runtime DLLs. 1.25 and newer need C++20
# module support that GCC does not yet provide correctly for Windows targets.
openal_version=${MBG_OPENAL_VERSION:-1.24.3}
openal_url=${MBG_OPENAL_URL:-https://github.com/kcat/openal-soft/releases/download/$openal_version/openal-soft-$openal_version.tar.bz2}

for command in curl tar cmake ninja python3 git; do
	command -v "$command" >/dev/null || {
		echo "ERROR: $command is required to build the Windows toolchain" >&2
		exit 1
	}
done

[[ -d "$hashlink_src/src" ]] || {
	echo "ERROR: HashLink sources not found: $hashlink_src" >&2
	exit 1
}
[[ -d "$datachannel_src/cpp/libdatachannel" ]] || {
	echo "ERROR: hxDatachannel sources not found: $datachannel_src" >&2
	echo "Its libdatachannel submodule has to be checked out." >&2
	exit 1
}

mkdir -p "$win_dir"
win_dir=$(cd -- "$win_dir" && pwd)
sysroot="$win_dir/sysroot"
prefix="$win_dir/lib"
src_dir="$win_dir/src"
mkdir -p "$sysroot" "$prefix" "$src_dir" "$win_dir/download"

# ---------------------------------------------------------------- compiler ---
# A system-wide MinGW is used when one is installed; otherwise the Arch packages
# are unpacked into the toolchain directory, which needs no root privileges.
if command -v x86_64-w64-mingw32-gcc >/dev/null; then
	mingw_bin=$(dirname -- "$(command -v x86_64-w64-mingw32-gcc)")
	mingw_root=$(cd -- "$mingw_bin/../.." && pwd)
	echo "Using installed MinGW-w64: $mingw_bin"
elif [[ -x "$win_dir/mingw/usr/bin/x86_64-w64-mingw32-gcc" ]]; then
	mingw_root="$win_dir/mingw/usr"
	mingw_bin="$mingw_root/bin"
	echo "Using downloaded MinGW-w64: $mingw_bin"
else
	command -v pacman >/dev/null || {
		echo "ERROR: no MinGW-w64 cross compiler found." >&2
		echo "Install mingw-w64-gcc (and its binutils, crt, headers, winpthreads)," >&2
		echo "or put x86_64-w64-mingw32-gcc on PATH." >&2
		exit 1
	}
	echo "Downloading MinGW-w64 cross compiler..."
	mkdir -p "$win_dir/mingw"
	for url in $(pacman -Sp mingw-w64-gcc mingw-w64-binutils mingw-w64-crt \
		mingw-w64-headers mingw-w64-winpthreads); do
		package="$win_dir/download/$(basename -- "$url")"
		[[ -f "$package" ]] || curl -fsSL -o "$package" "$url"
		tar -xf "$package" -C "$win_dir/mingw" --exclude='.*'
	done
	mingw_root="$win_dir/mingw/usr"
	mingw_bin="$mingw_root/bin"
	[[ -x "$mingw_bin/x86_64-w64-mingw32-gcc" ]] || {
		echo "ERROR: the downloaded packages do not contain a working compiler" >&2
		exit 1
	}
fi

export PATH="$mingw_bin:$PATH"
CC=x86_64-w64-mingw32-gcc
AR=x86_64-w64-mingw32-gcc-ar
NM=x86_64-w64-mingw32-nm
OBJCOPY=x86_64-w64-mingw32-objcopy

# The compiler has to target the UCRT, because the prebuilt Windows libraries
# below are UCRT builds and the two C runtimes cannot be mixed in one binary.
probe=$(mktemp -d); trap 'rm -rf -- "$probe"' EXIT
printf 'int main(void){return 0;}\n' > "$probe/probe.c"
$CC "$probe/probe.c" -o "$probe/probe.exe"
if ! x86_64-w64-mingw32-objdump -p "$probe/probe.exe" | grep -qi 'api-ms-win-crt'; then
	echo "ERROR: this MinGW-w64 targets msvcrt, but a UCRT toolchain is required." >&2
	echo "Point MBG_WIN_TOOLCHAIN at a UCRT compiler, or unset it to download one." >&2
	exit 1
fi

# ----------------------------------------------------------------- sysroot ---
if [[ ! -f "$sysroot/lib/libSDL2.a" ]]; then
	echo "Downloading Windows SDL2..."
	staging=$(mktemp -d "$win_dir/.sysroot.XXXXXX")
	archive="$win_dir/download/$sdl2_pkg"
	[[ -f "$archive" ]] || curl -fsSL -o "$archive" "$msys_url/$sdl2_pkg"
	tar -xf "$archive" -C "$staging" --exclude='.*'
	mkdir -p "$sysroot"
	cp -a "$staging/ucrt64/include" "$staging/ucrt64/lib" "$sysroot/"
	rm -rf -- "$staging"
fi
[[ -f "$sysroot/lib/libSDL2.a" ]] || {
	echo "ERROR: libSDL2.a is missing from the Windows sysroot" >&2
	exit 1
}

# ------------------------------------------------------------- OpenAL Soft ---
openal_src="$src_dir/openal-soft-$openal_version"
redist="$win_dir/redist"
mkdir -p "$redist"
if [[ ! -f "$redist/OpenAL32.dll" || ! -f "$prefix/libOpenAL32.dll.a" ]]; then
	if [[ ! -d "$openal_src" ]]; then
		echo "Downloading OpenAL Soft $openal_version..."
		archive="$win_dir/download/openal-soft-$openal_version.tar.bz2"
		[[ -f "$archive" ]] || curl -fsSL -o "$archive" "$openal_url"
		tar -xf "$archive" -C "$src_dir"
	fi
	echo "Building OpenAL32.dll..."
	# The GCC runtime is linked in statically so the DLL needs nothing beside
	# it, and pkg-config is pointed at the sysroot so the host's own audio
	# libraries cannot be picked up for a Windows target.
	MBG_WIN_MINGW_ROOT="$mingw_root" MBG_WIN_SYSROOT="$sysroot" \
	PKG_CONFIG_LIBDIR="$sysroot/lib/pkgconfig" PKG_CONFIG_PATH= \
	cmake -S "$openal_src" -B "$win_dir/obj/openal" -G Ninja \
		-DCMAKE_TOOLCHAIN_FILE="$project_dir/cmake/mingw-w64-toolchain.cmake" \
		-DCMAKE_BUILD_TYPE=Release -DLIBTYPE=SHARED -DALSOFT_BUILD_IMPORT_LIB=ON \
		-DALSOFT_UTILS=OFF -DALSOFT_EXAMPLES=OFF -DALSOFT_TESTS=OFF -DALSOFT_INSTALL=OFF \
		-DCMAKE_SHARED_LINKER_FLAGS="-static -static-libgcc -static-libstdc++" >/dev/null
	cmake --build "$win_dir/obj/openal" -j "$job_count" >/dev/null
	install -m 755 "$win_dir/obj/openal/OpenAL32.dll" "$redist/OpenAL32.dll"
	x86_64-w64-mingw32-strip --strip-unneeded "$redist/OpenAL32.dll"
	cp "$win_dir/obj/openal/libOpenAL32.dll.a" "$prefix/"
fi

# --------------------------------------------------------- patched sources ---
# The MBHaxe HashLink fork is only built with MSVC upstream, so a small set of
# portability fixes is applied to a private copy of it.
if [[ ! -d "$src_dir/hashlink" ]]; then
	echo "Preparing patched HashLink sources..."
	cp -a "$hashlink_src" "$src_dir/hashlink"
	git -C "$src_dir/hashlink" apply "$project_dir/patches/hashlink-mingw.patch"
fi
[[ -d "$src_dir/hxDatachannel" ]] || cp -a "$datachannel_src" "$src_dir/hxDatachannel"

HL="$src_dir/hashlink"
INC="$HL/include"
DC="$src_dir/hxDatachannel"

# LIBHL_STATIC turns HashLink's dllimport/dllexport decorations off so the
# runtime, its native modules and the game can live in a single executable.
export MBG_CC=$CC MBG_SRC_DIR=$src_dir
export MBG_BASE_CFLAGS="-O2 -std=gnu11 -DNDEBUG -march=x86-64 -mtune=generic -w \
	-DLIBHL_STATIC -DUNICODE -D_UNICODE -I$HL/src -I$HL/include"

compile_one() { # source object-directory
	local source=$1 objdir=$2
	local object="$objdir/$(echo "${source#$MBG_SRC_DIR/}" | tr '/' '_').o"
	$MBG_CC $MBG_BASE_CFLAGS $MBG_EXTRA_CFLAGS -c "$source" -o "$object"
}
export -f compile_one

build_static_lib() { # name extra-cflags sources...
	local name=$1; local objdir="$win_dir/obj/$name"
	export MBG_EXTRA_CFLAGS=$2
	shift 2
	rm -rf -- "$objdir"; mkdir -p "$objdir"
	printf '%s\0' "$@" |
		xargs -0 -P "$job_count" -I{} bash -c 'compile_one "$1" "$2"' _ {} "$objdir" ||
		{ echo "ERROR: failed to compile $name" >&2; exit 1; }
	rm -f "$prefix/lib$name.a"
	$AR rcs "$prefix/lib$name.a" "$objdir"/*.o
	echo "  lib$name.a"
}

echo "Building the HashLink runtime..."
libhl_srcs=("$HL/src/gc.c")
for f in array buffer bytes cast date error file fun maps math obj random regexp socket string \
	sys track types ucs2 thread process; do libhl_srcs+=("$HL/src/std/$f.c"); done
for f in auto_possess chartables compile config context convert dfa_match error extuni \
	find_bracket jit_compile maketables match_data match newline ord2utf pattern_info script_run \
	serialize string_utils study substitute substring tables ucd valid_utf xclass; do
	libhl_srcs+=("$INC/pcre/pcre2_$f.c")
done
build_static_lib hl "-DHAVE_CONFIG_H -DPCRE2_CODE_UNIT_WIDTH=16 -I$INC/pcre" "${libhl_srcs[@]}"

echo "Building the HashLink native modules..."
build_static_lib hlui "" "$HL/libs/ui/ui_win.c"

uv_srcs=("$HL/libs/uv/uv.c")
for f in fs-poll inet threadpool uv-common version; do uv_srcs+=("$INC/libuv/src/$f.c"); done
for f in async core dl error fs-event fs getaddrinfo getnameinfo handle loop-watcher pipe poll \
	process-stdio process req signal snprintf stream tcp thread timer tty udp util winapi winsock; do
	uv_srcs+=("$INC/libuv/src/win/$f.c")
done
build_static_lib hluv "-I$INC/libuv/include -I$INC/libuv/src" "${uv_srcs[@]}"

ssl_srcs=("$HL/libs/ssl/ssl.c")
for f in aes aesni arc4 asn1parse asn1write base64 bignum blowfish camellia ccm certs cipher \
	cipher_wrap ctr_drbg debug des dhm ecdh ecdsa ecjpake ecp ecp_curves entropy entropy_poll \
	error gcm havege hmac_drbg md md2 md4 md5 md_wrap memory_buffer_alloc oid padlock pem pk \
	pkcs11 pkcs12 pkcs5 pkparse pkwrite pk_wrap platform ripemd160 rsa rsa_internal sha1 sha256 \
	sha512 ssl_cache ssl_ciphersuites ssl_cli ssl_cookie ssl_srv ssl_ticket ssl_tls threading \
	timing version version_features x509 x509write_crt x509write_csr x509_create x509_crl \
	x509_crt x509_csr xtea; do ssl_srcs+=("$INC/mbedtls/library/$f.c"); done
build_static_lib hlssl "-I$INC/mbedtls/include" "${ssl_srcs[@]}"

fmt_srcs=("$HL/libs/fmt/fmt.c" "$HL/libs/fmt/sha1.c" "$HL/libs/fmt/dxt.c" "$HL/libs/fmt/mikkt.c"
	"$INC/mikktspace/mikktspace.c")
for f in png pngerror pngget pngmem pngpread pngread pngrio pngrtran pngrutil pngset pngtrans \
	pngwio pngwrite pngwtran pngwutil; do fmt_srcs+=("$INC/png/$f.c"); done
# jsimd_none replaces the hand written SIMD kernels, whose only prebuilt form
# here is an MSVC import library.
for f in jaricom jcapimin jcapistd jcarith jccoefct jccolor jcdctmgr jchuff jcinit jcmainct \
	jcmarker jcmaster jcomapi jcparam jcphuff jcprepct jcsample jctrans jdapimin jdapistd jdarith \
	jdatadst-tj jdatadst jdatasrc-tj jdatasrc jdcoefct jdcolor jddctmgr jdhuff jdinput jdmainct \
	jdmarker jdmaster jdmerge jdphuff jdpostct jdsample jdtrans jerror jfdctflt jfdctfst jfdctint \
	jidctflt jidctfst jidctint jidctred jmemmgr jmemnobs jquant1 jquant2 jsimd_none jutils \
	transupp turbojpeg; do fmt_srcs+=("$INC/turbojpeg/$f.c"); done
for f in adler32 crc32 deflate inffast inflate inftrees trees zutil; do fmt_srcs+=("$INC/zlib/$f.c"); done
for f in bitrate bitwise block codebook envelope floor0 floor1 framing info lookup lpc lsp \
	mapping0 mdct psy registry res0 sharedbook smallft synthesis vorbisfile window; do
	fmt_srcs+=("$INC/vorbis/$f.c")
done
build_static_lib hlfmt "-I$INC/zlib -I$INC/png -I$INC/turbojpeg -I$INC/vorbis -I$INC/minimp3 -I$INC/mikktspace" \
	"${fmt_srcs[@]}"

build_static_lib hlsdl "-I$sysroot/include/SDL2 -I$INC/gl" "$HL/libs/sdl/sdl.c" "$HL/libs/sdl/gl.c"
build_static_lib hlopenal "-I$openal_src/include" "$HL/libs/openal/openal.c"

echo "Building libdatachannel..."
export MBG_WIN_MINGW_ROOT="$mingw_root" MBG_WIN_SYSROOT="$sysroot"
cmake -S "$DC/cpp" -B "$win_dir/obj/datachannel" -G Ninja \
	-DCMAKE_TOOLCHAIN_FILE="$project_dir/cmake/mingw-w64-toolchain.cmake" \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS=OFF -DBUILD_SHARED_DEPS_LIBS=OFF \
	-DNO_EXAMPLES=ON -DNO_TESTS=ON \
	-DHASHLINK_INCLUDE_DIR="$HL/src" -DHASHLINK_LIBRARY_DIR="$prefix" >/dev/null
cmake --build "$win_dir/obj/datachannel" --target datachannel-static -j "$job_count" >/dev/null
dc_build="$win_dir/obj/datachannel/libdatachannel"
cp "$dc_build/libdatachannel-static.a" "$dc_build/libMbedTLS.a" \
	"$dc_build/deps/libjuice/libjuice-static.a" \
	"$dc_build/deps/usrsctp/usrsctplib/libusrsctp.a" "$prefix/"

echo "Building the hxDatachannel bindings..."
build_static_lib hldc "-DRTC_STATIC -I$DC/cpp/libdatachannel/include" "$DC/cpp/src/datachannel.c"

# ssl.hdll bundles Mbed TLS 2.7 while libdatachannel bundles Mbed TLS 3.6. In
# separate .hdll libraries each keeps its own copy, but a single executable
# would silently bind one library's calls to the other version's code, so the
# older copy's symbols are renamed out of the way.
#
# Each member of the archive is rewritten on its own. Partial-linking them into
# one object with `ld -r` also works for the renaming, but it mangles the
# per-function .pdata/.xdata associations that PE stack unwinding relies on,
# which leaves the finished game spinning forever the first time anything
# unwinds through this code.
echo "Separating the two bundled Mbed TLS versions..."
work="$win_dir/obj/ssl-isolation"
rm -rf -- "$work"; mkdir -p "$work/members"
(cd "$work/members" && $AR x "$prefix/libhlssl.a")
: > "$work/ssl-symbols.txt"
for member in "$work/members"/*.o; do
	$NM --defined-only --extern-only --format=posix "$member" | awk '{print $1}' >> "$work/ssl-symbols.txt"
done
sort -u -o "$work/ssl-symbols.txt" "$work/ssl-symbols.txt"
$NM --defined-only --extern-only --format=posix "$prefix/libMbedTLS.a" \
	"$prefix/libdatachannel-static.a" "$prefix/libjuice-static.a" "$prefix/libusrsctp.a" |
	awk 'NF>2 {print $1}' | sort -u > "$work/datachannel-symbols.txt"
comm -12 "$work/ssl-symbols.txt" "$work/datachannel-symbols.txt" |
	grep -v '^\.refptr\.' > "$work/shared-symbols.txt"
# The indirect reference stubs GCC emits for data symbols have to be renamed
# along with the symbols they point at.
awk '{print $1" hlssl_"$1"\n.refptr."$1" .refptr.hlssl_"$1}' "$work/shared-symbols.txt" |
	sort -u > "$work/rename-map.txt"
for member in "$work/members"/*.o; do
	$OBJCOPY --redefine-syms="$work/rename-map.txt" "$member"
done
rm -f "$prefix/libhlssl.a"
$AR rcs "$prefix/libhlssl.a" "$work/members"/*.o
if $NM --defined-only --extern-only --format=posix "$prefix/libhlssl.a" |
	awk 'NF>2 {print $1}' | sort -u |
	comm -12 - "$work/datachannel-symbols.txt" | grep -q .; then
	echo "ERROR: Mbed TLS symbols are still shared between ssl.hdll and libdatachannel" >&2
	exit 1
fi

cat > "$win_dir/toolchain.env" <<EOF
# Written by setup-windows-toolchain.sh
MBG_WIN_MINGW_BIN=$mingw_bin
MBG_WIN_SYSROOT=$sysroot
MBG_WIN_LIB=$prefix
MBG_WIN_REDIST=$redist
MBG_WIN_HASHLINK_SRC=$HL
EOF

echo
echo "Windows toolchain ready: $win_dir"
echo "Build the game with ./compile-windows.sh"
