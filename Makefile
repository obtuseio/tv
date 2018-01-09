dist:
	rm -rf dist
	cd front && yarn build --no-clear
	mv front/dist .
	mkdir dist/data
	cp -R back/data/series.json back/data/series dist/data

deploy: dist
	cd dist && rsync -avz --progress -h . obtuse:/srv/http/tv.obtuse.io/htdocs/

.PHONY: dist deploy
