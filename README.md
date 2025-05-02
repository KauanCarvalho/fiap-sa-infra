# 🏗️ fiap-sa-infra

This repository manages the infrastructure for the `fiap-sa` microservices ecosystem, both for **local development** and **production deployment**.

## 📦 Microservices Covered

- `fiap-sa-order-service`
- `fiap-sa-product-service`
- `fiap-sa-payment-service`
- Databases: **MySQL**, **MongoDB**

---

## ⚙️ Local Development

### Requirements

- Docker
- Docker Compose
- Shared Docker network:

```bash
docker network create shared_network
```

### Starting the environment

```bash
make up
```

This will start:

- MongoDB + `fiap-sa-payment-service` (port **8083**)
- MySQL + `fiap-sa-product-service` (port **8081**)
- `fiap-sa-order-service` (port **8080**) – adjust if needed

### Useful commands

```bash
make down     # Stop and remove containers
make logs     # Show logs for all services
make ps       # List running containers
```

### Service access

| Service      | Port  | URL                                  |
|--------------|-------|--------------------------------------|
| Order        | 8080  | http://localhost:8080                |
| Product      | 8081  | http://localhost:8081                |
| Payment      | 8083  | http://localhost:8083                |
| MongoDB      | 27017 | mongodb://admin:secret@localhost:27017 |
| MySQL        | 3306  | mysql://root@localhost:3306          |

---

## ☁️ Production Infrastructure

The production infrastructure is defined in [`production/terraform/`](./production/terraform), including:

- Amazon RDS (MySQL).
- MongoDB (Atlas).
- Amazon EKS / Kubernetes resources.

> 🛑 **Important:**  
> Terraform is **not executed locally**.  
> All Terraform plans and applies are managed through **Terraform Cloud**, triggered via **CI/CD pipelines** (GitHub Actions).

---

## 📁 Project Structure

```
fiap-sa-infra/
├── local/                  # Local development environment (Docker Compose)
│   └── docker-compose.yml
├── production/
│   └── terraform/          # Production infrastructure (Terraform Cloud)
├── Makefile                # Common commands for dev and infra
└── README.md               # You're here!
```

---

## 🧰 Makefile shortcuts

Run `make help` to see available commands:

| Command               | Description                           |
|-----------------------|---------------------------------------|
| `make up`             | Start local dev environment           |
| `make down`           | Stop all containers                   |
| `make logs`           | Show logs for all services            |
| `make terraform-init` | (for debugging only, handled by CI)   |

---

## 📌 Notes

- Local apps mount your Go source via `volumes`, so changes reflect in real time.
- Each service must expose ports and use the `shared_network`.
- Keep secrets and environment variables out of version control (use `.env`, GitHub Actions Secrets, or Terraform Cloud variables).

---
