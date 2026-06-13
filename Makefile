REGION       ?= eu-west-1
SERVICE_NAME ?= crow-hello
TF_DIR       := terraform
TFVARS       := secrets.tfvars
AWS_KEY      := $(shell awk -F'=' '/aws_access_key/ {gsub(/[ "]/,"",$$2); print $$2}' $(TF_DIR)/$(TFVARS) 2>/dev/null)
AWS_SECRET   := $(shell awk -F'=' '/aws_secret_key/ {gsub(/[ "]/,"",$$2); print $$2}' $(TF_DIR)/$(TFVARS) 2>/dev/null)

.PHONY: deploy push tf-init tf-apply-service tf-apply-image url

deploy: tf-apply-service push tf-apply-image url

tf-init:
	cd $(TF_DIR) && terraform init

tf-apply-service:
	cd $(TF_DIR) && terraform apply -auto-approve -var-file=$(TFVARS)

push:
	docker build -t $(SERVICE_NAME) .
	AWS_ACCESS_KEY_ID=$(AWS_KEY) AWS_SECRET_ACCESS_KEY=$(AWS_SECRET) \
		aws lightsail push-container-image \
		--region $(REGION) \
		--service-name $(SERVICE_NAME) \
		--label $(SERVICE_NAME) \
		--image $(SERVICE_NAME):latest \
		2>&1 | tee .last-push.log
	@grep -oE ':$(SERVICE_NAME)\.$(SERVICE_NAME)\.[0-9]+' .last-push.log | tail -1 > .last-image
	@echo "Pushed image: $$(cat .last-image)"

tf-apply-image:
	cd $(TF_DIR) && terraform apply -auto-approve -var-file=$(TFVARS) -var 'image=$(shell cat .last-image)'

url:
	@cd $(TF_DIR) && terraform output -raw url
