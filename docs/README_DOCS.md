# Kubernetes Monitoring Documentation

# Generate documentation

Prerequisites
  - [Python3](https://www.python.org/downloads/)

```
pip3 install -r "docs/requirements.txt"
make docs-generate
```

Afterwards folder `docs/site` with static website is created. 

# Local development
Python script [docs/generate_md_docs.py](generate_md_docs.py) is responsible for creating markdown documents 
from configuration files.

[Mkdocs](https://www.mkdocs.org/) tool is used for generating documentation website from markdown files.
Tool comes with built-in dev-server that can be used to preview work on documentation.
```
# whole project is copied inside docs/project folder
rsync -Rr ./ docs/project
cd docs/project
python3 docs/generate_md_docs.py
cd ..
mkdocs serve
```
[Mkdocs](https://www.mkdocs.org/) doesn't have access to files outside `docs_dir` (in our case `docs/project`) 
and configuration file (`mkdocs.yaml`) has to be at least one level above `docs_dir` in filesystem tree. 
Therefore whole project has to be copied inside `docs/project` to allow Mkdocs to access files like `chart/README.md` or 
`helpers/FAQ.md`. 
To see changes at dev-server, files inside `docs/project` has to be modified. After development is done, 
changes has to be copied to `kubernetes-monitoring` folder and command `make docs-generate` has to be run.

Other option that avoids copying changes is using symlink.
```
# symlink to kubernets-monitoring folder is created inside docs folder
ln -s .. docs/project
python3 docs/generate_md_docs.py
cd docs
mkdocs serve --no-livereload
```
Disadvantage is unability to use livereload because of 'infinite path' of symlink (`docs/project/docs/project/...`).
Server has to be restarted to reload changes. After development is done, symlink has to be deleted and command `make docs-generate` run.

# CI/CD
Github workflow is used to regenerate documentation and deploy site to branch `gh-pages` if changes
are made inside `docs` folder, any REAMDE file or in configuration files.
