GCR_URL = us.gcr.io/vcm-ml
IMAGE_TAG ?= latest

COMPILED_IMAGE ?= $(GCR_URL)/fv3gfs-compiled-$(COMPILED_TAG_NAME)
IMAGE=$(GCR_URL)/ufs:$(IMAGE_TAG)
BUILD_TARGET ?= ufs-test
SSH_KEY_PATH ?= ~/.ssh/id_rsa
GITHUB_KEY := "$$(cat $(SSH_KEY_PATH))"

build: 
	@docker build -f Dockerfile -t $(IMAGE) --target $(BUILD_TARGET) --build-arg SSH_PRIVATE_KEY=$(GITHUB_KEY) . 

enter:
	docker run -it $(IMAGE) bash

.PHONY: build
