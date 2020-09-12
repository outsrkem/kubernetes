# kubernetes 1.19 安装metrics-server

### 下载清单文件

```
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/aggregated-metrics-reader.yaml
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/auth-delegator.patch
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/auth-delegator.yaml
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/auth-reader.patch
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/auth-reader.yaml
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/metrics-apiservice.patch
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/metrics-apiservice.yaml
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/metrics-server-deployment.patch
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/metrics-server-deployment.yaml
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/metrics-server-service.yaml
wget https://gitee.com/Outsrkem/kubernetes/raw/master/metrics-server/1.8+/resource-reader.yaml
```

### 打补丁

```
patch -p0 < auth-delegator.patch
patch -p0 < auth-reader.patch
patch -p0 < metrics-apiservice.patch
patch -p0 < metrics-server-deployment.patch
```

### 启动应用

```
kubectl apply -f ./
```

```
kubectl get deploy,svc,pods -n kube-system  | grep metrics
deployment.apps/metrics-server   1/1     1            1           28m
service/metrics-server   ClusterIP   10.96.179.233   <none>        443/TCP                  28m
pod/metrics-server-7795b48bbd-9rgrw      1/1     Running   0          28m
```

### 使用

```
kubectl proxy --port=8080
curl http://localhost:8080/apis/metrics.k8s.io/v1beta1/nodes
kubectl top node
```




