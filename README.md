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
├── deploy-myapp.yaml
├── ingress
│   ├── deploy-demo.yaml
│   ├── ingress-myapp.yaml
│   ├── ingress-tomcat-tls.yaml
│   ├── ingress-tomcat.yaml
│   ├── tls.crt
│   ├── tls.key
│   └── tomcat-demo.yaml
├── kubernetes-dashboard.yaml
├── liveness-exec.yaml
├── liveness-http.yaml
├── myapp-svc-headless.yaml
├── myapp-svc.yaml
├── pod-demo.yaml
├── poststart-pod.yaml
├── readiness-httpget.yaml
├── README.md
├── redis-ds-demo-svc.yaml
├── redis-ds-demo.yaml
├── rs-myapp-svc.yaml
├── rs-myapp.yaml
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

5 directories, 39 files
```
