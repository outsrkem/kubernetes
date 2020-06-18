# kubernetes

#### 介绍
kubernetes 资源清单文件

#### git创建ssh通道，避免每次都输密码

https://blog.csdn.net/lvdepeng123/article/details/79215882

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
│   └── pod-secret-1.yaml
├── coredns
│   ├── coredns.yaml.sed
│   ├── deploy.sh
│   └── kubernetes1.13.1\351\233\206\347\276\244\351\203\250\347\275\262coredns.md
├── dashboard
│   ├── dashboard-adminuser-k8sv1.13.yaml
│   ├── dashboard-admin.yaml
│   ├── kubernetes-dashboard-k8sv1.13.yaml
│   ├── namespace-dashboard.yaml
│   └── recommended.yaml
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
│   ├── tls.crt
│   ├── tls.key
│   └── tomcat-demo.yaml
├── liveness-exec.yaml
├── liveness-http.yaml
├── master
│   ├── aggregated-metrics-reader.yaml
│   ├── auth-delegator.yaml
│   ├── auth-reader.yaml
│   ├── metrics-apiservice.yaml
│   ├── metrics-server-deployment.yaml
│   ├── metrics-server-service.yaml
│   └── resource-reader.yaml
├── metrics-server
│   ├── aggregated-metrics-reader.yaml
│   ├── auth-delegator.yaml
│   ├── auth-reader.yaml
│   ├── metrics-apiservice.yaml
│   ├── metrics-server-deployment.yaml
│   ├── metrics-server-service.yaml
│   ├── pod-demo.yaml
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
└── \344\272\214\350\277\233\345\210\266\346\220\255\345\273\272
    ├── 10--\351\203\250\347\275\262coredns.txt
    ├── 1--kube-etcd.txt
    ├── 2--kube-apiserver.txt
    ├── 3--kube-controller-manager.txt
    ├── 4--kube-scheduler.txt
    ├── 5--\350\256\244\350\257\201\345\222\214\346\216\210\346\235\203.txt
    ├── 6--flannel.txt
    ├── 7--kubelet.txt
    ├── 8--kube-proxy.txt
    ├── 9--\346\267\273\345\212\240\351\233\206\347\276\244\350\212\202\347\202\271.txt
    ├── create-ca.sh
    └── dashboard.txt

14 directories, 93 files
```
