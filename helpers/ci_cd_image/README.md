# Jsonnet

A simple Docker image includes jsonnet, jsonnetfmt, jsonnet-lint, yq and jsonnet lib like grafonnet-lib, kube-libsonnet and grafonnet-polystat-panel.    
Docker image was build for the CI/CD purposes or to avoid having to install jsonnet tools on your computer (keep it in docker).

# Usage

```
# Jsonnet
docker run --rm -it -v `pwd`:/src dnationcloud/jsonnet:<tagname> jsonnet -h
# Jsonnet Formater
docker run --rm -it -v `pwd`:/src dnationcloud/jsonnet:<tagname> jsonnetfmt -h
# Jsonnet Linter
docker run --rm -it -v `pwd`:/src dnationcloud/jsonnet:<tagname> jsonnet-lint -h
# YQ
docker run --rm -it -v `pwd`:/src dnationcloud/jsonnet:<tagname> yq -h
```

Inspect versions
```
docker inspect --format '{{ index .Config.Labels }}' dnationcloud/jsonnet:<tagname>
```
