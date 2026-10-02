# AWS Free Plan operations runbook

This runbook controls operation and teardown of the CloudOps ServiceHub learning environment. It must be followed before the first Terraform apply and for every later learning session.

## Account and deadline

| Setting | Required value |
| --- | --- |
| AWS account | `912281739191` |
| AWS CLI profile | `cloudops-free` |
| AWS region | `ap-southeast-1` |
| Account plan | `FREE` |
| Plan status | `ACTIVE` |
| Remaining credits at preflight | `100 USD` |
| Hard Free Plan deadline | **2027-04-01 19:36:50 UTC** |
| Separate credit expiration | `2027-10-01` |

The hard Free Plan deadline is controlling. The separate October credit expiration does not extend the Free Plan. The owner does not want to upgrade to the Paid Plan.

Destroy all Terraform-managed resources no later than **2027-03-01 UTC**, leaving at least 31 days to investigate and correct an incomplete teardown. Do not wait until the hard deadline.

## Non-negotiable cost controls

- Never run `terraform apply` or `terraform destroy` without explicit human approval for that specific operation.
- Never use `-auto-approve`.
- Verify the caller identity immediately before every AWS-changing operation.
- Stop the EC2 instance when a learning session ends. Destroy the environment when it is no longer needed.
- Do not create a NAT Gateway, Application Load Balancer (ALB), RDS database, EKS cluster, AWS Organization, or paid VPC endpoint unless the owner separately approves that service and its cost.
- Do not add resources manually in the AWS console. Resources outside Terraform can survive `terraform destroy`.
- Do not place AWS credentials in the repository, Terraform variables, scripts, or instance user data.
- Check the Cost and Usage widget and remaining credits before each learning session.

## Identity verification

Run from PowerShell before any AWS-changing command:

```powershell
$identity = aws sts get-caller-identity `
  --profile cloudops-free `
  --region ap-southeast-1 `
  --output json | ConvertFrom-Json

if ($identity.Account -ne "912281739191") {
  throw "STOP: expected AWS account 912281739191, received $($identity.Account)"
}

$identity
```

Stop if the account is not exactly `912281739191`. The Terraform provider also has an `allowed_account_ids` guard, but the CLI check remains mandatory.

To recheck the Free Plan state:

```powershell
aws freetier get-account-plan-state `
  --profile cloudops-free `
  --region us-east-1 `
  --no-cli-pager
```

Expected state is `accountPlanType: FREE` and `accountPlanStatus: ACTIVE`. Treat any other state, unexpectedly reduced credits, or an earlier expiration as a stop condition.

## Terraform preflight

Run all Terraform commands from `infra/terraform`:

```powershell
Set-Location infra/terraform

terraform fmt -check -recursive
terraform validate

$env:AWS_PROFILE = "cloudops-free"
$env:AWS_REGION = "ap-southeast-1"
$env:AWS_DEFAULT_REGION = "ap-southeast-1"

terraform plan -input=false -lock=false
```

The expected default plan is 16 resources to add, zero to change, and zero to destroy. Investigate any different result before requesting approval. In particular, reject a plan containing any forbidden service listed above.

### Apply approval gate

Planning does not authorize deployment. Before an apply:

1. Record the plan summary and expected monthly credit consumption.
2. Obtain explicit human approval for this exact plan.
3. Repeat the identity verification immediately before applying.
4. Run an interactive apply without `-auto-approve`:

   ```powershell
   terraform apply
   ```

5. Type `yes` only after comparing the displayed plan with the approved plan.

## Expected resources and baseline cost

The default configuration is expected to create:

- One `t4g.micro` Ubuntu ARM64 EC2 instance using standard CPU credits.
- One encrypted 10 GiB `gp3` root EBS volume, deleted when its instance is terminated.
- One auto-assigned public IPv4 address while the instance is running.
- One private ECR repository with basic scan-on-push and a lifecycle policy.
- One VPC, internet gateway, public subnet, route table, route, and route-table association.
- One security group, public HTTP ingress rule, and IPv4 egress rule.
- One IAM role, instance profile, SSM managed-policy attachment, and ECR pull policy.

