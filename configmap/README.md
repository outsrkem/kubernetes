## configMap  资源

多生产环境中的应用程序配置较为复杂，可能需要多个 config 文件、命令行参数和环境变量的组合。使用容器部署
时，把配置应该从应用程序镜像中解耦出来，以保证镜像的可移植性。尽管 Secret 允许类似于验证信息和秘钥等信息从应用
中解耦出来，但在 K8S1.2 前并没有为了普通的或者非 secret 配置而存在的对象。在 K8S1.2 后引入 ConfigMap 来处理这
    种类型的配置数据。自 1.14 kubectl 开始支持 kustomization.yaml。

```shell
kubectl create configmap nginx-config \
--from-literal=WEB.NGINX_PORT=80 \
--from-literal=WEB.SERVER_NAME=myapp.yong.com \
--from-literal=WEB.DB_IP=1.2.3.4 \
--from-literal=WEB.DB_PORT=3306 \
--from-literal=WEB.DB_USER_NAME=server
```

查看该资源，看到此时 WEB.*** 均为键，后面均为值，这种创建方式更有利于使用env方式注入到pods里面。我们可看到get出来的yaml清单中的键是以字母顺序排序的。

```shell
kubectl get configmaps nginx-config -o yaml # 简写为 kubectl get cm nginx-config -o yaml
apiVersion: v1
data:
  WEB.DB_IP: 1.2.3.4
  WEB.DB_PORT: "3306"
  WEB.DB_USER_NAME: server
  WEB.NGINX_PORT: "80"
  WEB.SERVER_NAME: myapp.yong.com
......
```

使用如下方式通过env注入，但是这种注入方式，不会自动更新。需要重启pod才能被重新应用，所以这种方式更适合配置长期固定不变的配置项。

```shell
    env: 
    - name: NGINX_SERVER_PORT # 这是环境变量的名称
      valueFrom: # kubectl explain pods.spec.containers.env.valueFrom.configMapKeyRef
        configMapKeyRef:
          name: nginx-config   # 只是configmap的资源名称
          key: WEB.NGINX_PORT  # 这是configmap中的键，可以与环境变量不同，但建议使用相同的名称。
    - name: NGINX_SERVER_NAME
      valueFrom:
        configMapKeyRef:
          name: nginx-config
          key: WEB.SERVER_NAME
```



