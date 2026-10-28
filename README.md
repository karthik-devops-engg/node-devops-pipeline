# node-devops-pipeline

Small Node.js app with CI/CD, Terraform, Ansible, monitoring and logging on AWS.

## Architecture

- GitHub Actions builds, tests and deploys the app.
- AWS (eu-north-1): VPC with 2 public subnets, Application Load Balancer, 2 app servers, 1 monitoring server.
- App servers run the app in Docker, plus node_exporter and Filebeat.
- Monitoring server runs Prometheus, Alertmanager, Grafana and ELK.

## Repo layout

- `app/` - Node.js app, tests, Dockerfile
- `terraform/` - modules (vpc, security, ec2, alb) and `envs/dev`
- `ansible/` - roles: common, app, node_exporter, monitoring, logging, filebeat
- `.github/workflows/ci.yml` - pipeline

## CI/CD

- Pipeline: lint -> test -> build -> terraform -> deploy.
- Pull requests run lint, test and build only. Pushes to main run everything.
- Docker image is tagged with the commit SHA and pushed to GitHub Container Registry.
- Terraform job runs fmt check, validate, plan and apply.
- Deploy job opens SSH for the runner's IP, runs Ansible, then removes the rule.
- Smoke test calls /health through the load balancer.

## Infrastructure (Terraform)

- Modules: vpc, security, ec2, alb. The ec2 module is reused for app and monitoring servers.
- State stored in S3 with versioning and a lock file.
- App servers only accept app traffic from the load balancer. SSH and dashboards only from my IP.
- Ubuntu 24.04 image looked up from Canonical's SSM parameter.
- No NAT gateway or private subnets, to keep cost down.

## Configuration (Ansible)

- Dynamic AWS inventory groups servers by their Role tag.
- common: installs Docker. app: writes env file, runs the container, checks /health.
- node_exporter, monitoring, logging and filebeat roles set up the rest.
- Image tag is passed in with `-e app_image_tag=<sha>`.
- Re-running the playbook gives changed=0.

## Monitoring

- Prometheus scrapes node_exporter on all servers and /metrics on the app.
- App exposes request count and response time metrics.
- Alerts: instance down, CPU > 80%, memory > 85%, error rate > 5%, p95 latency > 1s.
- Alerts go to Alertmanager. Grafana uses the Node Exporter Full dashboard.
- Tested with /simulate-error. The error rate alert went pending, then firing.

## Logging

- App logs one JSON line per request.
- Filebeat ships app and system logs to Logstash, then Elasticsearch, viewed in Kibana.
- Logs are searchable by field, e.g. `app.status : 500`.

## Troubleshooting steps

- Check alerts in Prometheus / Alertmanager.
- Check Grafana for CPU, memory and disk on each server, and ALB target health.
- Search Kibana for errors in the same time window.
- Check the last pipeline run to see what was deployed.
- Roll back by deploying an older image: `ansible-playbook site.yml -e app_image_tag=<old sha>`.

## How to run

- Needs: AWS CLI profile, Terraform 1.17, Python venv with Ansible and boto3.
- `cd terraform/envs/dev && terraform init && terraform apply`
- `cd ansible && ansible-playbook site.yml -e app_image_tag=<sha>`
- GitHub secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, SSH_PRIVATE_KEY.
- GitHub variables: MY_IP_CIDR, SSH_PUBLIC_KEY.

## Assumptions

- One environment (dev) in one region.
- HTTP only, no HTTPS.
- ELK security turned off for the exercise.
- App has no database.

## Challenges

- eu-west-2 blocked by an AWS account policy, so I used eu-north-1.
- Ubuntu image lookup by name failed, so I used the SSM parameter.
- GitHub OIDC was blocked, so the pipeline uses an IAM user with keys in GitHub secrets.
- `pull: always` made Ansible report changes every run, so I switched to `pull: missing`.
- Committed a Terraform plan file by mistake, then removed it and added it to `.gitignore`.

## What I'd improve

- Use OIDC instead of access keys.
- Private subnets with a NAT gateway.
- HTTPS on the load balancer.
- Least-privilege IAM.
- Alert notifications to Slack or email.
- Turn on ELK security.

## Clean-up

`cd terraform/envs/dev && terraform destroy`
