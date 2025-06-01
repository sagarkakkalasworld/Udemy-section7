# 🚀 CI/CD with AWS: CodeBuild, CodeDeploy, and CodePipeline

This project demonstrates a complete CI/CD pipeline using three powerful AWS services:

- **CodeBuild** – Builds a Docker image and pushes it to Docker Hub.
- **CodeDeploy** – Restarts application pods on a server.
- **CodePipeline** – Connects build and deploy stages and acts as a webhook for automation.

---

## 🔧 AWS CodeBuild

### 🛠 Step 1: Create a CodeBuild Project

1. Go to **CodeBuild** in the AWS Console.
2. Click **Create Project**.
3. Choose a project name.
4. In the **Source** section, select **GitHub** (or your code repo).
   - For public repositories, choose **Public repository**.
5. In **Environment**:
   - Managed image: **Ubuntu**
   - Runtime: **Standard**
   - Role: Let AWS create a new service role

---

### 🔐 Authentication with Docker Hub

To push Docker images, you need:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

We explore two ways to store these securely.

---

### 📦 Case 1: Environment Variables

1. Save credentials in **Environment variables**.
2. Use the following `buildspec.yml`:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Docker Hub...
      - echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

  build:
    commands:
      - npm install
      - npm run build
      - docker build -t ci-cd-deployment .
      - docker tag ci-cd-deployment sagarkakkalasworld/ci-cd-deployment

  post_build:
    commands:
      - docker push sagarkakkalasworld/ci-cd-deployment
````

3. Start the build and monitor logs.
4. ✅ Image will appear in Docker Hub.

---

### 🔒 Case 2: AWS Secrets Manager (More Secure)

1. **Create an IAM role** with access to Secrets Manager.

   * Attach CodeBuild's default policies.
2. **Store DockerHub credentials** in Secrets Manager:

   * Secret name: `DockerHubCredentials`
   * Format:

```json
{
  "DOCKER_USERNAME": "your_dockerhub_username",
  "DOCKER_PASSWORD": "your_dockerhub_password"
}
```

3. Use this `buildspec.yml`:

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 16
    commands:
      - apt-get update && apt-get install -y jq

  pre_build:
    commands:
      - echo Fetching Docker credentials from AWS Secrets Manager...
      - |
        SECRET=$(aws secretsmanager get-secret-value --secret-id DockerHubCredentials --query SecretString --output text)
        export DOCKER_USERNAME=$(echo $SECRET | jq -r '.DOCKER_USERNAME')
        export DOCKER_PASSWORD=$(echo $SECRET | jq -r '.DOCKER_PASSWORD')
      - echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

  build:
    commands:
      - npm install
      - npm run build
      - docker build -t ci-cd-deployment .
      - docker tag ci-cd-deployment sagarkakkalasworld/ci-cd-deployment

  post_build:
    commands:
      - docker push sagarkakkalasworld/ci-cd-deployment
```

4. Start the build and confirm success.

---

## 🚀 AWS CodeDeploy

> 🔔 **Pre-requisite**: Ensure both the **deploy server** and **agent server** are **running**.

### 🖥️ Step 1: Setup EC2 Instance

1. Launch an EC2 Ubuntu instance.
2. SSH into the instance.

### 🔑 Step 2: Generate SSH Keys

```bash
ssh-keygen
```

* Save in: `/home/ubuntu/.ssh/id_rsa`
* Copy `id_rsa.pub` to the target server’s `authorized_keys`.

### 🔁 Step 3: Test SSH

```bash
ssh ubuntu@<DEMO_SERVER_IP>
exit
```

---

### 🔧 Step 4: CodeDeploy Agent Setup

1. Create two IAM roles:

   * For **CodeDeploy** (access EC2/S3)
   * For **EC2** (access CodeDeploy)
2. Attach EC2 role to instance.
3. SSH into EC2 and run:

```bash
sudo apt update
sudo apt install ruby-full wget
cd /home/ubuntu

wget https://aws-codedeploy-us-west-1.s3.us-west-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Check status
systemctl status codedeploy-agent

# If not running
sudo systemctl start codedeploy-agent
```

> ⚠️ After attaching the role:

```bash
sudo service codedeploy-agent restart
```

📌 [AWS Agent Install Docs](https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-ubuntu.html)
📌 [AWS Regional S3 Buckets](https://docs.aws.amazon.com/codedeploy/latest/userguide/resource-kit.html#resource-kit-bucket-names)

---

### 🏗 Step 5: Create CodeDeploy Application

1. Go to **CodeDeploy**.
2. Click **Create Application**.
3. Enter name.
4. Select **EC2/On-premises** as compute platform.
5. Click **Create Application**.

### 🔧 Step 6: Create Deployment Group

1. Click **Create Deployment Group**.
2. Enter name.
3. Use **CodeDeployRole** ARN.
4. Choose:

   * **EC2 instances**
   * EC2 instance **tags**
5. Disable "Enable load balancing".
6. Click **Create Deployment Group**.

---

### 🚀 Step 7: Create a Deployment

1. Click **Create Deployment**.
2. Select **My application is in GitHub**.
3. Authenticate via **GitHub token**.
4. Provide:

   * **Repo**: `sagarkakkalasworld/Udemy-section7`
   * **Commit ID**: `f3e7838c9be9733c7f27f006d2b5a3168430a308`

---

### 📄 Required Files in GitHub Repo

#### ✅ `appspec.yml`

```yaml
version: 0.0
os: linux
hooks:
  AfterInstall:
    - location: restart.sh
      timeout: 60
      runas: ubuntu
```

#### ✅ `restart.sh`

```bash
#!/bin/bash
ssh ubuntu@172.31.30.63 "microk8s kubectl rollout restart deployment react-deployment -n react-microk8s"
```

> ⚠️ Replace the IP with your internal server IP.

---

### 📊 Monitor Deployment

* Click **View Events**.
* Monitor stages like `DownloadBundle`, `AfterInstall`, etc.

---

## 🔄 AWS CodePipeline

Now that we have:

* ✅ CodeBuild (build and push)
* ✅ CodeDeploy (restart app pods)

Let's connect them.

### ⚙️ Steps:

1. Go to **AWS CodePipeline**.
2. Click **Create Pipeline**.
3. Choose a pipeline name.
4. Add stages:

   * **Source**: GitHub
   * **Build**: Select CodeBuild project
   * **Deploy**: Select CodeDeploy App & Deployment Group

---

## ✅ Final Workflow

1. Push code to GitHub
2. CodePipeline triggers build
3. CodeBuild builds and pushes Docker image
4. CodeDeploy restarts pods with updated image

---

## 📬 Connect with Me

I post content related to contrafactums, fun vlogs, travel stories, DevOps, and more.

🔗 [Sagar Kakkala One Stop – Linktree](https://linktr.ee/sagar_kakkalas_world)

🖊 Feedback and suggestions are welcome!
