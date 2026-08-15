# 01 - EKS Cluster Connection

This document contains the commands used to connect to the AWS EKS cluster from a local Git Bash terminal.

## Cluster Details

- **Cluster Name:** `pern-eks`
- **AWS Region:** `us-east-1`
- **Platform:** Amazon EKS

---

## 1. Check AWS CLI

Check whether AWS CLI is installed:

```bash
aws --version
```

---

## 2. Check AWS Identity

Check which AWS account and IAM identity are currently being used:

```bash
aws sts get-caller-identity
```

---

## 3. Check EKS Cluster

Check the status of the EKS cluster:

```bash
aws eks describe-cluster \
  --name pern-eks \
  --region us-east-1 \
  --query "cluster.status" \
  --output text
```

Expected output:

```text
ACTIVE
```

---

## 4. Check EKS OIDC Provider

Check the OIDC issuer associated with the EKS cluster:

```bash
aws eks describe-cluster \
  --name pern-eks \
  --region us-east-1 \
  --query 'cluster.identity.oidc.issuer' \
  --output text
```

Example output:

```text
https://oidc.eks.us-east-1.amazonaws.com/id/<OIDC_ID>
```

---

## 5. Configure kubectl for EKS

Connect the local `kubectl` configuration to the EKS cluster:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name pern-eks
```

This command adds the EKS cluster to the local kubeconfig.

---

## 6. Check Current Kubernetes Context

Verify that kubectl is connected to the correct cluster:

```bash
kubectl config current-context
```

Expected output will be similar to:

```text
arn:aws:eks:us-east-1:<AWS_ACCOUNT_ID>:cluster/pern-eks
```

---

## 7. List Kubernetes Contexts

If multiple Kubernetes clusters are configured locally:

```bash
kubectl config get-contexts
```

---

## 8. Check EKS Nodes

Verify that the EKS worker nodes are accessible:

```bash
kubectl get nodes
```

Expected output:

```text
NAME                          STATUS   ROLES    AGE   VERSION
<node-name>                   Ready    <none>   ...   ...
<node-name>                   Ready    <none>   ...   ...
```

The node status should be:

```text
Ready
```

---

## 9. Check All Pods

Check pods across all namespaces:

```bash
kubectl get pods -A
```

---

## 10. Check All Kubernetes Resources

Check Kubernetes resources across all namespaces:

```bash
kubectl get all -A
```

---

## 11. Check Kubernetes Permissions

Verify whether the current identity can list Kubernetes nodes:

```bash
kubectl auth can-i list nodes
```

Expected output:

```text
yes
```

---

## 12. Check EKS Access Entries

List the IAM principals that have access to the EKS cluster:

```bash
aws eks list-access-entries \
  --cluster-name pern-eks \
  --region us-east-1
```

---

## 13. Describe an EKS Access Entry

To inspect a specific IAM principal:

```bash
aws eks describe-access-entry \
  --cluster-name pern-eks \
  --principal-arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/<IAM_USER> \
  --region us-east-1
```

Replace:

- `<AWS_ACCOUNT_ID>` with the AWS account ID
- `<IAM_USER>` with the IAM user name

---

# Quick EKS Connection

For future connections, the main command required is:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name pern-eks
```

Then verify the connection:

```bash
kubectl get nodes
```

Check pods:

```bash
kubectl get pods -A
```

---

# Troubleshooting

## kubectl Authentication Error

First check the current AWS identity:

```bash
aws sts get-caller-identity
```

Then refresh the kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name pern-eks
```

Then verify:

```bash
kubectl get nodes
```

---

## Wrong Kubernetes Context

Check the current context:

```bash
kubectl config current-context
```

List all contexts:

```bash
kubectl config get-contexts
```

Switch to the EKS context if required:

```bash
kubectl config use-context arn:aws:eks:us-east-1:<AWS_ACCOUNT_ID>:cluster/pern-eks
```

---

# Environment

The commands in this project were executed from a fresh **Git Bash** terminal on Windows.

### Tools Used

- AWS CLI
- kubectl
- Helm
- Git Bash

### EKS Cluster

```text
pern-eks
```

### AWS Region

```text
us-east-1
```

---

# EKS Connection Flow

```text
AWS CLI
   |
   | aws sts get-caller-identity
   v
Verify AWS Identity
   |
   | aws eks describe-cluster
   v
Verify EKS Cluster
   |
   | aws eks update-kubeconfig
   v
Configure kubectl
   |
   | kubectl config current-context
   v
Verify Kubernetes Context
   |
   | kubectl get nodes
   v
Verify EKS Worker Nodes
```

---

# Result

After completing the above steps, the local Git Bash terminal is connected to the `pern-eks` EKS cluster and is ready to manage Kubernetes resources using `kubectl` and Helm.
