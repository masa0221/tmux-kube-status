# kube_status.tmux

`kube_status.tmux` is a Tmux plugin that displays your current Kubernetes context and environment (dev, test, staging, prod) in the Tmux status line. It's recommended to manage the installation of this plugin using [tmux-plugin-manager (TPM)](https://github.com/tmux-plugins/tpm).

## Installation

### Recommended Method: Using tmux-plugin-manager (TPM)

1. Add this line to your `.tmux.conf`:

```bash
set -g @plugin 'masa0221/tmux-kube-status'
```

2. Press `prefix` + <kbd>I</kbd> to install the plugin.

### Manual Method

1. Clone this repository or download the scripts (`kube_status.tmux` and `tmux_kube_status.sh`).

```
git clone git@github.com:masa0221/tmux-kube-status.git
```

2. Source the `kube_status.tmux` script in your `.tmux.conf`:


```
run-shell /path/to/tmux-kube-status/kube_status.tmux
```

## Usage

After installing the plugin, your Kubernetes context and environment will be automatically displayed in your Tmux status line.

## Configuration

You can configure various options using Tmux options. Here is a hierarchical summary:

- `@kube-status-format-dev`
  - Defines text color and background for dev environment
  - Default: `#[fg=colour255,bg=colour27]`

- `@kube-status-format-test`
  - Defines text color and background for test environment
  - Default: `#[fg=colour255,bg=colour28]`

- `@kube-status-format-stage`
  - Defines text color and background for staging environment
  - Default: `#[fg=colour255,bg=colour136]`

- `@kube-status-format-prod`
  - Defines text color and background for prod environment
  - Default: `#[fg=colour255,bg=colour200]`

- `@kube-status-context-cutoff-length`
  - Sets maximum length for Kubernetes context name
  - Default: `20`

- `@kube-status-empty-context-string`
  - Sets string to display when no Kubernetes context is available
  - Default: `-`

- `@kube-status-prod-pattern`
  - Regex pattern to match a production environment
  - Default: `.*prod.*`

- `@kube-status-stg-pattern`
  - Regex pattern to match a staging environment
  - Default: `.*stg.*|.*stage.*`

- `@kube-status-test-pattern`
  - Regex pattern to match a test environment
  - Default: `.*test.*`

## Debugging

The `tmux_kube_status.sh` script supports the `--debug` and `--debug-with-color-code` flags for debugging purposes.

## Contributing

Feel free to create an issue or submit a pull request.

## License

MIT

