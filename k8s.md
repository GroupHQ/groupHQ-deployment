The following is a list of commands to work with Kubernetes

- **Start Minikube with specified profile and configurations:**  
  `minikube start --cpus 2 --memory 4g --driver docker --profile grouphq`


- **Start Minikube with a specific profile:**  
  `minikube start --profile grouphq`


- **Stop Minikube with a specific profile:**  
  `minikube stop --profile grouphq`


- **Delete Minikube cluster with a specific profile:**  
  `minikube delete --profile grouphq`


- **Load a Docker image into Minikube with a specific profile:**  
  `minikube image load group-service --profile grouphq`


- **Retrieve all nodes in the Kubernetes cluster:**  
  `kubectl get nodes`


- **Get a list of all the Kubernetes contexts:**  
  `kubectl config get-contexts`


- **Display the current Kubernetes context:**  
  `kubectl config current-context`


- **Switch to a specific Kubernetes context:**  
  `kubectl config use-context grouphq`


- **Apply a Kubernetes manifest:**  
  `kubectl apply -f <resource-path>`


- **Retrieve all pods in the current namespace:**  
  `kubectl get pod`


- **Delete a resource using its manifest:**  
  `kubectl delete -f <resource-path>`


- **Get all Kubernetes resources with a specific label:**  
  `kubectl get all -l app=group-service`


- **View logs of a specific deployment:**  
  `kubectl logs deployment/group-service`


- **Describe a specific pod:**  
  `kubectl describe pod <pod_name>`


- **View logs of a specific pod:**  
  `kubectl logs <pod_name>`


- **Get services with a specific label:**  
  `kubectl get svc -l app=<service-name>`


- **Forward a local port to a port on the service:**  
  `kubectl port-forward service/<service-name> <host-port>:<service-port>`


- **Delete a specific pod:**  
  `kubectl delete pod <pod-name>`


- **Enable the ingress addon in Minikube with a specific profile:**  
  `minikube addons enable ingress --profile grouphq`


- **Get all resources in the ingress-nginx namespace:**  
  `kubectl get all -n ingress-nginx`


- **Create a tunnel to services in Minikube with a specific profile:**  
  `minikube tunnel --profile grouphq`


- **Retrieve all deployments in the current namespace:**  
  `kubectl get deploy`


- **Retrieve all configmaps with a specific label:**  
  `kubectl get cm -l app=group-service`


- **Create a secret from literals:**  
  `kubectl create secret generic <secret-name> --from-literal=<example-property-key>=<example-property-value>`


- **Retrieve a specific secret:**  
  `kubectl get secret <secret-name>`


- **Retrieve a specific secret in YAML format:**  
  `kubectl get secret <secret-name> -o yaml`


- **Apply a directory, file, or a URL with a Kustomize setup:**  
  `kubectl apply -k <resource-path>`


- **Delete resources using Kustomize definition:**  
  `kubectl delete -k <resource-path>`


- **Edit image details with Kustomize:**  
  `kustomize edit set image <image-name>=ghcr.io/<user or organization>/<package-name>:<tag>`


- **Get detailed information about pods, including the node they're running on:**  
  `kubectl get pod -o wide`


- **Watch the pods with a specific label:**  
  `kubectl get pods -l app=<label> --watch`


---

### doctl Commands (DigitalOcean):

- **List available Kubernetes regions on DigitalOcean:**  
  `doctl k8s options regions`


- **Create a Kubernetes cluster on DigitalOcean with specific configurations:**  
  `doctl k8s cluster create <cluster-name> --node-pool "name=basicnp;size=s-2vcpu-4gb;count=3;label=type=basic;" --region <region>`


- **List available VM sizes on DigitalOcean:**  
  `doctl compute size list`


- **List all Kubernetes clusters on DigitalOcean:**  
  `doctl k8s cluster list`


- **Get current Kubernetes context:**  
  `kubectl config current-context`


- **Retrieve all nodes in the Kubernetes cluster:**  
  `kubectl get nodes`


- **Create a PostgreSQL database on DigitalOcean:**  
  `doctl databases create grouphq-db --engine pg --region nyc1 --version 14`


- **List all databases on DigitalOcean:**  
  `doctl databases list`


- **Append a firewall rule to a PostgreSQL database on DigitalOcean:**  
  `doctl databases firewalls append <postgres_id> --rule k8s:<cluster_id>`


- **Create a database in a PostgreSQL instance on DigitalOcean:**  
  `doctl databases db create <postgres_id> <database_name>`


- **Get connection details of a PostgreSQL database on DigitalOcean:**  
  `doctl databases connection <postgres_id> --format Host,Port,User,Password`


- **Create a secret in Kubernetes from PostgreSQL connection details:**
```shell
  kubectl create secret generic <credential-name> \
  --from-literal=spring.flyway.url=jdbc:postgresql://<postgres_host>:<postgres_port>/<postgres_database> \
  --from-literal="spring.r2dbc.url=r2dbc:postgresql://<postgres_host>:<postgres_port>/<postgres_database>?ssl=true&sslMode=require" \
  --from-literal=spring.r2dbc.username=<username> \
  --from-literal=spring.r2dbc.password=<password>
```


- **Create a Redis database on DigitalOcean:**  
`doctl databases create grouphq-redis --engine redis --region nyc1 --version 7`


- **Append a firewall rule to a Redis database on DigitalOcean:**
`doctl databases create grouphq-redis --engine redis --region nyc1 --version 7`


- **Get connection details of a Redis database on DigitalOcean:**  
`doctl databases connection <redis_id> --format Host,Port,User,Password`


- **Create a secret in Kubernetes from Redis connection details:**
```shell
kubectl create secret generic <credential-name> \
--from-literal=spring.data.redis.host=<redis_host> \
--from-literal=spring.data.redis.port=<redis_port> \
--from-literal=spring.data.redis.username=<redis_username> \
--from-literal=spring.data.redis.password=<redis_password> \
--from-literal=spring.data.redis.ssl.enabled=true
```


- **Get the password of the initial admin user in ArgoCD:**
```shell
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d; echo
```


- **Get the service details for ArgoCD server:**
`kubectl -n argocd get service argocd-server`


- **Login to ArgoCD (username is admin. for password, see above):**
`argocd login <argocd-external-ip>`


- **Add a private repository to ArgoCD:**
```shell
argocd repo add <repo-link> \
--username <username> \
--password <password or access token with repo scope>
```


- **Create an ArgoCD app:**
```shell
argocd app create <deployment-name> \
--repo <repo-link> \
--path <directory-path-to-monitor> \
--dest-server https://kubernetes.default.svc \
--dest-namespace default \
--sync-policy auto \
--auto-prune 
```

argocd app create grouphq-ui \
--repo https://github.com/GroupHQ/groupHQ-deployment \
--path kubernetes/applications/grouphq-ui/production \
--dest-server https://kubernetes.default.svc \
--dest-namespace default \
--sync-policy auto \
--auto-prune

- **Get details of an ArgoCD app:**
`argocd app get <deployment-name>`


- **Get details of a specific application in ArgoCD:**
`argocd app get <deployment-name>`


- **List all Ingress resources in the current namespace:**
`kubectl get ingress`