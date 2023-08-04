DOCKER_REPOSITORY := jnorwood

build: dist

dist: node_modules version.json
	mv version.json src/
	./node_modules/webpack/bin/webpack.js -p --progress

node_modules:
	npm install

release:
	./release.sh

version.json:
	echo '{"build-timestamp": "$(shell date --utc --iso-8601=seconds)", "revision": "$(shell git rev-parse HEAD)", "version": "$(shell git tag -l | tail -n 1)"}' | jq . > version.json

deb: version.json
	debuild

nginx: version.json
	mv version.json src/
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

clean:
	rm -vf version.json src/version.json
