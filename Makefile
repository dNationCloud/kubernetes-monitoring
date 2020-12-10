.DEFAULT_GOAL := default

default: jsonnet-fmt jsonnet-lint jsonnet-package helm-lint

jsonnet-fmt:
	@echo "[Formatting jsonnet files]"
	find ./jsonnet/ -type f -regex '.*\.\(libsonnet\|jsonnet\)' -print | \
		while read f; do \
			docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnetfmt -i "$$f" || exit 1; \
		done

jsonnet-lint:
	@echo "[Linting jsonnet files]"
	find ./jsonnet/ -type f -regex '.*\.\(libsonnet\|jsonnet\)' -print | \
		while read f; do \
			docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet-lint "$$f" || exit 1; \
		done

jsonnet-package: jsonnet-package-dashboards jsonnet-package-rules

jsonnet-package-dashboards:
	@echo "[Packaging jsonnet dashboard files]"
	tar -czf chart/jsonnet-dashboards.tar.gz -C jsonnet dashboards config.libsonnet templates.libsonnet util.libsonnet dashboards.jsonnet

jsonnet-package-rules:
	@echo "[Packaging jsonnet rule files]"
	tar -czf chart/jsonnet-rules.tar.gz -C jsonnet rules config.libsonnet templates.libsonnet util.libsonnet rules.jsonnet

helm-lint:
	@echo "[Linting helm chart]"
	helm lint chart

json-dashboards:
	@echo "[Building grafana dashboards]"
	docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet -c -m json jsonnet/dashboards.jsonnet

json-rules:
	@echo "[Building prometheus rules]"
	docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet -c -m json jsonnet/rules.jsonnet

docs-generate:
	@echo "[Generate documentation]"
	rm -rf docs/project docs/site
	mkdir docs/project
	rsync -Rr ./ ./docs/project --exclude=".*"
	cd docs/project && python3 docs/generate_md_docs.py
	cd docs/ && python3 -m mkdocs build -f mkdocs.yml
	rm -rf docs/project
