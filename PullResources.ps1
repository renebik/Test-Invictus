param([string] $AccountName,[string] $SasToken,[string] $SaveLocation)
 
#Leave empty to always get the latest build: If you want a specific build supply the blob name for the targeted api ex: 21294/Invictus.Matrix.Connector.zip
#Ensure file exists or script will break
$apiSelectedBuilds = New-Object 'system.collections.generic.dictionary[string,string]'
$apiSelectedBuilds['pubsubconnector'] = "";
$apiSelectedBuilds['matrixconnector'] = "";
$apiSelectedBuilds['transcoconnector'] = "";
$apiSelectedBuilds['dashboardfrontend'] = "";
$apiSelectedBuilds['invictusgatewayapi'] = "";
$apiSelectedBuilds['importfunction'] = "";
 
$ctx = New-AzureStorageContext -StorageAccountName "$AccountName" -SasToken "$SasToken"
 
#Get list of containers in Blob Store
$containerListRequest = [System.Net.WebRequest]::Create("https://$AccountName.blob.core.windows.net$SasToken&comp=list")
$containersXml = (new-object System.IO.StreamReader($containerListRequest.GetResponse().GetResponseStream())).ReadToEnd()
$containers = ([xml]$containersXml ).EnumerationResults.Containers.Container
 
foreach ($container in $containers)
{
    #Get all blobs in container
    $resources = Get-AzureStorageBlob -Container $container.Name -Context $ctx
    
    #Get specified build by container name if set
    $selectedBuild = $apiSelectedBuilds[$container.Name]
    $resourceSelected = $selectedBuild;
 
    if([string]::IsNullOrEmpty($selectedBuild))
    {
        #Should get latest version
        $resources = $resources | Sort-Object -Property LastModified -Descending
        $resourceSelected = $resources[0].Name;
    }
 
   "Downloading: "+ $resourceSelected
 
   #Remove build number before saving to location
   $fileName = ($resourceSelected.Split('/') | Select-Object -Last 1)
   $destination = ""
 
   if([string]::IsNullOrEmpty($SaveLocation))
   {
      $destination = "$env:Build_ArtifactStagingDirectory" + "\" + $fileName
   }
   else
   {
      $destination  = $SaveLocation + "\" + $fileName
   }
 
    #Download and save file to specified location
    Get-AzureStorageBlobContent -Context $ctx -Container $container.Name -Blob $resourceSelected -Destination $destination
}