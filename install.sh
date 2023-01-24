#!/bin/bash

# specify the repository URL
repo_url="https://github.com/fabianschwab/openshift-tekton-pipeline/tree/main/"

# specify the files to be copied
files=("create-pipeline.sh" "template")

# loop through the files array and download each file
for file in "${files[@]}"; do
  curl -LJO "$repo_url/$file" -o "$file"
done
