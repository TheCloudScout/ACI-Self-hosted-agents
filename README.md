# What is this?
I wrote a blog article about building and deploying your own self-hosted container agents with Azure DevOps and Azure Container Instances.
See the blog article I've wrote here:
https://medium.com/@koosg/build-your-own-azure-devops-agents-with-pipelines-95104be095d5

With everything that’s inside this repository you’ll be able to customize, build and deploy your own container agents straight from Azure DevOps.

# Overview of how this works
To build your own container images you need a container registry to store the images. We’re going to be using Azure Container Registry for this. Next, we’re going to make use of Azure Container Instances to run the actual container. And since we want to play as securely as possible, let’s throw in an Azure Key Vault as well. We’ll be storing the Container Registry credentials in there as well as our DevOps Personal Access Token (PAT).
When you’re all done the deployment should look something like this:

![Overview](/_readme_images/01_overview.png)
1.	First we need to deploy the Key Vault and Container Registry.
2.	Secondly we need to store ACR credentials inside the Key Vault.
3.	Then we’ll deploy a Container Instance.
4.	During deployment we’ll refer to the vault for the registry credentials.
5.	Lastly the Container Instance can pull the container image from the ACR.

# Building, pushing and deploying your contain agent
For building and pushing our Docker image to the Azure Container Registry we need to use a Microsoft hosted agent with an OS that matches the source of our container. But we need to deploy the ACR and Key Vaults first. So we’ve decided to use a separate pipeline for setting up the initial infrastructure and a second one for building, pushing and deploying the container.
And then there’re three different tastes when it come to container agent flavors. We have a Windows and Linux version and also a Linux version with VNet integration. As as of right now VNet integration is not yet available for Azure Container Instances running Windows containers.
Lastly we wanted to provide some way in which teams can automatically start and stop their container instances so keep the costs of the ACI down since this will be generate cost every second it is running.
So we’ve ended up with several different pipelines:

![Pipeline_overview](/_readme_images/02_pipelines.png)

# Step-by-step instructions
Ok now you’ll have a general idea about how this will work and what components are needed, let’s start implementing these -pre-build pipelines and start deploying!
## Fork or clone this repository to your own Azure DevOps Project or Github

## Gather some object ID’s
In the next steps we’ll ne needing a few object ID’s, tenant ID and the names of certain object you’re already using. We need to gather and note down this information first before we can continue.
Go into _“Project Settings”_ within your own Azure DevOps and select _“Service Connections”_.
In there you’ll find some service connections you’re already using for deployments to Azure Resource Manager (ARM):

![service-connections](/_readme_images/04_service-connections.png)

Please **note down the name** of the service connection you’ll later be using for deploying the container agent resources.
Secondly, go into that service connection and **note its Service Principal Id**:

![service-principal-ID](/_readme_images/05_service-principal-ID.png)

Now we need to visit the Azure Portal and specifically Azure Active Directory. Open up _“Enterprise Applications”_ and search for the _“Service Principal ID”_ you’ve note down earlier.

![AAD-enterprise-application](/_readme_images/06_AAD-enterprise-application.png)

If your team has its own Azure Active Directory group look that up under _“Groups”_ and **note down the object ID**:

![AAD-group](/_readme_images/07_AAD-group.png)

If you don’t have a group lookup your own user account under _“Users”_ and **note down that object ID instead**:

![AAD-user](/_readme_images/08_AAD-user.png)

Ok now we have gathered all the information we need; we can continue working with Azure DevOps.
## Change ARM template for Key Vault deployment
Before we can start working with the pipelines, we need to make some changes to the ARM template parameters file which we’re going to use for deploying the Azure Key Vault. In there you’ll find two object ID already listed. You’ll need to change these so that both Azure DevOps deployments and you team itself have access permissions to this Key Vault after deployment.
Go to */key-vault/key-vault-parameters.json* and change those two object ID’s and replace them with the object ID’s from the Enterprise Application and User/Group you’ve lookup up earlier in Azure AD.

![KeyVault-ARM](/_readme_images/09_key-vault-arm.png)

Make sure to commit the change so the change is saved in the repository!
## Deploy the container agent infrastructure
Go into _“Repos”_ --> _“Pipelines”_ and import an existing YML pipeline from your repository: 

![Import-yml-pipelines-01](/_readme_images/09_Import-yml-pipeline-01.png)
![Import-yml-pipelines-02](/_readme_images/09_Import-yml-pipeline-02.png)

Select the */deploy-adsha-instrastructure.yml* file and import this pipeline: 

![Import-yml-pipelines-03](/_readme_images/09_Import-yml-pipeline-03.png)

Make changes to the variables in the YAML code:

![Alter-variables](/_readme_images/10_change-variables.png)
* **ResourceGroup:** the name of the RG you want to deploy the azure resource to
* **ServiceConnection:** the name of the service connection in Azure DevOps you’ve noted down earlier
* **KeyVaultName:** the preferred name of the Azure Key Vault you’re about to deploy
* **acrName:** the preferred name of the Azure Container Registry you’re about to deploy

