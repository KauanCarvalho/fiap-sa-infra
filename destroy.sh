#!/bin/bash

terraform init ./terraform
terraform plan -destroy -out=tfplan
terraform apply -auto-approve tfplan
