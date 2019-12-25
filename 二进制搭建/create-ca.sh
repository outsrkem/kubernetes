#!/bin/bash -v
# 2019‎年‎9‎月‎13‎日
# kubernetes 系统的各组件需要使用 TLS 证书对通信进行加密
# 本文档使用 CloudFlare 的 PKI 工具集 cfssl 来生成 Certificate Authority (CA) 和其它证书；
#  生成的 CA 证书和秘钥文件如下：
#       - ca-key.pem
#       - ca.pem
#       - kubernetes-key.pem
#       - kubernetes.pem
#       - kube-proxy.pem
#       - kube-proxy-key.pem
#       - admin.pem
#       - admin-key.pem
#
#
#
# 安装 CFSSL 直接使用二进制源码包安装
if ! which cfssl ; then
    wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /usr/local/bin/cfssl
fi
if ! which cfssljson ; then
    wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O /usr/local/bin/cfssljson
fi
if ! which cfssl-certinfo ; then
    wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O /usr/local/bin/cfssl-certinfo
fi
chmod +x /usr/local/bin/cfssl*

#创建 CA (Certificate Authority)

mkdir -p /opt/kubernetes/{cfg,data,bin,data,ssl}
cd /opt/kubernetes/ssl


# 根据config.json文件的格式创建如下的ca-config.json文件,过期时间设置成了 87600h(十年)
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

#字段说明
#ca-config.json：可以定义多个 profiles，分别指定不同的过期时间、使用场景等参数；后续在签名证书时使用某个 profile；
#signing：表示该证书可用于签名其它证书；生成的 ca.pem 证书中 CA=TRUE；
#server auth：表示client可以用该 CA 对server提供的证书进行验证；
#client auth：表示server可以用该CA对client提供的证书进行验证；


#创建 CA 证书签名请求
#创建 ca-csr.json 文件，内容如下：

cat > ca-csr.json <<EOF
    {
      "CN": "kubernetes",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "ST": "BeiJing",
          "L": "BeiJing",
          "O": "k8s",
          "OU": "System"
        }
      ]
    }
EOF

# "CN"：Common Name，kube-apiserver 从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法；
# "O"：Organization，kube-apiserver 从证书中提取该字段作为请求用户所属的组 (Group)；

# 生成 CA 证书和私钥,此时生成 ca.pem 有效期只有5年，过期时间查看 openssl x509  -noout -text -in ca.pem |grep -A 5 Validity
cfssl gencert -initca ca-csr.json | cfssljson -bare ca


# 创建 kubernetes 证书签名请求文件 kubernetes-csr.json:
cat > kubernetes-csr.json << EOF
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "10.10.10.10",
      "10.10.10.11",
      "10.10.10.12",
      "10.254.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
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
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
# 如果 hosts 字段不为空则需要指定授权使用该证书的 IP 或域名列表，
# 由于该证书后续被 etcd 集群和 kubernetes master 集群使用，
# 所以上面分别指定了 etcd 集群、kubernetes master 集群的主机 IP 和 kubernetes 服务的服务 IP
# 一般是 kube-apiserver 指定的 service-cluster-ip-range 网段的第一个IP，如 10.254.0.1。


#生成 kubernetes 证书和私钥
cfssl gencert -ca=ca.pem \
              -ca-key=ca-key.pem \
              -config=ca-config.json \
              -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes



# 创建 admin 证书签名请求文件 admin-csr.json：
cat > admin-csr.json << EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# 后续 kube-apiserver 使用 RBAC 对客户端(如 kubelet、kube-proxy、Pod)请求进行授权；
# kube-apiserver 预定义了一些 RBAC 使用的 RoleBindings，
# 如 cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该 Role 授予了调用kube-apiserver 的所有 API的权限；
# OU 指定该证书的 Group 为 system:masters，kubelet 使用该证书访问 kube-apiserver 时 ，
# 由于证书被 CA 签名，所以认证通过，同时由于证书用户组为经过预授权的 system:masters，所以被授予访问所有 API 的权限


# 生成 admin 证书和私钥
cfssl gencert -ca=ca.pem \
              -ca-key=ca-key.pem \
              -config=ca-config.json \
              -profile=kubernetes admin-csr.json | cfssljson -bare admin



# 创建 kube-proxy 证书签名请求文件 kube-proxy-csr.json
cat > kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# CN 指定该证书的 User 为 system:kube-proxy；
# kube-apiserver 预定义的 RoleBinding cluster-admin 将User system:kube-proxy 与 Role system:node-proxier 绑定，
# 该 Role 授予了调用 kube-apiserver Proxy 相关 API 的权限.


# 生成 kube-proxy 客户端证书和私钥
cfssl gencert -ca=ca.pem \
              -ca-key=ca-key.pem \
              -config=ca-config.json \
              -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy



# 创建 etcd 证书和私钥
cat > etcd-csr.json <<EOF
{
    "CN": "etcd",
    "hosts": [
        "127.0.0.1",
        "10.10.10.10",
        "10.10.10.11",
        "10.10.10.12"
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
            "O": "k8s",
            "OU": "4Paradigm"
        }
    ]
}
EOF
# hosts 字段指定授权使用该证书的 etcd 节点 IP 或域名列表

# 生成证书和私钥
cfssl gencert -ca=ca.pem \
              -ca-key=ca-key.pem \
              -config=ca-config.json \
              -profile=kubernetes etcd-csr.json | cfssljson -bare etcd

#ls etcd*
#etcd.csr  etcd-csr.json  etcd-key.pem  etcd.pem






