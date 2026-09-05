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

cmd=${1:-}

if [ "$cmd" = "--help" ]; then
    usage
    exit 0
elif [ "$cmd" = "summary" ]; then
    err "Not implemented yet"
    exit 1
elif [ "$cmd" = "services" ]; then
    err "Not implemented yet"
    exit 1
elif [ "$cmd" = "failed-logins" ]; then
    err "Not implemented yet"
    exit 1
elif [ "$cmd" = "report" ]; then
    err "Not implemented yet"
    exit 1
elif [ "$cmd" = "" ]; then
    err "no command given (try: ./logtool.sh --help)"
    exit 1
else
    err "unknown command: $cmd (try: ./logtool.sh --help)"
    exit 1
fi