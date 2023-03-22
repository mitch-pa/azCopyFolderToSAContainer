<# This Powershell script copy folders with azcopy from local Azure VM path to StorageAccount container. 
The VM in Azure need to use managed identity and have blob/storage permission to StorageAccount for azcopy to work.
The script use azcopy with SAS key to authenticate. 
Before running script, update the following variable: SubscriptionId, ResourceGroup, StorageAccount, PathToFolder and SASKey.

How to run the script:
.\azCopyFolderToContainer.ps1 FolderToCopy NewContainerToCreate ValueTag1 ValueTag2 ValueTag3
#>

# Mandatory parameter
param (
        [Parameter(Mandatory)][string]$SourceFolderName,
        [Parameter(Mandatory)][string]$ContainerName,
        [Parameter(Mandatory)][string]$TagValueOne,
        [Parameter(Mandatory)][string]$TagValueTwo,
        [Parameter(Mandatory)][string]$TagValueThree
)

# Variables
$SubscriptionId = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
$ResourceGroup = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
$StorageAccount = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
$PathToFolder = 'C:\XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
$SASKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX'

# Only lowecase, no underscore
$ContainerName = $ContainerName.ToLower().Replace('_','-')

# Check if folder and path exist, if not Exit code
if (!(Test-Path "$PathToFolder\$SourceFolderName")) 
{
        Write-Warning "The folder does not exist on path: $PathToFolder\$SourceFolderName. Please check path and folder name!" 
        Exit
}

# Connect to Azure using managed indentity
Add-AzAccount -identity
Select-AzSubscription -SubscriptionId $SubscriptionId
Set-AzCurrentStorageAccount -ResourceGroupName $ResourceGroup -AccountName $StorageAccount

# Check if Container name already exist
if (!(Get-AzStorageContainer -Name $ContainerName -erroraction 'silentlycontinue'))
{

        Try
        {
                # Create container
                New-AzStorageContainer -Name $ContainerName
                
                # Retrieve container
                $Container = Get-AzStorageContainer -Name $ContainerName 

                # Add metadata for container
                $MetaData = New-Object System.Collections.Generic.Dictionary"[String,String]"
                $MetaData.Add("ProjName",$TagValueOne)
                $MetaData.Add("ProjNumber",$TagValueTwo)
                $MetaData.Add("City",$TagValueThree)
                $Container.BlobContainerClient.SetMetadata($MetaData, $null)  

                # Run Azcopy with SAS token
                .\azcopy copy "$PathToFolder\$SourceFolderName" "https://$StorageAccount.blob.core.windows.net/$ContainerName/$SASKey" --blob-type=BlockBlob --block-blob-tier=cool --recursive=true
        }
        Catch
        {
                Write-Error "An error occurred:"
                Write-Host $_
        }  
}
 else 
{
        # Exit code
        Write-Warning "The Container name: $ContainerName already exists. Please use different name!" 
        Exit
}
