DOCKER_REPOSITORY := jnorwood
NGINX_IMAGE := nginx:1.13.12
VERSION_PLACEHOLDER := _VERSION

.PHONY: default
default:
	@echo "Available Targets:"
	@echo
	@echo "  clean           - Clean up build artifacts"
	@echo "  down            - Tear down the local docker database"
	@echo "  nginx           - Build the nginx docker image"
	@echo "  webpack_builder - Build the nginx docker image"
	@echo "  push            - Push the nginx docker image"
	@echo "  run             - Run the app locally in docker"
	@echo "  run-no-build    - Run the app locally in docker without rebuilding the image"

version.txt:
	echo "$(shell docker run --rm --entrypoint date $(NGINX_IMAGE) --utc "+%y.%m%d.0")" > version.txt

_version.json: version.txt
	echo "{\"version\": \"$(cat version.txt)\"}" > _version.json

.PHONY: update-package-json
update-package-json: version.txt
	sed -i "" "s|$(VERSION_PLACEHOLDER)|$(shell cat version.txt)|g" package.json package-lock.json

.PHONY: nginx
nginx: _version.json update-package-json
	cp _version.json src/
	docker-compose build nginx

.PHONY: webpack_builder
webpack_builder: update-package-json
	docker-compose build webpack_builder

.PHONY: push
push: nginx
	docker tag $(DOCKER_REPOSITORY)/stupidchess-nginx:current $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell cat version.txt)
	docker push $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell cat version.txt)

.PHONY: run
run: nginx
	docker-compose up

.PHONY: run
run-no-build:
	docker-compose up

.PHONY: down
down:
	docker-compose down

.PHONY: clean
clean: version.txt
	sed -i "" "s|$(shell cat version.txt)|$(VERSION_PLACEHOLDER)|g" package.json package-lock.json
	rm -f _version.json src/_version.json version.txt
