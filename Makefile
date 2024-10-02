DOCKER_IMAGE_NAME := helloworld
DOCKER_IMAGE_TAG := latest
REGION := us-east-1
TERRAFORM_DIR := ./terraform/
DOCKER_DIR := ./app/
ECR_URI := $(shell cd terraform/ && terraform output -raw ecr_repo)

all: docker_build terraform_init terraform_apply auth_to_ecr docker_push

# DOCKER
docker_build:
	@echo "Building Docker image..."
	cd $(DOCKER_DIR) && sudo docker build -t local/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) .

docker_run:
	@echo "Running Docker image..."
	cd $(DOCKER_DIR) && sudo docker run -p '5000:5000' local/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

docker_push: docker_build setup_ecr_repository
	@echo "Pushing Docker image to ECR..."
	sudo docker tag local/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) $(ECR_URI):$(DOCKER_IMAGE_TAG)
	sudo docker push $(ECR_URI):$(DOCKER_IMAGE_TAG)

# TERRAFORM
terraform_init:
	@echo "Initializing Terraform..."
	cd $(TERRAFORM_DIR) && terraform init

terraform_plan:
	@echo "Applying all on terraform..."
	cd $(TERRAFORM_DIR) && terraform plan -var="project_name=${DOCKER_IMAGE_NAME}"

terraform_apply:
	@echo "Applying all on terraform..."
	cd $(TERRAFORM_DIR) && terraform apply -var="project_name=${DOCKER_IMAGE_NAME}" -auto-approve

terraform_destroy:
	@echo "Destroying all on terraform..."
	cd $(TERRAFORM_DIR) && terraform destroy -var="project_name=${DOCKER_IMAGE_NAME}" -auto-approve

#ECR
auth_to_ecr:
	@echo "Authenticating to ECR..."
	cd $(TERRAFORM_DIR) && aws ecr get-login-password --region ${REGION} --profile personal | sudo docker login --username AWS --password-stdin $(ECR_URI)

.PHONY: docker_build docker_run docker_push terraform_init terraform_plan terraform_apply terraform_destroy auth_to_ecr