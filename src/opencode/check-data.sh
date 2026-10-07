#!/usr/bin/env bash
set -e
set -o pipefail

data_root="/var/lib/opencode"
data_link="${HOME}/.local/share/opencode"

if ! mountpoint -q -- "$data_root"; then
    printf 'Error: cannot confirm a mount at %s. Check the Feature mounts configuration.\n' \
        "$data_root" >&2
    exit 1
fi

if [ ! -L "$data_link" ]; then
    printf 'Error: %s must be a symlink pointing to %s.\n' \
        "$data_link" "$data_root" >&2
    exit 1
fi

if ! actual_target="$(readlink -- "$data_link")"; then
    printf 'Error: cannot read symlink %s.\n' \
        "$data_link" >&2
    exit 1
fi

if [ "$actual_target" != "$data_root" ]; then
    printf 'Error: %s points to %s; expected %s.\n' \
        "$data_link" "$actual_target" "$data_root" >&2
    exit 1
fi

if ! test_file="$(mktemp -- "$data_link/.write-test.XXXXXX")"; then
    printf 'Error: cannot create a test file in %s.\n' \
        "$data_link" >&2
    exit 1
fi

trap 'rm -f -- "$test_file"' EXIT

if ! printf '%s\n' 'opencode-data-check' > "$test_file"; then
    printf 'Error: cannot write to test file %s.\n' \
        "$test_file" >&2
    exit 1
fi

if ! actual_text="$(cat -- "$test_file")"; then
    printf 'Error: cannot read test file %s.\n' \
        "$test_file" >&2
    exit 1
fi

if [ "$actual_text" != "opencode-data-check" ]; then
    printf 'Error: invalid content of text file %s, expected %s, received %s.\n' \
        "$test_file" "opencode-data-check" "$actual_text" >&2
    exit 1
fi

if ! rm -- "$test_file"; then
    printf 'Error: cannot remove test file %s.\n' \
        "$test_file" >&2
    exit 1
fi

printf 'OpenCode data check passed: user=%s, path=%s\n' \
    "$(id -un)" "$data_link"

if ! paths_output="$(opencode debug paths)"; then
    printf '%s\n' \
        'Error: unable to obtain OpenCode paths.' >&2
    exit 1
fi

opencode_tmp="$(
    printf '%s\n' "$paths_output" |
        sed -n 's/^tmp[[:space:]]*//p'
)"

if [ -z "$opencode_tmp" ]; then
    printf '%s\n' \
        'Error: OpenCode did not report its temporary directory.' >&2
    exit 1
fi

if ! tmp_test_file="$(
    mktemp -- "$opencode_tmp/.write-test.XXXXXX"
)"; then
    printf 'Error: OpenCode temporary directory is not writable: %s\n' \
        "$opencode_tmp" >&2
    exit 1
fi

if ! rm -- "$tmp_test_file"; then
    printf 'Error: cannot remove OpenCode temporary test file %s\n' \
        "$tmp_test_file" >&2
    exit 1
fi

printf 'OpenCode temporary directory check passed: user=%s, path=%s\n' \
    "$(id -un)" "$opencode_tmp"