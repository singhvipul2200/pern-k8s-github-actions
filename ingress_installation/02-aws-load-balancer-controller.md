# 02 - AWS Load Balancer Controller

This document contains all commands used to install and configure the AWS Load Balancer Controller in the `pern-eks` Amazon EKS cluster.

The AWS Load Balancer Controller is required to allow Kubernetes Ingress resources to create and manage AWS Application Load Balancers (ALB).

---

# Cluster Information

```text
Cluster Name: pern-eks
AWS Region: us-east-1
AWS Account ID: 542650110758
Kubernetes Namespace: kube-system
```

---

# 1. Check EKS OIDC Provider

The AWS Load Balancer Controller uses the EKS OIDC provider to allow a Kubernetes ServiceAccount to assume an AWS IAM role.

Run:

```bash
aws eks describe-cluster \
  --name pern-eks \
  --region us-east-1 \
  --query 'cluster.identity.oidc.issuer' \
  --output text
```

Expected output:

```text
https://oidc.eks.us-east-1.amazonaws.com/id/3E52DEECBBB987A41EB8F72FBE46AEB
```

The OIDC provider ID for this cluster is:

```text
3E52DEECBBB987A41EB8F72FBE46AEB
```

---

# 2. Check AWS Load Balancer Controller IAM Policy

Check whether the IAM policy already exists:

```bash
aws iam get-policy \
  --policy-arn arn:aws:iam::542650110758:policy/AWSLoadBalancerControllerIAMPolicy
```

Expected result contains:

```text
AWSLoadBalancerControllerIAMPolicy
```

The policy ARN is:

```text
arn:aws:iam::542650110758:policy/AWSLoadBalancerControllerIAMPolicy
```

---

# 3. Check IAM Policy Versions

List all versions of the AWS Load Balancer Controller IAM policy:

```bash
aws iam list-policy-versions \
  --policy-arn arn:aws:iam::542650110758:policy/AWSLoadBalancerControllerIAMPolicy
```

Expected output contains:

```text
VersionId: v1
IsDefaultVersion: true
```

---

# 4. Check Whether IAM Role Exists

Check whether the AWS Load Balancer Controller IAM role exists:

```bash
aws iam get-role \
  --role-name AmazonEKSLoadBalancerControllerRole
```

The IAM role used for this installation is:

```text
AmazonEKSLoadBalancerControllerRole
```

The role ARN is:

```text
arn:aws:iam::542650110758:role/AmazonEKSLoadBalancerControllerRole
```

If the role does not exist, it must be created with an OIDC trust policy.

---

# 5. Create Trust Policy File

Create a file named:

```text
trust-policy.json
```

The trust policy allows the Kubernetes ServiceAccount:

```text
system:serviceaccount:kube-system:aws-load-balancer-controller
```

to assume the IAM role.

Create the file with:

```bash
cat > trust-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::542650110758:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/3E52DEECBBB987A41EB8F72FBE46AEB"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/3E52DEECBBB987A41EB8F72FBE46AEB:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "oidc.eks.us-east-1.amazonaws.com/id/3E52DEECBBB987A41EB8F72FBE46AEB:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF
```

---

# 6. Verify Trust Policy File

Display the file:

```bash
cat trust-policy.json
```

The important values should be:

```text
OIDC Provider:
oidc.eks.us-east-1.amazonaws.com/id/3E52DEECBBB987A41EB8F72FBE46AEB

ServiceAccount:
system:serviceaccount:kube-system:aws-load-balancer-controller
```

---

# 7. Create IAM Role

If the IAM role does not already exist, create it:

```bash
aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-document file://trust-policy.json
```

Expected result contains:

```text
AmazonEKSLoadBalancerControllerRole
```

---

# 8. Verify IAM Role

Check the IAM role:

```bash
aws iam get-role \
  --role-name AmazonEKSLoadBalancerControllerRole
```

The expected role ARN is:

```text
arn:aws:iam::542650110758:role/AmazonEKSLoadBalancerControllerRole
```

---

# 9. Check IAM Role Trust Relationship

The IAM role should contain the EKS OIDC provider.

Run:

```bash
aws iam get-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --query 'Role.AssumeRolePolicyDocument'
```

The output should contain:

```text
oidc.eks.us-east-1.amazonaws.com
```

and:

```text
system:serviceaccount:kube-system:aws-load-balancer-controller
```

---

# 10. Attach IAM Policy to IAM Role

Attach the AWS Load Balancer Controller IAM policy:

```bash
aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::542650110758:policy/AWSLoadBalancerControllerIAMPolicy
```

---

# 11. Verify IAM Policy Attachment

Check the policies attached to the role:

```bash
aws iam list-attached-role-policies \
  --role-name AmazonEKSLoadBalancerControllerRole
```

Expected output:

```text
AWSLoadBalancerControllerIAMPolicy
```

The policy ARN should be:

