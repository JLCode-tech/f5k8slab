#! /bin/bash
#sudo apt-get install -y docker.io
#sudo systemctl enable docker
#curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
#sudo add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
#sudo apt-get update
#sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

#MASTER INSTALL
#sudo kubeadm init --config=kubeadm-config.yaml
#mkdir -p $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Get Kubectl CONFIG for export to local machine
#cat $HOME/.kube/config
#export KUBECONFIG=/mnt/c/Users/lucia/Documents/git_working/terraform_k3s_lab/proxmox-tf/prod/kubeconfig

#--- Network Install ---------------------------------------------------------------------------------------
#Cilium Install
#kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/cilium/cilium.yaml
#Verify pods start up correctly
#kubectl -n kube-system get pods --watch


#--- Worker Node Install ---------------------------------------------------------------------------------------
#Install Worker Nodes



#--- Load Balancer Install ---------------------------------------------------------------------------------------
#Install LB - Using Metallb
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/metallb/metallb-namespace.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/metallb/metallb.yaml
# On first install only
#kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/metallb/metallbconfigmap.yaml

#--- Dashboard Install ---------------------------------------------------------------------------------------
#Install Dashboard
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/dashboard/dashboard.yaml
#Create Admin Access
kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/dashboard/dashboard.admin-user.yml -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/dashboard/dashboard.admin-user-role.yml
#Get Token for Access
kubectl -n kubernetes-dashboard describe secret admin-user-token | grep ^token
kubectl -n kubernetes-dashboard get services

#--- Storage Longhorn ---------------------------------------------------------------------------------------
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/longhorn/001-longhorn.yaml
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/longhorn/002-storageclass.yaml
kubectl -n longhorn-system get services

#--- Portainer Install ---------------------------------------------------------------------------------------
#Portainer Install
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/portainer/portainer.yaml
#NodePort Install Below
#kubectl apply -f portainer-nodeport.yaml
### ---- Check LB IP and Port allocated  ---------------------------------------------------
kubectl -n portainer get services


#--- Hubble Install ---------------------------------------------------------------------------------------
#Hubble Install
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/hubble/hubble.yaml
kubectl -n kube-system get services

#HELM Install
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add influxdata https://helm.influxdata.com/

# K8s Infra monitoring stack --------------------------------------------------------------------------
# ---- Prometheus -----------
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/prometheus-grafana/prometheus/001-namespace.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/prometheus-grafana/prometheus/002-promdeploy.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/prometheus-grafana/prometheus/003-promconfig.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/prometheus-grafana/prometheus/004-nodeexport.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/prometheus-grafana/prometheus/005-statemetrics.yaml
kubectl create namespace monitoring
helm install prometheus stable/prometheus --namespace monitoring --set alertmanager.persistentVolume.storageClass="longhorn" --set server.persistentVolume.storageClass="longhorn"
#
#
# ---- Grafana -----------
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/prometheus-grafana/grafana/001-grafana.yaml
helm install grafana stable/grafana --namespace monitoring --set persistence.storageClassName="longhorn" --set persistence.enabled=true --set adminPassword='Mongo!123' --values https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/prometheus-grafana/grafana/002-grafanavalues.yaml --set service.type=LoadBalancer
### ---- Check LB IP and Port allocated  ---------------------------------------------------
kubectl -n monitoring get services

# EFK monitoring stack --------------------------------------------------------------------------
kubectl apply -f efk-logging/elastic.yaml
kubectl apply -f efk-logging/kibana.yaml
kubectl apply -f efk-logging/fluentd.yaml

# --- InfluxDB ------
helm install influx influxdata/influxdb --namespace monitoring --set persistence.enabled=true,persistence.size=20Gi --set persistence.storageClass="longhorn"

Install Name: http://influx-influxdb.monitoring:8086

# ---- Speedtest--------
helm install speedtest billimek/speedtest -n monitoring --set config.influxdb.host="influx-influxdb.monitoring" --set config.delay="14400" --set debug="true"
kubectl logs -f --namespace monitoring $(kubectl get pods --namespace monitoring -l app=speedtest -o jsonpath='{ .items[0].metadata.name }')

# ---- Ingress -----
kubectl create namespace nginx-ingress-system
helm install nginx-ingress ingress-nginx/ingress-nginx --wait --namespace nginx-ingress-system --set rbac.create=true

# ---- Private Registry ----
kubectl create namespace registry
helm install harbor --namespace registry harbor/harbor --set expose.tls.commonName=harbor.solutionslab.co --set expose.ingress.hosts.core=harbor.solutionslab.co --set expose.ingress.hosts.notary=notary.solutionslab.co --set externalURL=https://harbor.solutionslab.co --set harborAdminPassword=admin --wait

docker push harbor.solutionslab.co/f5spk/REPOSITORY[:TAG]