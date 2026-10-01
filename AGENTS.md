\# CloudOps ServiceHub Agent Instructions



\## Approved AWS Context



Approved AWS account:

912281739191



Approved AWS CLI profile:

cloudops-free



Forbidden AWS accounts:

774609032765

503561423514



Before any AWS-changing operation:



aws sts get-caller-identity --profile cloudops-free



The returned Account must equal:



912281739191



If it does not, STOP.



\## Cost Safety



This project must remain extremely low cost.



\- Prefer ephemeral infrastructure.

\- Do not leave EC2 instances running unnecessarily.

\- Prefer the smallest viable resources.

\- Avoid NAT Gateway, ALB, RDS, EKS, and other always-on managed services unless explicitly approved.

\- Every billable resource must have a teardown path.

\- Do not run infrastructure that could exceed the account's available free-plan credits.

\- Do not use AWS Organizations.



\## AWS Change Safety



Agents may run:



\- aws sts get-caller-identity

\- read-only AWS CLI commands

\- terraform fmt

\- terraform validate

\- terraform plan



Agents must NOT run without explicit human approval:



\- terraform apply

\- terraform destroy

\- AWS resource creation

\- AWS resource mutation

\- AWS resource deletion

\- deployment commands



\## Validation



Application:

\- dotnet restore

\- dotnet build

\- dotnet test



Terraform:

\- terraform fmt -check -recursive

\- terraform validate



Containers:

\- docker compose config

\- docker compose build



\## Git



\- main is the integration branch.

\- Keep changes scoped to the assigned task.

\- One logical task per branch.

\- Do not merge your own branch.

\- Do not push unless requested.

\- Do not modify unrelated files.



\## Handoff



Every task should report:



1\. files changed

2\. what changed

3\. validation performed

4\. assumptions

5\. unresolved issues

6\. cost implications

7\. recommended next step