Click on _“Run”_ in the top-right corner to start deploying these resources.
## Generate PAT and store it safely
Before we can start running our self-hosted agent we need to create an _“agent pool”_ for it and a Personal Access Token (PAT) so it can authorization to Azure DevOps.
Click on the “settings” button in the top-right corner and follow these steps to generate a PAT.

![generate-PAT](/_readme_images/11_generate-PAT.png)

Enable **Agent Pools** (read, manage) & **Deployment group** (read, manage)
**Note down that PAT** because you won’t be able to retrieve it afterwards! If you lose it, you’ll need to generate a new one.

Next visit your newly created Azure Key Vault and _“Generate/Import”_ a new _“Secret”_ to store this PAT. Make sure the secret is named _”patTokenManageAgent”_:

![store-PAT-in-KV](/_readme_images/12_store-PAT-in-KV.png)
## Create Agent Pool in Azure DevOps
Crreate a new agent pool within your Azure DevOps project:

![create-agent-pool](/_readme_images/13_create-agent-pool.png)

**Note down the name of this agent pool**, you’ll be needing it later.
## Import one of the container pipelines
Repeat the steps from step 4 to create another pipeline and choose from one of the three container pipeline YAML files.
We’ll need to make changes to variables here as well:

![import_container-pipeline](/_readme_images/14_import-container-pipeline.png)
* **azdURL:** the URL to your Azure DevOps organization
* **agentPool:** the name of the agent pool you’ve created earlier in Azure DevOps
* **ServiceConnection:** the name of the service connection in Azure DevOps you’ve noted down earlier
* **ResourceGroup:** the name of the RG you want to deploy the azure resource to
* **KeyVaultName:** the name of the Azure Key Vault you’ve deployed earlier
* **containerInstanceName:** the preferred name of the container instance you’re about to deploy
* **acrName:** the preferred name of the Azure Container Registry you’re about to deploy
* **containerRepository:** the name of the container image as it is saved in the container registry

Click on _“Run”_ in the top-right corner and wait for all the magic to happen.
## Verify your running container agent
After both of your pipelines deployed successfully:

![successful-pipeline](/_readme_images/15_successfull-pipelines.png)

Check your agent pool is the agent has come online:

![online-agent](/_readme_images/16_online-agent.png)

# Troubleshooting
If you happen to run into any issues and your container agents does not show up. Please try the following steps to get back on track:
Unfortunately, there’s no way to set up an interactive session with your container running in ACI. So there’s no easy way to see what’s going on inside. Make sure the the container is in a “Running” state and that the environment variables are pushed correctly so that the Microsoft agent running inside the container knows where to connect to:

![troubleshoot-container](/_readme_images/17_troubleshoot-container.png)

If this looks OK but the agent is not connecting, please try and run the container locally with an interactive session. That way you can see what might be going wrong.
Please see the appropriate steps for running a Docker container locally in [this blog]( https://bgelens.nl/azuredevops-container-instance/). If you need any additional help you can also contact our team. 

# Maintaining low Azure consumption
As we stated in the introduction running an Azure Container Instance is cheaper then running a Virtual Machine (with the mandatory operations costs) but it’s still best practice obviously to keep the costs down as much as possible.
Once these pipelines are deployed, we end up with three Azure resources in place:
* **Azure Key Vault** Generates cost on read/write operations on secrets, keys and certificate. Sine the amount of request will be extremely low, we can neglect the costs generated by this Key Vault since it won’t even cost € 0,01 a month. 

* **Azure Container Registry** An ACR in the current tier we’re using has a default storage of 10Gb for container images. Let’s say we’re going to exceed that and use approx. 30Gb of storage. Then this ACR will cost you about € 5,- a month.

* **Azure Container Instance** This is the most expensive resource of the three. Let’s the Linux container agent as an example. It uses 3Gb of memory and 2 CPUs. If you’re going to keep it running 24/7 It’ll cost you about € 50,- a month. 
For calculations on multiple containers, Windows OS and different specs please see the [Azure calculator]( https://azure.microsoft.com/nl-nl/pricing/calculator/) for more details.
## Automatically start/stop your container agent
We’ve also provided to pipelines which can stop and start your ACI on a specific time and day. So start using this import these two pipelines in the same way you’ve imported the other pipelines.
Change the following variables:

![stop-start-ACI-01](/_readme_images/18_stop-start-ACI-01.png)
* **cron:** adjust the timeslot and days to your liking
* **ResourceGroup:** the name of the RG you want to deploy the azure resource to
* **ServiceConnection:** the name of the service connection in Azure DevOps you’ve noted down earlier
* **ACIname:** the name of the container instance you’ve deployed earlier

Eventually your pipelines should look something like this:

![stop-start-ACI-02](/_readme_images/18_stop-start-ACI-02.png)

# Contribute
Developers are invited to send feedback and their improvements on the project.

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)