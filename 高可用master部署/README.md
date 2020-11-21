# 高可用master

给需要运行的节点打上标签

```shell
kubectl label nodes k8s-master kubernetes.io/halb=apiserver-lb
```

创建配置项

```shell
kubectl create configmap lb-nginx-conf --from-file=lb-nginx.conf=./lb-nginx.conf
```
nginx 主配置文件（基本不用修改）

```shell
#user  nobody;
worker_processes  2;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;

daemon off;
events {
    worker_connections  1024;
}
include ../conf.d/*.conf;
```

按需修改lb-nginx.conf配置即可。


