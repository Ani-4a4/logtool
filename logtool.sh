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

count_field() {
    dir=$1
    field=$2
    find "$dir" -type f -name '*.log' -exec grep -hoE "$field=[^ ]+" {} + |
        sort |
        uniq -c |
        sort -k1,1nr -k2,2 |
        while read count kv; do
            echo "${kv#*=} $count"
        done
}

summary() {
    need_dir "$@"
    dir=$1

    files_scanned=$(log_files "$dir" | grep -c .)
    lines_processed=$(find "$dir" -type f -name '*.log' -exec cat {} + |
        grep -vE '^[[:space:]]*#' |
        grep -vE '^[[:space:]]*$' |
        grep -c .)

    echo "FILES_SCANNED=$files_scanned"
    echo "LINES_PROCESSED=$lines_processed"

    for level in ERROR WARN INFO; do
        count=$(find "$dir" -type f -name '*.log' -exec grep -hoE "level=$level" {} + |
            grep -c .)
        echo "$level=$count"
    done
}

services() {
    need_dir "$@"
    count_field "$1" service
}

failed_logins() {
    need_dir "$@"
    dir=$1
    find "$dir" -type f -name '*.log' -exec grep -hE 'event=FAILED_LOGIN' {} + |
        grep -oE 'user=[^ ]+' |
        grep -vE '^user=-$' |
        sort |
        uniq -c |
        sort -k1,1nr -k2,2 |
        while read count kv; do
            echo "${kv#*=} $count"
        done
}

report() {
    if [ "$#" -lt 2 ]; then
        err "usage: report <log_dir> <output_file>"
        exit 1
    fi
    need_dir "$1"
    dir=$1
    out=$2

    {
        echo "=== Log Report ==="
        echo "[Overview]"
        echo "Files scanned: $(log_files "$dir" | grep -c .)"
        echo "Lines processed: $(find "$dir" -type f -name '*.log' -exec cat {} + |
            grep -vE '^[[:space:]]*#' |
            grep -vE '^[[:space:]]*$' |
            grep -c .)"
        echo "[COUNTS BY LEVEL]"
        for level in ERROR WARN INFO; do
            count=$(find "$dir" -type f -name '*.log' -exec grep -hoE "level=$level" {} + |
                grep -c .)
            echo "$level $count"
        done
        echo "[COUNTS BY SERVICE]"
        count_field "$dir" service
        echo "[FAILED LOGIN USERS]"
        failed_logins "$dir"
    } > "$out"
}

top_events() {
    need_dir "$@"
    dir=$1
    n=${2:-3}
    if ! echo "$n" | grep -qE '^[0-9]+$'; then
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