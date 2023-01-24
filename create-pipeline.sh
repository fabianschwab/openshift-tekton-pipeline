#!/bin/bash

function print_help {
    echo -e "This script generates a simple Tekton pipeline for Red Hat OpenShift."
    
    echo -e "\nKey steps which are done in the pipeline:"
    echo "  1. Clone the repository"
    echo "  2. Build an image with the provided containerfile / dockerfile."
    echo "     Than the image gets pushed into the internal regisrty, with the commit hash as tag."
    echo "  3. A manifest file is created"
    echo "  4. The manifest is used to create a test-deployment."
    echo "  5. If the deployment was successfull. The manifest file gets pushed to a gitops repository."
    
    echo -e "\nGenerated files:"
    echo "  • /k8s                - This folder must be placed into the repositories root folder and is used by the pipeline."
    echo "  • pipeline.config     - Which holds all the values of the needed varaibles, for manual change or lookup."
    echo "                          This file holds senisitive information and should not be commited to any repository."
    echo "                          However you can still keep this file if it is added to your git ignore list."
    # echo "  • /pipeline           - This folder contains the created pipeline *.yaml files, for inspection or custom modifications."

    echo -e "\nParameter:"
    echo "  • NAMESPACE           - An OpenShift project is an alternative representation of a Kubernetes namespace." 
    echo "  • APPLICATION_NAME    - Label applicaiton name for grouping services together." 
    echo "  • SERVICE_NAME        - Service name which should eb deployed within the applicaiton." 
    echo "  • SERVICE_PORT        - Port of the service which should be exposed as a route." 
    echo "  • GIT_REPOSITORY_URL  - URL of the source git reposirory which should be cloned and build." 
    echo "  • GIT_SERVER_DOMAIN   - URL of the source git server (TDL of GIT_REPOSITORY_URL). Needed to get the authentication work." 
    echo "  • GIT_USER            - User to access the repositroy." 
    echo "  • GIT_ACCESS_TOKEN    - Token for authentication." 

    echo -e "\nOptions:"
    echo "  -h, --help            - Show this help text."
    echo "  -a, --apply           - Reapply the pipeline configuration to the connected cluster."
    echo "  -g, --generate        - Only generate the `yaml` files for the pipeline with the configured inputs."
}

function get_input {
    echo "Plaese provide the values for the needed parameter."
    echo -e "If you are note sure about the values, use the \033[1m--help\033[0m parameter to get a description.\n"

    # check if file exists and export all variables
    # they are reused as default value in the next step as a default
    if [ -e pipeline.config ]; then
        while read line; do
            if [[ -n "$line" ]]; then
                IFS="=" read -r parameter_name value <<< "$line"
                export $parameter_name=$value
            fi
        done < pipeline.config
    fi

    # as long as not everything is run through nothing should be saved persistent
    tmp=''

    for parameter_name in "${parameters[@]}" ; do
        input_text=''
        if [ -z "${!parameter_name}" ]; then
            input_text="$parameter_name: "
        else
            input_text="$parameter_name: ("${!parameter_name}") "
        fi
        read -p "$input_text" input
        if [ -z "$input" ]; then
            # keep old input
            export $parameter_name=${!parameter_name}
        else
            # set new input
            export $parameter_name=$input
        fi
        tmp+=$parameter_name"="${!parameter_name}"\n"
    done

    # updfate config and deployment folder
    echo -e ""
    pipeline_config $tmp
    echo -e ""
    kubernetes_folder
    echo -e ""
}

function pipeline_config {
    echo -e $1 > pipeline.config
    echo -e "\033[32mSuccess:\033[0m Created 'pipeline.config' file."
    echo -e "\033[34mInfo:\033[0m    Please add the 'pipeline.config' file to your .gitignore file."
}

function kubernetes_folder {
    if [ ! -d "./k8s" ]; then
        mkdir -p ./k8s
    fi
    cat ./template/k8s/deployment.yaml | envsubst > ./k8s/deployment.yaml
    cat ./template/k8s/route.yaml | envsubst > ./k8s/route.yaml
    cat ./template/k8s/service.yaml | envsubst > ./k8s/service.yaml
    cat ./template/k8s/kustomization.yaml | envsubst > ./k8s/kustomization.yaml

    echo -e "\033[32mSuccess:\033[0m Created deployment files in the 'k8s' directory."
    echo -e "\033[34mInfo:\033[0m    This folder needs to be added to the repository in order the execute the pipeline successfully."
}

