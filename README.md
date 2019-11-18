# Introduction to Azure DevOps Self Hosted Agents running inside an Azure Container Instance
Running your Azure DevOps self-hosted agent in a Azure Container Instance. Contains serveral dockerfile examples for Windows and Linux container agents as well as all the necessary YAML pipelines and ARM templates.

# Getting Started
1.	Clone this repository.
2.	Import the YAML pipelines.
3.  Generate an Azure DevOps PAT with the folowing permissions: Agent Pools (Read & Manage), Deployment Groups (Read & Manage)
4.  Create an agent pool in Azure DevOps to put your self-hosted agent container inside.	
5.  Alter the variables inside the "infrastructure" pipelines.
6.  Run the "infrastructure" pipeline for the first time.
7.  Store PAT token in newly created Azure Key Vault.
8.  Choose which "container" pipeline you want to start using and alter the variables inside.
9.  Alter the ARM template paramters file so that the Key Vault references matches up. 
10. Run the "container" pipeline for the first time.

For more information see the blog article I've wrote about this.
