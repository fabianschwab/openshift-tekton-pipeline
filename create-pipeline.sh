export NAMESPACE=fluxfabian

export APPLICATION_NAME=error-handling
export SERVICE_NAME=event-processor
export SERVICE_PORT=3000

export GIT_SERVER_DOMAIN=https://eu-de.git.cloud.ibm.com
export GIT_REPOSITORY_URL=https://eu-de.git.cloud.ibm.com/bmw-dreamwork/preprocess.git
export GIT_USER=project_219377_bot
export GIT_ACCESS_TOKEN=glpat-a9wNPLmHUkNwMTbdBrxF

mkdir -p ./build/pipeline

cat ./template/image-stream.yaml | envsubst > ./build/pipeline/image-stream.yaml
cat ./template/pipeline.yaml | envsubst > ./build/pipeline/pipeline.yaml
cat ./template/secret-git.yaml | envsubst > ./build/pipeline/secret-git.yaml
cat ./template/service-account-deployment.yaml | envsubst > ./build/pipeline/service-account-deployment.yaml
cat ./template/service-account-git.yaml | envsubst > ./build/pipeline/service-account-git.yaml
cat ./template/service-account-pipeline.yaml | envsubst > ./build/pipeline/service-account-pipeline.yaml
cat ./template/trigger-event-listener.yaml | envsubst > ./build/pipeline/trigger-event-listener.yaml
cat ./template/trigger-route.yaml | envsubst > ./build/pipeline/trigger-route.yaml
cat ./template/trigger-template.yaml | envsubst > ./build/pipeline/trigger-template.yaml

cp -r ./resources/tasks ./build/pipeline

mkdir -p ./build/k8s

cat ./template/k8s/deployment.yaml | envsubst > ./build/k8s/deployment.yaml
cat ./template/k8s/route.yaml | envsubst > ./build/k8s/route.yaml
cat ./template/k8s/service.yaml | envsubst > ./build/k8s/service.yaml
cat ./template/k8s/kustomization.yaml | envsubst > ./build/k8s/kustomization.yaml

oc apply -f ./build/pipeline/tasks
oc apply -f ./build/pipeline

echo "Please copy the folder k8s in the build directory into your repositories root folder."
echo "Please do not forget the containerfile / dockerfile in your repository for the build process."

oc get routes -o custom-columns=webhooks:spec.host | grep git-webhook-$APPLICATION_NAME-$SERVICE_NAME