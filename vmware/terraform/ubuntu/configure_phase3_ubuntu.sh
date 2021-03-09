#!/usr/bin/env bash

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#export kubever=$(kubectl version | base64 | tr -d '\n')
#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

#kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
#kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

#kubectl apply -f kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml

#Network CNI
kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/cilium/cilium-custom.yaml

#kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/calico/calicooperator.yaml
#kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/calico/calico.yaml

kubectl get pods --all-namespaces
kubectl get nodes