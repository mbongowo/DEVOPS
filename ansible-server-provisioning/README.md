# Ansible Server Provisioning

Idempotent provisioning of a Linux application server with **Ansible roles**,
tested end-to-end with **Molecule** against a real (containerised) systemd host.

## What it provisions

| Role | Responsibility |
|------|----------------|
| `common`    | Base packages, timezone, an `admin` user with passwordless sudo, SSH hardening (no root login, no password auth) |
| `docker`    | Docker Engine + Compose plugin from Docker's official apt repo; adds the admin user to the `docker` group |
| `webserver` | nginx with a templated site + landing page; disables the default site |
| `firewall`  | `ufw` default-deny with explicit allow rules for SSH/HTTP/HTTPS |

`site.yml` applies all four roles to the `servers` inventory group. Roles are
tag-scoped, so you can run a slice, e.g. `--tags web`.

## Layout

```
.
├── ansible.cfg
├── requirements.yml          Galaxy collections (community.general/posix/docker)
├── inventory/
│   ├── hosts.ini             example inventory
│   └── group_vars/all.yml    cross-role variables
├── site.yml                  top-level play
├── roles/{common,docker,webserver,firewall}/
└── molecule/default/         converge + idempotence + verify scenario
```

## Run it against real servers

```bash
ansible-galaxy collection install -r requirements.yml
# edit inventory/hosts.ini with your hosts, then:
ansible-playbook -i inventory/hosts.ini site.yml
# a subset:
ansible-playbook -i inventory/hosts.ini site.yml --tags web
```

## Local validation

The same checks run in CI (`.github/workflows/ansible.yml`):

```bash
python -m venv .venv && source .venv/bin/activate
pip install ansible-core ansible-lint yamllint molecule "molecule-plugins[docker]" docker
ansible-galaxy collection install -r requirements.yml

yamllint .
ansible-lint
ansible-playbook --syntax-check -i inventory/hosts.ini site.yml
molecule test          # spins a systemd container, converges, re-runs for
                       # idempotence (changed=0), then verifies
```

**Molecule** boots a `geerlingguy/docker-ubuntu2204-ansible` container, runs the
full role set, asserts the second run reports **zero changes** (idempotence),
then verifies: the admin user is in `sudo`+`docker`, the Docker CLI is present,
nginx is running, and the landing page is served over HTTP. The `docker` daemon
start and `ufw` are toggled off inside the container (not testable there) and
documented as such.
