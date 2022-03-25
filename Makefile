# SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>
#
# SPDX-License-Identifier: Apache-2.0

export CGO_ENABLED=1
export GO111MODULE=on

.PHONY: build

ONOS_PROTOC_VERSION := v0.6.7

build-tools:=$(shell if [ ! -d "./build/build-tools" ]; then cd build && git clone https://github.com/onosproject/build-tools.git; fi)
include ./build/build-tools/make/onf-common.mk

golang: # @HELP compile Golang sources
	go build ./...

test: # @HELP run the unit tests and source code validation  producing a golang style report
test: deps license linters
	go test -race github.com/onosproject/rrm-son-lib/pkg/...

jenkins-test:  # @HELP run the unit tests and source code validation producing a junit style report for Jenkins
jenkins-test: build deps license linters
	TEST_PACKAGES=github.com/onosproject/rrm-son-lib/pkg/... ./build/build-tools/build/jenkins/make-unit

protos: # @HELP compile the protobuf files (using protoc-go Docker)
	docker run -it -v `pwd`:/go/src/github.com/onosproject/rrm-son-lib/go \
		-v `pwd`/../build-tools/licensing:/build-tools/licensing \
		-w /go/src/github.com/onosproject/rrm-son-lib/go \
		--entrypoint build/bin/compile-protos.sh \
		onosproject/protoc-go:${ONOS_PROTOC_VERSION}

publish: # @HELP publish version on github and dockerhub
	./build/build-tools/publish-version ${VERSION}

jenkins-publish: build-tools jenkins-tools # @HELP Jenkins calls this to publish artifacts
	../build-tools/release-merge-commit

all: test golang

clean:: # @HELP remove all the build artifacts
	rm -rf ./build/_output ./vendor
