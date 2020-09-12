## 1.19.1部署flannel

#### 以下镜像拉取一套即可

##### 拉取镜像：

```
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-amd64
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-arm64
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-arm
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-ppc64le
docker pull registry.cn-shanghai.aliyuncs.com/leozhanggg/flannel:v0.12.0-s390x
```

##### 拉取镜像：

建议拉取这个，下面的补丁是基于这个做的。

```
docker pull registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-amd64
docker pull registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-arm64
docker pull registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-arm
docker pull registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-ppc64le
docker pull registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-s390x
```

对下载的kube-flannel.yml打补丁，修改镜像为刚拉取得镜像。

```
patch -p0 < kube-flannel.patch
```

#### 查看新yaml需要的镜像

```shell
cat kube-flannel.yml |grep image |uniq

# 结果如下
[root@localhost ~]# cat kube-flannel.yml |grep image
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-amd64
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-amd64
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-arm64
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-arm64
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-arm
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-arm
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-ppc64le
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-ppc64le
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-s390x
        image: registry.cn-shanghai.aliyuncs.com/outsrkem/flannel:v0.12.0-s390x

```

#### 加载flannel

```
kubectl apply -f kube-flannel.yml
```

#### 查看是否启动成功

```
kubectl get ds --all-namespaces
```


