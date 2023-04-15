IMAGE_NAME=lab
IMAGE_TAG=latest
DOCKERFILE=Dockerfile
DOCKER_REGISTRY_URL=myregistrydomain.com
DOCKER_REGISTRY_REPOSITOY_NAME=$(DOCKER_REGISTRY_ACCOUNT)/$(IMAGE_NAME)

test:
	echo $(DOCKER_REGISTRY_URL)/$(DOCKER_REGISTRY_REPOSITOY_NAME):$(TAG)
build:
	docker build -t $(DOCKER_REGISTRY_URL)/$(DOCKER_REGISTRY_REPOSITOY_NAME):$(TAG) -f $(DOCKERFILE) .

push:
	docker push $(DOCKER_REGISTRY_URL)/$(DOCKER_REGISTRY_REPOSITOY_NAME):$(TAG) 