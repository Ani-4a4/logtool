# logtool.sh

A Bash tool that scans a directory of .log files 
and prints summaries.

## Log format

Each valid log entry is a single line of `key=value` fields:

<timestamp> host=<host> service=<service> level=<LEVEL> event=<EVENT> user=<user> ip=<ip> msg="<message>"


- `level` is one of `ERROR`, `WARN`, `INFO`.
- `user` and `ip` may be `-` when not applicable.
- Lines beginning with `#` comments and blank lines are ignored.
- Only files ending in .log are scanned and other files are skipped.

## Usage

./logtool.sh <command> [arguments]


 Command 
| `--help` == Show the list of commands. |
| `summary <log_dir>` == Print `FILES_SCANNED`, `LINES_PROCESSED` and per-level counts. 
| `services <log_dir>` ==  Count entries by service as `<service> <count>`. 
| `failed-logins <log_dir>` == Count failed logins by user (ignores `user=-`). 
| `report <log_dir> <output_file>` == Write a plain-text report to a file. 
| `top-events <log_dir> [N]` == Print the N most frequent event labels (default N=3). 

Counts are sorted by count (descending), then by name (ascending).
Invalid input (missing arguments, a non-existent directory, a non-numeric N,
an unknown command) prints an error to stderr and exits with a non-zero status.


## Running the tests

./tests/run_tests.sh


This checks all commands against saved expected output for three categories:
normal cases (the provided `logs/`), edge cases (custom fixtures under
`tests/edge` and `tests/empty`), and invalid input cases. It prints `PASS`/`FAIL`
per check and exits nonzero if any fail.

## Repo structure

logtool.sh The tool
A1_example_logs/ Example log dataset
tests/ Test runner, expected outputs, and custom fixtures
README.md This file
.gitignore