#
# Copyright 2020 The dNation Kubernetes Monitoring Authors. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


import json
from ruamel import yaml as ruamel_yaml
import _jsonnet

yaml = ruamel_yaml.YAML(typ="safe")
_anchor_ID = 0


def load_file(path):
    with open(path) as f:
        return f.read()


def save_file(path, content):
    with open(path, "w") as f:
        f.write(content)


def load_yaml_file(values_path):
    with open(values_path) as f:
        return yaml.load(f)


def generate_json_config(jsonnet_config_path, values):
    """Generate json config from jsonnet config and values.yaml.

    Jsonnet code is used to load jsonnet config and merge it with values.

    Args:
        jsonnet_config_path (str): Path to jsonnet (libsonnet) config file.
        values (dict): Values from values.yaml.

    Returns:
        (str): Generated json config.
    """
    merge_configs_jsonnet = f"""
        local config = (import '{jsonnet_config_path}');
        function(customConfig={{}}) 
            config.mergeConfig(config.defaultConfig, customConfig)._config
    """

    return _jsonnet.evaluate_snippet(
        "merge_configs_jsonnet",
        merge_configs_jsonnet,
        tla_codes={"customConfig": json.dumps(values)},
    )


def to_md(key, obj, level):
    """Convert python object (loaded from json) to markdown/html string.

    If obj is dict (at least 2 entries or one long entry) and
    level <= max_granularity_level, table with anchor and reference to it is created
    (if level <= max_toc_level, anchor is included in table of content).
    Otherwise obj is simply converted to string.

    Args:
        key (str): Key/Name of obj.
        obj (Any): Python object from json file.
        level (int): How deep in json structure is obj.

    Returns:
        (str, str): Returns markdown string from object, resp.
            reference to anchor and anchor with html table from object.
    """
    global _anchor_ID
    max_granularity_level = 5
    max_toc_level = 4

    if (
        isinstance(obj, dict)
        and level <= max_granularity_level
        and (len(obj) > 1 or len(str(obj)) > 50)
    ):

        anchor_content = f"<a name='{key}_{_anchor_ID}'>{key}</a>"
        if level <= max_toc_level:
            anchor = f"{'#' * level} {anchor_content} \n\n"
        else:
            # Used <p> insted of header, it will not be in toc
            anchor = f"<p> {anchor_content} </p>\n\n"
        ref = f"<a href='#{key}_{_anchor_ID}'>{key}</a>"
        _anchor_ID += 1

        return ref, anchor + table(obj, level + 1)

    # lists/dicts are dumped as yaml for prettier formatting
    if isinstance(obj, list) or isinstance(obj, dict):
        obj_to_str = ruamel_yaml.dump(obj, Dumper=ruamel_yaml.RoundTripDumper)
    else:
        obj_to_str = json.dumps(obj)
    if key != "description":
        obj_to_str = f"<div class='my-pre'><code>{obj_to_str}</code></div>"

    return obj_to_str, None


def table(obj, level):
    """Create html table from dict (loaded from json).

    For every key in dict generate row in table. Each row is
    markdown representation of value or reference to anchor
    with sub table.

    Args:
        obj (dict): Python dict to be converted to table.
        level (int): How deep in json structure is this dict.

    Returns:
        str: table or tables in html
    """
    sub_tables = []
    rows = []
    html = "<table><tr><th>Property</th><th>Value</th></tr>"

    for key in obj.keys():
        cell_value, sub_table = to_md(key, obj[key], level)
        row = f"<tr><td>{key}</td><td>{cell_value}\n</td></tr>"
        rows.append(row)

        if sub_table is not None:
            sub_tables.append(sub_table)

    double_nl = "\n\n"
    html += "\n".join(rows) + "</table>"
    return f"{html}\n\n<br>\n\n{double_nl.join(sub_tables)}"


def main():
    """Generate markdown files from config files.

    Returns:
        None
    """
    jsonnet_config_path = "jsonnet/config.libsonnet"
    values_path = "chart/values.yaml"
    intro_path = "docs/documentation-intro.md"
    docs_path = "docs/documentation.md"

    values = load_yaml_file(values_path)
    json_config = json.loads(generate_json_config(jsonnet_config_path, values))
    intro = load_file(intro_path)
    docs = f"{intro}\n\n{table(json_config, 2)}"
    save_file(docs_path, docs)


if __name__ == "__main__":
    main()
