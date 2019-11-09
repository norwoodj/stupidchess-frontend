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


##
# Versioning targets
##
version.txt:
	echo "$(shell docker run --rm --entrypoint date $(NGINX_IMAGE) --utc "+%y.%m%d.0")" > version.txt

_version.json: version.txt
	echo "{\"version\": \"$(shell cat version.txt)\"}" > _version.json

update-versions: version.txt
	sed -i "" "s|$(VERSION_PLACEHOLDER)|$(shell cat version.txt)|g" package.json package-lock.json deb/*/DEBIAN/control
	touch update-versions


##
# Docker images
##
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


##
# debian packaging
##
node_modules:
	npm install

dist: node_modules update-versions _version.json
	cp _version.json src/
	./node_modules/webpack/bin/webpack.js -p --progress

nginx-load-balancer-$(shell cat version.txt).deb: update-versions
	dpkg-deb -b deb/nginx-load-balancer nginx-load-balancer-$(shell cat version.txt).deb

stupidchess-nginx-$(shell cat version.txt).deb: dist
	cp etc/nginx/nginx.conf deb/stupidchess-nginx/opt/stupidchess/nginx/nginx.conf
	cp -R dist deb/stupidchess-nginx/opt/stupidchess/dist
	dpkg-deb -b deb/stupidchess-nginx stupidchess-nginx-$(shell cat version.txt).deb

.PHONY: deb
deb: nginx-load-balancer-$(shell cat version.txt).deb stupidchess-nginx-$(shell cat version.txt).deb


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
	docker-compose down

.PHONY: clean
clean: version.txt
	sed -i "" "s|$(shell cat version.txt)|$(VERSION_PLACEHOLDER)|g" package.json package-lock.json deb/*/DEBIAN/control
	rm -rf _version.json src/_version.json version.txt deb/stupidchess-nginx/opt/stupidchess/nginx/nginx.conf deb/stupidchess-nginx/opt/stupidchess/dist
