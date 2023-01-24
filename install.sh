#!/bin/bash

# specify the repository URL
repo_url="https://github.com/fabianschwab/openshift-tekton-pipeline/archive/refs/heads/main.zip"

curl -LJO "$repo_url" && unzip -m main.zip -d ./tmp-installer/

mv -r ./tmp-installer/template ./tmp-installer/create-pipeline.sh . && rm -rf ./tmp-installer

./create-pipeline.sh