```text
arn:aws:iam::542650110758:policy/AWSLoadBalancerControllerIAMPolicy
```

---

# 12. Create Kubernetes ServiceAccount

Create the ServiceAccount in the `kube-system` namespace:

```bash
kubectl create serviceaccount aws-load-balancer-controller \
  -n kube-system
```

Expected output:

```text
serviceaccount/aws-load-balancer-controller created
```

---

# 13. Verify ServiceAccount

Check the ServiceAccount:

```bash
kubectl get serviceaccount aws-load-balancer-controller \
  -n kube-system
```

Expected output:

```text
NAME
aws-load-balancer-controller
```

---

# 14. Annotate ServiceAccount With IAM Role

Attach the IAM role to the Kubernetes ServiceAccount:

```bash
kubectl annotate serviceaccount aws-load-balancer-controller \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::542650110758:role/AmazonEKSLoadBalancerControllerRole
```

Expected output:

```text
serviceaccount/aws-load-balancer-controller annotated
```

---

# 15. Verify ServiceAccount Annotation

Run:

```bash
kubectl get serviceaccount aws-load-balancer-controller \
  -n kube-system \
  -o yaml
```

The output should contain:

```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::542650110758:role/AmazonEKSLoadBalancerControllerRole
```

You can also check only the role ARN:

```bash
kubectl get serviceaccount aws-load-balancer-controller \
  -n kube-system \
  -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

Expected output:

```text
arn:aws:iam::542650110758:role/AmazonEKSLoadBalancerControllerRole
```

---

# 16. Add EKS Helm Repository

Add the official EKS Helm repository:

```bash
helm repo add eks https://aws.github.io/eks-charts
```

If the repository already exists, Helm may show:

```text
"eks" already exists with the same configuration, skipping
```

This is not an error.

---

# 17. Update EKS Helm Repository

Update the Helm repository:

```bash
helm repo update eks
```

Expected output:

```text
Successfully got an update from the "eks" chart repository
Update Complete.
```

---

# 18. Search AWS Load Balancer Controller Helm Chart

Check the available AWS Load Balancer Controller chart versions:

```bash
helm search repo eks/aws-load-balancer-controller --versions
```

This displays available chart versions.

The version selected for this EKS cluster was:

```text
1.17.1
```

---

# 19. Install AWS Load Balancer Controller

Install the AWS Load Balancer Controller using Helm:

```bash
helm install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=pern-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --version 1.17.1
```

Expected result:

```text
NAME: aws-load-balancer-controller
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
```

---

# 20. Explanation of Helm Installation Options

The following option tells the controller which EKS cluster it belongs to:

```bash
--set clusterName=pern-eks
```

The following option prevents Helm from creating a new ServiceAccount:

```bash
--set serviceAccount.create=false
```

This is important because the ServiceAccount was already created manually.

The following option tells Helm to use the existing ServiceAccount:

```bash
--set serviceAccount.name=aws-load-balancer-controller
```

The following option specifies the Helm chart version:

```bash
--version 1.17.1
```

---

# 21. Verify Helm Release

Check the Helm release:

```bash
helm list -n kube-system
```

The output should contain:

```text
aws-load-balancer-controller
```

The status should be:

```text
deployed
```

---

# 22. Check Helm Release Status

Run:

```bash
helm status aws-load-balancer-controller \
  -n kube-system
```

Expected:

```text
STATUS: deployed
```

---

# 23. Verify AWS Load Balancer Controller Deployment

Check the deployment:

```bash
kubectl get deployment aws-load-balancer-controller \
  -n kube-system
```

Expected output:

```text
NAME                           READY   UP-TO-DATE   AVAILABLE
aws-load-balancer-controller   2/2     2            2
```

The important values are:

```text
READY: 2/2
UP-TO-DATE: 2
AVAILABLE: 2
```

---

# 24. Verify AWS Load Balancer Controller Pods

Check the controller pods:

```bash
kubectl get pods \
  -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller
```

Expected output should contain two pods similar to:

```text
NAME                                             READY   STATUS    RESTARTS
aws-load-balancer-controller-xxxxxxxxxx-xxxxx   1/1     Running   0
aws-load-balancer-controller-xxxxxxxxxx-xxxxx   1/1     Running   0
```

Both pods should show:

```text
1/1
Running
```

---

# 25. Verify Controller ServiceAccount Used by Deployment

Check the ServiceAccount configured on the deployment:

```bash
kubectl get deployment aws-load-balancer-controller \
  -n kube-system \
  -o jsonpath='{.spec.template.spec.serviceAccountName}'
```

Expected output:

```text
aws-load-balancer-controller
```

---

# 26. Check Controller Logs

Check the controller logs:

```bash
kubectl logs \
  -n kube-system \
  deployment/aws-load-balancer-controller
```

To continuously follow the logs:

```bash
kubectl logs \
  -n kube-system \
  deployment/aws-load-balancer-controller \
  -f
