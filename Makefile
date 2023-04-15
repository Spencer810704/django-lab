# Dockerfile檔案名稱
DOCKERFILE=Dockerfile

# Image設置
IMAGE_NAME=lab
IMAGE_IMAGE_TAG=latest

# Docker Registry Information
DOCKER_REGISTRY_URL=myregistrydomain.com
DOCKER_REGISTRY_REPOSITOY_NAME=$(DOCKER_REGISTRY_USERNAME)/$(IMAGE_NAME)

# Build image
build:
	docker build -t $(DOCKER_REGISTRY_URL)/$(DOCKER_REGISTRY_REPOSITOY_NAME):$(IMAGE_TAG) -f $(DOCKERFILE) .

# 登入 & Push Image
push:
	
	echo $(DOCKER_REGISTRY_PASSWORD) | docker login $(DOCKER_REGISTRY_URL) -u $(DOCKER_REGISTRY_CREDENTIALS_USR) --password-stdin
	docker push $(DOCKER_REGISTRY_URL)/$(DOCKER_REGISTRY_REPOSITOY_NAME):$(IMAGE_TAG) 
