#What is Azure Toolkit?

Azure Toolkit is a collection of scripts that I have developed to make things easier for a variety of scenarios.

The toolkit consists of the following scripts -\

1. **vhdcopy.sh** - vhdcopy.sh a bash shell script to copy VHD files from one subscription to another or in same subscription in a different stora account.
2. **vmcopy.sh** - vmcopy.sh is based on the vhdcopy.sh but does a lot more than that. you can use vmcopy.sh to copy VMs from one subscription to another, one region to another, change the vnets/subnets among others.

#Prerequisites
+ Install [**Azure CLI**] (https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/) and the awesome command-line JSON processor [**jq**] (https://stedolan.github.io/jq/)

+ Add the source and target subscriptions on your system by running the following command (once for each subscription) -

```bash
azure login
```

This will display a code that you need to copy and paste in your browser after opening the http://aka.ms/devicelogin URL. Do this for both the subscriptions.

#How to use the scripts?

#vhdcopy.sh

To use vhdcopy.sh, you need to know the following parameters -
+ Source subscription id
+ Target subscription id
+ URL of the VHD file you want to copy between these subscriptions

If you have added the Azure accounts in question by running the **azure login** command, run the following command to display the subscription IDs for your subscriptions -

```bash
azure account list
```

Last thing you need is the URL of the blob you need to copy between the subscriptions. Easiest way to get that information is from the Azure portal.

Run the script with the following syntax -

```bash
./vhdcopy.sh <source subscription id> <target subscription id> <URL of the blob you want to copy> <optional-target storage account name> <optional-target container name>
```

By default, vhdcopy.sh will create a target storage account with **new** prefixed to the source storage account name unless a name was provided on the command line. Same rule is followed for the resource group created in the process.

Do this for every blob you need to copy and that's all - sit back and relax!

**Note**: This script was developed on a **Windows 10** system with **Bash on Ubuntu** running on it so I had to use sudo with every Azure CLI command - if you are on a Mac or Linux machine, you may not have to use sudo at all.

#How does this work?

This script use the Azure CLI commands along with the JQ command line tools to do the following -

1. Determine the resource group information for the source and target storage accounts
2. Create a storage account the target subscription. If no storage account was provided on the command line, it creates a new storage account with a prefix to the name of the storage account in the source subscription - **new**. A resource group is also created in the target subscription in the same manner. The location of these resources is set to same as the location information in the source subscription.
3. Determine if the source container/blob exists
4. Verify the presence of target container and create if not already present
5. Finally, copy the blob to the target subscription

#vmcopy.sh

The vmcopy.sh script is based on the vhdcopy.sh script but allows you to do the following -
+ Clone a VM from one subscription to another subscription
+ Clone a VM in the same subscription (in the same location or a new one)
+ Clone your VMs from one region to another region
+ Clone a VM in a new VNET/Subnet of your choice

Please keep in mind that the term **cloning** is used all over here since all these operations are performed on the VMs without the need to generalized the VMs in the first place.

The vmcopy.sh script needs 4 mandatory parameters -
+ Source subscription id
+ Target subscription id - this can be same as the source subscription id if you wish to make a copy of the VM in the same subscription
+ Resource group name
+ VM name

Syntax:

```bash
./vmcopy.sh <source subscription id> <target subscription id> <new location of VM> <source resource group> <source vm name>
```

Example 1 - Clone a VM to a new location with minimal number of parameters:

```bash
./vmcopy.sh <source subscription id> <target subscription id> southeastasia MyTestRG MyVM0
```

The above example will copy the vm name provided on the command line to the target subscription. A new resource group in the target subscription will be created in the name as **MyTestRGmmdd** where mm is current month and dd is current date. A new storage account will also be created as MyTestRGmmdd + name of source storage account (truncated to 24 characters). The name of the vm will remain same. All these resource will be created in the South East Asia location. Please note your target subscription needs to have access the region mentioned for it to work.

Example 2 - Clone a VM in a new resource group with a new VM:

```bash
./vmcopy.sh <source subscription id> <target subscription id> westus MyTestRG MyVM0 MyNewRG NewVM0
```

This syntax will create a new VM named **NewVM0** in a resource group called **MyNewRG** (it will be created if it doesn't exist) in a newly created storage account. The location of the new VM will be **West US**.

Example 3 - Clone a VM in the same subscription:

```bash
./vmcopy.sh <source subscription id> <source subscription id> westus MyTestRG MyVM0 MyNewRG NewVM0
```

This syntax will create a clone of MyVM0 named **NewVM0** in a resource group called **MyNewRG** in a new storage account. The location of the new VM will be **West US**. This assumes that the source VM is also in the **West US** region.

The script also has hardcoded values for Virtual Network and Subnet. If you just wish to change VNET or Subnets of your VMs, you can edit the script to have the desired ranges and run the command to move your VMs to a new VNET/Subnet.

**Disclaimer**: This script is provided as is and suitability for any purpose is not guaranteed - please test it thoroughly and modify as per your requirements.