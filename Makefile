# tools
TERRAFORM         ?= $(shell which terraform)
KUBECTL ?= $(shell which kubectl)
MAKE ?= $(shell which make)
AWS ?= $(shell which aws)
TFLINT ?= $(shell which tflint)
TFSEC ?= $(shell which tfsec)
PIP ?= $(shell which pip)

# dirs
ROOT_DIR ?= $(shell git rev-parse --show-toplevel)
INFRASTRUCTURE_DIR ?= $(ROOT_DIR)/infrastructure
INGESTER_DIR ?= $(ROOT_DIR)/ingester
OUT_DIR ?= $(ROOT_DIR)/out
INGESTER_OUT_DIR ?= $(OUT_DIR)/ingester

# prod
TFVARS ?= $(INFRASTRUCTURE_DIR)/terraform.tfvars
AWS_PROFILE ?= "samuel"

IMPORT_RESOURCE_PATH ?= $(shell IFS= read -p ResourcePath: pwd && echo "$$pwd")
IMPORT_RESOURCE_ID ?= $(shell IFS= read -p ResourceID: pwd && echo "$$pwd")

.PHONY: login
login:
	$(AWS) sso login --profile $(AWS_PROFILE)

.PHONY: apply
apply: build-ingester
	cd $(INFRASTRUCTURE_DIR) && TF_VAR_aws_profile=$(AWS_PROFILE) $(TERRAFORM) apply --var-file=$(TFVARS)

.PHONY: init
init:
	cd $(INFRASTRUCTURE_DIR) && $(TERRAFORM) init --backend-config profile=$(AWS_PROFILE)

.PHONY: lint
lint:
	cd $(INFRASTRUCTURE_DIR) && $(TERRAFORM) fmt --recursive
	cd $(INFRASTRUCTURE_DIR) && $(TERRAFORM) validate
	cd $(INFRASTRUCTURE_DIR) && $(TFLINT) --init  && $(TFLINT) --var-file $(TFVARS)
	cd $(INFRASTRUCTURE_DIR) && $(TFSEC) --tfvars-file $(TFVARS)


.PHONY: import
import:
	cd $(INFRASTRUCTURE_DIR) && TF_VAR_aws_profile=$(AWS_PROFILE) $(TERRAFORM) import --var-file=$(TFVARS) $(IMPORT_RESOURCE_PATH) $(IMPORT_RESOURCE_ID)

.PHONY: build-ingester
build-ingester:
	cd $(INGESTER_DIR) && cp -r . $(INGESTER_OUT_DIR)
	cd $(INGESTER_OUT_DIR) && $(PIP) install -r requirements.txt --target .