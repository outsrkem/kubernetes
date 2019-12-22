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
├── dashboard
│   ├── dashboard-admin.yaml
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
├── qweqweqwe.yml
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
├── stateful
│   ├── pv-demo.yaml
│   └── stateful-demo.yaml
├── upDataGit.sh
└── volumes
    ├── deploy-vol-pvc.yaml
    ├── pod-vol-demo.yaml
    ├── pod-vol-hostpath.yaml
    ├── pod-vol-html-demo.yaml
    ├── pod-vol-nfs.yaml
    ├── pod-vol-pvc.yaml
    └── pv-demo.yaml

11 directories, 76 files
```
