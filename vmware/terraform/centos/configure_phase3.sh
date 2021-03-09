#!/usr/bin/env bash

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Allow All to carry pods
kubectl taint nodes --all node-role.kubernetes.io/master-

#Network CNI
kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/cilium/cilium-custom.yaml

#kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/calico/calicooperator.yaml
#kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/calico/calico.yaml

kubectl get pods --all-namespaces
kubectl get nodes