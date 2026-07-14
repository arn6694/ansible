#!/usr/bin/env bash
# One-shot bootstrap: point a brand-new machine at the pull repo.
#   curl -fsSL https://raw.githubusercontent.com/arn6694/ansible/main/bootstrap.sh | bash
# Public repo, anonymous HTTPS clone — no keys or tokens needed.
set -euo pipefail

REPO="${REPO:-https://github.com/arn6694/ansible.git}"

# Arch gets the full `ansible` package, not ansible-core: the roles use
# ansible.builtin.package, which on Arch delegates to the pacman module from
# community.general — bundled with `ansible`, absent from `ansible-core`.
if   command -v apt-get >/dev/null; then sudo apt-get update -qq && sudo apt-get install -y ansible git
elif command -v dnf     >/dev/null; then sudo dnf install -y ansible-core git
elif command -v pacman  >/dev/null; then sudo pacman -Sy --needed --noconfirm ansible git
elif command -v zypper  >/dev/null; then sudo zypper --non-interactive install ansible git
else echo "Unsupported distro" >&2; exit 1
fi

sudo ansible-pull --url "$REPO" --directory /opt/ansible-pull local.yml
echo "Bootstrapped. The ansible-pull timer now keeps this box in sync."
