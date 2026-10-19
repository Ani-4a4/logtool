# logtool.sh

A Bash command-line tool that scans a directory of structured log files
and summarises them: entries per severity level, entries per service,
failed logins per user, the most frequent events, and a combined
plain-text report.

It answers the first questions you ask when reviewing logs for
suspicious activity: which accounts are failing to log in, which
services are producing errors, and what is happening most often.

Built with standard Unix tools (`find`, `grep`, `sort`, `uniq`, `sed`)
and covered by an automated test suite.

## Example

```text
$ ./logtool.sh failed-logins logs
alice 3
dave 2
bob 1
erin 1

$ ./logtool.sh top-events logs 3
FAILED_LOGIN 7
HTTP_500 7
DEVICE_OK 6
```

## Commands

| Command | What it does |
| --- | --- |
| `--help` | Lists the commands |
| `summary <log_dir>` | Prints `FILES_SCANNED`, `LINES_PROCESSED` and the count for each level |
| `services <log_dir>` | Counts entries per service |
| `failed-logins <log_dir>` | Counts `FAILED_LOGIN` events per user, ignoring `user=-` |
| `top-events <log_dir> [N]` | Prints the N most frequent events (default 3) |
| `report <log_dir> <output_file>` | Writes all of the above to a single report file |

Counts are sorted by count (highest first), then by name.

## Log format

Each entry is one line of `key=value` fields:

```text
<timestamp> host=<host> service=<service> level=<LEVEL> event=<EVENT> user=<user> ip=<ip> msg="<message>"
```

- `level` is `ERROR`, `WARN` or `INFO`.
- `user` and `ip` may be `-` when not applicable.
- Lines starting with `#` and blank lines are ignored.
- Only files ending in `.log` are scanned, including in subdirectories.

## Error handling

Invalid input prints a message to stderr and exits with a non-zero
status. This covers a missing argument, a directory that doesn't exist,
an unknown command, an `N` that isn't a positive integer, and a report
file that can't be written.

## Running the tests

```bash
./tests/run_tests.sh
```

The runner compares each command's output with saved expected output
and prints `PASS` or `FAIL` for each check. It covers:

- **Normal cases** using the sample logs in `logs/`.
- **Edge cases** in `tests/edge/` and `tests/empty/`: comment lines,
  blank lines, entries with `user=-`, a file whose last line has no
  trailing newline, and an empty log file.
- **Invalid input**, which must exit with a non-zero status.

It exits with a non-zero status if any check fails.

## How it works

- `find` locates every `.log` file; `grep` then drops comments and blank
  lines. Reading files through `grep`, rather than joining them with
  `cat`, keeps a file without a final newline from merging its last
  line into the next file's first line.
- Fields are extracted with `grep -o`, counted with `sort | uniq -c`,
  and sorted by count, then name.
- The script runs with `set -u` and `set -o pipefail` so that unset
  variables and failures inside pipelines aren't silently ignored.

## Known limitations

- A field name inside a quoted `msg` (for example
  `msg="retry service=x"`) is counted as if it were a real field.
- Field values can't contain spaces.

## Project structure

```text
logtool.sh          The tool
logs/               Sample log dataset, including a non-.log file that must be skipped
tests/run_tests.sh  Test runner
tests/edge/         Edge-case fixtures
tests/empty/        Empty-log fixture
tests/expected_*    Expected output for each test
```

## Background

Originally built as a university coursework project. The sample logs in
`logs/` were supplied with the assignment; the tool, edge-case fixtures
and test suite are my own work.
