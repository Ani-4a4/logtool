set -u

cd "$(dirname "$0")/.." || exit 1

tool=./logtool.sh
status=0

check() {
    name=$1
    expected=$2
    shift 2
    actual=$("$@")
    if [ "$actual" = "$(cat "tests/$expected")" ]; then
        echo "PASS: $name"
    else
        echo "FAIL: $name"
        echo "  --- expected ---"; cat "tests/$expected"
        echo "  --- actual ---";   echo "$actual"
        status=1
    fi
}

check_fails() {
    name=$1
    shift
    if "$@" >/dev/null 2>&1; then
        echo "FAIL: $name (expected non-zero exit)"
        status=1
    else
        echo "PASS: $name"
    fi
}

echo "# Normal cases"
check "summary"       expected_summary.txt       "$tool" summary logs
check "services"      expected_services.txt      "$tool" services logs
check "failed-logins" expected_failed_logins.txt "$tool" failed-logins logs
check "top-events"    expected_top_events.txt    "$tool" top-events logs

echo
echo "# Edge cases"
check "edge summary"       expected_edge_summary.txt       "$tool" summary tests/edge
check "edge services"      expected_edge_services.txt      "$tool" services tests/edge
check "edge failed-logins" expected_edge_failed_logins.txt "$tool" failed-logins tests/edge
check "edge top-events"    expected_edge_top_events.txt    "$tool" top-events tests/edge
check "empty summary"      expected_empty_summary.txt      "$tool" summary tests/empty

echo
echo "# Invalid-input cases"
check_fails "no such directory"     "$tool" summary /no/such/dir
check_fails "missing argument"      "$tool" summary
check_fails "non-numeric N"         "$tool" top-events logs abc
check_fails "unknown command"       "$tool" bogus
check_fails "report missing output" "$tool" report logs

echo
echo "# report file output"
"$tool" report logs tests/report_actual.txt
if [ "$(cat tests/report_actual.txt)" = "$(cat tests/expected_report.txt)" ]; then
    echo "PASS: report"
else
    echo "FAIL: report"
    status=1
fi
rm -f tests/report_actual.txt

echo
if [ "$status" -eq 0 ]; then echo "All tests passed."; else echo "Some tests failed."; fi
exit $status