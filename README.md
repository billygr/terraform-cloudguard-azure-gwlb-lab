# terraform-cloudguard-azure-gwlb-lab

## Prerequisites

Edit terraform.tfvars and change the my-pub-ip to your external ip. 
NSG rules are in place for ssh/https/cpmi of the cpmgmt it will not allow you to connect when the mgmt is up.

A Pay As You Go (PAYG) subscription of Azure has a max vCPU quota per region of 10 vCPU so we needed to fit everything.

You will need a service principal for the provision of the gateways

I have left as an exersice how you will chain the serviceA/serviceB to the Azure GW Load Balancer in order to explain the process

## Notes
MGMT with 2 vCPUs will take 15-18 minutes till you are able to login from SmartConsole (have that in mind).

## IP scheme

serviceA VM: 10.0.1.4 Standard_DS1_v2 1 vCPU <br>
serviceB VM: 10.0.2.4 Standard_DS1_v2 1 vCPU<br>
cpmgmt   VM: 172.16.1.4 Standard_D2_v2 2 vCPU<br>
jumpbox  VM: 172.18.0.4 Standard_DS1_v2 1 vCPU<br>
cpvmss1  VM: 192.168.0.5 Standard_DS1_v2 1 vCPU <br>
cpvmss2  VM: 192.168.0.6 Standard_DS1_v2 1 vCPU<br>
<br>
## vnet peerings
from/to jumpbox serviceA<br>
from/to jumpbox serviceB<br>
from/to jumpbox cpmgmt<br>
<br>
from/to cpmgmt to vmms scaleset<br>

## Connectivity
In case you forget the IP<br>

terraform output public_ip_address-jumpbox<br>
ssh -i azureuser.pem azureuser@jumpboxpublicip

From jumpbox you can ping serviceA/serviceB/cpmgmt

ssh to mgmt at 172.16.1.4 to have ssh access to the vmss gateway (ping will not work due to InitialPolicy)

## Manual configuration steps (will be automated in the feature)
On your management server:

If you are running a Standard D2 v2 (2 vcpus, 7 GiB memory) =<8GB of RAM you need to enable the api manually on cpmgmt: api start
with bigger sizes it enables it automatically

Install a license for 172.16.1.4<br>
Update the CME script, the defaults works in any case<br>

## Autoprovision of GWs
```
autoprov_cfg -f init Azure \
-mn cpmgmt -tn az-cpgwlbvmss -otp 123456789012 \
-ver R81.10 -po Standard -cn Azure \
-sb SUBSCRIPTION \
-at SERVICE_PRINCIPAL_CREDENTIALS_TENANT \
-aci SERVICE_PRINCIPAL_CREDENTIALS_CLIENT ID \
-acs SERVICE_PRINCIPAL_CREDENTIALS_CLIENT_SECRET
```

Switch template to use also IPS
```
autoprov_cfg -f set template -tn az-ckpgwlbvmss -ips
```
