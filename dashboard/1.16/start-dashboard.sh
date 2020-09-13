#!/bin/bash
kubectl create -f namespace-dashboard.yaml

kubectl create -f dashboard-admin.yaml

kubectl create secret generic kubernetes-dashboard-certs \
--from-file=dashboard.key \
--from-file=dashboard.crt \
-n kubernetes-dashboard

kubectl apply -f recommended.yaml

kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep dashboard-admin | awk '{print $1}')
