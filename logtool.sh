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
else
    err "unknown command: $cmd (try: ./logtool.sh --help)"
    usage >&2
    exit 1
fi