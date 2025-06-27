# Deploy _The Good, the Bad, and Chad!_ with Terraform

This project automates the deployment of _The Good, the Bad, and Chad!_, a browser-based web game, using [Terraform](https://www.terraform.io) and AWS.

[_The Good, the Bad, and Chad!_](https://github.com/b1gd3vd0g/good-bad-chad-devin) is a game built with vanilla JavaScript by [Devin Peevy](https://github.com/b1gd3vd0g), [Trae Claar](https://github.com/tclaar), [Caleb Krauter](https://github.com/calebkrauter), and [Nathan Hinthorne](https://github.com/NathanHinthorne). You can play the original deployment [here](https://goodbadchad.bigdevdog.com).

To support features like user accounts and save files, this deployment includes a RESTful backend API. All infrastructure is provisioned on AWS using Terraform in a cost-effective, modular setup.

> **Note:** Each deployment includes its own isolated database instance. Saves created on one deployment will not transfer to others.

## Repository Structure

This repository contains two separate Terraform projects:

- `frontend/`: Provisions the static frontend site, hosted via S3 + CloudFront.
- `backend/`: Provisions the backend REST API with Lambda, API Gateway, and RDS.

## Prerequisites

- A registered domain in Route 53 with an existing hosted zone.
- Terraform installed (`terraform -v`)
- AWS CLI installed and configured (`aws configure`)

## 🚀 Frontend Deployment

### AWS Services Used

- **S3** — Hosts the game's static files.
- **CloudFront** — Serves content via a global CDN.
- **ACM** — Provides TLS certificates for HTTPS.
- **Route 53** — DNS routing for your custom domain.

### Deployment Steps

1. Navigate to the `frontend/` directory.
2. Create a `terraform.tfvars` file with the following:

   ```hcl
   domain_name              = "goodbadchad.<yourdomain>.com"
   route_53_hosted_zone_id  = "<your_hosted_zone_id>"
   ```

3. Run:

   ```bash
   terraform apply
   ```

4. Deploy the frontend code:

   ```bash
   git clone https://github.com/b1gd3vd0g/good-bad-chad-devin.git gbc
   cd gbc
   rm -rf dev_tools_temp/ .git* tileMapIn.txt README.md
   # [IMPORTANT] Update `config.js` to point to your backend API URL!
   aws s3 sync . s3://<your_domain_name>
   ```

After syncing, you should be able to visit the domain and play the game.

## 🛠️ Backend Deployment

### AWS Services Used

- **Lambda** — Hosts the REST API.
- **API Gateway** — Handles public HTTP requests.
- **RDS** — PostgreSQL database for user accounts and saves.
- **VPC** — Isolates the database and Lambda networking.
- **ACM** — TLS for API Gateway.
- **Route 53** — DNS routing for your API.

### Deployment Steps

1. Navigate to the `backend/` directory.
2. Create a `terraform.tfvars` file with:

   ```hcl
   pg_username              = "your_pg_user"
   pg_password              = "your_pg_pass"
   db_name                  = "goodbadchad"
   jwt_secret               = "your_jwt_secret"
   api_domain_name          = "api.<yourdomain>.com"
   game_domain_name         = "goodbadchad.<yourdomain>.com"
   route_53_hosted_zone_id  = "<your_hosted_zone_id>"
   ```

3. Prepare the API source code:

   ```bash
   git clone https://github.com/b1gd3vd0g/good-bad-chad-saving-api.git gbc-save
   zip -r gbc_save.zip gbc-save
   rm -rf gbc-save
   ```

4. Place the resulting `gbc_save.zip` in the `backend/` directory, then run:

   ```bash
   terraform apply
   ```

You can now make authenticated HTTP requests to your custom API domain.

## Notes

- All infrastructure is deployed in the cloud using Terraform modules.
- Your backend database is isolated and secured in a private VPC.
- TLS encryption is enabled for both frontend and backend traffic.
