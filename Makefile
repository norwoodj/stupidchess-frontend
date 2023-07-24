DOCKER_REPOSITORY := jnorwood
VERSION_PLACEHOLDER := _VERSION
VERSION_FILES := package.json package-lock.json

##
# Build targets
##
main: dist

all: main push

release: all
	git tag $(cat version.txt)
	git push --tags

node_modules:
	npm install

dist: node_modules update-versions version.json
	cp version.json src/
	./node_modules/webpack/bin/webpack.js -p --progress

.PHONY: help
help:
	@echo "Available Targets:"
	@echo
	@echo "  clean           - Clean up build artifacts"
	@echo "  deb             - Build debian packages for deploying stupidchess"
	@echo "  down            - Tear down the local docker database"
	@echo "  nginx           - Build the nginx docker image"
	@echo "  webpack_builder - Build the nginx docker image"
	@echo "  push            - Push the nginx docker image"
	@echo "  release         - Build and deploy assets, tag a release"
	@echo "  run             - Run the app locally in docker"
	@echo "  run-no-build    - Run the app locally in docker without rebuilding the image"


##
# Versioning targets
##
version.txt:
	date --utc "+%y.%m%d.0" > version.txt

version.json: version.txt
	echo '{"build-timestamp": "$(shell date --utc --iso-8601=seconds)", "revision": "$(shell git rev-parse HEAD)", "version": "$(shell cat version.txt)"}' | jq . > version.json

update-versions: version.txt
	sed -i "s|$(VERSION_PLACEHOLDER)|$(shell cat version.txt)|g" $(VERSION_FILES)
	touch update-versions

update-deb-version: version.txt
	sed -i "s|$(VERSION_PLACEHOLDER)|$(shell cat version.txt)|g" debian/changelog
	touch update-deb-version


##
# debian packaging
##
.PHONY: deb
deb: update-deb-version
	debuild


##
# Docker images
##
.PHONY: nginx
nginx: version.json update-versions
	cp version.json src/
	docker-compose build nginx

.PHONY: webpack_builder
webpack_builder: update-versions
	docker-compose build webpack_builder

.PHONY: push
push: nginx
	docker tag $(DOCKER_REPOSITORY)/stupidchess-nginx:current $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell cat version.txt)
	docker push $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell cat version.txt)


##
# Run application
##
.PHONY: run
run: nginx
	docker-compose up

.PHONY: run
run-no-build:
	docker-compose up


##
# Cleanup
##
.PHONY: down
down:
	docker-compose down --volumes

.PHONY: clean
clean: version.txt
	sed -i "s|$(shell cat version.txt)|$(VERSION_PLACEHOLDER)|g" $(VERSION_FILES)
	rm -rf dist version.json src/version.json version.txt update-versions

.PHONY: cleaner
cleaner: version.txt
	sed -i "s|$(shell cat version.txt)|$(VERSION_PLACEHOLDER)|g" $(VERSION_FILES) debian/changelog
	rm -rf dist version.json src/version.json version.txt update-versions update-deb-version