At the accepted preflight rates, continuous operation is approximately **12-13 USD per month before credits**:

| Cost source | Approximate baseline |
| --- | ---: |
| `t4g.micro` compute at `0.0106 USD/hour` | `7.74 USD/month` |
| One public IPv4 at `0.005 USD/hour` | `3.65 USD/month` |
| 10 GiB `gp3` EBS | About `1 USD/month`, subject to current regional pricing and allowances |
| ECR storage and data transfer | Variable; keep images small and within current allowances |
| Internet data transfer | Variable; monitor usage and current allowances |

Rates and Free Tier allowances can change. Recheck AWS pricing and the Cost and Usage widget before applying. Continuous operation can exhaust the 100 USD credit balance, so this environment is for short learning sessions, not always-on hosting.

## Terraform outputs

From `infra/terraform`, list all outputs:

```powershell
terraform output
```

Retrieve individual values for scripts:

```powershell
$instanceId = terraform output -raw ec2_instance_id
$publicIp = terraform output -raw ec2_public_ip
$publicDns = terraform output -raw ec2_public_dns
$repositoryUrl = terraform output -raw ecr_repository_url
$ssmCommand = terraform output -raw session_manager_command
```

Outputs depend on the local Terraform state. Do not treat them as credentials or commit generated state files.

## Connect through SSM

The instance role includes `AmazonSSMManagedInstanceCore`. Once the instance is running, has completed bootstrap, and appears online in Systems Manager, connect using the generated command:

```powershell
Set-Location infra/terraform
$ssmCommand = terraform output -raw session_manager_command
Invoke-Expression $ssmCommand
```

Alternatively, avoid command evaluation and pass the instance ID directly:

```powershell
$instanceId = terraform output -raw ec2_instance_id
aws ssm start-session `
  --target $instanceId `
  --profile cloudops-free `
  --region ap-southeast-1
```

The AWS CLI Session Manager plugin must be installed locally. Do not enable public SSH merely to work around a missing plugin.

## Start and stop learning sessions

Both stop and start are AWS-changing operations. Verify identity first and obtain explicit human approval for the requested action.

### Stop after a session

From `infra/terraform`, after identity verification:

```powershell
$instanceId = terraform output -raw ec2_instance_id

aws ec2 stop-instances `
  --instance-ids $instanceId `
  --profile cloudops-free `
  --region ap-southeast-1 `
  --no-cli-pager

aws ec2 wait instance-stopped `
  --instance-ids $instanceId `
  --profile cloudops-free `
  --region ap-southeast-1
```

Confirm the final state:

```powershell
aws ec2 describe-instances `
  --instance-ids $instanceId `
  --query "Reservations[0].Instances[0].State.Name" `
  --output text `
  --profile cloudops-free `
  --region ap-southeast-1 `
  --no-cli-pager
```

### Start a session

After identity verification and approval:

```powershell
$instanceId = terraform output -raw ec2_instance_id

aws ec2 start-instances `
  --instance-ids $instanceId `
  --profile cloudops-free `
  --region ap-southeast-1 `
  --no-cli-pager

aws ec2 wait instance-running `
  --instance-ids $instanceId `
  --profile cloudops-free `
  --region ap-southeast-1
