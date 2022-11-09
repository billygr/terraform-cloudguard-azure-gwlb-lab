#!/bin/sh
echo "Authenticating to Azure using a Service Principal and a Client Secret"
echo "run it in shell.azure.com. It creates a new appName=ServicePrincipalDemo1 or creates a new azure-client-secret on the second run"
echo "and display the azure-client-id/azure-client-secret/azure-subscription/azure-tenant to use it in your application"


subscriptioniD=`az account show --query id --output tsv`
appName="ServicePrincipalDemo1"
spPassword="ServicePrincipalDemo1"

createprincipal()
{
  echo "Creating principal"

# /dev/null could be removed to show the whole output 
  az ad app create \
  --display-name $appName > /dev/null

  azureclientsecret=$(az ad sp create-for-rbac --name "$appName" --role contributor --scope /subscriptions/$subscriptioniD | jq -r '.password')

  appId=$(az ad app list --display-name $appName --query [].appId -o tsv)
  echo "azure-client-id     =" \"$appId\"
  echo "azure-client-secret =" \"$azureclientsecret\"
  echo "azure-subscription  =" \"$subscriptioniD\"
  echo "azure-tenant        = "`az account show --query tenantId`
}

while true; do
    read -p "Do you wish to create a new Service Principal ? " yn
    case $yn in
        [Yy]* ) createprincipal; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done 
