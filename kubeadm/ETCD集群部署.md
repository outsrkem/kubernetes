## ETCD集群部署

### 准备etcd二进制文件

```shell
tar xf etcd-v3.3.10-linux-amd64.tar.gz
mv etcd-v3.3.10-linux-amd64/etcd* /opt/kubernetes/bin/
```

### 创建etcd所需证书文件

#### 1、创建 etcd 证书的etcd-csr.json文件

```shell
cat > etcd-csr.json <<EOF
{
    "CN": "etcd",
    "hosts": [
        "127.0.0.1",
        "10.10.10.31",
        "10.10.10.32",
        "10.10.10.33",
        "etcd1.k8s.org",
        "etcd2.k8s.org",
        "etcd3.k8s.org"
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

#### 2、生成证书和私钥

```shell
cfssl gencert -ca=ca.pem \
              -ca-key=ca-key.pem \
              -config=ca-config.json \
              -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
```

#### 3、分发证书

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
--client-cert-auth=True \
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
--client-cert-auth=True \
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
--client-cert-auth=True \
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

### CTCD集群信息查看

**由于是https，所以查看操作集群需要使用证书。**

> etcdctl 默认使用的是api v2版本

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
--ca-file=/opt/kubernetes/ssl/ca.pem -cert-file=/opt/kubernetes/ssl/etcd.pem \
--key-file=/opt/kubernetes/ssl/etcd-key.pem"
etcdctl cluster-health
etcdctl member list
```

> etcdctl 的api v3版本使用

```shell
# 使用环境变量定义api版本
export ETCDCTL_API=3

# 申明etcd相关信息，etcdctl 默认连接的是http://127.0.0.1:2379，因无证书也能访问，建议关闭回环网卡监听。
export ETCDCTL_FILE=/opt/kubernetes/bin/etcdctl
export ETCD_ENDPOINTS=https://10.10.10.31:2379,https://10.10.10.32:2379,https://10.10.10.33:2379
export ETCD_CA_FILE=/opt/kubernetes/ssl/ca.pem
export ETCD_cert_FILE=/opt/kubernetes/ssl/etcd.pem
export ETCD_key_FILE=/opt/kubernetes/ssl/etcd-key.pem

# 配置etcdctl别名
alias etcdctl="$ETCDCTL_FILE --endpoints=$ETCD_ENDPOINTS --cacert=$ETCD_CA_FILE --cert=$ETCD_cert_FILE --key=$ETCD_key_FILE"

# 列出集群成员
etcdctl member list
etcdctl member list -w table

#----示例
[root@k8s-master ~]# etcdctl member list
a01381d0afc19e9, started, etcd1, https://10.10.10.31:2380, https://10.10.10.31:2379
53807b9bddd14168, started, etcd2, https://10.10.10.32:2380, https://10.10.10.32:2379
7b8d79f533deb5ed, started, etcd3, https://10.10.10.33:2380, https://10.10.10.33:2379
[root@k8s-master ~]# etcdctl member list -w table
+------------------+---------+-------+--------------------------+--------------------------+
|        ID        | STATUS  | NAME  |        PEER ADDRS        |       CLIENT ADDRS       |
+------------------+---------+-------+--------------------------+--------------------------+
|  a01381d0afc19e9 | started | etcd1 | https://10.10.10.31:2380 | https://10.10.10.31:2379 |
| 53807b9bddd14168 | started | etcd2 | https://10.10.10.32:2380 | https://10.10.10.32:2379 |
| 7b8d79f533deb5ed | started | etcd3 | https://10.10.10.33:2380 | https://10.10.10.33:2379 |
+------------------+---------+-------+--------------------------+--------------------------+

# 集群状态,集群状态主要是etcdctl endpoint status 和etcdctl endpoint health两条命令。
etcdctl endpoint health
etcdctl endpoint status --write-out=table 或etcdctl endpoint status -w table

#----示例
[root@k8s-master ~]# etcdctl endpoint status -w table
+--------------------------+------------------+---------+---------+--------
|         ENDPOINT         |        ID        | VERSION | DB SIZE |   .....
+--------------------------+------------------+---------+---------+--------
| https://10.10.10.31:2379 |  a01381d0afc19e9 |  3.3.10 |  3.8 MB |   .....
| https://10.10.10.32:2379 | 53807b9bddd14168 |  3.3.10 |  3.8 MB |   .....
| https://10.10.10.33:2379 | 7b8d79f533deb5ed |  3.3.10 |  3.8 MB |   .....
+--------------------------+------------------+---------+---------+--------
```