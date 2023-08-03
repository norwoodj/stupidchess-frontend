DOCKER_REPOSITORY := jnorwood

help:
	@echo "Available Targets:"
	@echo
	@echo "  deb             - Build debian packages for deploying stupidchess"
	@echo "  down            - Tear down the local docker database"
	@echo "  nginx           - Build the nginx docker image"
	@echo "  webpack_builder - Build the nginx docker image"
	@echo "  push            - Push the nginx docker image"
	@echo "  release         - Create a release commit"
	@echo "  run             - Run the app locally in docker"

release:
	./release.sh

version.json:
	echo '{"build-timestamp": "$(shell date --utc --iso-8601=seconds)", "revision": "$(shell git rev-parse HEAD)", "version": "$(shell git tag -l | tail -n 1)"}' | jq . > version.json

deb: version.json
	debuild

nginx: version.json
	cp version.json src/
	docker-compose build nginx

webpack_builder:
	docker-compose build webpack_builder

push: nginx webpack_builder
	docker tag $(DOCKER_REPOSITORY)/stupidchess-nginx:current $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell git tag -l | tail -n 1)
	docker tag $(DOCKER_REPOSITORY)/stupidchess-webpack_builder:current $(DOCKER_REPOSITORY)/stupidchess-webpack_builder:$(shell git tag -l | tail -n 1)
	docker push $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell git tag -l | tail -n 1)
	docker push $(DOCKER_REPOSITORY)/stupidchess-webpack_builder:$(shell git tag -l | tail -n 1)

run: nginx
	docker-compose up

down:
	docker-compose down --volumes
