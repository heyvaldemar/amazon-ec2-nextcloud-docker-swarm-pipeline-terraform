# Nextcloud on Amazon EC2 in Docker Swarm with Terraform

The Terraform script performs the following operations to set up a Nextcloud environment on AWS:

1. **Database Secrets Management**: The script retrieves secrets such as passwords and keys stored in AWS Secrets Manager. It obtains the secrets for database, and Nextcloud configurations.

2. **RDS Instance Creation**: It creates an Amazon RDS instance using provided variables, including the DB engine, version, size, backup settings, etc. The RDS instance is configured with database credentials retrieved from AWS Secrets Manager.

3. **EC2 Instance Creation**: It creates an EC2 instance for the Nextcloud application running as a Docker container. The instance is created using a specific AMI and instance type. The instance metadata is set to enforce IMDSv2 for enhanced security.

4. **Redis Cluster Setup**: The script sets up an Amazon ElastiCache Redis cluster. Redis is an in-memory data store used by Nextcloud for caching and real-time operations.

5. **Nextcloud Configuration Generation**: It uses the Nextcloud Docker configuration file (nextcloud-docker-swarm.yml) using values from previously defined resources and the provided variables.s

6. **EBS Volume Creation and Attachment**: It creates two EBS volumes and attaches them to the EC2 instance. These volumes are used for persistent storage of Nextcloud data and backups.

7. **Route53 Record Creation**: The script creates Route53 DNS record pointing to the ALB. This DNS record provides a user-friendly way to access the Nextcloud application.

8. **Application Load Balancer Creation**: The script creates an application (ALB) load balancer. This load balancer is used for routing traffic to the Nextcloud EC2 instance. The ALB is used for HTTP/HTTPS traffic. It also creates the necessary target groups, listeners, and attachments for the load balancer.

9. **Network Load Balancer Creation**: In addition to the creation of an application load balancer (ALB) for HTTP/HTTPS traffic, an NLB (Network Load Balancer) is created specifically for port 22. The NLB is used for routing traffic to the Nextcloud EC2 instance over SSH. The creation process involves setting up the necessary target groups, listeners, and attachments for the NLB.

## Background Jobs Using Cron

To ensure your Nextcloud instance operates efficiently, it's important to use the "Cron" method to execute background jobs. A dedicated Docker container has already been set up in your environment to handle these tasks.

### Steps to Enable Cron

1. **Log in to Nextcloud as an Administrator.**
2. Go to **Administration settings** (click on your user profile in the top right corner and select "Administration settings").
3. In the **Administration** section on the left sidebar, select **Basic settings**.
4. Scroll down to the **Background jobs** section.
5. Select the **"Cron (Recommended)"** option.

