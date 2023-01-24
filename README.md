# Create a Simple Tekton Pipeline for Openshift Projects

Run the command below directly from your projects repository:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/fabianschwab/openshift-tekton-pipeline/main/install.sh)"
```

If you are connected to the cluster, all resources can be created automatically in a given project.
Otherwise all files are in the `build` directory.

## Folder and File Structure

If the command is executed successfully, some files are downloaded to current dictionary:

• `create-pipeline.sh` executable
• `template` containing all `.yaml` files needed for the pipeline

After the execution of the script there is a `pipeline.config` file, which contains all the inputs from the command.
The values can be changed by running the script again or by editing them manually.

To update a changed configuration, execute the `create-pipeline.sh --apply` command.
If you are not connected to your cluster, generate the output files with `create-pipeline.sh --generate`

## Created Resources

1. Service accounts for the project:
   - For triggering pipeline runs [service-account-pipeline](./template/service-account-pipeline.yaml)
   - For accessing repositories [service-account-git](./template/service-account-git.yaml)
   - For deploying resources [service-account-deployment](./template/service-account-deployment.yaml)
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

## Future features

[ ] Push manifest to gitOps repo when successfully deployed

![GitHub](https://img.shields.io/github/license/fabianschwab/openshift-tekton-pipeline?logo=MIT&style=for-the-badge)
