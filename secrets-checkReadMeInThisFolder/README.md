# Rename the folder to `secrets` before doing anything else, making sure it's ignored by git!


## GitHub Container Registry Token
To run the `quick-start-test.sh` script, you'll need to set up the `ghcr-container-registry.read.yml` secret in the `secrets/kubernetes/development` folder.
This secret allows the grouphq minikube cluster to pull images from the GitHub container registry.

To set up the secret, you'll need to create a GitHub personal access token with the `read:packages` scope.

Once you have the token, [follow the instructions here to create the secret](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line).
Hint: The guide linked above assumes you already have kubectl set to a cluster context. You can start up
the local cluster using the script to follow the guide. The script step applying the secret will fail, so you'll need
to follow the link above to create it. Then, continue following this guide to set the secret in its own file
for the `quick-start-test.sh` script to apply it.

After creating the token, extract the docker config json data from the token by running the following command:

```bash
kubectl get secret ghcr-secret -o yaml
```

Copy the `dockerconfigjson` value and paste it into the `ghcr-container-registry.read.yml` file in the `secrets/kubernetes/development` folder.
Make sure it's all on one line. Note that it's already base64 encoded. If you want to verify the data, you can decode it using the following command:

```bash
echo "your-base64-encoded-string" | base64 --decode
```

The `quick-start-test.sh` script will apply the secret to the cluster for you the next time you run it.

## Let's Encrypt CloudFlare API Token (production only)
This secret should exist in production. It uses an API token generated through the CloudFlare dashboard to allow 
communication between cert-manager and CloudFlare's DNS API. 
The API token needs to have certain permissions and settings. [See here for the recommended settings](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/)

If you're configuring Let's Encrypt for production, then add the API token and apply the secret to the cluster using the following command:
```shell
kubectl apply -f production/cloudflare-api-token-secret.yml
```

## OpenAI API Key (production only)
This secret should exist in production if OpenAI integration is enabled.

If you're configuring OpenAI for production, then add the API key and apply the secret to the cluster using the following command:
```commandline
kubectl apply -f production/openai-api-key.yml
```