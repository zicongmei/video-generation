IMAGE_NAME = zicongmei/comfyui
TAG = latest

.PHONY: build publish

build:
	docker build -t $(IMAGE_NAME):$(TAG) .

publish:
	docker push $(IMAGE_NAME):$(TAG)
