#!/bin/bash

# specify the repository URL
repo_url="https://github.com/fabianschwab/openshift-tekton-pipeline/archive/refs/heads/main.zip"

curl -LJO "$repo_url" && unzip -o -q openshift-tekton-pipeline-main.zip

mv ./openshift-tekton-pipeline-main/template ./openshift-tekton-pipeline-main/create-pipeline.sh ./ && rm -rf ./openshift-tekton-pipeline-main ./openshift-tekton-pipeline-main.zip

while true; do
    read -p "Are you currently connected to your cluster where you want to set up the pipeline? (yes/no): " answer
    if [[ $answer = "yes" || $answer = "y" ]]; then
        echo -e "Proceeding..."
        ./create-pipeline.sh
        break
    elif [[ $answer = "no" || $answer = "n" ]]; then
        echo "Aborting..."
        ./create-pipeline.sh -g
        exit 1
    else
        echo "Invalid input. Please enter 'yes' or 'no'."
    fi
done

echo -e "If you are connected to your cluster run 'create-pipeline.sh --apply' to cerate the pipeline or apply all the files manually from the '/build/pipeline' folder."
