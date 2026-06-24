# 06 — AWS Platform: Terraform + Ansible

Provision-then-configure platform engineering: **Terraform** builds the AWS
foundation (network, compute, managed database) and **Ansible** configures the
EC2 fleet on top of it. Two tools, two responsibilities, one handoff — the
Terraform `db_endpoint` and `app_private_ips` outputs feed the Ansible run.

> **Validate-only / no cloud spend.** Everything here is verified locally and in
> CI with `terraform validate`, `ansible-lint`, and a playbook syntax check. No
> `terraform apply` and no live SSH ever run in this repo — applying is a
> deliberate, credentialed, manual step documented below.

## Architecture

```
              Terraform                         Ansible
  ┌────────────────────────────────┐   ┌──────────────────────────┐
  │ VPC (2 AZ, public + private,    │   │ common  → time, users,   │
  │      single NAT gateway)        │   │           SSH hardening  │
  │ EC2 app fleet (private subnets, │──▶│ docker  → engine + SDK   │
  │      IMDSv2, encrypted EBS)     │   │ app     → container wired │
  │ RDS Postgres 16 (private,       │   │           to RDS via env  │
  │      encrypted, SG-scoped)      │   └──────────────────────────┘
  └────────────────────────────────┘
        outputs: app_private_ips, db_endpoint ──┘ (inventory / extra-vars)
```

## Terraform layer (`terraform/`)

| Resource | Module / type | Notes |
|----------|---------------|-------|
| Network | `terraform-aws-modules/vpc/aws ~> 5.8` | 2 AZ, public + private subnets, single NAT gateway |
| App fleet | `terraform-aws-modules/ec2-instance/aws ~> 5.7` | private subnets, IMDSv2 required, encrypted root volume, `Role=app` tag |
| Database | `terraform-aws-modules/rds/aws ~> 6.10` | Postgres 16, encrypted, managed master password, multi-AZ in prod |
| Security groups | inline | DB reachable only from the app SG; app SSH/HTTP scoped to the VPC CIDR |

Per-environment inputs live in `terraform/env/{dev,prod}.tfvars`. Remote,
locked S3 state is pre-wired but commented in `backend.tf` so CI needs no AWS.

```bash
cd terraform
terraform init -backend=false
terraform validate
terraform fmt -check -recursive

# To actually deploy (needs AWS credentials — not done in CI):
#   terraform init                       # after filling in backend.tf
#   terraform apply -var-file=env/dev.tfvars
```

## Ansible layer (`ansible/`)

```
ansible/
├── ansible.cfg               # dynamic inventory + SSM/bastion notes
├── requirements.yml          # amazon.aws, community.general/docker, ansible.posix
├── inventory/
│   ├── aws_ec2.yml           # dynamic: discovers the fleet by tag:Project=aws-platform
│   └── hosts.ini.example     # static fallback
├── group_vars/all.yml
├── site.yml                  # common → docker → app
└── roles/{common,docker,app}
```

- **common** — timezone, chrony, a non-login service account, and SSH hardening
  (`validate: sshd -t` before reload, restart via handler).
- **docker** — Docker engine + Python SDK, service account added to the group.
- **app** — renders `/etc/platform-app/app.env` (DATABASE_URL points at the RDS
  endpoint) and runs the container with a restart policy and a healthcheck.

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
yamllint .
ansible-lint
ansible-playbook -i inventory/hosts.ini.example site.yml --syntax-check

# To actually configure the fleet (needs SSH/SSM reachability):
#   export DB=$(cd ../terraform && terraform output -raw db_endpoint)
#   ansible-playbook site.yml -e "db_host=${DB%%:*}"
```

The app instances sit in **private subnets** — reach them over AWS Systems
Manager Session Manager or a bastion (`ansible.cfg` has a ProxyCommand example).

## CI

`.github/workflows/platform.yml` runs two jobs on every change:

1. **terraform** — `fmt -check`, `init -backend=false`, `validate`, plus Checkov (soft-fail).
2. **ansible** — `yamllint`, `ansible-lint` (production profile), and a playbook syntax check.
