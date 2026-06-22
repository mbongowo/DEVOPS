# terraform-azure-infra

Modular Terraform for a **zero-cost Azure footprint**: a resource group, a
virtual network with an NSG-protected subnet, and a Linux web app on the **F1
(free) App Service tier**. Built to demonstrate clean module composition,
version pinning, input validation, and a CI pipeline that validates on every
push without needing any cloud credentials.

> Free-tier first. The `app_service_sku` variable is validated to reject
> anything beyond `F1`/`B1`, so the repo can't accidentally provision a billable
> SKU.

## Architecture

```
root module
├── module.resource_group   → azurerm_resource_group
├── module.network          → vnet + subnet(s) + NSG + subnet/NSG association
└── module.webapp           → service_plan (F1 Linux) + linux_web_app (Node 20)
```

| Resource            | SKU / tier      | Cost            |
| ------------------- | --------------- | --------------- |
| Resource group      | —               | Free            |
| Virtual network     | —               | Free            |
| Subnet + NSG        | —               | Free            |
| App Service Plan    | F1 (Linux)      | Free            |
| Linux Web App       | F1              | Free            |

> **Note on VNet integration:** App Service VNet integration requires a B1+
> plan, so on F1 the web app is *not* wired into the VNet. The network module is
> included to show reusable networking IaC and to be ready for a paid SKU.

## Layout

```
.
├── versions.tf          provider + Terraform version constraints
├── providers.tf         azurerm provider (auth from env / az login)
├── backend.tf           remote state (documented, commented out by default)
├── main.tf              module wiring
├── variables.tf         inputs with validation (free-tier guardrails)
├── outputs.tf           RG, network, and web app outputs
├── environments/        dev.tfvars / prod.tfvars
└── modules/
    ├── resource_group/
    ├── network/
    └── webapp/
```

## Prerequisites

- Terraform >= 1.5
- For a real `plan`/`apply`: an Azure subscription and either `az login` or a
  service principal exported as `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`,
  `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`.

## Usage

Validate locally without any cloud credentials:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

Plan / apply against Azure:

```bash
az login
terraform init
terraform plan  -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

Tear everything down:

```bash
terraform destroy -var-file=environments/dev.tfvars
```

## Remote state

State is local by default so the repo validates out of the box. To use Azure
Blob Storage for shared state, follow the bootstrap steps and uncomment the
backend block in [`backend.tf`](./backend.tf), then re-run `terraform init`.

## CI

[`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) runs
`fmt -check`, `init -backend=false`, and `validate` on every push and pull
request — fully offline. An Azure-authenticated `plan` job runs on `main` only
when the repo variable `AZURE_PLAN_ENABLED=true` and the `ARM_*` secrets are
configured.

## License

[MIT](./LICENSE).
