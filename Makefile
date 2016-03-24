all: build

build:
	@docker build --tag=absolootly/docker-postgresql:latest .

release: build
	@docker build --tag=absolootly/docker-postgresql:latest:$(shell cat VERSION) .
