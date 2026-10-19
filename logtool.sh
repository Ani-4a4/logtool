#!/usr/bin/env bash
set -u
set -o pipefail

err() {
    echo "logtool: $1" >&2
}

usage() {
    echo "Commands:"
    echo "  --help"
    echo "      Show this help message"
    echo "  summary <log_dir>"
    echo "      Print summary counts for the log directory"
    echo "  services <log_dir>"
    echo "      Print counts by service"
    echo "  failed-logins <log_dir>"
    echo "      Print failed login counts by user"
    echo "  report <log_dir> <output_file>"
    echo "      Generate a consolidated plain-text report"
    echo "  top-events <log_dir> [N]"
    echo "      Print the most frequent event labels (default N=3)"
}

need_dir() {
    if [ "$#" -eq 0 ]; then
        err "missing <log_dir> argument"
        exit 1
    fi
    if [ ! -d "$1" ]; then
        err "no such directory: $1"
        exit 1
    fi
}

log_files() {
    find "$1" -type f -name '*.log'
}

# Print every log entry (non-comment, non-blank line) from all .log files.
# grep reads each file separately, so a file whose last line has no
# trailing newline is never merged with the first line of the next file.
entries() {
    find "$1" -type f -name '*.log' -exec grep -hvE '^[[:space:]]*(#|$)' {} +
}

count_lines() {
    entries "$1" | grep -c .
}

count_level() {
    entries "$1" | grep -cE "(^| )level=$2( |$)"
}

count_field() {
    local dir=$1
    local field=$2
    local count kv
    entries "$dir" | grep -oE "(^| )$field=[^ ]+" | sed 's/^ //' |
        sort |
        uniq -c |
        sort -k1,1nr -k2,2 |
        while read -r count kv; do
            echo "${kv#*=} $count"
        done
}

summary() {
    need_dir "$@"
    local dir=$1 level

    echo "FILES_SCANNED=$(log_files "$dir" | grep -c .)"
    echo "LINES_PROCESSED=$(count_lines "$dir")"

    for level in ERROR WARN INFO; do
        echo "$level=$(count_level "$dir" "$level")"
    done
}

services() {
    need_dir "$@"
    count_field "$1" service
}

failed_logins() {
    need_dir "$@"
    local dir=$1
    local count kv
    entries "$dir" | grep -E '(^| )event=FAILED_LOGIN( |$)' |
        grep -oE '(^| )user=[^ ]+' | sed 's/^ //' |
        grep -vE '^user=-$' |
        sort |
        uniq -c |
        sort -k1,1nr -k2,2 |
        while read -r count kv; do
            echo "${kv#*=} $count"
        done
}

report() {
    if [ "$#" -lt 2 ]; then
        err "usage: report <log_dir> <output_file>"
        exit 1
    fi
    need_dir "$1"
    local dir=$1
    local out=$2
    local level

    # Check the output file can be written before building the report
    if ! : 2>/dev/null > "$out"; then
        err "cannot write report to: $out"
        exit 1
    fi

    {
        echo "=== Log Report ==="
        echo "[Overview]"
        echo "Files scanned: $(log_files "$dir" | grep -c .)"
        echo "Lines processed: $(count_lines "$dir")"
        echo "[COUNTS BY LEVEL]"
        for level in ERROR WARN INFO; do
            echo "$level $(count_level "$dir" "$level")"
        done
        echo "[COUNTS BY SERVICE]"
        count_field "$dir" service
        echo "[FAILED LOGIN USERS]"
        failed_logins "$dir"
    } > "$out"
}

top_events() {
    need_dir "$@"
    local dir=$1
    local n=${2:-3}
    if ! echo "$n" | grep -qE '^[1-9][0-9]*$'; then
        err "N needs to be a positive integer"
        exit 1
    fi
    count_field "$dir" event | head -n "$n"
}

cmd=${1:-}

if [ "$cmd" = "--help" ]; then
    usage
    exit 0
elif [ "$cmd" = "summary" ]; then
    summary "${@:2}"
    exit 0
elif [ "$cmd" = "services" ]; then
    services "${@:2}"
    exit 0
elif [ "$cmd" = "failed-logins" ]; then
    failed_logins "${@:2}"
    exit 0
elif [ "$cmd" = "report" ]; then
    report "${@:2}"
    exit 0
elif [ "$cmd" = "top-events" ]; then
    top_events "${@:2}"
    exit 0
elif [ "$cmd" = "" ]; then
    err "no command given (try: ./logtool.sh --help)"
    exit 1
else
    err "unknown command: $cmd (try: ./logtool.sh --help)"
    exit 1
fi