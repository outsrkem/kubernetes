# kubernetes

#### 介绍
kubernetes 资源清单文件


```
.
├── configmap
│   ├── game
│   │   ├── game.properties
│   │   ├── pod-single-configmap-env-variable.yaml
│   │   └── ui.properties
│   ├── nginx-www
│   ├── pod-configmap-2.yaml
│   ├── pod-configmap-3.yaml
│   ├── pod-configmap.yaml
│   ├── pod-secret-1.yaml
│   └── README.md
├── coredns
│   ├── coredns.yaml.patch
│   ├── coredns.yaml.sed
│   ├── deploy.sh
│   └── kubernetes1.13.1集群部署coredns.md
├── dashboard
│   ├── 1.16
│   │   ├── dashboard-admin.yaml
│   │   ├── README.md
│   │   ├── recommended.patch
│   │   └── recommended.yaml
│   ├── dashboard-adminuser-k8sv1.13.yaml
│   └── kubernetes-dashboard-k8sv1.13.yaml
├── deploy-myapp.yaml
├── deploy-sa-myapp.yaml
├── deploy-zkweb.yaml
├── heapster
│   ├── grafana.yaml
│   ├── heapster-rbac.yaml
│   ├── heapster.yaml
│   └── influxdb.yaml
├── ingress
│   ├── deploy-demo.yaml
│   ├── ingress-myapp.yaml
│   ├── ingress-tomcat-tls.yaml
│   ├── ingress-tomcat.yaml
│   ├── service-nodeport.yaml
│   ├── tls.crt
│   ├── tls.key
│   └── tomcat-demo.yaml
├── jobs
│   ├── job-demo.yaml
│   └── pi-demo.yaml
├── kubeadm
│   └── README.md
├── liveness
│   ├── liveness-exec.yaml
│   ├── liveness-http.yaml
│   └── liveness-tcp.yaml
├── master
│   ├── aggregated-metrics-reader.yaml
│   ├── auth-delegator.yaml
│   ├── auth-reader.yaml
│   ├── metrics-apiservice.yaml
│   ├── metrics-server-deployment.yaml
│   ├── metrics-server-service.yaml
│   └── resource-reader.yaml
├── myapp-svc-headless.yaml
├── myapp-svc.yaml
├── pod-demo.yaml
├── poststart-pod.yaml
├── rbac
│   ├── clusterrolebinding-demo.yaml
│   ├── clusterrole-demo.yaml
│   ├── rolebinding-clusterrole-demo.yaml
│   ├── rolebinding-demo.yaml
│   ├── rolebinding-ns-admin-demo.yaml
│   ├── role-deml.yaml
│   └── test.role.yaml
├── readiness-httpget.yaml
├── README.md
├── redis-ds-demo-svc.yaml
├── redis-ds-demo.yaml
├── registrykey-myhub.yml
├── required-Affinity-demo-pod.yaml
├── required-anti-Affinity-demo-pod.yaml
├── rs-myapp-svc.yaml
├── rs-myapp.yaml
├── schedule
│   ├── deploy-myapp.yaml
│   ├── required-Affinity-demo-pod.yaml
│   └── required-anti-Affinity-demo-pod.yaml
├── secret
│   └── deploy-myapp-secret.yaml
├── stateful
│   ├── pv-demo.yaml
│   └── stateful-demo.yaml
├── upDataGit.sh
├── volumes
│   ├── deploy-vol-pvc.yaml
│   ├── pod-vol-demo.yaml
│   ├── pod-vol-hostpath.yaml
│   ├── pod-vol-html-demo.yaml
│   ├── pod-vol-nfs.yaml
│   ├── pod-vol-pvc.yaml
│   └── pv-demo.yaml
└── 二进制搭建
    ├── 10--部署coredns.txt
    ├── 1--kube-etcd.txt
    ├── 2--kube-apiserver.txt
    ├── 3--kube-controller-manager.txt
    ├── 4--kube-scheduler.txt
    ├── 5--认证和授权.txt
    ├── 6--flannel.txt
    ├── 7--kubelet.txt
    ├── 8--kube-proxy.txt
    ├── 9--添加集群节点.txt
    ├── create-ca.sh
    └── dashboard.txt

17 directories, 93 files
```
