#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] <source_dir> <dest_dir>

Scan all ELF binaries in source_dir with ldd, find dynamic library
dependencies, classify them, and copy into dest_dir.

Arguments:
  source_dir    Directory to scan recursively for ELF binaries
  dest_dir      Target directory where missing libraries are copied

Options:
  -s, --include-system  Also copy system libraries (/lib*, /usr/lib*)
  -l, --log-file PATH   Log file path (default: <dest_dir>/ldd-install.log)
  -h, --help            Show this help message

Environment variables:
  LDD_INCLUDE_SYSTEM    Set to 1 to include system libraries (same as -s)
  LDD_LOG_FILE          Log file path (same as -l)

Library classification:
  [OPENGL]    OpenGL/EGL/GLES/gbm/drm related libraries
  [SYSTEM]    System libraries from /lib*, /usr/lib*
  [OTHER]     Other non-system libraries

Examples:
  $(basename "$0") ./build/install/lib ./build/install/lib
  $(basename "$0") -s -l /tmp/deploy.log ./build/install/lib ./build/install/lib
EOF
    exit 1
}

# ---- arg parsing ----
INCLUDE_SYSTEM=false
LOG_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--include-system) INCLUDE_SYSTEM=true; shift ;;
        -l|--log-file) LOG_FILE="$2"; shift 2 ;;
        -h|--help) usage ;;
        --) shift; break ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            ;;
        *) break ;;
    esac
done

[[ $# -lt 2 ]] && usage

SRC_DIR="$1"
DST_DIR="$2"

[[ -d "$SRC_DIR" ]] || { echo "Error: source_dir '$SRC_DIR' not found" >&2; exit 1; }
mkdir -p "$DST_DIR"

# ---- env override ----
[[ "${LDD_INCLUDE_SYSTEM:-}" == "1" ]] && INCLUDE_SYSTEM=true
[[ -z "$LOG_FILE" && -n "${LDD_LOG_FILE:-}" ]] && LOG_FILE="$LDD_LOG_FILE"
[[ -z "$LOG_FILE" ]] && LOG_FILE="${DST_DIR}/ldd-install.log"

# ---- log setup ----
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
exec 3>&1
exec > >(tee "$LOG_FILE") 2>&1

echo "============================================"
echo " ldd_install.sh - Dependency Collector"
echo " Timestamp   : $TIMESTAMP"
echo " Source dir  : $SRC_DIR"
echo " Dest dir    : $DST_DIR"
echo " Include sys : $INCLUDE_SYSTEM"
echo " Log file    : $LOG_FILE"
echo "============================================"
echo ""

# ---- classification helpers ----
is_opengl() {
    local name="$1"
    # Match known OpenGL/EGL/GLES/gbm/drm libraries
    [[ "$name" == libGL* || "$name" == libEGL* || "$name" == libGLES* \
    || "$name" == libglapi* || "$name" == libdrm* || "$name" == libgbm* \
    || "$name" == libX11* || "$name" == libXext* || "$name" == libxcb* ]]
}

is_system_path() {
    local path="$1"
    [[ "$path" == /lib* || "$path" == /usr/lib* ]]
}

classify() {
    local path="$1"
    local name
    name=$(basename "$path")
    if is_opengl "$name"; then
        echo "OPENGL"
    elif is_system_path "$path"; then
        echo "SYSTEM"
    else
        echo "OTHER"
    fi
}

# ---- counters ----
declare -A SEEN
declare -A CAT_COUNT
CAT_COUNT[OPENGL]=0
CAT_COUNT[SYSTEM]=0
CAT_COUNT[OTHER]=0
MISSING=false
TOTAL_COPIED=0
WARN_SYSTEM=false

# ---- main scan ----
while IFS= read -r -d '' f; do
    file "$f" | grep -q ELF || continue
    echo "--- scanning: $f"

    while IFS= read -r line; do
        # missing library
        if [[ "$line" =~ not\ found ]]; then
            lib=$(echo "$line" | awk '{print $1}')
            echo "  [MISSING] $lib  *** NOT FOUND ON SYSTEM ***"
            MISSING=true
            continue
        fi

        # resolved library:  libname => /path/to/lib.so (0x...)
        re_lib='^[[:space:]]*(.+)[[:space:]]=>[[:space:]]+(.+)[[:space:]]\(0x'
        if [[ "$line" =~ $re_lib ]]; then
            libname="${BASH_REMATCH[1]}"
            libpath="${BASH_REMATCH[2]}"
            libpath="${libpath## }"
            libpath="${libpath%% }"
        else
            continue
        fi

        # skip linux-vdso, ld-linux (these are kernel/vdso, not real files)
        [[ "$libname" == linux-vdso* ]] && continue
        [[ "$libpath" == linux-vdso* ]] && continue

        file_basename=$(basename "$libpath")
        [[ -n "${SEEN[$file_basename]:-}" ]] && continue
        SEEN["$file_basename"]=1

        cat=$(classify "$libpath")
        CAT_COUNT[$cat]=$((CAT_COUNT[$cat] + 1))

        case "$cat" in
            OPENGL)
                echo "  [OPENGL]  $libpath"
                cp -n "$libpath" "$DST_DIR/" 2>/dev/null || true
                TOTAL_COPIED=$((TOTAL_COPIED + 1))
                ;;
            SYSTEM)
                if $INCLUDE_SYSTEM; then
                    echo "  [SYSTEM]  $libpath  (packaged - may cause conflicts on other servers)"
                    cp -n "$libpath" "$DST_DIR/" 2>/dev/null || true
                    TOTAL_COPIED=$((TOTAL_COPIED + 1))
                    WARN_SYSTEM=true
                else
                    echo "  [SYSTEM]  $libpath  (skipped)"
                fi
                ;;
            OTHER)
                echo "  [OTHER]   $libpath"
                cp -n "$libpath" "$DST_DIR/" 2>/dev/null || true
                TOTAL_COPIED=$((TOTAL_COPIED + 1))
                ;;
        esac
    done < <(ldd "$f" 2>/dev/null || true)
done < <(find "$SRC_DIR" -type f -print0)

# ---- summary ----
echo ""
echo "============================================"
echo " Summary"
echo "============================================"
echo "  OPENGL : ${CAT_COUNT[OPENGL]} libraries"
echo "  SYSTEM : ${CAT_COUNT[SYSTEM]} libraries"
echo "  OTHER  : ${CAT_COUNT[OTHER]} libraries"
echo "  Copied : $TOTAL_COPIED libraries to $DST_DIR"
echo "============================================"

$MISSING && echo "WARNING: some libraries were NOT FOUND on the system (see [MISSING] above)." >&2

if $WARN_SYSTEM; then
    echo "WARNING: system libraries have been packaged. These may cause ABI conflicts on" >&2
    echo "         target servers with different OS versions. Review the [SYSTEM] entries" >&2
    echo "         in the log above and consider removing them if unnecessary." >&2
fi

echo "Detailed log written to: $LOG_FILE"