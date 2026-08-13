#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
binary=${MBG_BINARY:-$project_dir/marblegame}
library_dir=${MBG_LIBRARY_DIR:-${MBHAXE_TOOLCHAIN:-/home/cachy/mbhaxe-toolchain}/prefix/lib}
requested_dist_dir=${MBG_DIST_DIR:-$project_dir/dist/MBHaxe-Gold-Linux}

case "$requested_dist_dir" in
	""|/) echo "ERROR: refusing unsafe output directory: ${requested_dist_dir:-<empty>}" >&2; exit 1 ;;
esac

for command in readelf patchelf file ldd ldconfig realpath; do
	command -v "$command" >/dev/null || {
		echo "ERROR: $command is required to create a portable Linux build" >&2
		exit 1
	}
done

[[ -x "$binary" ]] || {
	echo "ERROR: Linux executable not found: $binary" >&2
	exit 1
}
[[ -d "$library_dir" ]] || {
	echo "ERROR: native library directory not found: $library_dir" >&2
	exit 1
}

# These are supplied by the Linux ABI or the host's graphics stack. Bundling the
# graphics loader can prevent the application from finding the user's GPU driver.
is_host_library() {
	case "$1" in
		linux-vdso.so.*|ld-linux*.so.*|libc.so.*|libm.so.*|libmvec.so.*|libdl.so.*|libpthread.so.*|librt.so.*|libresolv.so.*|libnss_*.so.*|libutil.so.*) return 0 ;;
		libGL*.so.*|libEGL*.so.*|libGLES*.so.*|libOpenGL*.so.*|libX*.so.*|libxcb*.so.*|libwayland*.so.*|libdrm*.so.*|libgbm.so.*|libvulkan.so.*) return 0 ;;
		*) return 1 ;;
	esac
}

needed_libraries() {
	readelf -d "$1" 2>/dev/null | sed -n 's/.*Shared library: \[\([^]]*\)\].*/\1/p'
}

require_baseline_x86_64() {
	local object=$1 properties
	properties=$(readelf -n "$object" 2>/dev/null || true)
	if grep -Eq 'x86 ISA needed:.*x86-64-v[234]' <<<"$properties"; then
		echo "ERROR: $(basename "$object") requires newer-than-baseline x86-64 instructions:" >&2
		grep 'x86 ISA needed:' <<<"$properties" >&2
		echo "Build releases in the Steam Linux Runtime container/CI, not on an x86-64-v3 host distribution." >&2
		exit 1
	fi
}

resolve_library() {
	local object=$1 soname=$2 resolved

	if [[ -f "$library_dir/$soname" ]]; then
		realpath "$library_dir/$soname"
		return
	fi

	resolved=$(LD_LIBRARY_PATH="$dist_dir:$library_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		ldd "$object" 2>/dev/null | awk -v name="$soname" '$1 == name && $2 == "=>" && $3 ~ /^\// { print $3; exit }')
	if [[ -n "$resolved" && -f "$resolved" ]]; then
		realpath "$resolved"
		return
	fi

	ldconfig -p 2>/dev/null | awk -v name="$soname" '$1 == name { print $NF; exit }'
}

dist_parent=$(dirname -- "$requested_dist_dir")
dist_name=$(basename -- "$requested_dist_dir")
mkdir -p -- "$dist_parent"
dist_parent=$(cd -- "$dist_parent" && pwd)
requested_dist_dir="$dist_parent/$dist_name"
stage_dir=$(mktemp -d "$dist_parent/.mbg-package.XXXXXX")
trap 'rm -rf -- "$stage_dir"' EXIT
dist_dir="$stage_dir/$dist_name"
mkdir -p -- "$dist_dir"
install -m 755 "$binary" "$dist_dir/marblegame"
cp -a "$project_dir/data" "$dist_dir/data"

declare -a queue=("$dist_dir/marblegame")
declare -A inspected=()

while ((${#queue[@]})); do
	object=${queue[0]}
	queue=("${queue[@]:1}")
	[[ -z ${inspected[$object]+x} ]] || continue
	inspected[$object]=1

	while IFS= read -r soname; do
		[[ -n "$soname" ]] || continue
		is_host_library "$soname" && continue

		target="$dist_dir/$soname"
		if [[ ! -f "$target" ]]; then
			source=$(resolve_library "$object" "$soname")
			[[ -n "$source" && -f "$source" ]] || {
				echo "ERROR: could not bundle $soname (required by $(basename "$object"))" >&2
				exit 1
			}
			install -m 755 "$source" "$target"
		fi
		queue+=("$target")
	done < <(needed_libraries "$object")
done

# GNU_PROPERTY_X86_ISA_1_NEEDED is the CPU floor, unlike ISA_1_USED, which can
# describe safe runtime-dispatched implementations. Reject v2+ requirements so
# a release made on an optimized distro cannot SIGILL on an older x86-64 CPU.
while IFS= read -r elf; do
	require_baseline_x86_64 "$elf"
done < <(find "$dist_dir" -maxdepth 1 -type f -print0 | xargs -0 file | awk -F: '/ELF/ { print $1 }')

while IFS= read -r elf; do
	patchelf --set-rpath '$ORIGIN' "$elf"
done < <(find "$dist_dir" -maxdepth 1 -type f -print0 | xargs -0 file | awk -F: '/ELF/ { print $1 }')

cat > "$dist_dir/run-mbg.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export LD_LIBRARY_PATH="$DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
cd "$DIR"
exec "$DIR/marblegame" "$@"
EOF
chmod +x "$dist_dir/run-mbg.sh"

cat > "$dist_dir/run-mbg-steam-deck.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export LD_LIBRARY_PATH="$DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export ALSOFT_DRIVERS="pulse,alsa"
export SDL_AUDIODRIVER="pulse"
cd "$DIR"
exec "$DIR/marblegame" "$@"
EOF
chmod +x "$dist_dir/run-mbg-steam-deck.sh"

# Validate every ELF in the finished directory, not only the main executable.
missing=0
while IFS= read -r elf; do
	while IFS= read -r soname; do
		is_host_library "$soname" && continue
		if [[ ! -f "$dist_dir/$soname" ]]; then
			echo "ERROR: $soname required by $(basename "$elf") is absent from the bundle" >&2
			missing=1
		fi
	done < <(needed_libraries "$elf")
done < <(find "$dist_dir" -maxdepth 1 -type f -print0 | xargs -0 file | awk -F: '/ELF/ { print $1 }')
((missing == 0)) || exit 1

if LD_LIBRARY_PATH="$dist_dir" ldd "$dist_dir/marblegame" | grep -q 'not found'; then
	echo "ERROR: portable build still has unresolved shared libraries" >&2
	LD_LIBRARY_PATH="$dist_dir" ldd "$dist_dir/marblegame" >&2
	exit 1
fi

rm -rf -- "$requested_dist_dir"
mv -- "$dist_dir" "$requested_dist_dir"
rmdir -- "$stage_dir"
trap - EXIT

echo "Portable Linux build created: $requested_dist_dir"
