#!/usr/bin/env bash
set -e
set -o pipefail

requested_version="${OPENCODEVERSION:?Error: Version is required}"

remote_user="${_REMOTE_USER:?Remote user is required}"
remote_home="${_REMOTE_USER_HOME:?Remote user home is required}"
remote_group="$(id -gn "$remote_user")"

data_root="/var/lib/opencode"
data_link="$remote_home/.local/share/opencode"

install -D -o root -g root -m 0755 \
    ./check-data.sh \
    /usr/local/bin/opencode-check-data

install -d -m 0700 \
    -o "$remote_user" \
    -g "$remote_group" \
    "$data_root"

runuser -u "$remote_user" -- \
    mkdir -p -- "$remote_home/.local/share"

if [ -L "$data_link" ]; then
    actual_target="$(readlink -- "$data_link")"

    if [ "$actual_target" != "$data_root" ]; then
        printf 'Error: %s points to %s; expected %s. Existing link left unchanged.\n' \
            "$data_link" "$actual_target" "$data_root" >&2
        exit 1
    fi

elif [ -e "$data_link" ]; then
    printf 'Error: %s already exists and is not a symlink. Prepare this path manually and retry.\n' \
        "$data_link" >&2
    exit 1

else
    runuser -u "$remote_user" -- \
        ln -sT -- "$data_root" "$data_link"
fi


if [ "$requested_version" = "latest" ]; then
    echo "Requested 'latest' OpenCode version. Resolve latest version"
    if ! requested_version="$(npm view opencode-ai@latest version)"; then
        printf '%s\n' \
            'Error: Unable to determine OpenCode version in npm' >&2
        exit 1
    fi

    if [ -z "$requested_version" ]; then
        printf '%s\n' \
            'Error: npm returned an empty OpenCode version' >&2
        exit 1
    fi
    echo "Latest OpenCode version: ${requested_version}"
fi

echo "Installing opencode, version: ${requested_version}."
npm install --global --allow-scripts=opencode-ai "opencode-ai@${requested_version}"

installed_version="$(opencode --version)"
echo "Opencode installed, version: ${installed_version}."

if [ "$installed_version" != "$requested_version" ]; then
    printf 'Error: requested version: %s, but installed version: %s.\n' \
        "$requested_version" "$installed_version" >&2
    exit 1
fi

if ! paths_output="$(opencode debug paths)"; then
    printf '%s\n' \
        'Error: unable to obtain OpenCode paths.' >&2
    exit 1
fi

opencode_tmp="$(
    printf '%s\n' "$paths_output" |
        sed -n 's/^tmp[[:space:]]*//p'
)"

if [ -L "$opencode_tmp" ] || {
    [ -e "$opencode_tmp" ] && [ ! -d "$opencode_tmp" ]
}; then
    printf 'Error: OpenCode temporary path is not a directory: %s\n' \
        "$opencode_tmp" >&2
    exit 1
fi

mkdir -p -- "$opencode_tmp"

chown -R -- \
    "$remote_user:$remote_group" \
    "$opencode_tmp"

chmod 0700 -- "$opencode_tmp"