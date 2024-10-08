# **Terraform Project for Network Configuration** 💻

## ⭐️ Overview

This Terraform project automates the configuration of a network of VMs which includes:

```text
🔹 Gateway
🔹 DNS
🔹 DHCP
🔹 Webserver
```

The scripts facilitate the setup of these virtual machines in [vSphere](https://vcenter.easlab.co.uk).

## ⚙️ Prerequisites

This project assumes you have the following:

```text
🔸 Access to a vSphere environment
🔸 Necessary permissions for VM management and configuration
🔸 Have VS code installed
🔸 Have the necessary permissions to download the git repo used in this playbook
🔸 Already generated a RSA key pair and saved the values on your machine and public key to github
```

## 🐾 Step One

Change your directory to where you wish to run this script and store the cloned repository:

```bash
cd <filename>
```

## 🐾 Step Two

Clone the repository from github and then move into the new directory.

```bash
git clone https://github.com/laurawarren88/terraform.git
cd terraform
```

## 🐾 Step Three

Take a look 👀 around the file 📂 structure and see what is happening with VS code.

```bash
code .
```

You will need to add a secrets 🤫 file into the file tree to store necessary information to run the script.

I'll walk you through it:

```bash
touch secret.tfvars
vim secret.tfvars
```

In the file you need to include your information ℹ️ into the following variables:

```text
vcenter_username        = ""
vcenter_password        = ""
folder_path             = ""
internal_network        = ""
password_vm             = ""
```

Inbetween the double quotes store your username and password you use to login to **vSphere** 

For the folder path list a location where you want the VMs to be stored in vSphere ***e.g. "/Development/vm"***.

For the internal network, list the name of a VM network you want to use for the internal network to connect to.

If the template you are using to deploy the VMs from has a password, list that here so you can SSH into the VM without inputting the password.

Take a look at the terraform.tfvars file as well as you may need to change some of these non-secret variables to correspond with your own environment.

## 🐾 Step Five

Initiate Terraform

```bash
terraform init
```

Ensure it builds correctly and will run without errors

```bash
terraform plan -var-file="secret.tfvars"
```

Run the Terraform script, with or without extra debugging information:

```bash
TF_LOG=DEBUG terraform apply -var-file="secret.tfvars" --auto-approve
```

or

```bash
terraform apply -var-file="secret.tfvars" --auto-approve
```

## 🐾 Step Six

Open your browser to vSphere and watch as the VMs are created (in your desired folder).

The VMs should poweron and connect to the desired networks.

In your terminal once everything has finished building the terminal should display a JSON todo list.

This display will let you know the VMs are all connected and the webserver connects to the internet with the webapp running from the installed Git Repo.