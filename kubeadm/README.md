## 一、系统初始化操作

系统初始化操作是集群每个节点都要操作的步骤。

### 群集环境

| IP          | 主机名     | 说明        |
| ----------- | ---------- | ----------- |
| 10.10.10.31 | k8s-master | master 节点 |
| 10.10.10.32 | k8s-node1  | node 节点   |
| 10.10.10.33 | k8s-node2  | node 节点   |

### 关闭相关防护及swap

```
# 关闭防火墙和 selinux
systemctl stop firewalld && systemctl disable firewalld
sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config && setenforce 0

# 关闭 swap (k8s默认不使用 swap，可以指定参数使用 swap)
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab
```
### 配置时间同步
centos7 默认已启用 chrony  服务，执行 chronyc sources 命令，查看存在以*开头的行，说明已经与NTP服务器时间同步.

配置时间源。

`vim /etc/chrony.conf`
```
server cn.pool.ntp.org iburst
server ntp.aliyun.com iburst 
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
server ntp3.aliyun.com iburst
server ntp4.aliyun.com iburst
server ntp5.aliyun.com iburst
server ntp6.aliyun.com iburst
```

重启服务

```
systemctl restart chronyd.service
systemctl enable chronyd.service
chronyc sources
# 出现如下“^*” 开头的行，说明已经同步成功。
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* 193.182.111.142               2   6   357    30   -142ms[ -218ms] +/-  151ms
```

### 基本配置

```
# 修改 /etc/hosts 文件
cat << EOF >> /etc/hosts
10.10.10.31 k8s-master k8s-master.k8s.com
10.10.10.32 k8s-node1 k8s-node1.k8s.com
10.10.10.33 k8s-node2 k8s-node2.k8s.com
EOF

# 修改主机名
master节点:
hostnamectl set-hostname k8s-master

node1节点：
hostnamectl set-hostname k8s-node1

node2节点:
hostnamectl set-hostname k8s-node2
```

### 修改 iptables 相关参数
CentOS 7 上的一些用户报告了由于iptables被绕过而导致流量路由不正确的问题。创建/etc/sysctl.d/k8s.conf文件，添加如下内容：

```
cat << EOF >  /etc/sysctl.d/k8s.conf
vm.swappiness = 0
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# 使配置生效
modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf
```
### 加载 ipvs 相关模块
由于ipvs已经加入到了内核的主干，所以为 kube-proxy 开启ipvs的前提需要加载以下的内核模块：
在所有的Kubernetes节点执行以下脚本:

```
cat << EOF > /etc/sysconfig/modules/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

# 执行脚本
chmod 755 /etc/sysconfig/modules/ipvs.modules \
&& bash /etc/sysconfig/modules/ipvs.modules \
&& lsmod | grep -e ip_vs -e nf_conntrack_ipv4
```

上面脚本创建了/etc/sysconfig/modules/ipvs.modules文件，保证在节点重启后能自动加载所需模块。 使用`lsmod | grep -e ip_vs -e nf_conntrack_ipv4 `  命令查看是否已经正确加载所需的内核模块。

接下来还需要确保各个节点上已经安装了ipset软件包。 为了便于查看ipvs的代理规则，最好安装一下管理工具ipvsadm。

```
yum install ipset ipvsadm -y
```

### 安装Docker

```
# 安装要求的软件包
yum install yum-utils device-mapper-persistent-data lvm2 -y 

# 添加Docker repository，这里改为国内阿里云repo
yum-config-manager --add-repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装docker
# 查询docker版本  yum list docker-ce --showduplicates|sort -r
# 安装指定版本
yum install docker-ce-18.09.8 -y  

# 创建daemon.json配置文件
# 注意，这里这指定了cgroupdriver=systemd，另外由于国内拉取镜像较慢，最后追加了阿里云镜像加速配置。
mkdir /etc/docker
cat << EOF > /etc/docker/daemon.json 
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "registry-mirrors": ["https://uyah70su.mirror.aliyuncs.com"]
}
EOF

# mkdir -p /etc/systemd/system/docker.service.d

# 重启docker服务
systemctl daemon-reload && systemctl restart docker && systemctl enable docker
```
### 安装kubeadm、kubelet、kubectl
官方安装文档可以参考：https://kubernetes.io/docs/setup/independent/install-kubeadm/

- kubelet 在群集中所有节点上运行的核心组件, 用来执行如启动pods和containers等操作。
- kubeadm 引导启动k8s集群的命令行工具，用于初始化 Cluster。
- kubectl 是 Kubernetes 命令行工具。通过 kubectl 可以部署和管理应用，查看各种资源，创建、删除和更新各种组件。