function generate_pipeline_files {

    echo -e "\033[34mInfo:\033[0m Creating all necessary files to step up the build pipeline...\n"

    mkdir -p ./build/pipeline
    for file_name in $(ls -p ./template/resources/ | grep -v /); do
        if [ ! -d "$file_name" ]; then
            cat "./template/resources/$file_name" | envsubst > ./build/pipeline/$file_name.yaml
            echo -e "created file: ./build/pipeline/$file_name"
        fi
    done

    cp -r ./template/tasks/ ./build/pipeline
    echo -e "\ntasks created: ./build/pipeline/\n"

    echo -e "\033[34mInfo:\033[0m ..all files created in '/build/pipeline'.\n"
}

function apply_pipeline_to_openshift {

    if ! command -v oc >/dev/null; then
        echo -e "\033[31mError:\033[0m Cannot find the openshift 'oc' cli. Make sure its installed correctly."
        echo -e "       or use the '--generate' option to create all neccesary 'yaml' files and apply them via the OpenShift user interface."
        exit 1
    fi

    # check connection to cluster
    if ! oc cluster-info &> /dev/null; then
        echo -e "\033[31mError:\033[0m You are not connected to a cluster. Connect first and than try again."
        echo -e "       or use the '--generate' option to create all neccesary 'yaml' files and apply them by yourself."
        exit 1
    fi
    
    status=$(oc cluster-info)
    cluster_url=$(echo "$status" | sed -n 's/.*\(https:\/\/[^ ]*\).*/\1/p')

    echo -e "\033[34mInfo:\033[0m Creating resources on connected cluster: \033[1m$cluster_url\033[0m"

    while true; do
        read -p "Are you sure? (yes/no): " answer
        if [[ $answer = "yes" || $answer = "y" ]]; then
            echo -e "Proceeding..."
            break
        elif [[ $answer = "no" || $answer = "n" ]]; then
            echo "Aborting..."
            exit 1
        else
            echo "Invalid input. Please enter 'yes' or 'no'."
        fi
    done

    for file_name in $(ls -p ./template/resources/ | grep -v /); do
        if [ ! -d "$file_name" ]; then
            cat "./template/resources/$file_name" | envsubst | oc apply -f -
            if [ $? -ne 0 ]; then
                echo -e "\033[31mError applying $file_name\033[0m"
                exit 1
            fi
        fi
    done
    oc apply -f ./template/tasks/

    route=$(oc get routes --namespace $NAMESPACE -o custom-columns=webhooks:spec.host | grep git-webhook-$APPLICATION_NAME-$SERVICE_NAME)

    echo -e "\n🎉 \033[32mSuccessfully created pipeline:\033[0m You can add the following route as webhook in your repositories:"
    echo -e "\n\033[35mImportant:\033[0m $route\n"
}

function check_ignore {
    if [ -n "$ignore" ]; then
        #gitignore
        echo -e "\npipeline.config" >> .gitignore
        echo -e "build/pipeline" >> .gitignore
        #dockerignore
        echo -e "\npipeline.config" >> .dockerignore
        echo -e "build/pipeline" >> .dockerignore
        
        echo -e "\n\033[32mSuccess:\033[0m Updated 'ignore' files."
    else
        echo -e "\033[33mWarning:\033[0m Don't forgett to put the pipeline.config and the pipeline folder on your ignore files, as well as the build/pipeline in case you created it.\n"
        echo -e "\033[33mWarning:\033[0m Do not commit the generated files to your repositroy due to saved secrets." 
        echo -e "         You can use the '-i' option to update the files automatically."
    fi
}

# ------------------------------------- Main Programm -----------------------------------------
# List of available parameter in the config file
parameters=("NAMESPACE" "APPLICATION_NAME" "SERVICE_NAME" "SERVICE_PORT" "GIT_REPOSITORY_URL" "GIT_SERVER_DOMAIN" "GIT_USER" "GIT_ACCESS_TOKEN")

while getopts "hagi" opt; do
  case $opt in
    h)
        print_help
        exit 0
        ;;
    a)
        apply=true
        ;;
    g)
        generate=true
        ;;
    i)
        ignore=true
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
  esac
done

echo -e "\033[1;47m Red Hat OpenShift Pipeline Creator \033[0m\n"

# ------------------------------------- Precheck -----------------------------------------
 if [ ! -d "./template" ]; then
    echo -e "\033[31mError:\033[0m Cannot run script. Missing folder \033[1m'template'\033[0m"
    exit 1
fi

get_input

# only generate files and exit
if [ -n "$generate" ] && [ ! -n "$apply" ]; then
    generate_pipeline_files
    check_ignore
    exit 0
# generate files but also apply
elif [ -n "$generate" ] && [ -n "$apply" ]; then
    generate_pipeline_files
fi

# if apply or no options passed also apply
apply_pipeline_to_openshift
check_ignore


echo -e "\033[35mImportant:\033[0m Please do not forget the containerfile / dockerfile in your repository for the build process."

exit 0