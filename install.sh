#!/bin/bash

# specify the repository URL
repo_url="https://github.com/fabianschwab/openshift-tekton-pipeline/archive/refs/heads/main.zip"

curl -LJO "$repo_url" && unzip -o -q openshift-tekton-pipeline-main.zip

mv ./openshift-tekton-pipeline-main/template ./openshift-tekton-pipeline-main/create-pipeline.sh ./ && rm -rf ./openshift-tekton-pipeline-main ./openshift-tekton-pipeline-main.zip

./create-pipeline.sh