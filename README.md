# Ansible (pull mode)

Self-configuring machines, LearnLinuxTV-style: every box clones **this public
repo** over anonymous HTTPS and applies `local.yml` to itself on a systemd
timer. No control node, no deploy keys, no secrets anywhere in this tree.

New machine, one command:

    curl -fsSL https://raw.githubusercontent.com/arn6694/ansible/main/bootstrap.sh | bash

That installs ansible + git, runs `ansible-pull` once, and the `ansible_pull`
role then installs a systemd timer that re-pulls **hourly** with
`--only-if-changed` — so nothing happens unless a commit lands here. Push to
`main` and the fleet converges within the hour.

## Layout

    local.yml          pull entrypoint (ansible-pull's default filename)
    bootstrap.sh       one-shot enrolment for a fresh machine
    ansible.cfg
    roles/
      common/          base packages, shell config, prompt
      admin_user/      user, SSH public key, passwordless sudo
      motd/            dynamic login banner
      wireguard/       wireguard-tools + import-firewalla-wg helper
      ansible_pull/    the systemd service + timer (self-updating)

Supported distros — tested in containers, idempotent (`changed=0` on rerun):
Debian/Ubuntu, RHEL/Rocky/Fedora, Arch, openSUSE. Roles use **builtin modules
only**, because `ansible-core` (what RHEL-family boxes get) ships zero
collections. Exception: Arch must install the full `ansible` package (its
`package:` backend, the pacman module, lives in community.general).

## Rules of this repo

- **Public means no secrets, ever.** No vault, no tokens, no passwords, no
  network topology. Inventory, vaulted secrets, and push-mode orchestration
  (site.yml, CheckMK playbooks) live on the control node, off GitHub. If a
  task needs a credential, it does not belong in this repo.
- The only key here is a **public** SSH key (`admin_user` role).
- Per-machine differences go in role variables — override in `local.yml` or,
  if divergence grows, add `host_vars/<hostname>.yml` and switch `local.yml`
  to `hosts: all` (ansible-pull adds the machine's hostname to its inventory).

## Machine-local overrides

`local.yml` loads `/etc/ansible-pull.local.yml` if it exists. That file is
where anything machine- or network-specific goes (internal IPs, DNS servers,
NAS paths) — it never enters this public repo. Example:

    # /etc/ansible-pull.local.yml  (root:root 0644)
    wireguard_import_dns: "<your internal DNS server>"

## Enrolling a laptop on the VPN

The `wireguard` role installs the tools and the import helper everywhere, but
tunnel configs are per-device secrets and stay off GitHub. Once per laptop:

1. Create the device in the Firewalla app / web UI and download its `.conf`.
2. `import-firewalla-wg ~/Downloads/<device>.conf` — imports into
   NetworkManager without echoing the private key, applying the DNS/MTU
   overrides from `/etc/ansible-pull.local.yml`.
3. `nmcli connection up firewalla` when away from home.

## Day-to-day

    # run manually on a host (what the timer does hourly)
    sudo ansible-pull -U https://github.com/arn6694/ansible.git -o local.yml

    # check the timer on a host
    systemctl list-timers ansible-pull.timer
    journalctl -u ansible-pull.service -n 50

    # test a change locally before pushing
    ansible-playbook -i localhost, -c local local.yml --check --diff
