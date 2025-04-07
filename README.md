# PowerFlex Azure automation
This project will deploy 4 x instances in AWS using Terraform based infrastructure as code. 
The purpose of this script is to setup a Windows and Linux VM with several storage volumes to be used for performance testing and comparison benchmarking of AWS EBS storage and Dell PowerStore storage.
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
```
az login --tenant xxxxxxxxxxxxxxxxxxxxx
```



### Clone the repo
```
git clone https://github.com/theocrithary/Terraform-PowerFlex-4.6-on-Azure.git
```

### Navigate to the working directory
```
cd Terraform-PowerFlex-4.6-on-Azure
```

### Rename the vars.tf.example file to vars.tf
```
mv vars-example-tf vars.tf
```

### Edit the vars.tf file and replace any variables with your own environment variables
```
vi vars.tf
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
