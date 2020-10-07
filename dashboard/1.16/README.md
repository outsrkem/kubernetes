## Dashboard V2.0(beta5)

### Kubernetes V1.16.2部署

dashboard 为 Kubernetes 的 Web 用户界面，用户可以通过 Dashboard 在 Kubernetes 集群中部署容器化的应用，对应用进行问题处理和管理，并对集群本身进行管理。通过 Dashboard，用户可以查看集群中应用的运行情况，同时也能够基于ashboard 创建或修改部署、任务、服务等 Kubernetes 的资源。通过部署向导，用户能够对部署进行扩缩容，进行滚动更新、重启 Pod 和部署新应用。

项目地址：https://github.com/kubernetes/dashboard/tree/v2.0.0-beta5/aio/deploy

我已经下载好该文件了，稍后下载使用即可。

### 1. 创建名称空间

```shell
kubectl create namespace kubernetes-dashboard
```

### 2. 创建名称空间管理员

```shell
kubectl apply -f https://gitee.com/Outsrkem/kubernetes/raw/master/dashboard/1.16/dashboard-admin.yaml
```

### 3 .创建自签证书

```shell
openssl req -newkey rsa:2048 -nodes -sha256 -keyout ./dashboard.key -x509 -out ./dashboard.crt \
-subj "/CN=dashboard-cert" -days 3650
```

### 4. 创建dashboard-certs资源

```shell
kubectl -n kubernetes-dashboard create secret generic kubernetes-dashboard-certs \
--from-file=dashboard.key \
--from-file=dashboard.crt
```

### 5. 下载Dashboard 清单文件并创建应用

```shell
wget https://gitee.com/Outsrkem/kubernetes/raw/master/dashboard/1.16/recommended.yaml
wget https://gitee.com/Outsrkem/kubernetes/raw/master/dashboard/1.16/recommended.patch
# 打入补丁（补丁注释了原有的ssl证书，添加了NodePort端口:30008）：
patch -p0 < recommended.patch
kubectl apply -f recommended.yaml
```

### 6.获取token

```shell
kubectl -n kubernetes-dashboard describe secret \
$(kubectl -n kubernetes-dashboard get secret | grep dashboard-admin | awk '{print $1}')
```

### 7.浏览器访问 

```shell
https://节点ip:30008
```

![](https://images.cnblogs.com/cnblogs_com/outsrkem/1571911/o_201007005302Snipaste_2020-10-07_08-52-37.png)

![](https://images.cnblogs.com/cnblogs_com/outsrkem/1571911/o_201007005519Snipaste_2020-10-07_08-54-44.png)

### 使用 kubeconfig  文件 认证登录

```shell
export KUBE_APISERVER="https://10.10.10.31:6443"
export KUBE_CA_ROOT="/etc/kubernetes/pki/ca.crt"
export KUBE_CONFIG_PATH_DIR="./dashborad-admin.conf"
export DASHBOARD_SECRETS_NAME=$(kubectl -n kubernetes-dashboard get secret | awk '/^dashboard-admin-token/{print $1}')
export DASHBOARD_ADMIN_TOKEN=$(kubectl -n kubernetes-dashboard get secrets $DASHBOARD_SECRETS_NAME -o jsonpath={.data.token}|base64 -d)

kubectl config set-cluster kubernetes \
--certificate-authority=${KUBE_CA_ROOT} \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${KUBE_CONFIG_PATH_DIR}

kubectl -n kubernetes-dashboard describe secret \
$(kubectl -n kubernetes-dashboard get secret | grep dashboard-admin | awk '{print $1}')

kubectl config set-credentials dashboard-admin \
--token=${DASHBOARD_ADMIN_TOKEN} \
--kubeconfig=${KUBE_CONFIG_PATH_DIR}

kubectl config set-context dashboard-admin@kubernetes \
--cluster=kubernetes \
--user=dashboard-admin \
--kubeconfig=${KUBE_CONFIG_PATH_DIR}

kubectl config use-context dashboard-admin@kubernetes \
--kubeconfig=${KUBE_CONFIG_PATH_DIR}

kubectl config view --kubeconfig=${KUBE_CONFIG_PATH_DIR}
# 将./dashborad-admin.conf 文件复制到桌面，浏览器使用该文件即可通过认证登录
```


