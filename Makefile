DOCKER_REPOSITORY := jnorwood

build: dist

dist: node_modules frontend-version.json
	mv frontend-version.json src/
	./node_modules/webpack/bin/webpack.js -p --progress

node_modules:
	npm install

release:
	./scripts/release.sh

frontend-version.json:
	echo '{"build_timestamp": "$(shell date --utc --iso-8601=seconds)", "git_revision": "$(shell git rev-parse HEAD)", "version": "$(shell git describe)"}' | jq . > frontend-version.json

deb:
	debuild

nginx: frontend-version.json
	mv frontend-version.json src/
	docker-compose build nginx

webpack_builder:
	docker-compose build webpack_builder

push: nginx
	docker tag $(DOCKER_REPOSITORY)/stupidchess-nginx $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell git tag -l | tail -n 1)
	docker push $(DOCKER_REPOSITORY)/stupidchess-nginx:$(shell git tag -l | tail -n 1)

run: frontend-version.json
	mv frontend-version.json src/
	docker-compose up

down:
	docker-compose down --volumes

clean:
	rm -vf frontend-version.json src/frontend-version.json
