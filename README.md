CI/CD ProjectGit-Docker-Jenkins-K8's-ArgoCD using AWS.

In this project, we will deploy a Python application with two method.

First, we will commit code changes to a public github repo,and we will trigger CICD jenkins job using VSCode itself and connect Kubernetes nodes to ArgoCD.

Second, we will create a private repo for CD job, connect it to ArgoCD, and trigger CD Jenkins job using Curl command and pass variables from CI pipeline.

Prerequisites.

1. VSCode (Text Editor), jenkins runner & pipeline-linter-connector configured.
2. Docker install on your local host.
3. AWS CLI installed.
4. A personal AWS account.

Deployment

1. Declarative CI/CD Jenkins job.

Create:

Python application code

Kubernetes manifest files (deployment.yaml,service.yaml and setting.json).

Dockerfile

Jenkinsfile with the followig stages:

* Cleanup workspace
* Checkout SCM
* Build Docker Image
* Push Docker Image
* Delete Docker Image
* Updatting Kubernetes Deployment files
* Push the changed Deployment file to Git

Server Setup & Installation

Create a server in AWS (jenkins-server), OS Ubuntu, instance type t2.medium in my case with 20 GIB enough to download docker and Kubernetes softwares, edit setting to add security group rule with source type anywhere and set port range 8080, lauch instance and connect to the server.

Download  Java

sudo apt-get update
sudo apt-get install openjdk-11-jdk -y

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update

Install & Unlock Jenkins

sudo apt-get install jenkins -y
sudo systemctl start jenkins.service
sudo systemctl status jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
#by default, jenkins runs on port 8080.
We will create login credentials, manage jenkins plugins, create access tokens for both github and dockerhub, generate jekins API token.

Install Docker

vi dock.sh

#!/bin/bash
sudo apt update -y


sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" -y

sudo apt update -y

apt-cache policy docker-ce -y

sudo apt install docker-ce -y

#sudo systemctl status docker

sudo chmod 777 /var/run/docker.sock


sh dock.sh

docker info

#enable minikube
minikube start
minikube status

Download Argo CD on your local host and the followig commands on a terminal.

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl get all -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
#Open a new terminal for username & password command.
argocd admin initial-password -n argocd

Job Excution

Create a declative jenkins pipeline job.

Set jekins url (localhost:8080) on your settings.json file.

Trigger jenkins job from VSCode using command palette Jenkins Runner: Run Pipeline Script On Default job. We will be adding stages on jenkins file one by one after each successful run to aviod botleneck when error due occur and make it easier to fix issues before moving forward.

Create Argo CD application which will be checking repo latest update,connect kubernetes nodes to Argo CD and trigger the job from VSCode.


2. Declarative Jenkins pipeline CD job.

For best practice, we will create a private repo (for CD job) where we will copy and past the same deployment.yaml file used on the precedent job. We will manually trigger CD job from a jenkins CI pipeline using newly created jenkinsfileCI and  jenkinsfileCD.

JenkinsfileCI without CD stages:

* Cleanup workspace
* Checkout SCM
* Build Docker Image
* Push Docker Image
* Delete Docker Image
* Trigger config change pipeline with curl command below.

sh "curl -v -k --user name: jekins API Token -X POST -H 'cache-control: no-cache' -H  'content-type:application/x-www-form-urlencoded'  --data  'IMAGE_TAG=${IMAGE_TAG}' 'jenkins url/job/CD job name/buildWithParameters?token=token name' "



jenkinsfileCD

* Cleanup workspace
* Checkout SCM
* Updatting Kubernetes Deployment files
* Push the changed Deployment file to Git

Job Excution

First, create a jenkins CI pipeline job where on the pipeline script we will simply copy and past the newly created jenkinsfileCI, then click on Build Now to ensure the job is running properly.

Second, create a a jenkins CI pipeline where we will check: 'this project is parameterized'-> add 'String Parameter', write the paramter name and description, in case "IMAGE_TAG"; check 'Trigger remotely' and write a token name, in my case "jenkins-config" that we will insert on our jenkins CI pipeline "curl command", and we will copy and past jenkinsfileCD on the pipeline script as well.

Third, run the jenkins CI pipeline job, if everything is properly setup, CI job should be trigging CD jankins job using curl command and pass variable. Then we will create an Argo CD application for CD jenkins job, connect kubernetes nodes to Argo CD then trigger the job from CI jenkins pipeline.





 






Documentation

https://www.youtube.com/watch?v=kuSdi8bDztk

https://kubernetes.io/

https://www.jenkins.io/