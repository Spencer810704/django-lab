# Dockerfile 檔案名稱
DOCKERFILE=Dockerfile

# Docker Registry 資訊
DOCKER_REGISTRY_URL=myregistrydomain.com
IMAGE_NAME=django-lab

# 目標Imag名稱 (格式：docker_registry_url/account_name/your_image_name:your_image_tag)
TARGET_IMAGE_NAME=$(DOCKER_REGISTRY_URL)/$(DOCKER_REGISTRY_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)

# Build image (直接在Build的時候打Tag)
build:
	docker build -t $(TARGET_IMAGE_NAME) -f $(DOCKERFILE) .

# 登入 & Push Image
push:
	
	echo $(DOCKER_REGISTRY_PASSWORD) | docker login $(DOCKER_REGISTRY_URL) -u $(DOCKER_REGISTRY_CREDENTIALS_USR) --password-stdin
	docker push $(TARGET_IMAGE_NAME) 