![nextcloud-cron](https://github.com/user-attachments/assets/325d511b-9c4c-4303-b931-f96594649abb)

### Why Use Cron?

The "Cron" method ensures that background tasks, such as file indexing, notifications, and cleanup operations, run at regular intervals independently of user activity. This method is more reliable and efficient than AJAX or Webcron, particularly for larger or more active instances, as it does not depend on users accessing the site to trigger these tasks. With the dedicated container in your setup, this method keeps your Nextcloud instance responsive and in good health by running these jobs consistently.

## Requirements

Install AWS CLI by following the [guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

Configure AWS CLI by following the [guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

Install Terraform by following the [guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

Install pre-commit by following the [guide](https://pre-commit.com/#install)

Install tflint by following the [guide](https://github.com/terraform-linters/tflint)

Install tfsec by following the [guide](https://github.com/aquasecurity/tfsec)

Install tfupdate by following the [guide](https://github.com/minamijoyo/tfupdate)

## Route53

Please be aware that this Terraform deployment operates on the premise that your application's domain is registered/parked with Amazon Route53. The deployment process will automatically create "A" records within the Route53 zone that correspond to your application's domain. In addition, Amazon Certificate Manager (ACM) will seamlessly obtain an SSL certificate for the specified domain.

## Secrets

Create secrets with [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) for:

1. Username and password for the database
2. Username and password for the Nextcloud
3. Set secrets ARNs in the `00-variables.tf` file

## Pre-commit Hooks

`.pre-commit-config.yaml` is useful for identifying simple issues before submission to code review. Pointing these issues out before code review, allows a code reviewer to focus on the architecture of a change while not wasting time with trivial style nitpicks. Make sure you have all tools from the requirements section installed for pre-commit hooks to work.

## Manual Installation

Make sure you have all tools from the requirements section installed.

You may change variables in the `00-variables.tf` to meet your requirements.

Initialize a working directory containing Terraform configuration files using the command:

`terraform init`

Run the pre-commit hooks to check for formatting and validation issues:

`pre-commit run --all-files`

Review the changes that Terraform plans to make to your infrastructure using the command:

`terraform plan`

Deploy using the command:

`terraform apply -auto-approve`

## SSH

Once you've run `terraform apply` and the resources are successfully created, a private key file will be generated in your project root directory (where your Terraform files are located). This key can be used to securely connect to the created Amazon Lightsail instance via SSH.

Here's an example of how to use the key to connect via SSH (replace myuser with your username and myinstance with your instance's public IP address or hostname):

`ssh -i key-pair-1.pem ubuntu@instance-static-ip`

## user_data.sh Description

The `user_data.sh` script is a bootstrapping script used for provisioning an EC2 instance. The main tasks performed by the script are as follows:

1. **Creating a Directory for Logs**: It creates a directory `/var/log/user_data_script` to store the error logs for the script.

2. **EBS Volume Attachment and Formatting**: The script waits for EBS volumes to be attached to the instance and formats them if necessary.

3. **Mounting EBS Volumes**: It mounts the EBS volumes to specific directories on the instance and configures them to automatically mount on reboot.

4. **Creating Directories on EBS Volumes**: It creates directories on EBS volumes for various purposes such as storing files and backups for Nextcloud.

5. **Package Installation**: It installs necessary packages including curl, openssh-server, ca-certificates, tzdata, and PostgreSQL client.

6. **Creating Cron Jobs**: It sets up a cron job to create Nextcloud backups.

7. **Docker Installation**: The script then uses the curl command to download a script from https://get.docker.com and executes it with sh to install Docker on the machine.

8. **Adding User to Docker Group**: The script then adds the default user of the distribution to the docker group. This is done so that the default user can run Docker commands without requiring sudo.

9. **Creating Nextcloud Docker Swarm File**: The script generates a Docker Swarm file for the Nextcloud server by writing the rendered Nextcloud configuration to a file named nextcloud-docker-swarm.yml in the /opt directory.

10. **Deploying Nextcloud Server**: The script then uses Docker Swarm to deploy the Nextcloud server. It does this by executing the Docker Swarm file with the `sudo docker stack deploy -c /opt/nextcloud-docker-swarm.yml nextcloud` command, which launches the Nextcloud server.

## user_data.sh Logs

Once your EC2 instance is provisioned and the `user_data.sh` script has run, you can check its logs to confirm whether it ran successfully or encountered any errors.

The logs for `user_data.sh` can be found at `/var/log/user_data_script/errors.log`.

To view these logs, you can use the cat command as follows:

`cat /var/log/user_data_script/errors.log`

## Backups

Nextcloud Backups are made daily by default and stored on the separate EBS volume in `/mnt/backups/nextcloud`.

The filename is `TIMESTAMP_nextcloud_data_backup.tar.gz`, where `TIMESTAMP` identifies the time at which each backup was created. The timestamp is needed if you need to restore Nextcloud and multiple backups are available.

For example, if the backup name is `2023_07_23_05_31_nextcloud_data_backup.sql`, the timestamp is `2023_07_23_05_31`.

## Disabling Skeleton Directory for New Users

New Nextcloud users typically receive default files and folders upon account creation, which are sourced from the skeleton directory. Disabling this feature can be useful to provide a clean start for users and reduce disk usage. Use the `occ config:system:set` command to set the skeleton directory path to an empty string, effectively disabling the default content for new users.

List all running containers to find the one running Nextcloud:

`docker ps`

Run the command below, replacing `nextcloud-container-name` with your container's name. Adjust `33` to the correct user ID if different:

`docker exec -u 33 -it nextcloud-container-name php occ config:system:set skeletondirectory --value=''`

## Fixing Database Index Issues

Your Nextcloud database might be missing some indexes. This situation can occur because adding indexes to large tables can take considerable time, so they are not added automatically. Running `occ db:add-missing-indices` manually allows these indexes to be added while the instance continues running. Adding these indexes can significantly speed up queries on tables like `filecache` and `systemtag_object_mapping`, which might be missing indexes such as `fs_storage_path_prefix` and `systag_by_objectid`.

List all running containers to find the one running Nextcloud:

`docker ps`

Run the command below, replacing `nextcloud-container-name` with your container's name. Adjust `33` to the correct user ID if different:

`docker exec -u 33 -it nextcloud-container-name php occ db:add-missing-indices`

Confirm the indices were added by checking the status:

`docker exec -u 33 -it nextcloud-container-name php occ status`

- Operations on large databases can take time; consider scheduling during low-usage periods.
- Always backup your database before making changes.

## Rescanning Files

When files are added directly to Nextcloud's data directory through methods other than the web interface or sync clients (e.g., via FTP or direct server access), they are not automatically visible in the Nextcloud user interface. This happens because these files bypass Nextcloud's normal indexing process.

To make all manually added files visible in the UI, you can use the `occ files:scan` command to update Nextcloud's file index. This command should be used with care as it can impact server performance, especially on larger installations.

List all running containers to find the one running Nextcloud:

`docker ps`

Run the command below, replacing `nextcloud-container-name` with your container's name. Adjust `33` to the correct user ID if different:

`docker exec -u 33 -it nextcloud-container-name php occ files:scan --all`

- Be aware that this command can significantly affect performance during its execution. It is advisable to run this scan during periods of low user activity.
- Always ensure that you have up-to-date backups before performing any operations that affect the filesystem or database.

## Backend for Terraform State

The `backend` block in the `01-providers.tf` must remain commented until the bucket and the DynamoDB table are created.

After all your resources will be created, you will need to replace empty values for `region` and `bucket` in the `backend` block of the `01-providers.tf` since variables are not allowed in this block.

For `region` you need to specify the region where the S3 bucket and DynamoDB table are located. You need to use the same value that you have in the `00-variables.tf` for the `region` variable.

For `bucket` you will get its values in the output after the first run of `terraform apply -auto-approve`.

After your values are set, you can then uncomment the `backend` block and run again `terraform init` and then `terraform apply -auto-approve`.

In this way, the `terraform.tfstate` file will be stored in an S3 bucket and DynamoDB will be used for state locking and consistency checking.

## GitHub Actions

`.github` is useful if you are planning to run a pipeline on GitHub and implement the GitOps approach.

Remove the `.example` part from the name of the files in `.github/workflow` for the GitHub Actions pipeline to work.

Note, that you will need to add variables such as AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, and AWS_SECRET_ACCESS_KEY in your GitHub projects CI/CD settings section to run your pipeline.

Therefore, you will need to create a service user in advance, using AWS Identity and Access Management (IAM) to get values for these variables and assign an access policy to the user to be able to operate with your resources.

You can delete `.github` if you are not planning to use the GitHub pipeline.

1. **Terraform Unit Tests**

This workflow executes a series of unit tests on the infrastructure code and is triggered by each commit. It begins by running [terraform fmt]( https://www.terraform.io/cli/commands/fmt) to ensure proper code formatting and adherence to terraform best practices. Subsequently, it performs [terraform validate](https://www.terraform.io/cli/commands/validate) to check for syntactical correctness and internal consistency of the code.

To further enhance the code quality and security, two additional tools, tfsec and tflint, are utilized:

tfsec: This step checks the code for potential security issues using tfsec, an open-source security scanner for Terraform. It helps identify any security vulnerabilities or misconfigurations in the infrastructure code.

tflint: This step employs tflint, a Terraform linting tool, to perform additional static code analysis and linting on the Terraform code. It helps detect potential issues and ensures adherence to best practices and coding standards specific to Terraform.

2. **Terraform Plan / Apply**

This workflow runs on every pull request and on each commit to the main branch. The plan stage of the workflow is used to understand the impact of the IaC changes on the environment by running [terraform plan](https://www.terraform.io/cli/commands/plan). This report is then attached to the PR for easy review. The apply stage runs after the plan when the workflow is triggered by a push to the main branch. This stage will take the plan document and [apply](https://www.terraform.io/cli/commands/apply) the changes after a manual review has signed off if there are any pending changes to the environment.

3. **Terraform Drift Detection**

This workflow runs on a periodic basis to scan your environment for any configuration drift or changes made outside of terraform. If any drift is detected, a GitHub Issue is raised to alert the maintainers of the project.

If you have paid version of GitHub and you wish to have the approval process implemented, please refer to the provided [guide](https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment#creating-an-environment) to create an environment called production and uncomment this part in the `02-terraform-plan-apply.yml`:

```
on:
  push:
    branches:
    - main
  pull_request:
    branches:
    - main
```

And comment out this part in the `02-terraform-plan-apply.yml`:

```
on:
  workflow_run:
    workflows: [Terraform Unit Tests]
    types:
      - completed
```

Once the production environment is created, set up a protection rule and include any necessary approvers who must approve production deployments. You may also choose to restrict the environment to your main branch. For more detailed instructions, please see [here](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-protection-rules).

If you have a free version of GitHub no action is needed, but approval process will not be enabled.

## GitLab CI/CD

`.gitlab-ci.yml` is useful if you are planning to run a pipeline on GitLab and implement the GitOps approach.

Remove the `.example` part from the name of the file `.gitlab-ci.yml` for the GitLab pipeline to work.

Note, that you will need to add variables such as AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, and AWS_SECRET_ACCESS_KEY in your GitLab projects CI/CD settings section to run your pipeline.

Therefore, you will need to create a service user in advance, using AWS Identity and Access Management (IAM) to get values for these variables and assign an access policy to the user to be able to operate with your resources.

You can delete `.gitlab-ci.yml` if you are not planning to use the GitLab pipeline.

1. **Terraform Unit Tests**

This workflow executes a series of unit tests on the infrastructure code and is triggered by each commit. It begins by running [terraform fmt]( https://www.terraform.io/cli/commands/fmt) to ensure proper code formatting and adherence to terraform best practices. Subsequently, it performs [terraform validate](https://www.terraform.io/cli/commands/validate) to check for syntactical correctness and internal consistency of the code.

To further enhance the code quality and security, two additional tools, tfsec and tflint, are utilized:

tfsec: This step checks the code for potential security issues using tfsec, an open-source security scanner for Terraform. It helps identify any security vulnerabilities or misconfigurations in the infrastructure code.

tflint: This step employs tflint, a Terraform linting tool, to perform additional static code analysis and linting on the Terraform code. It helps detect potential issues and ensures adherence to best practices and coding standards specific to Terraform.

2. **Terraform Plan / Apply**

To ensure accuracy and control over the changes made to your infrastructure, it is essential to manually initiate the job for applying the configuration. Before proceeding with the application, it is crucial to carefully review the generated plan. This step allows you to verify that the proposed changes align with your intended modifications to the infrastructure. By manually reviewing and approving the plan, you can confidently ensure that only the intended modifications will be implemented, mitigating any potential risks or unintended consequences.

## Committing Changes and Triggering Pipeline

Follow these steps to commit changes and trigger the pipeline:

1. **Install pre-commit hooks**: Make sure you have all tools from the requirements section installed.

2. **Clone the Git repository** (If you haven't already):

`git clone <repository-url>`

3. **Navigate to the repository directory**:

`cd <repository-directory>`

4. **Create a new branch**:

`git checkout -b <new-feature-branch-name>`

5. **Make changes** to the Terraform files as needed.

6. **Run pre-commit hooks**: Before committing, run the pre-commit hooks to check for formatting and validation issues:

`pre-commit run --all-files`

7. **Fix any issues**: If the pre-commit hooks report any issues, fix them and re-run the hooks until they pass.

8. **Stage and commit the changes**:

`git add .`

`git commit -m "Your commit message describing the changes"`

9. **Push the changes** to the repository:

`git push origin <branch-name>`

Replace `<branch-name>` with the name of the branch you are working on (e.g., `new-feature-branch-name`).

10.  **Monitor the pipeline**: After pushing the changes, the pipeline will be triggered automatically. You can monitor the progress of the pipeline and check for any issues in the CI/CD interface.

11.  **Merge Request**: If the pipeline is successful and the changes are on a feature branch, create a Merge Request to merge the changes into the main branch. If the pipeline fails, investigate the issue, fix it, and push the changes again to re-trigger the pipeline. Once the merge request is created, your team can review the changes, provide feedback, and approve or request changes. After the merge request has been reviewed and approved, it can be merged into the main branch to apply the changes to the production infrastructure.

## Author

hey everyone,

💾 I’ve been in the IT game for over 20 years, cutting my teeth with some big names like [IBM](https://www.linkedin.com/in/heyvaldemar/), [Thales](https://www.linkedin.com/in/heyvaldemar/), and [Amazon](https://www.linkedin.com/in/heyvaldemar/). These days, I wear the hat of a DevOps Consultant and Team Lead, but what really gets me going is Docker and container technology - I’m kind of obsessed!

💛 I have my own IT [blog](https://www.heyvaldemar.com/), where I’ve built a [community](https://discord.gg/AJQGCCBcqf) of DevOps enthusiasts who share my love for all things Docker, containers, and IT technologies in general. And to make sure everyone can jump on this awesome DevOps train, I write super detailed guides (seriously, they’re foolproof!) that help even newbies deploy and manage complex IT solutions.

🚀 My dream is to empower every single person in the DevOps community to squeeze every last drop of potential out of Docker and container tech.

🐳 As a [Docker Captain](https://www.docker.com/captains/vladimir-mikhalev/), I’m stoked to share my knowledge, experiences, and a good dose of passion for the tech. My aim is to encourage learning, innovation, and growth, and to inspire the next generation of IT whizz-kids to push Docker and container tech to its limits.

Let’s do this together!

## My 2D Portfolio

🕹️ Click into [sre.gg](https://www.sre.gg/) — my virtual space is a 2D pixel-art portfolio inviting you to interact with elements that encapsulate the milestones of my DevOps career.

## My Courses

🎓 Dive into my [comprehensive IT courses](https://www.heyvaldemar.com/courses/) designed for enthusiasts and professionals alike. Whether you're looking to master Docker, conquer Kubernetes, or advance your DevOps skills, my courses provide a structured pathway to enhancing your technical prowess.

🔑 [Each course](https://www.udemy.com/user/heyvaldemar/) is built from the ground up with real-world scenarios in mind, ensuring that you gain practical knowledge and hands-on experience. From beginners to seasoned professionals, there's something here for everyone to elevate their IT skills.

## My Services

💼 Take a look at my [service catalog](https://www.heyvaldemar.com/services/) and find out how we can make your technological life better. Whether it's increasing the efficiency of your IT infrastructure, advancing your career, or expanding your technological horizons — I'm here to help you achieve your goals. From DevOps transformations to building gaming computers — let's make your technology unparalleled!

## Patreon Exclusives

🏆 Join my [Patreon](https://www.patreon.com/heyvaldemar) and dive deep into the world of Docker and DevOps with exclusive content tailored for IT enthusiasts and professionals. As your experienced guide, I offer a range of membership tiers designed to suit everyone from newbies to IT experts.

## My Recommendations

📕 Check out my collection of [essential DevOps books](https://kit.co/heyvaldemar/essential-devops-books)\
🖥️ Check out my [studio streaming and recording kit](https://kit.co/heyvaldemar/my-studio-streaming-and-recording-kit)\
📡 Check out my [streaming starter kit](https://kit.co/heyvaldemar/streaming-starter-kit)

## Follow Me

🎬 [YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1)\
🐦 [X / Twitter](https://twitter.com/heyvaldemar)\
🎨 [Instagram](https://www.instagram.com/heyvaldemar/)\
🐘 [Mastodon](https://mastodon.social/@heyvaldemar)\
🧵 [Threads](https://www.threads.net/@heyvaldemar)\
🎸 [Facebook](https://www.facebook.com/heyvaldemarFB/)\
🧊 [Bluesky](https://bsky.app/profile/heyvaldemar.bsky.social)\
🎥 [TikTok](https://www.tiktok.com/@heyvaldemar)\
💻 [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)\
📣 [daily.dev Squad](https://app.daily.dev/squads/devopscompass)\
🧩 [LeetCode](https://leetcode.com/u/heyvaldemar/)\
🐈 [GitHub](https://github.com/heyvaldemar)

## Community of IT Experts

👾 [Discord](https://discord.gg/AJQGCCBcqf)

## Refill My Coffee Supplies

💖 [PayPal](https://www.paypal.com/paypalme/heyvaldemarCOM)\
🏆 [Patreon](https://www.patreon.com/heyvaldemar)\
💎 [GitHub](https://github.com/sponsors/heyvaldemar)\
🥤 [BuyMeaCoffee](https://www.buymeacoffee.com/heyvaldemar)\
🍪 [Ko-fi](https://ko-fi.com/heyvaldemar)

🌟 **Bitcoin (BTC):** bc1q2fq0k2lvdythdrj4ep20metjwnjuf7wccpckxc\
🔹 **Ethereum (ETH):** 0x76C936F9366Fad39769CA5285b0Af1d975adacB8\
🪙 **Binance Coin (BNB):** bnb1xnn6gg63lr2dgufngfr0lkq39kz8qltjt2v2g6\
💠 **Litecoin (LTC):** LMGrhx8Jsx73h1pWY9FE8GB46nBytjvz8g

<div align="center">

### Show some 💜 by starring some of the [repositories](https://github.com/heyValdemar?tab=repositories)!

![octocat](https://user-images.githubusercontent.com/10498744/210113490-e2fad07f-4488-4da8-a656-b9abbdd8cb26.gif)

</div>

![footer](https://user-images.githubusercontent.com/10498744/210157572-1fca0242-8af2-46a6-bfa3-666ffd40ebde.svg)
