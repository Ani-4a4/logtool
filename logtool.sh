if [ "$1" = "--help" ]; then
    echo "Commands:"
    echo "  --help    Show this help message"
    exit 0
fi

echo "logtool: unknown command" >&2
exit 1