```

Press:

```text
CTRL + C
```

to stop following the logs.

---

# 27. Check Controller Events

Check events in the `kube-system` namespace:

```bash
kubectl get events \
  -n kube-system \
  --sort-by=.lastTimestamp
```

---

# 28. Verify Controller Resources

Check all resources related to the controller:

```bash
kubectl get all \
  -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller
```

---

# 29. Verify ServiceAccount and IAM Role Together

Check the ServiceAccount:

```bash
kubectl get serviceaccount aws-load-balancer-controller \
  -n kube-system \
  -o yaml
```

Check the IAM role:

```bash
aws iam get-role \
  --role-name AmazonEKSLoadBalancerControllerRole
```

Check the IAM policy attachment:

```bash
aws iam list-attached-role-policies \
  --role-name AmazonEKSLoadBalancerControllerRole
```

---

# 30. Complete Verification Commands

The following commands can be used for a quick verification after installation.

## Check Helm

```bash
helm list -n kube-system
```

## Check Deployment

```bash
kubectl get deployment aws-load-balancer-controller \
  -n kube-system
```

## Check Pods

```bash
kubectl get pods \
  -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Check ServiceAccount

```bash
kubectl get serviceaccount aws-load-balancer-controller \
  -n kube-system
```

## Check ServiceAccount Annotation

```bash
kubectl get serviceaccount aws-load-balancer-controller \
  -n kube-system \
  -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

## Check IAM Role

```bash
aws iam get-role \
  --role-name AmazonEKSLoadBalancerControllerRole
```

## Check IAM Policy Attachment

```bash
aws iam list-attached-role-policies \
  --role-name AmazonEKSLoadBalancerControllerRole
```

---

# 31. Expected Final State

After successful installation:

```text
EKS Cluster
│
├── pern-eks
│
├── OIDC Provider
│   └── 3E52DEECBBB987A41EB8F72FBE46AEB
│
├── IAM Role
│   └── AmazonEKSLoadBalancerControllerRole
│
├── IAM Policy
│   └── AWSLoadBalancerControllerIAMPolicy
│
└── Kubernetes
    │
    └── kube-system
        │
        ├── ServiceAccount
        │   └── aws-load-balancer-controller
        │
        └── Deployment
            └── aws-load-balancer-controller
                ├── Pod 1 → Running
                └── Pod 2 → Running
```

---

# 32. AWS Load Balancer Controller Installation Flow

```text
EKS Cluster
     |
     v
Check OIDC Provider
     |
     v
Check IAM Policy
     |
     v
Create IAM Role
     |
     v
Attach IAM Policy
     |
     v
Create Kubernetes ServiceAccount
     |
     v
Annotate ServiceAccount
     |
     v
Add EKS Helm Repository
     |
     v
Update Helm Repository
     |
     v
Install AWS Load Balancer Controller
     |
     v
Verify Helm Release
     |
     v
Verify Deployment
     |
     v
Verify Pods
     |
     v
AWS Load Balancer Controller Ready
```

---

# 33. Why the Controller Is Installed in kube-system

The AWS Load Balancer Controller is a cluster-level infrastructure component.

Therefore, it is installed in:

```text
kube-system
```

The application itself will later be deployed separately in:

```text
pern-app
```

The architecture will be:

```text
kube-system
│
└── AWS Load Balancer Controller
          |
          | watches Ingress resources
          v
pern-app
│
├── Frontend Deployment
├── Backend Deployment
├── Frontend Service
├── Backend Service
└── Ingress
          |
          v
AWS Application Load Balancer
```

---

# 34. Important Note About Application Namespace

The AWS Load Balancer Controller does NOT need to be installed inside the application namespace.

The controller remains:

```text
kube-system
```

The PERN application will use:

```text
pern-app
```

The controller can watch and manage Ingress resources created in the `pern-app` namespace.

---

# 35. AWS Load Balancer Controller Is Installed Only Once

The AWS Load Balancer Controller is a cluster-level component.

It does not need to be installed every time the PERN application is deployed.

Once installed successfully, the Helm application chart can create the application's:

```text
Namespace
Deployments
Services
Ingress
ConfigMaps
Secrets
```

The existing AWS Load Balancer Controller will handle the application's Ingress and communicate with AWS to create/manage the Application Load Balancer.

---

# 36. Final Verification

Run:

```bash
kubectl get deployment aws-load-balancer-controller \
  -n kube-system
```

Expected:

```text
aws-load-balancer-controller   2/2   2   2
```

Then:

```bash
kubectl get pods \
  -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller
```

Expected:

```text
1/1   Running
1/1   Running
```

Then:

```bash
helm list -n kube-system
```

Expected:

```text
aws-load-balancer-controller
```

with:

```text
STATUS: deployed
```

At this point, the AWS Load Balancer Controller is successfully installed and ready for the PERN application's Kubernetes Ingress.
