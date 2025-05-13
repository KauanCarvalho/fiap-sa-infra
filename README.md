# 🏗️ fiap-sa-infra

[Vídeo no youtube da fase 4](https://youtu.be/DnscHNmON-A).

Este repositório gerencia a infraestrutura do ecossistema de microsserviços `fiap-sa`, tanto para **desenvolvimento local** quanto para **implantação em produção**.

## 🌐 Represetação da comunicação entre os serviços

```mermaid
flowchart TD
  subgraph API_Gateway["API Gateway"]
    POST_Webhook(["POST - /prod/webhook_events"])
    POST_SignUp(["POST - /signup"])
    POST_Login(["POST - /login"])
    POST_Checkout(["POST - /checkout"])
  end

  subgraph Lambda["Lambda"]
    SQSEnqueuePaymentWebhook(["SQSEnqueuePaymentWebhook"])
    UserAuth(["UserAuth"])
    UserLogin(["UserLogin"])
    CheckoutHandler(["CheckoutHandler"])
  end

  subgraph Databases["Databases"]
    subgraph Relational["Relational"]
        MySQL_Product[("MySQL - [RDS]")]
        MySQL_Order[("MySQL - [RDS]")]
    end

    subgraph Non_relational["Non-relational"]
        MongoDB_Payment{{"MongoDB - [Atlas]"}}
    end
  end

  subgraph Messaging_Layer["Messaging Layer"]
    SQS_Payment{{"SQS: fiap_sa_payment_service_webhook_events"}}
    SQS_Order{{"SQS: fiap_sa_order_service_payment_events"}}
    SNS_Payment(["SNS: fiap_sa_payment_service_payment_events"])
  end

  subgraph CognitoLayer["CognitoLayer"]
    Cognito{{PoolID}}
  end

  subgraph Services["Services"]
    subgraph Payment["fiap-sa-payment-service"]
      Payment_Worker["Worker"]
      Payment_API["API"]
    end

    subgraph Product["fiap-sa-product-service"]
      Product_Service["API"]
    end

    subgraph Order["fiap-sa-order-service"]
      Order_Worker["Worker"]
      Order_API["API"]
    end
  end

  POST_Webhook --> SQSEnqueuePaymentWebhook
  SQSEnqueuePaymentWebhook --> SQS_Payment
  SQS_Payment --> Payment_Worker
  POST_SignUp --> UserAuth
  UserAuth --> Cognito
  UserAuth --> Order_API
  POST_Login --> UserLogin
  UserLogin --> Cognito
  POST_Checkout --> CheckoutHandler
  CheckoutHandler --> Cognito
  CheckoutHandler --> Order_API
  Payment_Worker --> MongoDB_Payment
  Payment_API --> MongoDB_Payment
  Product_Service --> MySQL_Product
  Order_Worker --> MySQL_Order
  Order_API --> MySQL_Order
  Order_API --> Product_Service
  Order_API --> Payment_API
  Payment_Worker -- publica evento --> SNS_Payment
  SNS_Payment -- publica na fila --> SQS_Order
  SQS_Order -- consumido por --> Order_Worker
  SQS_Payment -- consumido por --> Payment_Worker
```

---

## 📦 Microsserviços incluídos

- `fiap-sa-order-service`
- `fiap-sa-product-service`
- `fiap-sa-payment-service`
- Bancos de dados: **MySQL** e **MongoDB**
- API Gaetways (AWS)
- Lambdas (AWS)
- Cognito (AWS)

---

## ⚙️ Desenvolvimento Local

### Requisitos

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- Rede Docker compartilhada:

```bash
docker network create shared_network
```

### ⛏️ Inicializando o ambiente local

```bash
make up
```

Esse comando inicia os seguintes serviços:

- MongoDB + `fiap-sa-payment-service` (porta **8083**)
- MySQL + `fiap-sa-product-service` (porta **8081**) + `fiap-sa-order-service` (porta **8080**)
- LocalStack (porta **4566** e **4571**) com os serviços SQS e SNS emulados

### Comandos úteis

```bash
make down     # Encerra e remove os containers
make logs     # Exibe os logs de todos os serviços
make ps       # Lista os containers em execução
```

### Acesso aos serviços

| Serviço      | Porta  | URL                                      |
|--------------|--------|------------------------------------------|
| Order        | 8080   | http://localhost:8080                    |
| Product      | 8081   | http://localhost:8081                    |
| Payment      | 8083   | http://localhost:8083                    |
| MongoDB      | 27017  | mongodb://admin:secret@localhost:27017   |
| MySQL        | 3306   | mysql://root@localhost:3306              |
| LocalStack   | 4566	| http://localhost:4566                    |

---

## ☁️ Infraestrutura de Produção

A infraestrutura de produção está definida no diretório [`production/terraform/`](./production/terraform), incluindo:

- Amazon RDS (MySQL) **x 2** (1 para o `fiap-sa-product-service` e outro para `fiap-sa-order-service`)
- MongoDB (Atlas)
- Recursos Kubernetes via Amazon EKS e seus respectivos _Security Groups, ..._

> 🛑 **Importante:**  
> O Terraform **não é executado localmente**.  
> Todos os planos e execuções (`apply`) são realizados via **Terraform Cloud**, acionados através de **pipelines CI/CD** (GitHub Actions).

---

## 📁 Estrutura do Projeto

```
fiap-sa-infra/
├── local/                  # Ambiente de desenvolvimento local (Docker Compose)
│   └── docker-compose.yml
|   ├── testdata/           # "Scripts" de criação de banco de dados e seeds inciais
|   ├── init.js             # Para o MongoDB
|   └── init.sql            # Para o MySQL
├── production/
│   └── terraform/          # Infraestrutura de produção (Terraform Cloud)
├── Makefile                # Comandos comuns para desenvolvimento e infraestrutura
└── README.md               # Este arquivo!
```

---

## 🧰 Atalhos do Makefile

Execute `make help` para ver todos os comandos disponíveis:

| Comando               | Descrição                              |
|-----------------------|----------------------------------------|
| `make up`             | Inicia o ambiente de desenvolvimento   |
| `make down`           | Encerra e remove todos os containers   |
| `make logs`           | Exibe os logs de todos os serviços     |
| `make terraform-init` | (somente para depuração – CI executa)  |
| `make create-sns-sqs` | Cria filas SQS e tópicos SNS           |
---

## 📌 Observações

- Os serviços locais montam o código-fonte Go via `volumes`, permitindo _hot reload_.
- Todos os serviços devem expor suas portas e utilizar a rede `shared_network`.
- Variáveis sensíveis e segredos **não devem ser versionados** — utilizando `.env`, Secrets do GitHub Actions ou variáveis no Terraform Cloud.

---
