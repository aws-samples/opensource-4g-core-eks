## x86 Architecture

**Open5gs images:**

 cd x86-Architecture/Dockerfiles/open5gs-epc/
 
 docker build -t container_registry/open5gs-x86-aio:41fd851 -f open5gs-epc-aio .
 
 docker build -t container_registry/open5gs-x86-web:41fd851 -f web-gui .

**Service discovery and secondary_init_controller:**

 cd x86-Architecture/Dockerfiles/aws-secondary-ip-sync-controller/
 
 docker build -t container_registry/multus-x86-sec-ip-controller:v0.1 .
 
 cd x86-Architecture/Dockerfiles/multus-svc-watcher-route53-controller/
 
 docker build -t container_registry/multus-x86-svc-watcher-route53:v0.1 .
 
**Push images to your ECR:**

 docker push container_registry/open5gs-x86-aio:41fd851
 
 docker push container_registry/open5gs-x86-web:41fd851
 
 docker push container_registry/multus-x86-sec-ip-controller:v0.1
 
 docker push container_registry/multus-x86-svc-watcher-route53:v0.1
 
## Arm Architecture 
 **Open5gs images:**
 
 cd Arm-Architecture/Dockerfiles/open5gs-epc/
 
 docker build -t container_registry/open5gs-arm-aio:v2.1.1-5-gefd1780 -f open5gs-epc-aio .
 
 docker build -t container_registry/open5gs-arm-web:v2.1.1-5-gefd1780 -f web-gui .

**Service discovery and secondary_init_controller:**

 cd Arm-Architecture/Dockerfiles/aws-secondary-ip-sync-controller/
 
 docker build -t container_registry/multus-arm-sec-ip-controller:v0.1 .
 
 cd Arm-Architecture/Dockerfiles/multus-svc-watcher-route53-controller/
 
 docker build -t container_registry/multus-arm-svc-watcher-route53:v0.1 .
 
**Push images to your ECR:**

 docker push container_registry/open5gs-arm-aio:v2.1.1-5-gefd1780
 
 docker push container_registry/open5gs-arm-web:v2.1.1-5-gefd1780
 
 docker push container_registry/multus-arm-sec-ip-controller:v0.1
 
 docker push container_registry/multus-arm-svc-watcher-route53:v0.1
