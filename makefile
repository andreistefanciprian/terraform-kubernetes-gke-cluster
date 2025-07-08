TF_TARGET=
TF_PLAN_FILE=$(TF_TARGET)-tf.tfplan
TF_EXEC=docker compose run terraform
TF_EXTRA_OPS=
TFSTATE_BUCKET=terraform-state-demo-74341
TFSTATE_DIR=tfstate/$(TF_TARGET)

all: plan

clean-orphan-containers:
	@docker rm -f $$(docker ps -aq --filter "name=gcp_setup-terraform-run") 2>/dev/null || echo "No matching containers to remove."

clean:
	@rm -rf $(TF_TARGET)/.terraform
	@rm -rf $(TF_TARGET)/terraform.tfstate.backup
	@rm -rf $(TF_TARGET)/terraform.tfstate
	@rm -rf $(TF_TARGET)/.terraform.lock.hcl
	@rm -rf $(TF_TARGET)/$(TF_PLAN_FILE)

get:
	$(TF_EXEC) -chdir=$(TF_TARGET) get
	$(TF_EXEC) -chdir=$(TF_TARGET) fmt

init: clean get clean-orphan-containers
	$(TF_EXEC) -chdir=$(TF_TARGET) init -backend-config 'bucket=$(TFSTATE_BUCKET)' -backend-config 'prefix=$(TFSTATE_DIR)' -input=false

plan: init
	$(TF_EXEC) -chdir=$(TF_TARGET) plan -input=false -out=$(TF_PLAN_FILE)

deploy: plan
	$(TF_EXEC) apply $(TF_PLAN_FILE) && rm $(TF_PLAN_FILE)

deploy-auto-approve: init
	$(TF_EXEC) -chdir=$(TF_TARGET) apply -input=false -auto-approve

destroy: init
	$(TF_EXEC) -chdir=$(TF_TARGET) destroy $(TF_EXTRA_OPS)

destroy-auto-approve: init
	$(TF_EXEC) -chdir=$(TF_TARGET) destroy -input=false -auto-approve

verify_version: 
	$(TF_EXEC) version