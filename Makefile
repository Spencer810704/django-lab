# Dockerfile 檔案名稱
DOCKERFILE=Dockerfile

# 根據專案名稱做修改
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

deploy-sit:
	helm secrets upgrade --kubeconfig $(KUBECONFIG) --install $(HELM_RELEASE_NAME) $(HELM_CHART_NAME) --namespace $(KUBERNETES_NAMESPACE) --set image.repository=$(DOCKER_REGISTRY_REPOSITORY) --set environment=sit --set image.tag=$(IMAGE_TAG) --values django-lab-chart/values-sit.yaml --values django-lab-chart/secrets.sit.yaml

deploy-stg:
	helm secrets upgrade --kubeconfig $(KUBECONFIG) --install $(HELM_RELEASE_NAME) $(HELM_CHART_NAME) --namespace $(KUBERNETES_NAMESPACE) --set image.repository=$(DOCKER_REGISTRY_REPOSITORY) --set environment=stg --set image.tag=$(IMAGE_TAG) --values django-lab-chart/values-stg.yaml --values django-lab-chart/secrets.stg.yaml

deploy-prod:
	helm secrets upgrade --kubeconfig $(KUBECONFIG) --install $(HELM_RELEASE_NAME) $(HELM_CHART_NAME) --namespace $(KUBERNETES_NAMESPACE) --set image.repository=$(DOCKER_REGISTRY_REPOSITORY) --set environment=prod --set image.tag=$(IMAGE_TAG) --values django-lab-chart/values-prod.yaml --values django-lab-chart/secrets.prod.yaml
