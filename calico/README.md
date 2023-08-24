#### 安装指导

[为本地部署安装 Calico 网络和网络策略 (tigera.io)](https://docs.tigera.io/archive/v3.18/getting-started/kubernetes/self-managed-onprem/onpremises)

> calico v3.18
>
> 支持K8s 版本
>
> - 1.18
> - 1.19
> - 1.20

##### Install Calico with Kubernetes API datastore, 50 nodes or less

1. Download the Calico networking manifest for the Kubernetes API datastore.

    ```bash
    curl https://docs.projectcalico.org/archive/v3.18/manifests/calico.yaml -O
    ```

1. If you are using pod CIDR , skip to the next step. If you are using a different pod CIDR with kubeadm, no changes are required - Calico will automatically detect the CIDR based on the running configuration. For other platforms, make sure you uncomment the CALICO_IPV4POOL_CIDR variable in the manifest and set it to the same value as your chosen pod CIDR.`192.168.0.0/16`

2. Customize the manifest as necessary.

3. Apply the manifest using the following command.

   ```bash
   kubectl apply -f calico.yaml
   ```

##### Install Calico with Kubernetes API datastore, more than 50 nodes

1. Download the Calico networking manifest for the Kubernetes API datastore.

   ```
   $ curl https://docs.projectcalico.org/archive/v3.18/manifests/calico-typha.yaml -o calico.yaml
   ```

2. If you are using pod CIDR , skip to the next step. If you are using a different pod CIDR with kubeadm, no changes are required - Calico will automatically detect the CIDR based on the running configuration. For other platforms, make sure you uncomment the CALICO_IPV4POOL_CIDR variable in the manifest and set it to the same value as your chosen pod CIDR.`192.168.0.0/16`

3. Modify the replica count to the desired number in the named, .`Deployment``calico-typha`

   ```
   apiVersion: apps/v1beta1
   kind: Deployment
   metadata:
     name: calico-typha
     ...
   spec:
     ...
     replicas: <number of replicas>
   ```

   We recommend at least one replica for every 200 nodes, and no more than 20 replicas. In production, we recommend a minimum of three replicas to reduce the impact of rolling upgrades and failures. The number of replicas should always be less than the number of nodes, otherwise rolling upgrades will stall. In addition, Typha only helps with scale if there are fewer Typha instances than there are nodes.

   > **Warning**: If you set and set the Typha deployment replica count to 0, Felix will not start.`typha_service_name`

4. Customize the manifest if desired.

5. Apply the manifest.

   ```
   $ kubectl apply -f calico.yaml
   ```

##### 安装后如下

```bash
[root@k8s-master ~]# kubectl -n kube-system get pod
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-7b5bcff94c-sdtqs   1/1     Running   0          16m
calico-node-jn6fj                          1/1     Running   0          16m
calico-node-lrkdr                          1/1     Running   0          16m
calico-node-spd79                          1/1     Running   1          16m
coredns-59c7994f5d-gh7cn                   1/1     Running   7          10h
coredns-59c7994f5d-x28b7                   1/1     Running   8          10h
etcd-k8s-master                            1/1     Running   9          275d
......
```

