## Sample srsLTE Deployment Manifest And Configurations

This is to make it a bit easier to deploy srsLTE enb and ue.

Description of the folders are:

**sample-srs-lte-config:** This consists of sample config files, you can use them if you want to deploy srsLTE in a separate VM, this does not include the building/compilation of the srsLTE.

**k8s-manifests:** This consists of both the Dockerfile and Kubernetes manifest files, you can use this to deploy srsLTE inside the same Kubernetes cluster that is been used for Open5gs. Kindly take note of the following directions:

1.) Build the srsLTE and push to ECR

2.) Create the configmaps first (srs-configmap.yaml)

3.) Create the deployments (srs-deployment.yaml), you have to replace {{srsLTEImage}} with the srsLTE you built.

4.) Exec into the srslte POD:

- copy the enb.conf, rr.conf, sib.conf and drb.conf files from /srsLTEconfig to the srsLTE/build/srsenb/src/ and change the following place-holders:

​	**enb.conf -** 

​			**{{MCC}}:** replace with MCC

​			**{{MNC}}:** replace with MNC

​			**{{MME_ADDR}}:** replace with the MME POD net1 interface IP (you need to exec inside the POD to get 			the IP)

​			**{{GTP_BIND_ADDR}}:** replace with the net1 interface IP inside the srslte POD

​			**{{S1C_BIND_ADDR}}:** replace with the net2 interface IP inside the srslte POD

​    **rr.conf:**

​		**{{TAC}}:** replace with the TAC (example is 0x0007)

* copy *ue.conf* from /srsLTEconfig to the srsLTE/build/srsue/src/ and change the following place-holders, these values must match what was configured in the Open5gs web-gui:

​       **{{OPC_CODE}}:** replace with the opc (example is e734f8734007d6c5ce7a0508809e7e9c)

​       **{{SECURITY_KEY}}:** replace with the security key (example is 8baf473f2f8fd09487cccbd7097c6862)

​       **{{UE_IMSI}}:** replace with the subscriber IMSI (example is 208930100001111)

* Exec into the srslte POD and start the enb from the srsLTE/build/srsenb/src/: **./srsenb enb.conf**
* Open another exec session into the srslte POD start the ue from the srsLTE/build/srsue/src/: **ip netns add ue1;./srsue ue.conf**

Check the srsLTE zeroMQ for more details: https://docs.srslte.com/en/latest/app_notes/source/zeromq/source/index.html#zeromq-installation