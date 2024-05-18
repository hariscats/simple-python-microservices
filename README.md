# Flask Microservices Demo on K8s

This repository contains a Flask microservices application that demonstrates deploying a Flask app on Azure Kubernetes Service (AKS) using Helm. The application uses Gunicorn as the WSGI server and includes health checks, system information endpoints, and more.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Build and Push Docker Image](#build-and-push-docker-image)
- [Deploy to AKS](#deploy-to-aks)
- [Verify Deployment](#verify-deployment)
- [Usage](#usage)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)

## Prerequisites

1. **Azure CLI**: Install the Azure CLI. Follow the instructions [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
2. **Kubectl**: Install kubectl. Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
3. **Helm**: Install Helm. Follow the instructions [here](https://helm.sh/docs/intro/install/).
4. **Docker**: Install Docker. Follow the instructions [here](https://docs.docker.com/get-docker/).
5. **Python 3.10**: Ensure Python 3.10 is installed on your machine.

## Setup

1. **Clone the Repository**:
   ```sh
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Create a Virtual Environment and Install Dependencies**:
   ```sh
   python -m venv venv
   source venv/bin/activate  # On Windows, use `venv\Scripts\activate`
   pip install -r requirements.txt
   ```

## Build and Push Docker Image

1. **Login to Azure and ACR**:
   ```sh
   az login
   az acr login --name <acr-name>
   ```

2. **Build the Docker Image**:
   ```sh
   docker build -t flask-microservices-demo .
   ```

3. **Tag the Docker Image**:
   ```sh
   docker tag flask-microservices-demo <acr-login-server>/flask-microservices-demo:1.0.0
   docker tag flask-microservices-demo <acr-login-server>/flask-microservices-demo:latest
   ```

4. **Push the Docker Image to ACR**:
   ```sh
   docker push <acr-login-server>/flask-microservices-demo:1.0.0
   docker push <acr-login-server>/flask-microservices-demo:latest
   ```

## Deploy to AKS

1. **Create AKS Cluster (if not already created)**:
   ```sh
   chmod +x create_aks_cluster.sh
   ./infra/provision-aks-cni-overlay.sh
   ```

2. **Set the Default Namespace**:
   ```sh
   kubectl create namespace mynamespace
   kubectl config set-context --current --namespace=mynamespace
   ```

3. **Update Helm Values**:
   Ensure your `values.yaml` in the Helm chart uses the correct ACR repository and image tag.
   ```yaml
   image:
     repository: <acr-login-server>/flask-microservices-demo
     tag: "1.0.0"
     pullPolicy: IfNotPresent
   ```

4. **Deploy the Helm Chart**:
   ```sh
   helm upgrade --install flask-app ./flask-app-0.2.0.tgz --namespace mynamespace --create-namespace
   ```

## Verify Deployment

1. **Check the Status of the Deployment**:
   ```sh
   kubectl get deployments
   kubectl get services
   kubectl get pods
   ```

2. **Get the External IP of the Service**:
   ```sh
   kubectl get svc flask-service
   ```

   Access the application using the external IP address.

## Usage

1. **Endpoints**:
   - `GET /`: Returns "Hello, World!"
   - `GET /health`: Returns the health status of the application.
   - `GET /details`: Returns the hostname and IP address of the pod.
   - `GET /env`: Returns environment variables.
   - `GET /time`: Returns the current server time.
   - `GET /network`: Returns network details of the pod.
   - `GET /system-info`: Returns CPU, memory, and disk usage.
   - `GET /random-joke`: Returns a random joke.

2. **Access the Application**:
   Open your browser and navigate to the external IP address of the service.

## Cleanup

To delete the resources created for this deployment, run the following commands:

1. **Uninstall the Helm Release**:
   ```sh
   helm uninstall flask-app --namespace mynamespace
   ```

2. **Delete the AKS Cluster**:
   ```sh
   az aks delete --resource-group <resource-group> --name <cluster-name> --yes --no-wait
   ```

## Troubleshooting

If you encounter issues, check the following:

1. **Check Pod Logs**:
   ```sh
   kubectl logs <pod-name> -n mynamespace
   ```

2. **Describe the Pod**:
   ```sh
   kubectl describe pod <pod-name> -n mynamespace
   ```

3. **Ensure All Services are Running**:
   ```sh
   kubectl get all -n mynamespace
   ```

4. **Check the Helm Release Status**:
   ```sh
   helm status flask-app --namespace mynamespace
   ```

For additional troubleshooting, refer to the Kubernetes and Helm documentation.

## Disclaimer

This project is provided "as-is" without any warranty or guarantee of any kind. Use at your own risk. The authors and maintainers are not responsible for any damages or issues that may arise from using this project.
```

Replace placeholder values like `<repository-url>`, `<acr-name>`, `<acr-login-server>`, `<resource-group>`, and `<cluster-name>` with the actual values relevant to your environment. This `README.md` provides comprehensive instructions for setting up, deploying, and using your Flask application on AKS.