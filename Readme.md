# CloudPulse

## 📌 Project Description
CloudPulse is a cloud‑native monitoring and automation solution that integrates **Prometheus, Grafana, AWS EC2, IAM, S3**, and **GitHub Actions with OIDC** to provide a complete, secure, and automated observability platform.

The project ensures:
- Real‑time infrastructure metrics collection using **Prometheus**
- Interactive dashboards using **Grafana**
- Automated deployments using **GitHub Actions**
- Secure, keyless authentication using **AWS IAM Identity Federation (OIDC)**
- Infrastructure provisioning using **Terraform**

CloudPulse eliminates the need for long‑lived IAM access keys by using GitHub OIDC to allow GitHub Actions to assume IAM roles securely.

---

## 🔧 Required Setup
Before running CloudPulse, ensure the following components are ready:

### **1. AWS Setup**
- AWS Account
- IAM Role for GitHub OIDC
- EC2 Instances
  - Prometheus instance
  - Grafana instance
- Security Groups for inbound/outbound control
- S3 bucket (optional, if storing logs/metrics)
- Custom VPC with subnets (optional)

### **2. GitHub Repository**
- Source code hosted on GitHub
- GitHub Actions workflow enabled

### **3. Terraform**
- Terraform installed locally
- Terraform AWS provider configured to use OIDC role

---

## 🔐 OIDC Setup (GitHub → AWS IAM)
CloudPulse uses **GitHub Actions OIDC** to allow workflows to assume a role without storing secret keys.

### **Step 1 — Create OIDC Identity Provider**
1. Go to **IAM → Identity Providers → Add Provider**
2. Select **OpenID Connect**
3. Provider URL:
   ```
   https://token.actions.githubusercontent.com
   ```
4. Audience:
   ```
   sts.amazonaws.com
   ```
5. Create Provider

### **Step 2 — Create IAM Role for GitHub OIDC**
1. Go to **IAM → Roles → Create Role**
2. Select **Web Identity**
3. Choose Provider:
   - `token.actions.githubusercontent.com`
4. Specify:
   - GitHub Organization
   - Repository (optional)
   - Branch (optional)
5. Skip permissions for now → Create role

### **Step 3 — Add Permissions to the Role**
1. Go to **IAM → Policies → Create Policy**
2. Add your required permissions (EC2, S3, VPC, etc.)
3. Save the policy
4. Attach the policy to your OIDC role

### **Step 4 — Add Trust Policy Conditions**
Example trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:*"
        }
      }
    }
  ]
}
```

### **Step 5 — Add Custom Permission Policy to the Role**
Below is the custom IAM policy to attach to the role created for GitHub OIDC:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "ec2:Describe*",
        "ec2:CreateVpc",
        "ec2:CreateSubnet",
        "ec2:CreateRouteTable",
        "ec2:AssociateRouteTable",
        "ec2:CreateInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DeleteSecurityGroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:GetPolicy:,
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### **Step 6 — Configure GitHub Actions****
In `.github/workflows/deploy.yml`:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::ACCOUNT_ID:role/YOUR_OIDC_ROLE
      aws-region: ap-south-1
```

Your workflow can now deploy without secrets.

---

## 🚀 Project Benefits
- Fully automated deployments
- Secure authentication without static AWS keys
- Real-time server monitoring
- Infrastructure stored as code
- Works seamlessly across environments

---


