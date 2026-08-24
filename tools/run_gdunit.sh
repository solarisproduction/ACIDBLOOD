#!/bin/bash

# ACIDBLOOD-owned GdUnit4 integration.
# GdUnit4 6.2.1's vendored runtest.sh adds --remote-debug tcp://127.0.0.1:0,
# which Godot 4.7 rejects before the command tool starts. Invoke the supported
# command tool directly and keep the third-party addon unchanged.

set -u

godot_binary="${GODOT_BIN:-${GODOT:-}}"
user_data_dir="${ACIDBLOOD_GDUNIT_USER_DIR:-/private/tmp/acidblood-gdunit-user}"
log_file="${ACIDBLOOD_GDUNIT_LOG:-/private/tmp/acidblood-gdunit.log}"
runner_args=()

while [ $# -gt 0 ]; do
	if [ "$1" = "--godot_binary" ] && [ $# -gt 1 ]; then
		godot_binary="$2"
		shift 2
	else
		runner_args+=("$1")
		shift
	fi
done

if [ -z "$godot_binary" ]; then
	echo "Godot binary path is not specified."
	echo "Set GODOT_BIN/GODOT or pass --godot_binary /path/to/godot."
	exit 1
fi

if [ ! -x "$godot_binary" ]; then
	echo "Error: Godot binary '$godot_binary' does not exist or is not executable."
	exit 1
fi

mkdir -p "$user_data_dir"

"$godot_binary" --headless --log-file "$log_file" --user-data-dir "$user_data_dir" --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd "${runner_args[@]}"
test_exit_code=$?
echo "Run tests ends with $test_exit_code"

# Preserve the vendored runner's report log copy step.
"$godot_binary" --headless --log-file "$log_file" --user-data-dir "$user_data_dir" --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd "${runner_args[@]}" > /dev/null
exit "$test_exit_code"
