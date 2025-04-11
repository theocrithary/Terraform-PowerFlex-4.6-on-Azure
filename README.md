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

## Step 2: Prepare the tfvars file with your environment variables

### Rename the terraform-example.tfvars file to terraform.tfvars
```
mv terraform-example.tfvars terraform.tfvars
```

### Edit the terraform.tfvars file and replace any variables with your own environment variables
```
vi terraform.tfvars
```

## Step 2: Run the Terraform deployment to install the PFMP cluster

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

### Login to the installer VM to check the logs and monitor progress
```
ssh -i azure.pem pflexuser@<InstallerIP>
```
- If you do not know the IP address of the installer VM, use the following AZ command to retrieve it (hint: the vm name is <prefix>-installer-vm)
```
az vm list-ip-addresses --resource-group <your-resource-group> --name <your-vm-name> --query "[].virtualMachine.network.privateIpAddresses[0]" --output tsv
```
- Once you are logged in to the installer VM, you can change to root user using sudo
```
sudo -i
```
- Then tail the logs to monitor progress of the installation
```
tail -f /tmp/bundle/atlantic/logs/bedrock.log
```

## Step 3: Login to PFMP UI

### First we need to retrieve the IP of the load balancer we created in the previous step

- If the Terraform output did not display the lb_ip, then you can retrieve the IP using the AZ CLI command
- Use the AZ CLI installed on your bastion host that dpeloyed the Terraform script and run the following command with your resource group and lb name (hint: the lb name is <prefix>-lb)
```
az network lb frontend-ip list \
  --resource-group <your-resource-group> \
  --lb-name <your-load-balancer-name>
```

### Open a browser on a jump host with access to the Azure network and navigate to the PFMP UI
- e.g. https://10.2.0.200
- PowerFlex UI default credentials admin / Admin123! ... you will be asked to change the password.

## Step 4: Deploy PowerFlex SDS/MDM using the installer VM to run the Terraform deployment

- For this part, the following steps need to be executed inside of installer.
- If you are not already logged into the installer VM from the previous steps, login using the below;
```
ssh -i azure.pem pflexuser@<InstallerIP>
```
- If you do not know the IP address of the installer VM, use the following AZ command to retrieve it (hint: the vm name is <prefix>-installer-vm)
```
az vm list-ip-addresses --resource-group <your-resource-group> --name <your-vm-name> --query "[].virtualMachine.network.privateIpAddresses[0]" --output tsv
```
- Check /root folder, make sure terraform.tfvars for PowerFlex core deployment has been automatically generated.
```
sudo -i
cd /root
cat terraform.tfvars
```
- See below for the link to the PowerFlex software. Login required. The process will need the proper PowerFlex bits in the /root folder to continue.
https://www.dell.com/support/product-details/en-us/product/scaleio/drivers

- 4.6.0 = 4.5.2100.105 (default build for this current Terraform)
- Extract Software_Only_Complete_4.6.0_105.zip
- Extract PowerFlex_4.5.2100.105_Complete_Core_SW.zip
- Extract and copy PowerFlex_4.5.2100.105_SLES15.4.zip to installer /root folder and unzip. (e.g. scp -i .\azure-powerflex-keypair.pem .\PowerFlex_4.5.2100.105_SLES15.4.zip pflexuser@x.x.x.x:/home/pflexuser)
- Move the file to /root directory and change owner to root
```
mv /home/pflexuser/PowerFlex_4.5.2100.105_SLES15.4.zip /root
chown root:root PowerFlex_4.5.2100.105_SLES15.4.zip
```
- Extract the zip
```
unzip PowerFlex_4.5.2100.105_SLES15.4.zip
```
- Download the Azure core Terraform scripts
```
wget https://github.com/dell/terraform-powerflex-modules.git
```
- Confirm the files are downloaded and copy the tfvars file into the azure-core directory
```
cp terraform.tfvars azure-core
cd azure_core

terraform init -upgrade
Copy terraform.tfvars and create a terraform execution plan

cp /root/terraform.tfvars .
terraform plan -out main.tfplan
Apply the terraform execution plan. This process will execute for roughly 5 minutes. +/-.

terraform apply main.tfplan
This step can be monitored via the PowerFlex Manager UI under Monitoring | Events
