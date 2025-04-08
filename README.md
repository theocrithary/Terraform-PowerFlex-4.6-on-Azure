# PowerFlex Azure automation
This project will deploy PowerFlex in Azure using Terraform based infrastructure as code. 
This was tested using a RHEL 8 Linux server as the host to run the terraform deployment and may require small tweaks to the code depending on which OS you are using.

## Step 1: Pre-reqs

### Install Terraform
- https://developer.hashicorp.com/terraform/downloads
* e.g. RHEL
```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

### Install Azure CLI
```
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo dnf install azure-cli
```

### Login to Azure
- If using SSO, you will need to do the following to authenticate
```
az login --tenant xxxxxxxxxxxxxxxxxxxxx
```
- Use your browser that has access to SSO (i.e. not inside a jump host): https://microsoft.com/devicelogin
- Enter the key, then your domain login password and token and you should be authenticated via SSO
- If you have more than 1 tenant or subscription, you may be prompted to select the appropriate tenant or subscription.

### verify the result
```
az account show
```

### Clone the repo
```
git clone https://github.com/theocrithary/Terraform-PowerFlex-4.6-on-Azure.git
```

### Navigate to the working directory
```
cd Terraform-PowerFlex-4.6-on-Azure
```

### Rename the terraform-example.tfvars file to terraform.tfvars
```
mv terraform-example.tfvars terraform.tfvars
```

### Edit the terraform.tfvars file and replace any variables with your own environment variables
```
vi terraform.tfvars
```

## Step 2: Run the Terraform deployment

### terraform init
```
terraform init
```

### terraform validate & plan
```
terraform validate && terraform plan
```

### terraform apply
```
terraform apply -auto-approve
```

### Confirm the deployment completed successfully, with no errors
