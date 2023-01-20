# Create Tekton Pipeline for Openshift Projects

To create a pipeline check out the `create-pipeline.sh` and modify the environment variables.

Than run:

```shell
./create-pipeline.sh
```

If you are connected to the cluster, all resources are created automatically in the current project.
Otherwise all files are in the `build` directory.

## Created Resources

1. Service accounts for the project:
   - For triggering pipeline runs [service-account-pipeline](./template/service-account-pipeline.yaml)
   - For accessing repositories [service-account-git](./template/service-account-git.yaml)
   - For deploying resources [service-account-deployment](./template/service-account-deployment.yaml)
   <!-- ! FIXME trigger service account cluster role ??? namespace for project??? -->
2. Secret for each service of an application
   - For accessing the source repository [secret-git](./template/secret-git.yaml)
3. Image streams for each service to keep the build images
   - Image streams where the build images get stored [image-stream](./template/image-stream.yaml)
4. Pipeline for each service
   - Pipeline which defines all steps which are executed [pipeline](./template/pipeline.yaml)
5. Routes (webhook) and Triggers for each service, so that the pipeline can start on git events
   - Trigger template which specifies a blueprint for a pipeline run [trigger-template](./template/trigger-template.yaml)
   - Event Listener which is triggering the pipeline [trigger-event-listener](./template/trigger-event-listener.yaml)
   - Route for the git webhook [trigger-route](./template/trigger-route.yaml)
6. Tekton Tasks
   <!-- TODO - kustomize-build -->
   <!-- TODO - test-deployment -->

## Manual steps

Change all `environment variables` in the files to your needs and apply all `.yaml` files.

```shell
# To setup the pipeline run the following commands
cd template

oc apply -f service-account-pipeline.yaml
oc apply -f service-account-git.yaml
oc apply -f service-account-deployment.yaml

oc apply -f secret-git.yaml
oc apply -f image-stream.yaml
oc apply -f pipeline.yaml
oc apply -f trigger-template.yaml
oc apply -f trigger-event-listener.yaml
oc apply -f trigger-route.yaml

# To setup the tasks needed by the pipeline run the following commands
cd .. && cd resources/tasks

oc apply -f kustomize-build.yaml
oc apply -f test-deployment.yaml

cd ../..

# Tog et the webhook for you repository run
oc get routes -o custom-columns=webhooks:spec.host
```

## Future features

[ ] Proper formatted output
[ ] Check for connected cluster (oc)
[ ] Push manifest to gitOps repo when successfully deployed
[ ] CLI asking for input vars => when already set show old input in brackets and allow as default value