```
# 配置kubernetes.repo的源，由于官方源国内无法访问，这里使用阿里云yum源

cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 查询版本安装指定版本
# yum list --showduplicates kubeadm --disableexcludes=kubernetes

# 在所有节点上安装kubelet、kubeadm 和 kubectl
yum install -y kubelet-1.16.2 kubeadm-1.16.2 kubectl-1.16.2

# 启动kubelet服务
systemctl enable kubelet && systemctl start kubelet
```

## 二、正式部署kubernetes

以下操作是分节点操作步骤。

### 部署master节点

#### 1、生成默认配置文件

```
 kubeadm config print init-defaults > kubeadm.yaml
```

kubeadm-config.yaml组成部署说明：

- InitConfiguration： 用于定义一些初始化配置，如初始化使用的token以及apiserver地址等
- ClusterConfiguration：用于定义apiserver、etcd、network、scheduler、controller-manager等master组件相关配置项
- KubeletConfiguration：用于定义kubelet组件相关的配置项
- KubeProxyConfiguration：用于定义kube-proxy组件相关的配置项\

可以看到，在默认的kubeadm-config.yaml文件中只有InitConfiguration、ClusterConfiguration 两部分。我们可以通过如下操作生成另外两部分的示例文件：

>https://www.cnblogs.com/breezey/p/11770780.html

```shell
# 生成KubeletConfiguration示例文件 
kubeadm config print init-defaults --component-configs KubeletConfiguration

# 生成KubeProxyConfiguration示例文件 
kubeadm config print init-defaults --component-configs KubeProxyConfiguration
```

#### 2、根据实际情况进行修改

```
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.10.10.31    # 修改为API Server的地址
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: k8s-master
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers 	# 修改为阿里云镜像仓库
kind: ClusterConfiguration
kubernetesVersion: v1.16.2          # 当前版本
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12       # 修改Service的网络，这里使用默认ip
  podSubnet: 10.244.0.0/16          # 修改Pod的网络，这个不指定会导致flannel起不来，这里使用默认ip
scheduler: {}
# 下面增加的配置，用于设置Kube-proxy使用LVS
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: "rr"
  strictARP: false
  syncPeriod: 30s
```

