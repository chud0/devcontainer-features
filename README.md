# Dev Container Features

A collection of reusable Dev Container Features.

## OpenCode

Installs OpenCode and keeps its application data persistent across Dev Container rebuilds.

### Features

- Installs [OpenCode](https://opencode.ai/) via npm.
- Installs the required Node.js environment automatically.
- Supports a specific OpenCode version or `latest`.
- Resolves `latest` to a concrete version before installation.
- Verifies that the installed version matches the requested version.
- Stores OpenCode data in a Docker volume scoped to the Dev Container.
- Works with arbitrary Dev Container users without hardcoding `/home/vscode`.
- Verifies the persistent storage after the container is created:
  - mount exists;
  - OpenCode data path points to the expected location;
  - data can be created, written, read, and deleted.

### Usage

Add the Feature to `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/chud0/devcontainer-features/opencode:0.1.0": {
      "opencodeVersion": "1.18.32"
    }
  }
}
```

To install the latest available OpenCode release:

```json
{
  "features": {
    "ghcr.io/chud0/devcontainer-features/opencode:0.1.0": {}
  }
}
```

For reproducible environments, pin a specific OpenCode version instead of using `latest`.

### Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `opencodeVersion` | string | `latest` | OpenCode version to install, without the leading `v`. |

### Node.js dependency

The Feature includes a dependency on the official Dev Containers Node Feature and currently uses Node.js 24.

You do not need to add the Node Feature separately just to use OpenCode.

### Persistent data

OpenCode normally stores its application data under:

```text
~/.local/share/opencode
```

This Feature redirects that path to:

```text
/var/lib/opencode
```

which is backed by a Docker volume named using the Dev Container ID:

```text
opencode-${devcontainerId}
```

This allows authentication data, sessions, and other OpenCode application data to survive container rebuilds while keeping unrelated Dev Containers isolated from each other.

### Existing OpenCode data

The Feature does **not** automatically migrate an existing OpenCode data directory.

If `~/.local/share/opencode` already exists and is not the symlink expected by this Feature, installation stops without modifying the existing data.

Migrate or remove the existing directory manually before rebuilding the Dev Container.

### Storage validation

After the container is created, the Feature verifies that persistent storage is correctly mounted and accessible to the Dev Container user.

The check validates that:

1. `/var/lib/opencode` is a mount point.
2. `~/.local/share/opencode` is a symlink to `/var/lib/opencode`.
3. A temporary file can be created.
4. Data can be written and read back correctly.
5. The temporary file can be removed.

A failed check stops the `postCreateCommand` with an explanatory error.

## Development

Features are located under:

```text
src/<feature-name>/
```

The OpenCode Feature consists of:

```text
src/opencode/
├── devcontainer-feature.json
├── install.sh
└── check-data.sh
```

Publishing to GitHub Container Registry is handled by the repository's GitHub Actions workflow.

Feature versions follow semantic versioning and are defined in `devcontainer-feature.json`.