```

An automatically assigned public IPv4 address can change after a stop/start cycle. Refresh the Terraform state before relying on the public IP or DNS output:

```powershell
terraform apply -refresh-only
terraform output ec2_public_ip
terraform output ec2_public_dns
```

`terraform apply -refresh-only` is an apply operation and therefore requires explicit approval even though it is intended only to update state.

### Costs that continue while EC2 is stopped

Stopping the instance stops EC2 instance compute charges and releases its auto-assigned public IPv4 address. It does **not** remove all costs:

- The 10 GiB EBS root volume remains provisioned and can continue consuming credits.
- ECR image storage remains and can continue consuming credits.
- Snapshots, logs, data transfer, or manually created resources outside this Terraform configuration may remain billable.
- Terraform state and IAM/network objects remain, even where the objects themselves have no direct hourly charge.

Only a verified teardown ends the planned persistent-resource exposure.

## Full teardown

Destroy as soon as the environment is no longer needed and no later than 2027-03-01 UTC.

### Destruction approval gate

1. Back up any non-secret learning artifacts that must be retained. ECR images and the EC2 root volume will be deleted.
2. From `infra/terraform`, verify formatting and configuration:

   ```powershell
   terraform fmt -check -recursive
   terraform validate
   ```

3. Set the approved AWS context and generate a destroy preview:

   ```powershell
   $env:AWS_PROFILE = "cloudops-free"
   $env:AWS_REGION = "ap-southeast-1"
   $env:AWS_DEFAULT_REGION = "ap-southeast-1"

   terraform plan -destroy -input=false -lock=false
   ```

4. Review every object in the destruction plan and obtain explicit human approval for the destroy.
5. Repeat identity verification immediately before destruction.
6. Run the interactive command without `-auto-approve`:

   ```powershell
   terraform destroy
   ```

7. Type `yes` only after confirming account `912281739191`, region `ap-southeast-1`, and the expected resource list.

Do not delete the local Terraform state before destruction and verification. Losing state can leave billable resources orphaned.

## Post-destroy verification

Perform every check after `terraform destroy` reports success:

- Confirm Terraform tracks no resources:

  ```powershell
  terraform state list
  terraform plan -input=false -lock=false
  ```

  `terraform state list` should be empty. A normal plan may propose recreating the configured resources; do not apply it.

- Check for non-terminated project instances:

  ```powershell
  aws ec2 describe-instances `
    --filters `
      "Name=tag:Project,Values=cloudops-servicehub" `
      "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" `
    --query "Reservations[].Instances[].{Id:InstanceId,State:State.Name}" `
    --output table `
    --profile cloudops-free `
    --region ap-southeast-1 `
    --no-cli-pager
  ```

- Check for remaining project EBS volumes:

  ```powershell
  aws ec2 describe-volumes `
    --filters "Name=tag:Project,Values=cloudops-servicehub" `
    --query "Volumes[].{Id:VolumeId,State:State,SizeGiB:Size}" `
    --output table `
    --profile cloudops-free `
    --region ap-southeast-1 `
    --no-cli-pager
  ```

- Verify that the ECR repository is absent:

  ```powershell
  aws ecr describe-repositories `
    --repository-names cloudops-servicehub `
    --profile cloudops-free `
    --region ap-southeast-1 `
    --no-cli-pager
  ```

  A `RepositoryNotFoundException` is the expected result.

- Check tagged resources across supported services:

  ```powershell
  aws resourcegroupstaggingapi get-resources `
    --tag-filters "Key=Project,Values=cloudops-servicehub" `
    --profile cloudops-free `
    --region ap-southeast-1 `
    --no-cli-pager
  ```

- Inspect the AWS Billing Cost and Usage widget, Free Tier page, EC2 console, EBS Volumes page, ECR console, and VPC console. Billing data can lag, so check again the next day.
- Do not consider teardown complete until no unintended billable resource remains.

## Emergency credit-exhaustion procedure

Use this procedure if credits fall unexpectedly, costs spike, the plan approaches suspension, or the remaining time becomes too short for normal operation:

1. Stop all learning activity and do not start new resources.
2. Verify account `912281739191` with the required identity check.
3. With explicit approval, stop the EC2 instance immediately using the stop procedure above.
4. Inspect the Cost and Usage widget and service-level charges. Check EC2, public IPv4, EBS, ECR, data transfer, and any resources created outside Terraform.
5. Obtain explicit destroy approval and run the full teardown procedure. Stopping EC2 alone is insufficient because EBS and ECR persist.
6. Complete the post-destroy verification checklist and recheck Billing after its reporting delay.
7. If the Free Plan is suspended or API access is unavailable, use the AWS console and contact AWS Support for account access and resource-cleanup assistance. Do not upgrade to the Paid Plan as a workaround; the owner has declined an upgrade.

The emergency target is zero unintended resources, not merely zero running EC2 instances. Regardless of credit balance, teardown must be completed well before **2027-04-01 19:36:50 UTC**.
