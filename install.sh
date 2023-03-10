#!/bin/bash

# specify the repository URL
repo_url="https://github.com/fabianschwab/openshift-tekton-pipeline/archive/refs/heads/main.zip"

curl -LJO "$repo_url" && unzip -o -q openshift-tekton-pipeline-main.zip

mv ./openshift-tekton-pipeline-main/template ./openshift-tekton-pipeline-main/create-pipeline.sh ./ && rm -rf ./openshift-tekton-pipeline-main ./openshift-tekton-pipeline-main.zip

while true; do
    read -p $'\n\e[33mAre you currently connected to your cluster where you want to set up the pipeline? (yes/no): \e[0m' answer
    if [[ $answer = "yes" || $answer = "y" ]]; then
        echo -e "Proceeding..."
        ./create-pipeline.sh
        break
    elif [[ $answer = "no" || $answer = "n" ]]; then
        ./create-pipeline.sh -g
        break
    else
        echo "Invalid input. Please enter 'yes' or 'no'."
    fi
done

echo -e "\n\033[36mIf you are connected to your cluster run 'create-pipeline.sh --apply' to cerate the pipeline or apply all the files manually from the '/build/pipeline' folder.\033[0m"

exit 0