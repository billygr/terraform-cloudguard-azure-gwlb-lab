# terraform-cloudguard-azure-gwlb-lab

## IP scheme

serviceA VM: 10.0.1.4<br>
serviceB VM: 10.0.2.4<br>
cpmgmt   VM: 172.16.1.4<br>
jumpbox  VM: 172.18.0.4<br>
cpvmss1  VM: 192.168.0.5<br>
cpvmss2  VM: 192.168.0.6<br>
<br>
## vnet peerings
from/to jumpbox serviceA<br>
from/to jumpbox serviceB<br>
from/to jumpbox cpmgmt<br>
<br>
from/to cpmgmt to vmms scaleset<br>

## Connectivity
ssh -i azureuser.pem azureuser@jumpboxpublicip

From jumpbox you can ping serviceA/serviceB/cpmgmt

ssh to mgmt at 172.16.1.4 to have ssh access to the vmss gateway (ping will not work due to InitialPolicy)

## Manual configuration steps (will be automated in the feature)
On your management server:

If you are running a Standard D2 v2 (2 vcpus, 7 GiB memory) =<8GB of RAM you need to enable the api manually on cpmgmt: api start
with bigger sizes it enables it automatically

Install a license for 172.16.1.4<br>
Install the CME script<br>

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
