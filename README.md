# lwdev installer

Install the private Long Way development sandbox CLI with GitHub authentication:

```bash
gh auth login
gh auth status
gh repo view BeyondHarnessLab/longway-sandbox-dev
curl -fsSL https://raw.githubusercontent.com/YouXing96/lwdev-install/main/install.sh | bash
```

The installer requires Bash, GitHub CLI, Git, Node.js 24.15+, and pnpm 12. It installs the private checkout in
`~/.local/share/lwdev`, the `lwdev` launcher in `~/.local/bin`, and never reads or writes secrets or creates a
sandbox. It does not modify shell startup files. After installation run:

```bash
lwdev init
lwdev doctor
```

For a reviewable install, download the script first:

```bash
curl -fsSL https://raw.githubusercontent.com/YouXing96/lwdev-install/main/install.sh -o /tmp/install-lwdev.sh
less /tmp/install-lwdev.sh
bash /tmp/install-lwdev.sh
```

Optional variables:

- `LWDEV_REF=main` — branch or tag to install.
- `LWDEV_INSTALL_DIR="$HOME/.local/share/lwdev"` — private checkout location.
- `LWDEV_BIN_DIR="$HOME/.local/bin"` — launcher location.

The installer refuses to overwrite a different directory, a dirty checkout, a checkout on another branch, or an
existing non-lwdev launcher.
