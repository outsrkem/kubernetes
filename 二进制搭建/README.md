# 部署前准备

## 1、帮助文档
```
https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG‐1.13.md#downloads‐for‐v1131
https://kubernetes.io/docs/home/?path=users&persona=app‐developer&level=foundational
https://github.com/etcd‐io/etcd
https://shengbao.org/348.html
https://github.com/coreos/flannel
http://www.cnblogs.com/blogscc/p/10105134.html
https://blog.csdn.net/xiegh2014/article/details/84830880
https://blog.csdn.net/tiger435/article/details/85002337
https://www.cnblogs.com/wjoyxt/p/9968491.html
https://blog.csdn.net/zhaihaifei/article/details/79098564
http://blog.51cto.com/jerrymin/1898243
http://www.cnblogs.com/xuxinkun/p/5696031.html
```

## 2、 组件介绍

| 组件 |      |      |
| ---- | ---- | ---- |
|      |      |      |
|      |      |      |
|      |      |      |

# 一 、环境

| 节点   | ip          | 主机名                       |
| ------ | ----------- | ---------------------------- |
| master | 10.10.10.21 | master master.kubernetes.com |
| node01 | 10.10.10.22 | node01 node01.kubernetes.com |
| node02 | 10.10.10.23 | node01 node01.kubernetes.com |

## 1. 基本环境操作

### 创建相关目录

```shell
mkdir -pv /opt/kubernetes/{cfg,data/etcd,bin,data,ssl,logs}
# 创建如下目录结构
├── bin
├── cfg
├── data
│   └── etcd
├── logs
└── ssl
echo 'export PATH=$PATH:/opt/kubernetes/bin' >> /etc/profile && . /etc/profile
```

### 内核优化

```shell
cat <<EOF > /etc/sysctl.d/k8s.conf
# https://github.com/moby/moby/issues/31208 
# ipvsadm -l --timout
# 修复ipvs模式下长连接timeout问题 小于900即可
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.ip_forward = 1
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.netfilter.nf_conntrack_max = 2310720
fs.inotify.max_user_watches=89100
fs.may_detach_mounts = 1
fs.file-max = 52706963
fs.nr_open = 52706963
net.bridge.bridge-nf-call-arptables = 1
vm.swappiness = 0
vm.overcommit_memory=1
vm.panic_on_oom=0
EOF

sysctl --system
```

```shell
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab
sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config
```



## 3. CA证书签发

### 安装cfssl

```shell
if ! which cfssl; then
    wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /usr/local/bin/cfssl
fi
if ! which cfssljson; then
    wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O /usr/local/bin/cfssljson
fi
if ! which cfssl-certinfo; then
    wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O /usr/local/bin/cfssl-certinfo
fi
chmod +x /usr/local/bin/cfssl*
```

### 集群证书说明

- kubernetes 系统的各组件需要使用 TLS 证书对通信进行加密
- 本文档使用 CloudFlare 的 PKI 工具集 cfssl 来生成 Certificate Authority (CA) 和其它证书；
- 生成的 CA 证书和秘钥文件如下

###  创建 CA (Certificate Authority)

#### 创建 CA 证书签名请求

创建30年（262800h）CA根证书

```shell
mkdir ~/ssl && cd ~/ssl
cat <<EOF> ca-csr.json 
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "ca": {
        "expiry": "262800h"
    },
    "names": [{}]
}
EOF
```

#### 生成 CA 自签证书和私钥