>#### 上面使用的是默认etcd，如果使用外部etcd，参照下面配置
>
![输入图片说明](https://images.gitee.com/uploads/images/2020/1107/172830_82423249_5330846.png "屏幕截图.png")
>
>#### 相关etcd操作
>
>操作etcd有命令行工具etcdctl，有两个api版本互不兼容的，系统默认的v2版本，kubernetes集群使用的是v3版本，v2版本下是看不到v3版本的数据的。
>
>```shell
># 使用环境变量定义api版本
>export ETCDCTL_API=3
>
># 申明etcd相关信息，etcdctl 默认连接的是http://127.0.0.1:2379，因无证书也能访问，建议关闭回环网卡监听。
>export ETCDCTL_FILE=/opt/kubernetes/bin/etcdctl
>export ETCD_ENDPOINTS=https://10.10.10.31:2379,https://10.10.10.32:2379,https://10.10.10.33:2379
>export ETCD_CA_FILE=/opt/kubernetes/ssl/ca.pem
>export ETCD_cert_FILE=/opt/kubernetes/ssl/etcd.pem
>export ETCD_key_FILE=/opt/kubernetes/ssl/etcd-key.pem
>
># 配置etcdctl别名
>alias etcdctl="$ETCDCTL_FILE --endpoints=$ETCD_ENDPOINTS --cacert=$ETCD_CA_FILE --cert=$ETCD_cert_FILE --key=$ETCD_key_FILE"
>
># etcd有目录结构类似linux文件系统，获取所有key。
>etcdctl get / --prefix --keys-only
>
># 查询命名空间下所有部署的数据：
>etcdctl get /registry/deployments/default --prefix --keys-only
>
># 删除某个数据
>etcdctl del /registry/daemonsets/kube-system/kube-proxy
>
># 删除所有数据
>etcdctl del / --prefix
>```

#### 3、执行初始化操作

````
kubeadm init --config kubeadm.yaml --dry-run # 模拟操作
kubeadm init --config kubeadm.yaml
````

完整的官方文档可以参考：
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/

### 配置 kubectl

kubectl 是管理 Kubernetes Cluster 的命令行工具， Master 初始化完成后需要做一些配置工作才能使用kubectl，，这里直接配置root用户:
```
export KUBECONFIG=/etc/kubernetes/admin.conf
```
普通用户可以参考 kubeadm init 最后提示

```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```
Kubernetes 集群默认需要加密方式访问，以上操作就是将刚刚部署生成的 Kubernetes 集群的安全配置文件保存到当前用户的.kube 目录下，kubectl  默认会使用这个目录下的授权信息访问 Kubernetes 集群。
如果不这么做的话，我们每次都需要通过 export KUBECONFIG 环境变量告诉 kubectl 这个安全配置文件的位置。


```
# 启用 kubectl 命令自动补全功能(注销重新登录生效)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```
查看集群状态：
```
[centos@k8s-master ~]# kubectl get componentstatuses  (简写  kubectl get cs)
NAME                 AGE
scheduler            <unknown>
controller-manager   <unknown>
etcd-0               <unknown> 
```
最新版本的kubernetes在执行kubectl get cs时输出内容有一些变化，以前是这样的：

```
# kubectl get componentstatuses
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health":"true"}
```

现在变成了：

> 原因可参考  https://segmentfault.com/a/1190000020912684 

```
# kubectl get componentstatuses
NAME                 Age    
controller-manager   <unknown>
scheduler            <unknown>
etcd-0               <unknown>
# 使用如下命令可以输出正常信息
kubectl get cs -o=go-template='{{printf "|NAME|STATUS|MESSAGE|\n"}}{{range .items}}{{$name:= .metadata.name}}{{range .conditions}}{{printf "|%s|%s|%s|\n" $name .status .message}}{{end}}{{end}}'
```

确认各个组件都处于healthy状态。查看节点状态

```
[centos@k8s-master ~]# kubectl get nodes 
NAME         STATUS     ROLES    AGE   VERSION
k8s-master   NotReady   master   36m   v1.16.0
[centos@k8s-master ~]# 
```

可以看到，当前只存在1个master节点，并且这个节点的状态是 NotReady。
使用 kubectl describe 命令来查看这个节点（Node）对象的详细信息、状态和事件（Event）：

```
[centos@k8s-master ~]# kubectl describe node k8s-master 
......
Events:
  Type    Reason                   Age               
----    ------                   ----               - ......
  Normal  Starting                 33m               
  Normal  NodeHasSufficientMemory  33m (x8 over 33m) 
  Normal  NodeHasNoDiskPressure    33m (x8 over 33m) 
  Normal  NodeHasSufficientPID     33m (x7 over 33m) 
  Normal  NodeAllocatableEnforced  33m               
  Normal  Starting                 33m               
```

通过 kubectl describe 指令的输出，我们可以看到 NodeNotReady 的原因在于，我们尚未部署任何网络插件，kube-proxy等组件还处于starting状态。
另外，我们还可以通过 kubectl 检查这个节点上各个系统 Pod 的状态，其中，kube-system 是 Kubernetes 项目预留的系统 Pod 的工作空间（Namepsace，注意它并不是 Linux Namespace，它只是 Kubernetes 划分不同工作空间的单位）：

```
[centos@k8s-master ~]# kubectl -n kube-system get pod -o wide    
NAME                                 READY   STATUS    RESTARTS  ......
coredns-78d4cf999f-7jdx7             0/1     Pending   0
coredns-78d4cf999f-s6mhk             0/1     Pending   0
etcd-k8s-master                      1/1     Running   0
kube-apiserver-k8s-master            1/1     Running   0
kube-controller-manager-k8s-master   1/1     Running   0
kube-proxy-przwf                     1/1     Running   0
kube-scheduler-k8s-master            1/1     Running   0
```
可以看到，CoreDNS依赖于网络的 Pod 都处于 Pending 状态，即调度失败。这当然是符合预期的：因为这个 Master 节点的网络尚未就绪。
集群初始化如果遇到问题，可以使用kubeadm reset命令进行清理然后重新执行初始化。

### 部署网络插件

要让 Kubernetes Cluster 能够工作，必须安装 Pod 网络，否则 Pod 之间无法通信。
Kubernetes 支持多种网络方案，这里我们使用 flannel

执行如下命令部署 flannel：

```
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 使用如下清单文件创建
https://gitee.com/Outsrkem/flannel/tree/master/1.16.2
```

部署完成后，我们可以通过 kubectl get 重新检查 Pod 的状态：
```
[centos@k8s-master ~]# kubectl get pod -n kube-system -o wide
NAME                                 READY   STATUS   ......
coredns-78d4cf999f-7jdx7             1/1     Running
coredns-78d4cf999f-s6mhk             1/1     Running
etcd-k8s-master                      1/1     Running
kube-apiserver-k8s-master            1/1     Running
kube-controller-manager-k8s-master   1/1     Running
kube-flannel-ds-amd64-lkf2f          1/1     Running
kube-proxy-przwf                     1/1     Running
kube-scheduler-k8s-master            1/1     Running
```

可以看到，所有的系统 Pod 都成功启动了，而刚刚部署的flannel网络插件则在 kube-system 下面新建了一个名叫kube-flannel-ds-amd64-lkf2f的 Pod，一般来说，这些 Pod 就是容器网络插件在每个节点上的控制组件。
Kubernetes 支持容器网络插件，使用的是一个名叫 CNI 的通用接口，它也是当前容器网络的事实标准，市面上的所有容器网络开源项目都可以通过 CNI 接入 Kubernetes，比如 Flannel、Calico、Canal、Romana 等等，它们的部署方式也都是类似的“一键部署”。

至此，Kubernetes 的 Master 节点就部署完成了。如果只需要一个单节点的 Kubernetes，现在你就可以使用了。不过，在默认情况下，Kubernetes 的 Master 节点有污点 (taint) 存在是不能运行用户 Pod 的。可以通过以下步骤删除污点。而**NoSchedule**这个污点仅影响调度过程，对现存 Pod 无影响。

Ⅰ、查看污点（Taints）

```shell
kubectl describe node k8s-master |grep Taints
Taints:             node-role.kubernetes.io/master:NoSchedule
```

Ⅱ、删除这个污点

```shell
kubectl taint nodes k8s-master node-role.kubernetes.io/master=:NoSchedule-
```

Ⅲ、添加这样的污点

```shell
kubectl taint nodes k8s-master node-role.kubernetes.io/master=:NoSchedule
```

### 部署node节点

Kubernetes 的工作节点与Master节点几乎是相同的，它们运行着的都是一个 kubelet 组件。唯一的区别在于，在 kubeadm init 的过程中，kubelet 启动后，Master 节点上还会自动运行 kube-apiserver、kube-scheduler、kube-controller-manger 这三个系统 Pod。
在 k8s-node1 和 k8s-node2 上分别执行如下命令，将其注册到集群中：

```
# 执行以下命令将节点接入集群
kubeadm join 10.10.10.31:6443 --token 67kq55.8hxoga556caxty7s \
    --discovery-token-ca-cert-hash ha256:7d50e704bbfe69661e37c5f3ad13b1b88032b6b2b703ebd4899e259477b5be69

# 如果执行kubeadm init时没有记录下加入集群的命令，可以通过以下命令重新创建
kubeadm token create --print-join-command
```

在k8s-node1上执行kubeadm join ：
```
[root@k8s-node1 ~]# kubeadm join 10.10.10.31:6443 --token 67kq55.8hxoga556caxty7s \
    --discovery-token-ca-cert-hash sha256:7d50e704bbfe69661e37c5f3ad13b1b88032b6b2b703ebd4899e259477b5be69
[preflight] Running pre-flight checks
......
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the master to see this node join the cluster.
```
重复执行以上操作将k8s-node2也加进去。

修改节点标签

```shell
kubectl label nodes k8s-node1 node-role.kubernetes.io/node=
kubectl label nodes k8s-node2 node-role.kubernetes.io/node=
```

然后根据提示，我们可以通过 kubectl get nodes 查看节点的状态：

```
[centos@k8s-master ~]# kubectl get nodes
NAME         STATUS   ROLES    AGE    VERSION
k8s-master   Ready    master   45m   v1.16.2
k8s-node1    Ready    node     45m   v1.16.2
k8s-node2    Ready    node     45m   v1.16.2
```
nodes状态全部为ready，由于每个节点都需要启动若干组件，如果node节点的状态是 NotReady，可以查看所有节点pod状态，确保所有pod成功拉取到镜像并处于running状态：

```
[centos@k8s-master ~]# kubectl get pod --all-namespaces -o wide
NAMESPACE     NAME                                 READY   STATUS    ......
kube-system   coredns-78d4cf999f-7jdx7             1/1     Running
kube-system   coredns-78d4cf999f-s6mhk             1/1     Running
kube-system   etcd-k8s-master                      1/1     Running
kube-system   kube-apiserver-k8s-master            1/1     Running
kube-system   kube-controller-manager-k8s-master   1/1     Running
kube-system   kube-flannel-ds-amd64-d2r8p          1/1     Running
kube-system   kube-flannel-ds-amd64-d85c6          1/1     Running
kube-system   kube-flannel-ds-amd64-lkf2f          1/1     Running
kube-system   kube-proxy-k8jx8                     1/1     Running
kube-system   kube-proxy-n95ck                     1/1     Running
kube-system   kube-proxy-przwf                     1/1     Running
kube-system   kube-scheduler-k8s-master            1/1     Running
```



测试集群各个组件
首先验证kube-apiserver, kube-controller-manager, kube-scheduler, pod network 是否正常：
部署一个 Nginx Deployment，包含2个Pod 副本
参考：https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

```
[centos@k8s-master ~]# kubectl create deployment nginx --image=nginx:alpine
deployment.apps/nginx created
[centos@k8s-master ~]$ kubectl scale deployment nginx --replicas=2
deployment.extensions/nginx scaled
[centos@k8s-master ~]#
```

验证Nginx Pod是否正确运行，并且会分配10.244.开头的集群IP

```
[centos@k8s-master ~]# kubectl get pods -l app=nginx -o wide
NAME                     READY   STATUS    RESTARTS   AGE  ......
nginx-54458cd494-p2qgx   1/1     Running   0          111s
nginx-54458cd494-sdlm7   1/1     Running   0          103s
```
再验证一下kube-proxy是否正常：

以 NodePort 方式对外提供服务（也是外部流量引入集群内部的方法）
参考：https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/

```
[centos@k8s-master ~]# kubectl expose deployment nginx --port=80 --type=NodePort
service/nginx exposed
[centos@k8s-master ~]$ kubectl get services nginx
NAME    TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.108.17.2   <none>        80:30670/TCP   12s
```
可以通过任意 NodeIP:Port 在集群外部访问这个服务：

```
[centos@k8s-master ~]# curl 10.10.10.31:30670
[centos@k8s-master ~]# curl 10.10.10.32:30670
[centos@k8s-master ~]# curl 10.10.10.33:30670
```



### kube-proxy开启ipvs

修改ConfigMap的kube-system/kube-proxy中的config.conf，mode: “ipvs”。

如果此前已经开启则无需操作，使用 `curl localhost:10249/proxyMode`命令可查看，如果要更换为iptables ，则在ConfigMap中修改：mode: "" 为空即可。

```
[centos@k8s-master ~]# kubectl edit cm kube-proxy -n kube-system
```

之后重启各个节点上的kube-proxy pod：

```
[centos@k8s-master ~]# kubectl get pod -n kube-system | grep kube-proxy | awk '{system("kubectl delete pod "$1" -n kube-system")}'
pod "kube-proxy-2w9sh" deleted
pod "kube-proxy-gw4lx" deleted
pod "kube-proxy-thv4c" deleted
[centos@k8s-master ~]# kubectl get pod -n kube-system | grep kube-proxy
kube-proxy-6qlgv                        1/1     Running   0          65s
kube-proxy-fdtjd                        1/1     Running   0          47s
kube-proxy-m8zkx                        1/1     Running   0          52s
```
查看日志：

```
[centos@k8s-master ~]# kubectl -n kube-system  logs kube-proxy-dpx74
I1213 09:50:15.414493       1 server_others.go:189] Using ipvs Proxier.
W1213 09:50:15.414908       1 proxier.go:365] IPVS scheduler not specified, use rr by default
I1213 09:50:15.415021       1 server_others.go:216] Tearing down inactive rules.
I1213 09:50:15.461658       1 server.go:464] Version: v1.13.0
I1213 09:50:15.467827       1 conntrack.go:52] Setting nf_conntrack_max to 131072
I1213 09:50:15.467997       1 config.go:202] Starting service config controller
I1213 09:50:15.468010       1 controller_utils.go:1027] Waiting for caches to sync for service config 
......
# 或者使用命令，返回ipvs也说明启用ipvs
curl localhost:10249/proxyMode
```
日志中打印出了 Using ipvs Proxier，说明 ipvs 模式已经开启。

移除节点和集群
kubernetes集群移除节点
以移除k8s-node2节点为例，在Master节点上运行：

```
kubectl drain k8s-node2 --delete-local-data --force --ignore-daemonsets
kubectl delete node k8s-node2
```

上面两条命令执行完成后，在k8s-node2节点执行清理命令，重置kubeadm的安装状态：
kubeadm reset
在master上删除node并不会清理k8s-node2运行的容器，需要在删除节点上面手动运行清理命令。
如果你想重新配置集群，使用新的参数重新运行kubeadm init或者kubeadm join即可。

至此3个节点的集群搭建完成，后续可以继续添加node节点，或者部署dashboard、helm包管理工具、EFK日志系统、Prometheus Operator监控系统、rook+ceph存储系统等组件。



参考：

https://blog.csdn.net/wc1695040842/article/details/105841329

