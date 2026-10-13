# CloudCart Terraform

This stack defines the AWS resources required by the existing CloudCart backend and worker. It does not deploy anything until `terraform apply` is explicitly run.

## Usage

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars; never add secrets to it.
terraform init
terraform fmt -check
terraform validate
terraform plan -var-file=terraform.tfvars
```

Keep `enable_ecs_services = false` for the first apply. Push the immutable images to the ECR repositories, set the image variables, change it to `true`, and apply again to start the backend, worker, and frontend services.

RDS is disabled by default with `enable_rds = false`. In this mode Terraform does not create the PostgreSQL instance, database subnet group, database password, database URL secret, or RDS security group. The backend task definition is still created, but it does not receive `DATABASE_URL`, so the backend cannot provide its database-backed functionality until RDS is enabled. Keep `enable_ecs_services = false` until RDS is available and migrations have completed.

Set `enable_rds = true` before a later plan/apply when you need PostgreSQL. Terraform then generates the RDS password and database URL secret and stores them in AWS Secrets Manager. Protect the Terraform state because generated secret values are represented in state. Use an encrypted remote state backend before a shared or production deployment.

The existing Nginx frontend is managed as an ECS service in public subnets behind the same ALB. The backend and worker also use public subnets with public IPs so this cost-optimized demo deployment does not require a NAT gateway. Their security groups still restrict inbound traffic, and `/api/*` and `/health` route to the backend while other paths route to Nginx. Build the frontend image with the shared ALB origin as `VITE_API_URL` before enabling the ECS services.

Redis is optional and disabled by default. Set `enable_redis = true` to create the private ElastiCache Redis resources and configure the backend cache; otherwise the backend runs with its existing cache-disabled behavior.

The ALB is optional and disabled by default with `enable_alb = false`. In this mode Terraform does not create the ALB, target groups, listeners, listener rules, or ALB security group, and the `alb_dns_name` and `frontend_url` outputs are `null`. There is no public ALB URL for the demo. If ECS services are later enabled while the ALB remains disabled, backend and frontend tasks have no inbound security-group rules and no load balancer attachment. Set `enable_alb = true` to restore the existing public HTTP/HTTPS routing and ALB-only task ingress.

## Migration image

The production backend image omits the Prisma CLI. Build the dedicated migration target after the RDS endpoint and secrets are available:

```powershell
docker build --target migration -f ../../backend/Dockerfile -t <MIGRATION_IMAGE> ../../backend
docker push <MIGRATION_IMAGE>
```

Run that image once as a private ECS task with `DATABASE_URL` injected from the database secret and command `npx prisma migrate deploy`. Do not run `prisma migrate reset` against RDS.