```shell
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

#### 证书如下

```shell
-rw------- 1 root root 1675 2020-08-15 16:27:19 ca-key.pem  # CA证书的私钥，可用于CA证书续期
-rw-r--r-- 1 root root 1363 2020-08-15 16:27:19 ca.pem		# CA证书
```

#### 分发证书

```shell
cp -a ca*.pem /opt/kubernetes/ssl
alias ha='for I in 10.10.10.{22..23};do'
ha scp ./ca.pem root@$I:/opt/kubernetes/ssl ;done
```

#### 创建如下的kubernetes证书模板文件

后续签发证书都依赖与此文件，配置相关证书年限为10年

```shell
cat <<EOF> ca-config.json 
{
    "signing": {
        "default": {
            "expiry": "8760h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF
```

### 创建其他相关证书

#### ETCD证书

#### apiserver证书

# 二、ETCD部署

**说明：三个etcd节点都要部署**

```shell
tar xf etcd-v3.3.10-linux-amd64.tar.gz
mv etcd-v3.3.10-linux-amd64/etcd* /opt/kubernetes/bin/
```

### 创建etcd所需证书文件

#### 创建 etcd 证书的etcd-csr.json文件

``` shell
cat > etcd-csr.json <<EOF
{
    "CN": "etcd",
    "hosts": [
        "127.0.0.1",
        "10.10.10.31",
        "10.10.10.32",
        "10.10.10.33"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "kubernetes",
            "OU": "System"
        }
    ]
}
EOF
```

#### 生成证书和私钥

```shell
cfssl gencert -ca=ca.pem \
              -ca-key=ca-key.pem \
              -config=ca-config.json \
              -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
```

#### 证书如下

```shell
-rw------- 1 root root 1675 2020-08-15 16:49:04 etcd-key.pem
-rw-r--r-- 1 root root 1436 2020-08-15 16:49:04 etcd.pem
```

#### 分发证书

```shell
cp -a etcd*.pem /opt/kubernetes/ssl
ha scp ./etcd*.pem root@$I:/opt/kubernetes/ssl ;done
```

### 创建etcd配置文件

- **节点一（10.10.10.31）**

```shell
cat << 'EOF' > /opt/kubernetes/cfg/kube-etcd.conf 
KUBE_ETCD_OPTS="--name=etcd1 \
--data-dir=/opt/kubernetes/data/etcd \
--listen-peer-urls=https://10.10.10.31:2380 \
--listen-client-urls=https://10.10.10.31:2379,http://127.0.0.1:2379 \
--initial-advertise-peer-urls=https://10.10.10.31:2380 \
--initial-cluster-token=etcd-cluster \
--advertise-client-urls=https://10.10.10.31:2379 \
--cert-file=/opt/kubernetes/ssl/etcd.pem \
--key-file=/opt/kubernetes/ssl/etcd-key.pem \
--peer-cert-file=/opt/kubernetes/ssl/etcd.pem \
--peer-key-file=/opt/kubernetes/ssl/etcd-key.pem \
--trusted-ca-file=/opt/kubernetes/ssl/ca.pem \
--peer-trusted-ca-file=/opt/kubernetes/ssl/ca.pem \
--initial-cluster etcd1=https://10.10.10.31:2380,etcd2=https://10.10.10.32:2380,etcd3=https://10.10.10.33:2380 \
--initial-cluster-state=new"
EOF
```

- **节点二：(10.10.10.32)**

```shell
cat << 'EOF' > /opt/kubernetes/cfg/kube-etcd.conf
KUBE_ETCD_OPTS="--name=etcd2 \
--data-dir=/opt/kubernetes/data/etcd \
--listen-peer-urls=https://10.10.10.32:2380 \
--listen-client-urls=https://10.10.10.32:2379,http://127.0.0.1:2379 \
--initial-advertise-peer-urls=https://10.10.10.32:2380 \
--initial-cluster-token=etcd-cluster \
--advertise-client-urls=https://10.10.10.32:2379 \
--cert-file=/opt/kubernetes/ssl/etcd.pem \
--key-file=/opt/kubernetes/ssl/etcd-key.pem \
--peer-cert-file=/opt/kubernetes/ssl/etcd.pem \
--peer-key-file=/opt/kubernetes/ssl/etcd-key.pem \
--trusted-ca-file=/opt/kubernetes/ssl/ca.pem \
--peer-trusted-ca-file=/opt/kubernetes/ssl/ca.pem \
--initial-cluster etcd1=https://10.10.10.31:2380,etcd2=https://10.10.10.32:2380,etcd3=https://10.10.10.33:2380 \
--initial-cluster-state=new"
EOF
```

- **节点三：(10.10.10.33)**

```shell
cat << 'EOF' > /opt/kubernetes/cfg/kube-etcd.conf
KUBE_ETCD_OPTS="--name=etcd3 \
--data-dir=/opt/kubernetes/data/etcd \
--listen-peer-urls=https://10.10.10.33:2380 \
--listen-client-urls=https://10.10.10.33:2379,http://127.0.0.1:2379 \
--initial-advertise-peer-urls=https://10.10.10.33:2380 \
--initial-cluster-token=etcd-cluster \
--advertise-client-urls=https://10.10.10.33:2379 \
--cert-file=/opt/kubernetes/ssl/etcd.pem \
--key-file=/opt/kubernetes/ssl/etcd-key.pem \
--peer-cert-file=/opt/kubernetes/ssl/etcd.pem \
--peer-key-file=/opt/kubernetes/ssl/etcd-key.pem \
--trusted-ca-file=/opt/kubernetes/ssl/ca.pem \
--peer-trusted-ca-file=/opt/kubernetes/ssl/ca.pem \
--initial-cluster etcd1=https://10.10.10.31:2380,etcd2=https://10.10.10.32:2380,etcd3=https://10.10.10.33:2380 \
--initial-cluster-state=new"
EOF
```

### 创建systemctl启动脚本

- **三个etcd节点是一样的，三个节点分别创建**

```shell
cat << 'EOF' > /usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos
[Service]
Type=notify
WorkingDirectory=/opt/kubernetes/data/etcd
EnvironmentFile=/opt/kubernetes/cfg/kube-etcd.conf
ExecStart=/opt/kubernetes/bin/etcd $KUBE_ETCD_OPTS
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
```

### 启动etcd集群

- **etcd节点要同时启动，才能启动成功**

```shell
systemctl daemon-reload
systemctl restart etcd 
systemctl status etcd 
systemctl enable etcd 
```

### 集群查看

**由于是https，所以查看操作集群需要使用证书。只需要指定CA证书即可**

- 方法一

```shell
cd /opt/kubernetes/ssl
etcdctl --ca-file=ca.pem --cert-file=etcd.pem --key-file=etcd-key.pem cluster-health
etcdctl --ca-file=ca.pem --cert-file=etcd.pem --key-file=etcd-key.pem member list
```

- 方法二

```shell
alias etcdctl="etcdctl \
--endpoints='https://10.10.10.31:2379,https://10.10.10.32:2379,https://10.10.10.33:2379' \
--ca-file=/opt/kubernetes/ssl/ca.pem"
etcdctl cluster-health
etcdctl member list
```

#### 结果如下

说明etcd集群部署成功。
![输入图片说明](https://images.gitee.com/uploads/images/2020/1111/224729_bc2670d9_5330846.png "etcd-1597484873206269963.png")