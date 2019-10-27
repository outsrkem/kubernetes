# kubernetes

#### 介绍
kubernetes 资源清单文件

#### git创建ssh通道，避免每次都输密码

https://blog.csdn.net/lvdepeng123/article/details/79215882

```
.
├── deploy-myapp.yaml
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
├── upDataGit.sh
└── volumes
    ├── deploy-vol-pvc.yaml
    ├── pod-vol-demo.yaml
    ├── pod-vol-hostpath.yaml
    ├── pod-vol-html-demo.yaml
    ├── pod-vol-nfs.yaml
    ├── pod-vol-pvc.yaml
    ├── pv-demo.yaml
    └── README.md

2 directories, 29 files
```
