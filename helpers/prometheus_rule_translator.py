#!/usr/bin/env python
import sys
import json
import yaml

with open('plugin/k8s.rules.yaml', 'w') as outfile:
    yaml.dump(yaml.safe_load(json.dumps(json.loads(open(sys.argv[1]).read()))), outfile, default_flow_style=False)