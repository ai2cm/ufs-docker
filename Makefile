GCR_URL = us.gcr.io/vcm-ml
IMAGE_TAG ?= latest

COMPILED_IMAGE ?= $(GCR_URL)/fv3gfs-compiled-$(COMPILED_TAG_NAME)
IMAGE=$(GCR_URL)/ufs:$(IMAGE_TAG)
BUILD_TARGET ?= ufs-test

build: 
	docker build -f Dockerfile -t $(IMAGE) --target $(BUILD_TARGET) .

enter:
	docker run -it $(IMAGE) bash

.PHONY: build
