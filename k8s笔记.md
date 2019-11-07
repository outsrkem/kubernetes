k8s简介


* kubernetes （希腊语：舵手，飞行员）
* 谷歌根据Borg系统的思想使用Go语言重写Borg系统为kubernetes
* 特性
    * 自动装箱
    * 自我修复
    * 水平扩展
    * 服务发现
    * 负载均衡
    * 自动发布和回滚
    * 秘钥和配置管理（同一管理配置）
    * 存储编排
    * 批量处理执行
* kubernetes即是一个集群    
    * master/nodes 集群
        * master 主节点（整个集群大脑一般生产环境3个即可）
        * node 工作节点，主要运行Pod
* master
    * API Server 整个系统的对外接口，供客户端和其它组件调用，接受，管理创建容器的请求
    * scheduler 调度器
    * controller-manager 控制器管理器
    * 以上3个组件分别运行为守护进程
* Node 
    * kubelet (与master节点通信，主要负责监视指派到它所在Node上的Pod，包括创建、修改、监控、删除等。)
    * docker (容器引擎)
* kubernetes集群最小运行的单元--Pod（可理解为容器的外壳，对容器做一层抽强的封装）
    * Pod内容器共享同一网络名称空间，共享同一存储卷
    * 一个Pod建议只有一个主容器，或者其他辅助主容器的容器（边车）
    * Label 标签选择器（KV类型数据Key=Value）
    * Label Selector：

----

* Pod：(Pod是由控制器创建)
	* 自主式Pod
	* 控制器管理的Pod
         * ReplicationController（较早）
             * ReplicaSet（副本集控制器，不直接使用）
             * Deployment（只能管理无状态引用）
             * StatefuISet
             * DacmonSet
             * Job,Ctonjob
             * HPA
* server 服务（只是iptables的DNAT规则 ） 修改名称或Ip会自动触发DNS自动修改记录
* AddOns：附加组件（如：DNS）

----
* kubernetes 网络
    * server网络（节点网络）
    * 集群网络
    * Pod 网络

* CNI 网络插件(第三方插件)
    * flannel：网络配置(叠加协议)使用简单
    * calico：网络配置，网络策略（三层隧道网络）配置复杂
    * canel：结合上面2种
    * ....
    

![](https://images.cnblogs.com/cnblogs_com/outsrkem/1571911/o_1571487842485_2.png)

---

---


# 尝试启动pod

```
kubectl run nginx-deploy --image=nginx:1.14-alpine --port=80 --replicas=1 --dry-run=true
```
```
	--dry-run=true 模拟启动
```

实际启动

```
kubectl run nginx-deploy --image=nginx:1.14-alpine --port=80 --replicas=1
```
```
    nginx-deploy				# 控制器名称	
    --image=nginx:1.14-alpine   # 指定镜像	
    --port=80                   # 暴露端口，不指定会默认有
    --replicas=1                # 副本数量	
```
### 启动svc 

为pod提供固定访问地址

```
kubectl expose deployment nginx-deploy --name=nginx  --port=80 --target-port=80 --protocol=TCP
```

```
yum install bind-utils -y
```

```
dig -t A nginx.default.svc.cluster.local @10.96.0.10
```

```
wget -O - -q http://nginx:80/

```



### 启动2个副本的myapp


```
kubectl run myapp --image=ikubernetes/myapp:v1 --replicas=2
```


- 创建myapp的svc

```
kubectl expose deployment myapp --name=myapp --port=80
```

- 动态监控

```
kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
If you don't see a command prompt, try pressing enter.
dnstools# while :; do wget -O - -q myapp; sleep 1; done
```

- pod扩容

```
kubectl scale --replicas=5 deployment myapp
```

- 版本升级

```
kubectl set image deployment myapp myapp=ikubernetes/myapp:v2
```

- 版本回滚

```
kubectl rollout undo deployment myapp
```
---

---

### 说明

- kubeclt本身提供了http restful接口：

    GET PUT DELETE POST...也就是我们在命令行通过kubectl与apiserver进行交互，来创建我们所需要的资源
- 在k8s中，为了方便我们对资源进行集中化管理，命令行操作显得力不从心，所以我们都是通过资源清单来进行对资源的管理
- 资源：
```
pod：k8s的最小调度资源
  pod控制器：
    ReplicationController：老版本
    ReplicaSet：替代了上面
    Deployment：管理ReplicaSet
    StatefulSet：管理有状态的的pod资源（mysql、redis）
    DaemonSet：启动为守护进程的pod
    Job：
    Cronjob：
```

# 资源清单的组成部分

> 资源清单就是所谓的yaml格式的文件，一般的资源清单包括5个一级标签组成：

```
#以下类型为pod，故我们可以通过以下命令来进行查看如何定义一个pod资源所需要的资源清单

kubectl explain pods
# 此命令执行完成后，会列出以下五个一级标签

apiServer:  # 表明此pod的版本号，通常我们选择稳定版；beta属于公测版，alpha属于内测版
kind:       # 资源类别
metadata：  # 元数据
spec：      # 定义用户期望的状态副本数等
status：    # 当前状态，只读的，不需要在清单中创建，属于k8s自己创建维护管理的

# 以上五个一级标签我们通过命令查看到之后，通常object代表包含嵌套字段；比如元数据metadata，我们可通过以下命令查看嵌套字段：
kubectl explain pods.metadata
...
metadata:
    name:       # 必须是唯一的，受限制于namespace
    namespace:  # 不同的namespace，name可以相同，我们一般采用default命名空间
    labels:     # 标签，标签很重要，后面我们的service发现就是基于标签选择器匹配来进行服务发现，可定义多个标签
    annotation: # 注解，也就是描述信息

#通过以上命令查看，不仅有object，并且还会有[]object；这是对象列表，代表可以继续往下嵌套，比如我们定义spec的时候
kubectl explain pods.spec.containers
所有的列表可以用[]或者- 以及字典类型的键值对{}来表示

# 以下一个例子
vim pod-myapp.yaml
apiVsersion: v1
kind: pod
metadata:
    name: myapp
    namespace: default
    lables: 1、{"app"："myapp"，"tier"："frontend"}-->json格式
     2、app: myapp
        tier: frontend
spec:
    containers:(一个pod可定义多个容器)
    - name: myapp                   # 容器名
      image: ikubenetes/myapp:v1    # 镜像
    - name: busybox
      image: busybox:latest
      imagePullPolicy: IfNotPresent # 镜像拉去策略，此策略为本地有镜像就不去拉取镜像了
      #command: ["/bin/bash","-c","sleep 30"]
      - /bin/bash
      - -c
      - sleep 30
      
而后我们启动此pod：
    kubectl create -f pod-myapp.yaml
    

kubectl get pods              # 查看pod：
kubectl get pods -o wide      # 查看pods的信息
kubectl describe pods         # 查看pod更详细的信息，包括事件
kubectl logs pods             # 查看日志
kubectl logs pods CONTAINER   # 一个pod中的多个容器的日志查看
kubectl get pods -w           # 查看pod启动过程中的实时情况watch
kubectl exec -it podname -- /bin/bash     # 进入pod：默认进入pod中的第一个容器
kubectl exec -it podname  -c CONTAINER -- /bin/bash

# 每个资源的引用PATH，可通过curl获取,大写的是动态的，创建好资源后，自动生成
/api/GROUP/VERSION/namespaces/NAMESPACE/TYPE/NAME
```



> Pod资源中，spec定义所必须的

```
spec:
     containers:
     - name:
       image:
       ports: # 此项是的作用类似于描述信息，可以通过kubectl explain pods.spec.containers.ports
       - name:
       - containerPort:
       imagePullPolicy: Always/Never/IfNotPresent
       
# 下面说明解释
imagePullPolicy： # 镜像拉取策略，分为以下三种
    Always            # 此项为默认值，不管本地有没有镜像，都去仓库中去下载
    Never             # 本地有镜像就用，没有就创建失败（应该），永不下载
    IfNotPresent      # 如果本地有镜像就用，没有镜像就去下载

command：类似于dockerfile中的ENTRYPOINT
args：(向command传递命令参数)，类似于dockerfile中ENTRYPOINT和CMD并存时的CMD
这两项参数的会出现以下的情况：
    1、如果这两都没设置，默认按照dockerfile镜像中执行
    2、如果只定义了command，那么只按照command来执行
    3、如果只定义了args那么会替换dockerfile中作为选项参数的CMD
    4、如果两都设置，镜像中失效

nodeSelector：节点标签选择器，特殊需求下使用，比如我们有一节点时ssd盘，有一节点时hsd盘，我们可通过给节点打标签，让pod去匹配
格式为key: value
nodeName： 直接运行在指定节点上
 
Selector:标签选择器（非常重要）
等值关系的标签选择器：
    =，==，！=
集合关系的标签选择器：
    in，notin
    KEY in （value1，value2，...）
    !KEY  in（value1，value2，...）
    
作用：在此pod中的作用为是为了是service服务发现相关联
二级标签如下：
    matchLabels：直接给定键值
    matchExpressions:基于给定的表达式来定义标签选择器{key:"KEY",operator(<>=!=):"OPERATOR",values:(VALUE1，VALUE2，...)}
    operator操作符：  In NotIn:values字段的值必须为非空列表
    Exists（存在），  NotExists:values字段的值必须为空列表
 
annotations：资源注解
    与label不同的地方在于，他不能用于挑选资源对象，仅仅用于为对象提供“元数据”
    比如可以写此pod是谁创建的：creater-by=luyou通过kubectl describe pods 查看
```


# 标签命令
```
# 显示所有
kubectl get pods --show-labels
# 显示带有app标签的值-l是作标签过滤，只显示谁拥有此键名的所有pod
kubectl get pods -L app
# 只显示此健对应的pod标签
kubectl get pods  -l app --show-labels
# 显示即拥有key1也有key2的
kubectl get pods -l key1，key2
# 打标签
kubectl label pods  资源名称  key=value 可以添加多个","号隔开
kubectl label pods  资源名称  key=value --overwrite  修改
key=value    键名和键值长度为63字符
key只能以字符 数字开头不能为空 value可以为空
```



###  pod打标签
```
kubectl label pods pod-demo relrase=canary
kubectl get pods  -l app --show-labels
# 修改标签
kubectl label pods pod-demo relrase=stable --overwrite
# 获取有relrase字段的pod
kubectl get pod -l relrase --show-labels
kubectl get pod -l relrase=stable,app=myapp --show-labels
kubectl get pod -l relrase!=canary --show-labels
# 集合方式获取（in包含关系，notin非包含关系）
kubectl get pod -l "relrase in (canary,beta,alpha)"
kubectl get pod -l "relrase notin (canary,beta,alpha)"
	操作符：
	in，notin：values字段的值必须为非空列表
	exists，notexists:values字段的值必须为空列表
```
###  node打标签

```
kubectl get nodes --show-labels
kubectl label nodes k8s-node1 disktype=ssd
kubectl explain pods.spec.nodeSelector
	nodeSelector <map[string]string>    # 节点标签选择器
	nodeName <string>
	Annotations # 资源注解，与lable不同，不用于挑选资源对象，仅为对象提供“元数据”
	
# 在 pod-demo.yaml 添加 nodeSelector
  nodeSelector:
    disktype: ssd
# 而后在创建 pod ，则 pod 会一直运行在含有 disktype=ssd 标签的node上
kubectl create -f pod-demo.yaml
```
# 节点选择器

- nodeSelector

```
~]# kubectl label nodes k8s-node1 disktype=ssd
node/node1 labeled
# 查看有标签的 node
~]# kubectl get nodes -l disktype=ssd --show-labels

manifests]# vim pod-demo.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    # kv格式的，也可以用花括号表示
    app: myapp
    # 定义所属的层次
    tier: frontend
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
    - name: https
      containerPort: 443
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command:
    #command: [ "/bin/sh","-c","sleep 3600" ]
    - "/bin/sh"
    - "-c"
    - "sleep 3600"
  # 定义节点选择器
  nodeSelector:
    disktype: ssd
    
----------------------------
# 创建 pods
manifests]# kubectl create  -f pod-demo.yaml
kubectl get pod -o wide # 可以看到pod在node1上
```

### 资源注解

```
# 在 pod-demo.yaml 添加 
  annotations:
    magedu.com/created-by: "cluster admin"
[root@master manifests]# cat pod-demo.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    # kv格式的，也可以用花括号表示
    app: myapp
    # 定义所属的层次
    tier: frontend
  # 资源注解,与label不同的地方在于，他不能用于挑选资源对象，仅仅用于为对象提供“元数据”
  annotations:
    magedu.com/created-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
    - name: https
      containerPort: 443
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command:
    #command: [ "/bin/sh","-c","sleep 3600" ]
    - "/bin/sh"
    - "-c"
    - "sleep 3600"
  nodeSelector:
    disktype: ssd

----------------------------
# 启动pod， 再次查看 pod 即可看到 Annotations
[root@k8s-master manifests]# kubectl describe pod pod-demo 
Name:         pod-demo
Namespace:    default
Priority:     0
Node:         k8s-node1/10.10.10.11
Start Time:   Sat, 05 Oct 2019 12:11:27 +0800
Labels:       app=myapp
              tier=frontend
Annotations:  magedu.com/created-by: cluster admin
Status:       Running
IP:           10.244.1.43


```





---

### Pod生命周期

状态：
- pending         挂起状态：任何节点都不能满足此资源的状态，调度没完成就会挂起
- running         已运行
- failed              失败
- successded   创建成功
- unknown       未知状态：kubelet有问题，apiserver就无法获取到状态

### Pod的创建过程

1、用户发起创建pod请求至apiserver

2、apiserver把创建清单请求目标状态保存至etcd当中

3、apiserver去找scheudle，调度成功后，结果保存至etcd pod资源信息当中

4、目标节点的kubelet通过apiserver当中的清单状态知道有个新任务给自己了，然后根据清单在当前节点运行这个pod，然后把状态发给apiserver再存至etcd中

> 创建pod

初始化容器

容器探测：

​	liveness

​	readiness



>  以下也是spec资源属性配置中比较重要

```
restartPolicy:    # 容器策略，以下三种
  Always          # 默认的：如果挂了总是重启
  onfailure       # 只有状态为错误时才重启
  never           # 从不重启 挂了就挂
```

---

# Pod中的容器监控检测
```
有三种探针方式：
kubectl explain pods.spec.containers
  ExecAction:         # 用户自定义命令探测
  TCPSocketAction:    # 通过tcp套接字探测
  HTTPGetAction:      # 通过http协议进行探测
```

---
- 以下为三种探针方式的实现，也是spec定义所必须的

```
# 都是二级标签，其下还有定义
kubectl explain pods.spec.containers.livenessProbe
# 此三种使用一种即可，这三种的内嵌字段都差不多相同
1、livenessProbe:存活性探针
2、readinessProbe:就绪性探针（比如nginx起来之后，进程正常，但是网页文件不在，这就是未就绪）
3、lifecycle：生命周期探针，很少使用
    内嵌字段：poststart启动后钩子
              关闭前钩子
# 内嵌字段：
exec：执行用户自定义的命令，必须是容器中存在的程序才能执行
# 通过以下命令查看exec的内嵌字段：
kubectl explain pods.spec.containers.livenessProbe.exec
为command列表对象

httpGet：通过http状态码确定是否存活
# 其内嵌字段如下：
kubectl explain pods.spec.containers.livenessProbe.httpGet
      host:默认为Pod ip
	  httpHeaders:
	  path: /index,html
	  port: 可以写端口 也可以写容器暴露端口的名称
	  schem: https/http

tcpSocket：
    host:默认为pod ip
	port:
	
initialDelaySenconds：容器启动之后多长时间开始探测，默认是容器已启动开始探测；应该定义 因为容器启动之后进程并不是直接就起来

failureThreshold：探测几次失败 才认为失败，默认是3

periodSeconds：每次探针的间隔时间 默认10s

timeoutSeconds：每次超时时间，发出之后没有响应 默认为1s
```

#### livenessProbe中exec示例

```
# 说明：此资源清单定义的主要作用为，对容器进行存活性探测，通过其exec属性，对/tmp目录下的health文件进行探测，并且，容器启动1s后开始探测，每次探针的间隔时间为1s
manifests]# vim liveness-exec.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec-pod
  namespace: default
spec:
  containers:
  - name: liveness-exec-container
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh","-c","touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 3600"]
    livenessProbe:  # 存活性探针
        exec: 		# 探针方式（执行用户定义的命令方式）
           command: ["test","-e","/tmp/healthy"] # -e 判断文件是否存在
        initialDelaySeconds: 1   # 表示容器启动后1s后开始探测
        periodSeconds: 3         # 表示每3s探测一次

----------------------------

kubectl get pods -w    #观察
kubectl describe pod liveness-exec-pod     # 查看详细情况

```
#### livenessProbe中httpGet示例

```
#此资源清单实现对容器内部nginx进行http访问进行探测，由于pod探测失败后会重新启动，所以会重新启动镜像，所以这个错误的过程我们只能看见一次通过describe
vim liveness-http.yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-httpget-pod
  namespace: default
spec:
  containers:
  - name: liven-httpget-container
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    livenessProbe:         # 存活性探针
      httpGet:             # 探针方式（获取状态码）
        port: http         # 填80也可以
        path: /index.html
      initialDelaySeconds: 1 # 表示容器启动后1s后开始探测
      periodSeconds: 3 # 表示每3s探测一次
      
----------------------------


# 登陆至pod
[root@master ~]# kubectl  exec -it liveness-httpget-pod -- /bin/bash
rm -rf /usr/local/nginx/html/index.html

# 删除成功后，pod检测到网页文件丢失，会强制我们退出pod，因为此pod相当于已经死亡，他会去重新下载新的image去启动所以我们只能捕捉到一次失败，我们可以设置pod重启策略restartPolicy，它默认是always总是重启
```

- 说明：

```
#执行命令
kubectl get pods
显示中的READY字段 1/1-->左1为就绪的右1为pod中容器的数量；pod中的容器并不是起来他的服务就已经就绪了，比如tomcat项目，一个war包很大，启动就得10s左右
```

#### readinessProbe就绪性探测

```
此示例场景为： 一个war包很大，启动就得10s左右，但是此时加入到service中，实质上是访问不到的，所以我们需要对他进行就绪性检测
vim readiness-httpget.yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-httpget-pod
  namespace: default
spec:
  containers:
  - name: readiness-httpget-container
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    readinessProbe: #就绪性探针
      httpGet: #探针方式（获取状态码）
        port: http  #填80也可以
        path: /index.html
      initialDelaySeconds: 1 #表示容器启动后1s后开始探测
      periodSeconds: 3 #表示每3s探测一次

----------------------------
# 进入pod
kubectl  exec -it readiness-httpget-pod -- /bin/bash
rm -rf  /usr/local/nginx/html/index.html
[root@master ~]# kubectl  get pod -w
NAME                   READY   STATUS    RESTARTS   AGE
readiness-httpget-pod   0/1   Running   0     61s
# 观察可发现，虽然网页文件不见了，但是进程还在，所以只是就绪失败了，左边1表示是否就绪，右边1表示pod中容器的数量

# 进入pod，新建网页文件
kubectl  exec -it readiness-httpget-pod -- /bin/bash
echo 123 > /usr/share/nginx/html/index.html
# 可看到pod的就绪状态恢复
[root@master ~]# kubectl  get pod -w
NAME                   READY   STATUS    RESTARTS   AGE
readiness-httpget-pod   1/1   Running   0     61s
```

### 实例lifecycle启动后钩子postStart

```
# postStart是指容器在启动之后立即执行的操作，如果执行操作失败了，容器将被终止并且重启。而重启与否是由重启策略。
# busy/box默认是有httpd但是没有网页文件
vim poststart-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: poststart-pod
  namespace: default
spec:
  containers:
  - name: busybox-httpd
    image: busybox
    imagePullPolicy: IfNotPresent
    lifecycle: #生命周期探测
      postStart:
        exec:
          #这个command是定义postStart后的需要执行的命令
          command: ["mkdir","-p","/data/web/html"]
    #这是定义容器里面执行的命令，不过这个命令要先于postStart里面的command
    command: ["/bin/sh","-c","sleep 3600"]
    
----------------------------

[root@master ~]# kubectl  exec -it poststart-pod -- /bin/sh
/ # ls
bin   data  dev   etc   home  proc  root  sys   tmp   usr   var
# 看到我们启动后创建了data相关目录
```

 - preStop终止之前钩子

```
[root@master ~]# kubectl  explain pods.spec.containers.lifecycle.preStop
#preStop是指容器在终止前要立即执行的命令，等这些命令执行完了，容器才能终止。
```

### 容器的重启策略-restartPolicy

```
restartPolicy 是属于spec标签下的
一旦pod中的容器挂了，我们就把容器重启。
    策略包括如下：
    Always：     表示容器挂了总是重启，这是默认策略 
    OnFailures： 表容器状态为错误时才重启，也就是容器正常终止时才重启 
    Never：      表示容器挂了不予重启 
        对于Always这种策略，容器只要挂了，就会立即重启，这样是很耗费资源的。所以Always重启策略是这么做的：第一次容器挂了立即重启，如果再挂了就要延时10s重启，第三次挂了就等20s重启...... 依次类推
```

 -  容器的终止策略

```
k8s会给容器30s的时间进行终止，如果30s后还没终止，就会强制终止。
```

### 总结

```
Pod的yaml文件包含如下5大块：
apiVersion
kind
metadata
spec
status(只读，不用我们写)
----------------------------
spec:
     containers:
     - name:
       image:
       imagePullPolicy:Always Never IfNotPresent
       ports:
           name:
           containerPort:
       livenessProbe:
       readinessProbe:
       lifecycle:
       这三个属性又有三种探针方式:
       ExecAction: exec
	   TCPSocketAction: tcpSocket
	   HTTPGetAction: httpGet
```

---



# Pod 控制器

此前直接创建的Pod 叫做自助式 pod 删除之后不会重建，是直接向apiserver请求创建的，并非由控制器管理

代替用户创建Pod 副本

#### Pod 控制器

作用：使我们创建的资源一直处于我们所期望的状态，帮助我们管理Pod，分为以下几种

- Replication Controller  :  老版的，基本上废弃 

- Replica Set    : 新的，主要帮用户管理无状态的pod资源，精确反应用户所定义的目标数量它由三个组件组成 

  - 1、用户期望的副本数
  - 2、标签选择器，以便选定由自己管理和控制的pod副本。如果说通过标签选择器选到的副本数量小于指定数量，那么它将用第三个组件来完成pod资源的新建
  - 3、Pod资源模板template
- Deployments: 工作再ReplicaSet之上，它控制ReplicaSet,通过ReplicaSet管理pod，支持replicaSet所有功能，并且支持滚动升级等，它目前是管理无状态pod最好的控制器 

- DaemonSet: (用来确保集群每一个节点只运行一个特定的Pod 副本【特定的系统级任务】)

- Job：任务完成就退出，不会重启新的pod，一次性的pod
- Cronjob：周期性运行，和Job都是无需持续性运行的pod
- StatefulSet：管理有状态的，比如redis  mysql挂了 重启之后需要重新导入数据的

#### 控制器示例
## 控制器之 ReplicaSet
 - ReplicaSet
    可以通过以下命令查看所需要的字段
    
```
#ReplicaSet可以简称为rs
kubectl explain rs.spec
#他的一级标签也是apiVersion、kind、metadata、spec、status
replicas:    副本数 默认是1
selector：   标签选择器（非常重要）
template：   pod模板
```
 - ReplicaSet示例

	vim rs-myapp.yaml

```
apiVersion: apps/v1
kind: ReplicaSet
metadata:
    name: myapp
    namespace: default
# 这里是指的是控制器的spec
spec: 
    replicas: 2 # 几个副本
    selector:   # 标签选择器
        matchLabels: # 攥着键值对模式
            app: myapp
            release: canary
    template: # pod模板
        metadata:
            name: myapp-pod
            labels: #要跟标签选择器是一样的
                app: myapp
                release: canary
                environment: qa
# 这里是pod的spec
        spec: 
            containers:
            - name: myapp-container
              image: ikubernetes/myapp:v1
              imagePullPolicy: IfNotPresent
              ports:
              - name: http
                containerPort: 80
```


- 扩容：数量从2扩容至5

```
kubectl edit rs myapp
修改副本数量
    replicas: 5 # 几个副本
    
也可以通过命令行更改
比如更换镜像：
kubectl set image命令，用法 --help
更改里面的字段用打补丁的方式：
kubectl patch --help查看用法
```

#### 需要人为干预的去滚动升级
- 升级：升级至v2

```
kubectl edit rs myapp
              image: ikubernetes/myapp:v2
              
#创建一个svc，便于查看实验结果
vim svc-rs-myapp.yaml

apiVersion: v1
kind: Service
metadata:
  name: svc-rs-myapp
  namespace: default
spec:
  selector:
    app: myapp
    release: canary
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30090
   
#写一个死循环：
[root@master rs]# while true;do curl 10.10.10.10:30090;sleep 1;done
#杀死pod观察
```

#### ReplicaSet的更新升级总结
    滚动升级改镜像文件的版本，但是正在运行的还是旧版本，杀了重启之后就会变了，需要人为参与，不智能

---

## 控制器之 Deployment
 - Deployment：工作再ReplicaSet之上，它控制ReplicaSet,通过ReplicaSet管理pod，支持replicaSet所有功能，并且支持滚动升级等，它目前是管理无状态pod最好的控制器，默认保留10个ReplicaSet
 - Deployment字段的查看

```
kubectl explain deploy
一级标签也是apiVersion、kind、metadata、spec、status
Deployment的许多字段和ReplicaSet不尽相同，以下为Deployment独有的标签字段

strategy:更新策略
kubectl explain deploy.spec.strategy （更新策略）
内嵌标签为：
Recreate：重建式更新，删除一个，重建一个
RollingUpdate：（默认的）定义滚动更新力度
    内嵌为：
     maxSurge：对应更新过程中，最多能超出我们定义的目标副本数有几个；可以定义数量，也可以定义百分比
     maxUnavailable:最多有几个不可用；可以定义数量，也可以定义百分比
revisionHistoryLimit：更新过程中，最多保持几个原始版本，方便回滚；默认是十个
template:pod模板
```

 - 定义一个Deployment资源清单

```
vim deploy-myapp.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deploy
  namespace: default
spec: #这里是指的是控制器的spec
  replicas: 2 #几个副本
  selector:   #标签选择器
    matchLabels: #攥着键值对模式
      app: myapp
      release: canary
  template: #pod模板
    metadata:
      labels: #要跟标签选择器是一样的
        app: myapp
        release: canary
    spec: #这里是pod的spec
      containers:
      - name: myapp
        image: ikubernetes/myapp:v1
        imagePullPolicy: IfNotPresent
        ports:
          - name: http
            containerPort: 80

---
# 为验证实验结果，我创建了svc可以通过访问网页查看
apiVersion: v1
kind: Service
metadata:
    name: rs-svc
    namespace: default
spec:
    selector:
        app: myapp
        release: canary
    type: NodePort
    ports:
    - port: 80
      targetPort: 80
      nodePort: 30090
                
```
 而后，我们不用此前的命令来创建资源，改为：
```
 kubectl apply -f deployment-myapp.yaml
 apply表示声名式更新，他可以应用多次，不像create只能用一次，主要是方便于我们修改完清单列表之后，他可以一直更新我们的资源配置
```
查看：
```
[root@master deployment]# kubectl  get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
myapp-deploy   2/2     2            2           4m54s
```
```
[root@master deployment]# kubectl  get rs
NAME                     DESIRED   CURRENT   READY   AGE
myapp-deploy-f5885857b   2         2         2       5m21s
```
 上面的rs式deployment自动创建的。 
```
kubectl  get pod
NAME                           READY   STATUS    RESTARTS   AGE
myapp-deploy-f5885857b-mssmh   1/1     Running   0          5m52s
myapp-deploy-f5885857b-mwmvv   1/1     Running   0          5m52s
```
修改清单文件，把replicas数字改为3，然后执行kubectl apply -f deploy-demo.yaml 即可使配置文件里的内容生效
```
#查看事件
kubectl describe deploy myapp-deploy
#-l使用标签过滤 -w是动态监控
kubectl  get rs -o wide
NAME                      DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                 SELECTOR
myapp-deploy-798dc9b584   0         0         0       30m   myapp        ikubernetes/myapp:v2   app=myapp,pod-template-hash=798dc9b584,release=canary


```
查看滚动更新的历史
```
kubectl  rollout  history deployment myapp-deploy
deployment.extensions/myapp-deploy 
REVISION  CHANGE-CAUSE
1         <none>
```
下面我们把deployment改成5个：我们可以使用vim  deploy-demo.yaml方法，把里面的replicas改成5。当然，还可以使用另外一种方法，就patch方法，举例如下。
```
kubectl  patch deployment myapp-deploy -p '{"spec":{"replicas":5}}'
deployment.extensions/myapp-deploy patched
```
查看
```
kubectl  get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
myapp-deploy   5/5     5            5           23m

kubectl  get pods
NAME                           READY   STATUS    RESTARTS   AGE
myapp-deploy-f5885857b-8xd74   1/1     Running   0          59s
myapp-deploy-f5885857b-bqspv   1/1     Running   0          59s
myapp-deploy-f5885857b-htmcg   1/1     Running   0          12m
myapp-deploy-f5885857b-mssmh   1/1     Running   0          23m
myapp-deploy-f5885857b-mwmvv   1/1     Running   0          23m
```
下面更改策略：
```
kubectl patch deployment myapp-deploy -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavaliable":0}}}}'

deployment.extensions/myapp-deploy patched
strategy：       表示策略
maxSurge：       对应更新过程中，最多能超出我们定义的目标副本数有几个pod；可以定义数量，也可以定义百分比
maxUnavaliable： 表示更新过程种最多有几个pod不可用，可以定义数量，也可以定义百分比
```
查看更新事件：
```
kubectl describe deployment myapp-deploy
RollingUpdateStrategy:  25% max unavailable, 1 max surge
```
下面用set image命令，将镜像myapp升级为v2版本，并且将myapp-deploy控制器标记为暂停。被pause命令暂停的资源不会被控制器协调使用，可以使“kubectl rollout resume”命令恢复已暂停资源。
```
[root@k8s-master manifests]# kubectl set image deployment myapp-deploy myapp=ikubernetes/myapp:v3 && kubectl rollout pause deployment myapp-deploy
deployment.apps/myapp-deploy image updated
deployment.apps/myapp-deploy paused


[root@k8s-master manifests]# kubectl get pod -w #监控
 
这个时候新开一个终端打开，另一个终端执行停止暂停
[root@k8s-master manifests]# kubectl rollout resume deployment myapp-deploy 
deployment.extensions/myapp-deploy resumed

#监控更新过程（删除一个更新一个）
[root@k8s-master manifests]# kubectl rollout status deployment myapp-deploy 
Waiting for deployment "myapp-deploy" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment spec update to be observed...
Waiting for deployment spec update to be observed...
Waiting for deployment "myapp-deploy" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "myapp-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "myapp-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "myapp-deploy" rollout to finish: 4 of 5 updated replicas are available...
deployment "myapp-deploy" successfully rolled out
```

查看rs会发现多了一个控制器：

```
[root@k8s-master manifests]# kubectl get rs -o wide
NAME                      DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                 SELECTOR
myapp-deploy-5dc9c974d7   5         5         5       4m40s   myapp        ikubernetes/myapp:v3   app=myapp,pod-template-hash=5dc9c974d7,release=canary
myapp-deploy-798dc9b584   0         0         0       117m    myapp        ikubernetes/myapp:v2   app=myapp,pod-template-hash=798dc9b584,release=canary
myapp-deploy-7d574d56c7   0         0         0       120m    myapp        ikubernetes/myapp:v1   app=myapp,pod-template-hash=7d574d56c7,release=canary
```
查看更新历史记录
```
#这里一开始应该是1和2，我多搞了几变成这个了
[root@k8s-master manifests]# kubectl rollout history deployment myapp-deploy
deployment.apps/myapp-deploy 
REVISION  CHANGE-CAUSE
3         <none>
4         <none>
5         <none>
```

下面回归到上一个版本，不指定就是上一个版本

```
[root@master deployment]# kubectl  rollout undo deployment myapp-deploy --to-revision=3
deployment.extensions/myapp-deploy rolled back

再次查看：
[root@master deployment]#  kubectl rollout history deployment myapp-deploy
deployment.apps/myapp-deploy 
REVISION  CHANGE-CAUSE
4         <none>
5         <none>
6         <none>
```
查看版本：
```
[root@k8s-master ~]# kubectl  get rs -o wide
NAME                      DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                 SELECTOR
myapp-deploy-5dc9c974d7   0         0         0       9m39s   myapp        ikubernetes/myapp:v3   app=myapp,pod-template-hash=5dc9c974d7,release=canary
myapp-deploy-798dc9b584   0         0         0       122m    myapp        ikubernetes/myapp:v2   app=myapp,pod-template-hash=798dc9b584,release=canary
myapp-deploy-7d574d56c7   5         5         5       125m    myapp        ikubernetes/myapp:v1   app=myapp,pod-template-hash=7d574d56c7,release=canary
```

说明：通过Deployment创建出来的资源，默认会自动创建出ReplicaSet，因为Deployment是通过管理ReplicaSet再来管理Pod的

kubectl get rs查看或者-o wide查看更详细，假如此时更新，我们可以给上面清单改个镜像，这个时候我们通过命令查看会发现我们多了一个ReplicaSet控制器，一个老的一个新的，方便回滚

### 回滚步骤


1、查看历史版本

```
kubectl rollout history deployment myapp-deploy
```
2、回滚
```
kubectl  rollout undo deployment myapp-deploy （默认回滚至上一版本）
kubectl  rollout undo deployment myapp-deploy --to-revision=3  前面查到的revision

更新可以查看过程
kubectl rollout status deployment myapp-deploy
```
3、此时如果发现正常 我们可通过命令实现全部更新
```
kubectl rollout resume deployment myapp-deploy
```
4、查看更新状态
```
kubectl rollout status  deployment myapp-deploy
或者：
kubectl  get pods -l app=myapp -w 
```



### 定义一个金丝雀发布场景

1、通过修改yml文件，我们把镜像设置为新的镜像，并且把更新策略换为定义0个不可用，更新过程种有可超出的有一个

2、通过命令更新一个Pod，并且暂停更新

```
kubectl set image deployment myapp-deploy myapp=ikubernetes/myapp:v3 && kubectl rollout pause deployment myapp-deploy
```
3、后面表示暂停更新过程，就实现了金丝雀，新版本启动了一个，老版本还没有动，金丝雀发布

---



## 控制器之 DaemonSet

DaemonSet：用于确保集群的每一个节点，只运行一个特定的pod副本，主要实现一些系统级别的后台任务，托管在k8s集群上的好处就是既可以以守护进程运行（不好就是挂了就是挂了），宕了之后被控制器自动创建，并且新增节点，都会去自动添加，他不能定义期望的数量了，pod模板是必须存在这样才能在节点上创建，标签选择器也是需要的，比如部署filebeat，就需要通过它来部署，保证每个节点都有一个收集日志，简称ds

示例：通过filebeat收集redis日志

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
      role: logstor
  template:
    metadata:
      labels:
        app: redis
        role: logstor
    spec:
      containers:
      - name: redis
        image: redis:4.0-alpine
        ports:
        - name: redis
          containerPort: 6379 
          
# --- 代表k8s中此代表下一清单 
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat-ds
  namespace: default
spec:
  selector:
    matchLabels:
      app: filebeat
      release: stable
  template:
    metadata:
      labels:
        app: filebeat
        release: stable
    spec:
      containers:
      - name: filebeat
        image: ikubernetes/filebeat:5.6.5-alpine
        env:
        - name: REDIS_HOST
          value: redis.default.svc.cluster.locall		#定义redis的地址
        - name: REDIS_LOG_LEVEL
          value: info

```

创建一个 redis 的 service

```
kubectl expose deployment redis --port=6379
```


升级filebeat到5.6.6

```
[root@k8s-master manifests]# kubectl set image daemonsets filebeat-ds filebeat=ikubernetes/filebeat:5.6.6-alpine
```

---

# service 资源

####  Service概述

&#8194;&#8194;&#8194;&#8194;是对一组提供相同功能的Pods的抽象，并为他们提供一个统一的入口，借助Service，应用可以方便的实现服务发现和负载均衡，并且实现应用的零宕机升级

#### Service的四种类型

使用 type 指定， type : ClusterIP

- ClusterIP
  
  ```
  默认类型，自动分配一个仅集群内部可以访问的虚拟IP
  ```
  
- NodePort 
  
  ```
  在clusterIP基础上为Service在每台机器上绑定一个端口，这样就可以通过NodeIP:来访问该服务。但是如果在kube-proxy上设置了 –nodeport-addresses=10.240.0.0/16（v1.10 支持），那么仅该 NodePort 仅对设置在范围内的 IP 有效
  ```
  
- LoadBalancer 
  
  ```
  在NodePort的基础之上，k8s请求底层云平台创建一个负载均衡器，将每个Node作为后端，负载均衡器将转发请求到[NodeIP]:[NodePort]；负载均衡器由底层云平台创建提供，会包含一个LoadBalancerIP，可以认为是LoadBalancerService的外部IP
  ```
  
- ExternalName
  
  ```
  将服务通过DNS、CNAME记录方式转发到指定的域名（通过 spec.externlName 设定）。需要 kube-dns 版本在 1.7 以上;也就是表示把集群外部的服务引入到集群内部中来，即实现了集群内部pod和集群外部的服务进行通信；我们可以用ExternalName对Service名称和集群外部服务地址做一个映射，使之访问Service名称就是访问外部服务
  ```

注意：

```
还有一种比较特殊的，headless service；eadless service是一个特殊的ClusterIP类service，这种service创建时不指定clusterIP(--cluster-ip=None)，因为这点，kube-proxy不会管这种service，于是node上不会有相关的iptables规则。
当headless service有配置selector时，其对应的所有后端节点，会被记录到dns中，在访问service domain时kube-dns会将所有endpoints返回，选择哪个进行访问则是系统自己决定；
当selector设置为空时，headless service会去寻找相同namespace下与自己同名的pod作为endpoints。这一点被应用到statefulset中，当一个三副本的statefulset（mysql1，mysql2,mysql3）运行在不同节点时，我们可以通过域名的方式对他们分别访问。
```

#### k8s的3种IP地址

- NodeIP
  - &#8194;&#8194;节点ip，由我们运维人员自行设定的也就是物理网卡的
- PodIP
  - &#8194;&#8194;虚拟的二层网络，通过我们的网络插件flannel划分出来的
- ClusterIP
  - &#8194;&#8194;Service的ip地址，这个是虚拟的，无法ping通，只能结合Service port组成一个具体的通信服务端口，单独的ClusterIP不具备TCP/IP通信的基础。

#### Service管理

- 网络代理模式
- 服务代理
- 服务发现
- 发布服务

注意：

- Service依赖与k8s集群中的coreDNS，老版本叫kube-DNS

- node节点上部署kube-proxy，利用k8s独有的功能watch监视功能，监视着apiserver中关于Service的情况

#### 服务代理
```
逻辑层面：
    Service被认为是真实应用的抽象，每一个Service关联着一系列的Pod。
物理层面：
   Service又是真实应用的代理服务器，对外表现为一个单一访问入口，通过k8s Proxy转发请求到Service关联的Pod。
Service同样是根据Label Selector来刷选pod进行关联的，实际上k8s在Service和pod之间通过Endpoint衔接，Endpoints同Service关联的Pod；相对应，可以认为是Service的服务代理后端，k8s会根据Service关联到Pod的PodIP信息组合成一个Endpoints；只不过我们在创建service时，它会自动创建跟Service同名的Endpoint，可通过describe查看，也可以kubectl get endpoints svcname 
```

#### Service三种代理模式

1.1之前版本：userspace
1.10版本   ：iptables
1.11版本后 ：ipvs的nat模式

- 早期的代理模式(userspace)：
  ![](https://images.cnblogs.com/cnblogs_com/outsrkem/1571911/o_1.png)

```
client先请求serviceip，经由iptables转发到kube-proxy上之后再转发到pod上去。这种方式效率比较低
```
- iptables的代理模式（iptables）
  ![](https://images.cnblogs.com/cnblogs_com/outsrkem/1571911/o_1571486185929_11.png)

```
这种模式种，kube-proxy回监视master对service对象和Endpoints对象的添加和移除，client请求serviceip后会直接转发到pod上。这种模式性能会高很多。kube-proxy就会负责将pod地址生成在node节点iptables规则中;
```
- ipvs代理方式：
  ![](https://images.cnblogs.com/cnblogs_com/outsrkem/1571911/o_1363_9.png)

```
这种方式是通过内核模块ipvs的Nat模式实现转发，这种效率更高。若没有激活 自动降为iptables
```
### Service资源清单

```
kubectl explain svc查看
spec:
    selector:标签选择器不需要matchLabel或者matchExpressions，它是直接给定的可通过命令查看kubectl describe
    clusterIP: ()可以不用定义，默认就是它，ip也是动态分配的
    type: ClusterIP、NodePort、LoadBalancer、ExternalName
    ports：
    - port: 80 service端口
      targetPort： 80 pod端口
      NodePort： 80 节点端口（必须是NodePort类型才能使用）
      protocol： 默认是TCP
```
##### 为 redis创建svc

vim redis-ds-demo-svc.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: default
spec:
  selector:
    app: redis
    role: logstor
  clusterIP: 10.102.102.102
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
```

##### 为 myapp 创建svc

```
vim myapp-svc.yaml
```

```
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: default
spec:
  selector:
    app: myapp
    release: canary
  clusterIP: 10.99.99.99
  type: NodePort
# sessionAffinity: ClientIP  # 定义sessionAffinity ，此时注释掉，下面是用补丁方式
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080 # 只有type: NodePort 时 才 能 生 效

```

```
# 修改对于同一客户端请求调度到同一Pod
kubectl patch svc myapp -p '{"spec":{"sessionAffinity":"ClientIP"}}'
# 在修改为None，又开始调度，立即生效
kubectl patch svc myapp -p '{"spec":{"sessionAffinity":"None"}}'
```

##### 创建无头svc

>  以myapp 为例

```
cp myapp-svc.yaml myapp-svc-headless.yaml
vim !$
```

```
apiVersion: v1
kind: Service
metadata:
  name: myapp-headless
  namespace: default
spec:
  selector:
    app: myapp
    release: canary
  clusterIP: None # 此处为None，则创建的svc是没有IP的
  ports:
  - port: 80
    targetPort: 80
```

```
[root@k8s-master manifests]# kubectl apply -f myapp-svc-headless.yaml 
service/myapp-headless created
```
> 此时myapp-headless 的CLUSTER-IP 为 None

```
[root@k8s-master manifests]# kubectl get svc
NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes       ClusterIP   10.96.0.1        <none>        443/TCP        18d
myapp            NodePort    10.99.99.99      <none>        80:30080/TCP   11m
myapp-headless   ClusterIP   None             <none>        80/TCP         3s
redis            ClusterIP   10.102.102.102   <none>        6379/TCP       51m
```

> 使用 dit 直接解析到Pod 的IP


```
dig -t A myapp-headless.default.svc.cluster.local @10.96.0.10
.......
;; ANSWER SECTION:
myapp-headless.default.svc.cluster.local. 30 IN	A 10.244.1.134
myapp-headless.default.svc.cluster.local. 30 IN	A 10.244.2.124
myapp-headless.default.svc.cluster.local. 30 IN	A 10.244.1.133
myapp-headless.default.svc.cluster.local. 30 IN	A 10.244.2.123
myapp-headless.default.svc.cluster.local. 30 IN	A 10.244.1.132
........
```

>  查看 Pod IP即为上面解析出的IP

```
kubectl get pod -l app=myapp -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
myapp-deploy-7d574d56c7-29xg5   1/1     Running   0          70m   10.244.1.133   k8s-node1   <none>           <none>
myapp-deploy-7d574d56c7-2c5dq   1/1     Running   0          69m   10.244.1.134   k8s-node1   <none>           <none>
myapp-deploy-7d574d56c7-88sjn   1/1     Running   0          70m   10.244.1.132   k8s-node1   <none>           <none>
myapp-deploy-7d574d56c7-kqfvh   1/1     Running   0          69m   10.244.2.124   k8s-node2   <none>           <none>
myapp-deploy-7d574d56c7-v58k9   1/1     Running   0          70m   10.244.2.123   k8s-node2   <none>           <none>
```

#### 总结

 k8s中service是一个面向微服务架构的设计，它从k8s本身解决了容器集群的负载均衡，并开放式地支持了用户所需要的各种负载均衡方案和使用场景。 通常一个service被创建后会在集群中创建相应的endpoints，随后，controller-manager中的endpointsController会去检查并向该endpoints填入关于这个service，符合下述所有条件的后端端点（即pod）：

1、相同的namespace；

2、pod的labels能满足service.Spec.selector（除非service.Spec.selector为空，这种情况下不会自动创建endpoints）；

3、如果service开放了port，且是以字符串名字的形式（targetPort=[字符串]），则相应的pod的某个container中必须有配置同名的port；

当endpoints被更新后，kube-proxy会感知，并根据更新后的endpoints，在宿主机上做转发规则的配置，kube-proxy目前支持iptables、ipvs两种负载均衡方式，默认是iptables。

# Ingress资源

DaemonSet 之 Ingress Controller

- Kubernetes 暴露服务的有三种方式，分别为 LoadBlancer Service、NodePort Service、Ingress。官网对ingress的定义为管理对外服务到进群内服务之间规则的集合，通俗讲就是它定义规则来允许进入集群的请求被转发到集群中对应的服务上，从来实现服务暴露。ingress能把集群内Service配置成外网能访问的url，流量负载均衡，终止ssl，提供基于域名访问的虚拟主机等
 - LoadBlancer Service是k8s结合云平台的组件，如aws gce 阿里云等，使用它向底层的云平台申请创建负载均衡器来实现，有局限性，对于使用云平台的集群比较方便
 - NodePort Service是通过在节点上暴露端口，然后通过将端口映射到具体某个服务上来实现服务暴露，比较直观方便，但是对于集群来说，随着Service的不断增加，需要增加的端口会越来越多，很容易出现端口冲突，并且不容易管理。当然对于小规模的集群服务，还是很不错的选择
 - Ingress：就是能利用Nginx（不常用）、Haproxy（不常用）、Traefik（常用）、Envoy（常用）等负载均衡器暴露集群内服务的工具。
 - ngress为您提供七层负载均衡能力，您可以通过 Ingress 配置提供外部可访问的，URL、负载均衡、SSL、基于名称的虚拟主机等。作为集群流量接入层，Ingress的高可靠性显得尤为重要；ingress-controller监听apiserver，获取服务新增，删除等变化，并结合ingress规则动态更新到反向代理负载均衡器上，并且重载配置使其生效
 - 小知识：我们把k8s里面的pod服务发布到集群外部，可以用ingress，也可以用NodePort。 

> ingress的部署文档
>
> https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal

#### 下载资源清单

```
for file in configmap.yaml  namespace.yaml  mandatory.yaml  rbac.yaml  with-rbac.yaml;do wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/$file; done
# 或者直接在我的git拉取
git clone https://gitee.com/Outsrkem/ingress-nginx.git
```



> 一键部署 ingress

```
[root@master ingress-nginx]# kubectl apply -f mandatory.yaml
[root@k8s-master ingress]# kubectl get pod -n ingress-nginx 
NAME                                        READY   STATUS    RESTARTS   AGE
nginx-ingress-controller-568867bf56-5kwxp   1/1     Running   0          42m
```

```
vim service-nodeport.yaml
```

```
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
    nodePort: 30080
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
    nodePort: 30443
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
```

```
kubectl apply -f service-nodeport.yaml
```

```
[root@k8s-master ingress]# kubectl get svc -n ingress-nginx 
NAME            TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx   NodePort   10.105.204.172   <none>        80:30080/TCP,443:30443/TCP   12m
```

```
[root@k8s-master ingress]# curl 10.10.10.10:30080
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>openresty/1.15.8.2</center>
</body>
</html>
# 看到此404代表成功了，这是此ingress-nginxpod设置的404页面
```

> 创建后端服务

```
vim deploy-demo.yaml
```

```
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: default
spec:
  selector:
    app: myapp
    release: canary
  ports:
  - name: http
    targetPort: 80 #这里是容器端口
    port: 80 #这是service端口
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deploy
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      release: canary
  template:
    metadata:
      labels:
        app: myapp
        release: canary
    spec:
      containers:
      - name: myapp
        image: ikubernetes/myapp:v2
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 80
```

```
vim ingress-myapp.yaml
```

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-myapp
  namespace: default #这里要和deployment和要发布的service处于同一命名空间
  annotations: #这个注解说明我们要用到的ingress-controller是nginx，而不是traefic，enjoy
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: myapp.yong.com #表示访问这个域名就会转发到后端myapp管理的pod上的服务:
    http:
      paths:
      - path:
        backend:
          serviceName: myapp
          servicePort: 80
```

```
[root@k8s-master ingress]# kubectl apply -f ingress-myapp.yaml
```

```
[root@k8s-master ingress]# kubectl get ingress
NAME            HOSTS            ADDRESS   PORTS   AGE
ingress-myapp   myapp.yong.com             80      16s

#查看详细信息
[root@k8s-master ingress]# kubectl describe ingress ingress-myapp 
Name:             ingress-myapp
Namespace:        default
Address:          10.105.204.172
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host            Path  Backends
  ----            ----  --------
  myapp.yong.com  
                     myapp:80 (10.244.1.140:80,10.244.2.127:80,10.244.2.128:80)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"extensions/v1beta1","kind":"Ingress","metadata":{"annotations":{"kubernetes.io/ingress.class":"nginx"},"name":"ingress-myapp","namespace":"default"},"spec":{"rules":[{"host":"myapp.yong.com","http":{"paths":[{"backend":{"serviceName":"myapp","servicePort":80},"path":null}]}}]}}

  kubernetes.io/ingress.class:  nginx
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  66s   nginx-ingress-controller  Ingress default/ingress-myapp
  Normal  UPDATE  40s   nginx-ingress-controller  Ingress default/ingress-myapp
```

> 主机添加hosts

```
vim /etc/hosts  ---->  10.10.10.10 myapp.yong.com
```

> 访问 myapp.yong.com:30080/hostname.html 成功

````
[root@k8s-master ingress]# curl myapp.yong.com:30080/hostname.html
myapp-deploy-798dc9b584-hmvrw
[root@k8s-master ingress]# kubectl get pod 
NAME                            READY   STATUS    RESTARTS   AGE
myapp-deploy-798dc9b584-dbr9g   1/1     Running   0          25m
myapp-deploy-798dc9b584-hmvrw   1/1     Running   0          25m
myapp-deploy-798dc9b584-mknj5   1/1     Running   0          25m

````

##### 把tomcat service通过ingress发布出去

```
vim tomcat-demo.yaml
```

```
apiVersion: v1
kind: Service         #此service资源必须设置为无头 svc
metadata:
  name: tomcat
  namespace: default
spec:
  selector:
    app: tomcat
    release: canary
  ports:
  - name: http
    targetPort: 8080  # 这里是容器端口
    port: 8080        # 这是service端口
  - name: ajp
    targetPort: 8009
    port: 8009
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat-deploy
  namespace: default
spec:
  replicas: 4
  selector:
    matchLabels:
      app: tomcat
      release: canary
  template:
      metadata:
        labels:
          app: tomcat
          release: canary
      spec:
        containers:
        - name: tomcat
          image: tomcat:8.5.34-jre8-alpine
          imagePullPolicy: IfNotPresent
          ports:
          - name: tomcat
            containerPort: 8080
          - name: ajp
            containerPort: 8009

```

```
cp ingress-myapp.yaml ingress-tomcat.yaml
vim !$
```

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-tomcat
  namespace: default #这里要和deployment和要发布的service处于同一命名空间
  annotations: #这个注解说明我们要用到的ingress-controller是nginx，而不是traefic，enjoy
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: tomcat.yong.com #表示访问这个域名就会转发到后端tomcat 管理的pod上的服务:
    http:
      paths:
      - path:
        backend:
          serviceName: tomcat
          servicePort: 8080

```

```
[root@k8s-master ingress]# kubectl apply -f tomcat-demo.yaml 
service/tomcat unchanged
deployment.apps/tomcat-deploy unchanged
[root@k8s-master ingress]# kubectl apply -f ingress-tomcat.yaml 
ingress.extensions/ingress-tomcat configured

```

```
[root@k8s-master ingress]# kubectl get pod,svc
NAME                                READY   STATUS    RESTARTS   AGE
pod/myapp-deploy-798dc9b584-dbr9g   1/1     Running   0          52m
pod/myapp-deploy-798dc9b584-hmvrw   1/1     Running   0          52m
pod/myapp-deploy-798dc9b584-mknj5   1/1     Running   0          52m
pod/tomcat-deploy-567cbb595-4qlcw   1/1     Running   0          13m
pod/tomcat-deploy-567cbb595-bcwz7   1/1     Running   0          13m
pod/tomcat-deploy-567cbb595-g85qt   1/1     Running   0          13m
pod/tomcat-deploy-567cbb595-hv8tb   1/1     Running   0          13m

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP             18d
service/myapp        ClusterIP   10.98.91.146    <none>        80/TCP              52m
service/tomcat       ClusterIP   10.96.245.100   <none>        8080/TCP,8009/TCP   12m

```

```
[root@k8s-master ingress]# kubectl get ingress
NAME             HOSTS             ADDRESS          PORTS   AGE
ingress-myapp    myapp.yong.com    10.105.204.172   80      6m56s
ingress-tomcat   tomcat.yong.com   10.105.204.172   80      11m
```

> 浏览器访问主机IP:30080 即可看到tomcat页面（添加hosts映射）

#####  测试https

> 创建证书

```
openssl genrsa -out tls.key 2048
openssl req -new -x509 -key tls.key -out tls.crt -subj /C=CN/ST=BJ/L=BJ/O=DEVOPS/CN=tomcat.yong.com
```

```
kubectl create secret tls tomcat-ingress-secret --cert=tls.crt --key=tls.key
```

```
[root@k8s-master ingress]# kubectl get secrets 
NAME                    TYPE                                  DATA   AGE
default-token-qhq9g     kubernetes.io/service-account-token   3      18d
tomcat-ingress-secret   kubernetes.io/tls                     2      12s
```

```
[root@k8s-master ingress]# kubectl describe secrets tomcat-ingress-secret
Name:         tomcat-ingress-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1261 bytes
tls.key:  1679 bytes

```

```
vim ingress-tomcat-tls.yaml
```

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-tomcat-tls
  namespace: default #这里要和deployment和要发布的service处于同一命名空间
  annotations: #这个注解说明我们要用到的ingress-controller是nginx，而不是traefic，enjoy
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
  - hosts:
    - tomcat.yong.com
    secretName: tomcat-ingress-secret
  rules:
  - host: tomcat.yong.com #表示访问这个域名就会转发到后端tomcat 管理的pod上的服务:
    http:
      paths:
      - path:
        backend:
          serviceName: tomcat
          servicePort: 8080

```

```
[root@k8s-master ingress]# kubectl get ingresses
NAME                 HOSTS             ADDRESS          PORTS     AGE
ingress-myapp        myapp.yong.com    10.105.204.172   80        24m
ingress-tomcat       tomcat.yong.com   10.105.204.172   80        29m
ingress-tomcat-tls   tomcat.yong.com   10.105.204.172   80, 443   9s
[root@k8s-master ingress]# kubectl describe ingress ingress-tomcat-tls 
Name:             ingress-tomcat-tls
Namespace:        default
Address:          10.105.204.172
Default backend:  default-http-backend:80 (<none>)
TLS:
  tomcat-ingress-secret terminates tomcat.yong.com
Rules:
  Host             Path  Backends
  ----             ----  --------
  tomcat.yong.com  
                      tomcat:8080 (10.244.1.141:8080,10.244.1.142:8080,10.244.2.129:8080 + 1 more...)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"extensions/v1beta1","kind":"Ingress","metadata":{"annotations":{"kubernetes.io/ingress.class":"nginx"},"name":"ingress-tomcat-tls","namespace":"default"},"spec":{"rules":[{"host":"tomcat.yong.com","http":{"paths":[{"backend":{"serviceName":"tomcat","servicePort":8080},"path":null}]}}],"tls":[{"hosts":["tomcat.yong.com"],"secretName":"tomcat-ingress-secret"}]}}

  kubernetes.io/ingress.class:  nginx
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  21s   nginx-ingress-controller  Ingress default/ingress-tomcat-tls
  Normal  UPDATE  12s   nginx-ingress-controller  Ingress default/ingress-tomcat-tls

```

> 浏览器访问 https://tomcat.yong.com:30443/



# 存储卷

###  背景
pod是有生命周期的，pod一旦重启，数据就会随着消失；所以我们需要数据持久化存储；然而在k8s中，存储卷并不是属于容器，而是属于pod；也就是说同一个pod中的容器可以共享一个存储卷；存储卷既可以是宿主机上的目录，也可以是挂载在宿主机上的外部设备

###  存储卷类型

- emptyDIR

  ```
  EmptyDir是一个空目录，他的生命周期和所属的 Pod 是完全一致的，可以在同一 Pod 内的不同容器之间共享工作过程中产生的文件pod重启，存储卷也删除，一般用于当作临时空间或者缓存关系，缺省情况下，EmptyDir 是使用主机磁盘进行存储的，也可以设置emptyDir.medium 字段的值为Memory，来提高运行速度，但是这种设置，对该卷的占用会消耗容器的内存份额
  ```

- hostPath

  ```
  这种会把宿主机上的指定卷加载到容器之中，当然，如果 Pod 发生跨主机的重建，其内容就难保证了。这种卷一般和DaemonSet搭配使用，用来操作主机文件，例如进行日志采集的 FLK 中的 [FluentD](https://www.centos.bz/tag/fluentd/) 就采用这种方式，加载主机的容器日志目录，达到收集本主机所有日志的目的。宿主机上的目录作为存储卷，这种也不是真正意义上实现了数据持久性。
  ```

- san（iscsi）或者nas(nfs、cifs)：网络存储设备

- 分布式存储（ceph、cephfs、glusterfs、rbd）：
  rbd是ceph的块接口存储，cephfs是ceph的文件系统存储接口

- 云存储（亚马逊的EBS，Azure Disk，阿里云）： 

  这种一般k8s也在云上部署的。 
  configMap：k8s的特殊的一种存储卷资源，是明文的，相当于是配置中心，我们的管理员或者用户提供了从外部向pod内部注入信息的方式，多个pod都可以读取
  secret：功能和configMap是一样的，只不过是密文的

```
kubectl explain pods.spec.volumes
```

#### hostPath的类型说明： 

- DirectoryOrCreate
  - 意思是我们要挂载的路径在宿主机上是个已经存在的目录，不存在就创建一个新的目录 
- Directory
  - 宿主机必须存在此目录，如果不存在，就会报错 
- FileOrCreate
  - 表示挂载的是文件，如果不存在就挂载一个文件，文件亦可以当作存储挂载的。 
- File
  - 表示要挂载的文件必须存在，否则就报错； 
- Socket
  - 表示必须是一个Socket类型的文件； 
- CharDevice
  - 表示一个字符类型的设备文件 
- BlockDevice
  - 表示的是一个块类型的设备文件

### 实验

#### 实验一

```
vim pod-vol-demo.yaml
```

```
apiVersion: v1 
kind: Pod
metadata:
  name: pod-demo-vol
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/created-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports: 
    - name: http
      containerPort: 80
    volumeMounts: 
    - name: html
      mountPath: /data/web/html/
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    volumeMounts: 
    - name: html
      mountPath: /data/
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 7200"
  volumes:
  - name: html
    emptyDir: {}
```

> 启动后在myapp 中的/data中写入文件，可在busybox中的/data/web/html/ 中可看到刚才写入的文件

```
[root@k8s-master volumes]# kubectl exec -it pod-demo-vol -c busybox -- /bin/sh
/ # cd data/
/data # echo `date`  >> index.html
[root@k8s-master vokubectl exec -it pod-demo-vol -c myapp -- /bin/sh
/ # ls /data/web/html/index.html 
/data/web/html/index.html
/ # cat /data/web/html/index.html 
Mon Oct 21 11:52:47 UTC 2019
```



#### 实验二

```
vim pod-vol-html-demo.yaml
```

```
apiVersion: v1 
kind: Pod
metadata:
  name: pod-demo-vol
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/created-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports: 
    - name: http
      containerPort: 80
    volumeMounts: 
    - name: html
      mountPath: /usr/share/nginx/html/
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    volumeMounts: 
    - name: html
      mountPath: /data/
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo `date` > /data/index.html; sleep 1; done"]
  volumes:
  - name: html
    emptyDir: {}

```

> 启动后访问 Pod 即可看到每秒钟写入到index.html文件中的时间

```
[root@k8s-master volumes]# kubectl get pod -o wide 
NAME                            READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
pod-demo-vol                    2/2     Running   0          6s    10.244.1.156   k8s-node1   <none>           <none>
[root@k8s-master volumes]# curl 10.244.1.156
Mon Oct 21 12:19:58 UTC 2019
```

#### 实验三

```
vim pod-hostpath-vol.yaml
```

```
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol-hostpath
  namespace: default
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    volumeMounts:		#将宿主机的共享文件或者目录挂载至容器位置
    - name: html
      mountPath: /usr/share/nginx/html/   
  volumes:		#创建存储卷
  - name: html	#存储卷名字，必须定义
    hostPath:
      path: /data/pod/volumel
      type: DirectoryOrCreate		#挂载类型为目录不存在则自动创建
```

```
kubectl apply -f pod-hostpath-vol.yaml
```

> 可以看到Pod 自动挂载本地文件

```
[root@k8s-master volumes]# kubectl get pod -o wide
NAME                            READY   STATUS    RESTARTS   AGE     IP             NODE        NOMINATED NODE   READINESS GATES
myapp-deploy-798dc9b584-dbr9g   1/1     Running   3          5d20h   10.244.2.143   k8s-node2   <none>           <none>
myapp-deploy-798dc9b584-hmvrw   1/1     Running   3          5d20h   10.244.2.141   k8s-node2   <none>           <none>
myapp-deploy-798dc9b584-mknj5   1/1     Running   3          5d20h   10.244.1.158   k8s-node1   <none>           <none>
pod-vol-hostpath                1/1     Running   0          10s     10.244.1.162   k8s-node1   <none>           <none>
tomcat-deploy-567cbb595-4qlcw   1/1     Running   3          5d20h   10.244.2.142   k8s-node2   <none>           <none>
tomcat-deploy-567cbb595-bcwz7   1/1     Running   3          5d20h   10.244.1.157   k8s-node1   <none>           <none>

[root@k8s-master volumes]# curl 10.244.1.162
node1
[root@k8s-master volumes]# kubectl delete -f pod-hostpath-vol.yaml 
pod "pod-vol-hostpath" deleted
[root@k8s-master volumes]# kubectl apply -f pod-hostpath-vol.yaml 
pod/pod-vol-hostpath created
[root@k8s-master volumes]# kubectl get pod -o wide
NAME                            READY   STATUS    RESTARTS   AGE     IP             NODE        NOMINATED NODE   READINESS GATES
myapp-deploy-798dc9b584-dbr9g   1/1     Running   3          5d21h   10.244.2.143   k8s-node2   <none>           <none>
myapp-deploy-798dc9b584-hmvrw   1/1     Running   3          5d21h   10.244.2.141   k8s-node2   <none>           <none>
myapp-deploy-798dc9b584-mknj5   1/1     Running   3          5d21h   10.244.1.158   k8s-node1   <none>           <none>
pod-vol-hostpath                1/1     Running   0          5s      10.244.2.144   k8s-node2   <none>           <none>
tomcat-deploy-567cbb595-4qlcw   1/1     Running   3          5d20h   10.244.2.142   k8s-node2   <none>           <none>
tomcat-deploy-567cbb595-bcwz7   1/1     Running   3          5d20h   10.244.1.157   k8s-node1   <none>           <none>
[root@k8s-master volumes]# curl 10.244.2.144
node2

```

- 当node1节点宕机后，pod就飘到node2节点上，并使用node2节点上的/data/pod/volume1目录。这就有问题了，因为node2节点上的目录并没有同步node1节点上目录的数据，所以出现数据不一致。所以我们需要用到共享存储来做，比如nfs，让两个node节点共享一个存储
- 使用NFS做共享存储 
  我用10.10.10.12（node2）做nfs server端

#### 实验四

安装nfs
```
yum -y install nfs-utils
mkdir /data/volumes
[root@localhost ~]# cat /etc/exports
/data/volumes 10.10.10.0/24(rw,no_root_squash)
#no_root_squash：登入 NFS 主机使用分享目录的使用者，如果是 root 的话，那么对于这个分享的目录来说，他就具有 root 的权限！这个项目『极不安全』，不建议使用！ 
#root_squash：在登入 NFS 主机使用分享之目录的使用者如果是 root 时，那么这个使用者的权限将被压缩成为匿名使用者，通常他的 UID 与 GID 都会变成 nobody 那个系统账号的身份；

systemctl start nfs && systemctl status nfs
nfs端口：2049
#在node1安装nfs-utils
在两台机器上挂载
[root@node1 ~]# mount -t nfs 10.10.10.40:/data/volumes /mnt
```
在master上
```
[root@master ~]# kubectl explain pods.spec.volumes.nfs
[root@master volumes]# vim pod-vol-nfs.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol-nfs
  namespace: default
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html/
  volumes:
  - name: html
    nfs:
      path: /data/volumes
      server: k8s-node2.com
```
启动pod-nfs
```
[root@master volumes]# kubectl apply -f pod-vol-nfs.yaml
[root@master volumes]# curl curl 10.244.1.164
This is nfs!
```

### PV和PVC 

不过nfs自身没有冗余能力，所以如果nfs宕机了，数据就丢了，因此我们一般用glusterfs或者cephfs分布式存储。

PV和PVC 

```
背景：k8s提供了emptyDir,hostPath,rbd,cephfs等存储方式供容器使用,不过这些存储方式都有一个缺点:开发人员必须得知指定存储的相关配置信息,才能使用存储.例如要使用cephfs,Pod的配置信息就必须指明cephfs的monitor,user,selectFile等等,而这些应该是系统管理员的工作.对此,k8s提供了两个新的API资源:PersistentVolume,PersistentVolumeClaim 
用户只需要挂载pvc到容器中而不需要关注存储卷采用何种技术实现。pvc和pv的关系与pod和node关系类似，前者消耗后者的资源。pvc可以向pv申请指定大小的存储资源并设置访问模式。
```

```
PV(PersistentVolume)是管理员已经提供好的一块存储.在k8s集群中,PV像Node一样,是一个资源 
PVC(PersistentVolumeClaim)是用户对PV的一次申请.PVC对于PV就像Pod对于Node一样,Pod可以申请CPU和Memory资源,而PVC也可以申请PV的大小与权限
```

```
有了PersistentVolumeClaim,用户只需要告诉Kubernetes需要什么样的存储资源,而不必关心真正的空间从哪里分配,如何访问等底层细节信息;这些Storage Provider的底层信息交给管理员来处理,只有管理员才应该关心创建PersistentVolume的细节信息 
```

```
在定义pod时，我们只需要说明我们要一个多大的存储卷就行了。pvc存储卷必须与当前namespace的pvc建立直接绑定关系。pvc必须与pv建立绑定关系。而pv是真正的某个存储设备上的空间。
```

- 查看

```
[root@master volumes]# kubectl explain pods.spec.volumes.persistentVolumeClaim
```

一个pvc和pv是一一对应关系，一旦一个pv被一个pvc绑定了，那么这个pv就不能被其他pvc绑定了。 
一个pvc是可以被多个pod所访问的。

#### PV和PVC实验 

在存储机器（10.10.10.12）上建立如下几个目录

mkdir -p /data/volumes/v{1,2,3,4,5}

```
cat /etc/exports
/data/volumes/v1 10.10.10.0/24(rw,no_root_squash)
/data/volumes/v2 10.10.10.0/24(rw,no_root_squash)
/data/volumes/v3 10.10.10.0/24(rw,no_root_squash)
/data/volumes/v4 10.10.10.0/24(rw,no_root_squash)
/data/volumes/v5 10.10.10.0/24(rw,no_root_squash)
```

```
#no_root_squash：登入 NFS 主机使用分享目录的使用者，如果是 root 的话，那么对于这个分享的目录来说，他就具有 root 的权限！这个项目『极不安全』，不建议使用！ 
#root_squash：在登入 NFS 主机使用分享之目录的使用者如果是 root 时，那么这个使用者的权限将被压缩成为匿名使用者，通常他的 UID 与 GID 都会变成 nobody 那个系统账号的身份；
[root@localhost ~]# exportfs  -arv #不重启服务
exporting 10.10.10.0/24:/data/volumes/v5
exporting 10.10.10.0/24:/data/volumes/v4
exporting 10.10.10.0/24:/data/volumes/v3
exporting 10.10.10.0/24:/data/volumes/v2
exporting 10.10.10.0/24:/data/volumes/v1
[root@localhost ~]# showmount  -e
Export list for localhost.localdomain:
/data/volumes/v5 10.10.10.0/24
/data/volumes/v4 10.10.10.0/24
/data/volumes/v3 10.10.10.0/24
/data/volumes/v2 10.10.10.0/24
/data/volumes/v1 10.10.10.0/24
#查看pv中定义nfs的字段
[root@master volumes]#  kubectl explain pv.spec.nfs
path：必须定义，nfs的共享路径
server： nfs服务地址
readOnly：是否只读 true/false
```

查看pv的访问控制

```
[root@master volumes]#  kubectl explain pv.spec.accessModesKIND:     PersistentVolumeVERSION:  v1FIELD:    accessModes <[]string>DESCRIPTION:     AccessModes contains all ways the volume can be mounted. More info:     https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes
```

accessModes模式有： 

```
ReadWriteOnce：单路读写，可以简写为RWO 
ReadOnlyMany：多路只读，可以简写为ROX 
ReadWriteMany ：多路读写，可以简写为RWX 
```

不同类型的存储卷支持的accessModes也不同 

不同类型的存储卷支持的accessModes也不同 

##### 定义5个pv

```
vim pv-demo.yaml
```

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001 #注意，定义pv时一定不要加名称空间；因为pv时属于整个集群的，而不是属于某个名称空间
  labels:
    name: pv001
spec:
  nfs:
    path: /data/volumes/v1
    server: k8s-node2.com
  accessModes: ["ReadWriteMany","ReadWriteOnce"] #多人读写，一人读写，简称RWX，RWO
  capacity:
    storage: 1Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
  labels:
    name: pv002
spec:
  nfs:
    path: /data/volumes/v2
    server: k8s-node2.com
  accessModes: ["ReadWriteOnce"] #一人读写
  capacity:
    storage: 2Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv003
  labels:
    name: pv003
spec:
  nfs:
    path: /data/volumes/v3
    server: k8s-node2.com
  accessModes: ["ReadOnlyMany","ReadWriteOnce"] #多人只读，一人读写
  capacity:
    storage: 1Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv004
  labels:
    name: pv004
spec:
  nfs:
    path: /data/volumes/v4
    server: k8s-node2.com
  accessModes: ["ReadOnlyMany"] #多人只读，ROX
  capacity:
    storage: 1Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv005
  labels:
    name: pv005
spec:
  nfs:
    path: /data/volumes/v5
    server: k8s-node2.com
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 1Gi
```

```
kubectl  get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM           STORAGECLASS   REASON   AGE
pv001   1Gi        RWO,RWX        Retain           Available                                           16h
pv002   2Gi        RWO            Retain           Available                                           16h
pv003   1Gi        RWO,ROX        Retain           Available                                           16h
pv004   1Gi        ROX            Retain           Available                                           16h
pv005   1Gi        RWO,RWX        Retain           Available                                           16h
```

上面RECLAIM POLICY这个字段时回收策略 
回收策略：如果某个pvc在pv里面存数据了，后来pvc删了，那么 pv里面的数据怎么处理呢。有如下几种策略： 
reclaim_policy：即pvc删了，但是pv里面的数据不删除，还保留着。（默认策略） 
recycle：即pvc删了，那么就把pv里面的数据也删了。 
delete：即pvc删了，那么就把pv也删了。

##### 创建PVC

```
[root@master volumes]# kubectl explain pvc.spec
[root@master volumes]# kubectl explain pods.spec.volumes.persistentVolumeClaim
```

```
vim pod-vol-pvc.yaml
```

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc
  namespace: default
spec:
  accessModes: ["ReadWriteMany"] #一定时pv的子集
  resources: #资源限制
    requests:
      storage: 1Gi #表示我要pvc为1G的空间
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol-pvc
  namespace: default
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html/
  volumes:
  - name: html
    persistentVolumeClaim:
     claimName: mypvc

```

```
kubectl get pvc
NAME    STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mypvc   Bound    pv001    1Gi        RWO,RWX                       15m
```

```
kubectl get pod
NAME                                READY   STATUS    RESTARTS   AGE
pod/pod-vol-pvc                     1/1     Running   0          12m
```

生产上，pv并不属于node节点，而是独立于node节点的。所以，node节点坏了，pv里面的数据还在。另外，pod才是属于node节点的。 
一个pvc只能绑定一个pv；所以当你把pvc删除之后，只能重新启动pv才能继续绑定，但是多个pod可以绑定同一个pvc

```
参数说明：
（1）访问模式
spec:
capacity:
storage: 10Gi #容量
accessModes: #访问模式
– ReadWriteMany
访问模式有三种：
ReadWriteOnce #可读写仅一次
ReadOnlyMany #只读
ReadWriteMany #可读写
（2）回收策略
pv可以设置三种回收策略：Retain（默认），Recycle和Delete。
– retain：允许人工处理保留的数据。
– recycle：将执行清除操作，之后可以被新的pvc使用，需要插件支持
– delete：将删除pv和外部关联的存储资源，需要插件支持。
网上资料：目前只有NFS和HostPath类型卷支持回收策略，AWS EBS,GCE PD,Azure Disk和Cinder支持删除(Delete)策略。
（3）pv状态
Available： pv可用
Bound： pv已被绑定到某pvc
Released： pv已经被释放，但需要手工处理
Faild：pv不可用
```

#### pv和pvc的生命周期

```
供应准备。通过集群外的存储系统或者云平台来提供存储持久化支持。
- 静态提供：管理员手动创建多个PV，供PVC使用。
- 动态提供：动态创建PVC特定的PV，并绑定。
绑定。用户创建pvc并指定需要的资源和访问模式。在找到可用pv之前，pvc会保持未绑定状态。
使用。用户可在pod中像volume一样使用pvc。
释放。用户删除pvc来回收存储资源，pv将变成“released”状态。由于还保留着之前的数据，这些数据需要根据不同的策略来处理，否则这些存储资源无法被其他pvc使用。
回收策略如上所示
```

### configMap 资源

多生产环境中的应用程序配置较为复杂，可能需要多个config文件、命令行参数和环境变量的组合。使用容器部署时，把配置应该从应用程序镜像中解耦出来，以保证镜像的可移植性。尽管Secret允许类似于验证信息和秘钥等信息从应用中解耦出来，但在K8S1.2前并没有为了普通的或者非secret配置而存在的对象。在K8S1.2后引入ConfigMap来处理这种类型的配置数据。自1.14 `kubectl`开始支持`kustomization.yaml`

`https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/`

```
kubectl create configmap nginx-config --from-literal=nginx_port=80 --from-literal=server_name=myapp.yong.com
此时nginx_port为键，80值
kubectl get cm
kubectl describe cm nginx-config 

```

```
vim nginx-www
```

```
server {
    server_name myapp.yong.com;
    listen 80;
    root /data/web/html;
}
```

```
kubectl create configmap nginx-www --from-file=nginx-www
# 这样创建nginx-www这个文件名就是键
kubectl create configmap nginx-www --from-file=www.conf=./nginx-www
# 这样创建 www.conf 就是键
```

#### 实验一

我们创建的configmap，可用ENV等方式注入到Pod中。 

```
cat pod-configmap.yaml 
apiVersion: v1 
kind: Pod
metadata:
  name: pod-cm-1
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/created-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports: 
    - name: http
      containerPort: 80
    env: 
    - name: NGINX_SERVER_PORT
      valueFrom: # kubectl explain pods.spec.containers.env.valueFrom.configMapKeyRef
        configMapKeyRef:
          name: nginx-config
          key: nginx_port
    - name: NGINX_SERVER_NAME
      valueFrom:
        configMapKeyRef:
          name: nginx-config
          key: server_name
```

```
kubectl exec -it pod-cm-1 -- /bin/sh
# env
NGINX_SERVER_PORT=80
NGINX_SERVER_NAME=myapp.yong.com
[root@master configmap]# kubectl edit cm nginx-config
configmap/nginx-config edited
 通过edit方式编辑的配置文件，在Pod里面不会立即理解生效，需要重启pod才能生效。 
kubectl delete -f pod-configmap.yaml 
pod "pod-cm-1" deleted
```

#### 实验二

配置mount存储卷的方法把configmap注入到pod中。

```shell
cat pod-configmap-2.yaml 
apiVersion: v1 
kind: Pod
metadata:
  name: pod-cm-2
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/created-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports: 
    - name: http
      containerPort: 80
    volumeMounts:
    - name: nginxconf
      mountPath: /etc/nginx/config.d/
      readOnly: true
  volumes:
  - name: nginxconf
    configMap:
      name: nginx-config
```

此时可以在Pod中看到两个链接文件，改个端口，然后再到pod里面，多等一会就会看到刚才修改的在pod里面生效了

#### 实验三

把 nginx-www 注入到pod中的/etc/nginx/conf.d/ 运行为虚拟主机

```
kubectl describe cm nginx-www
Name:         nginx-www
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
# 要保证键为*.conf  
www.conf:
----
server {
    server_name myapp.yong.com;
    listen 80;
    root /data/web/html;
}

Events:  <none>

```

创建pod

```
cat pod-configmap-3.yaml 
apiVersion: v1 
kind: Pod
metadata:
  name: pod-cm-3
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/created-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports: 
    - name: http
      containerPort: 80
    volumeMounts:
    - name: nginxconf
      mountPath: /etc/nginx/conf.d/
      readOnly: true
  volumes:
  - name: nginxconf
    configMap:
      name: nginx-www
```

```
kubectl get pod -o wide
NAME       READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
pod-cm-2   1/1     Running   0          22m   10.244.1.198   k8s-node1   <none>           <none>
pod-cm-3   1/1     Running   0          40s   10.244.2.46    k8s-node2   <none>           <none>
# node节点添加hosts映射
echo "10.244.2.46 myapp.yong.com" >> /etc/hosts
在pod内创建网页目录
mkdir -p /data/web/html
echo "myapp.yong.com" > /data/web/html/index.html
```

```
kubectl edit cm nginx-www
修改端口为8080 ,过一会pos 中就会变成8080
kubectl describe cm nginx-w
Name:         nginx-www
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
www.conf:
----
server {
    server_name myapp.luyou.com;
    listen 8080;
    root /data/web/html;
}

Events:  <none>
```

#### 实验四

如果我们期望只注入部分，而非所有，该怎么做呢？

```
[root@master configmap]# kubectl explain pods.spec.volumes.configMap.items
[root@master configmap]# kubectl create secret generic --help
```

- secret
  功能和configmap一样，只不过secret配置中心存储的配置文件不是明文的。

```
 [root@master configmap]# kubectl create secret --help
 generic：保存密码用的类型
 tls：保存证书用的类型
 docker-registry：保存docker认证信息用的类型，比如从私有docker仓库拉镜像时，就用这个类型。
 备注：k8s拖镜像的进程是kublete
 
如果是从私有仓库拉镜像，就用imagePullSecrets存登录验证的信息
 [root@master configmap]#  kubectl explain pods.spec.imagePullSecrets
```

- 例子命令行创建

```
[root@master secret]# kubectl create secret generic mysql-root-password --from-literal=password=123456
secret/mysql-root-password created

[root@master secret]# kubectl get secret
NAME                    TYPE                                  DATA      AGE
default-token-5r85r     kubernetes.io/service-account-token   3         19d
mysql-root-password     Opaque                                1         40s
tomcat-ingress-secret   kubernetes.io/tls                     2         2d

[root@master secret]# kubectl describe secret mysql-root-password
Name:         mysql-root-password
Namespace:    default
Labels:       <none>
Annotations:  <none>
Type:  Opaque
Data
====
password:  6 bytes

看到password的内容就是base64加密的形式了。
```

通过命令查看此资源的yaml

```
[root@master secret]# kubectl get secret mysql-root-password -o yaml
apiVersion: v1
data:
  password: MTIzNDU2
kind: Secret
metadata:
  creationTimestamp: "2019-06-15T10:10:34Z"
  name: mysql-root-password
  namespace: default
  resourceVersion: "429046"
  selfLink: /api/v1/namespaces/default/secrets/mysql-root-password
  uid: d0ac7198-8f55-11e9-83eb-000c29ee3e00
type: Opaque

# 看到密码是加密的，其实是可以解密的，可见是个伪君子
[root@master secret]#  echo MTIzNDU2 |base64 -d
123456
```

#### 实验五

演示通过env方式注入到pod里面

```
vim pod-secret-1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-1
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    yong.com/created-by: "cluster-admin" #这是注解的键值对
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    env: #这是一个容器的属性
    - name: MYSQL_ROOT_PASSWORD
      valueFrom: #kubectl explain pods.spec.containers.env.valueFrom
        secretKeyRef: #表示我们要引用一个configmap来获取数据
          name: mysql-root-password #这是configmap的名字，也就是通过kubectl get cm获取的名字
          key: password #通过kubectl describe cm nginx-config的键
    #定义第二个环境变量
    #- name: NGINX_SERVER_NAME
    #  valueFrom: #kubectl explain pods.spec.containers.env.valueFrom
    #    configMapKeyRef:
    #      name: nginx-config
    #      key: server_name


[root@master secret]# kubectl apply -f pod-secret-1.yaml
pod/pod-secret-1 created

[root@master configmap]# kubectl get pods
NAME                             READY     STATUS             RESTARTS   AGE
pod-secret-1                     1/1       Running            0          1m

[root@master secret]# kubectl exec -it pod-secret-1 -- /bin/sh
/ # env
# printenv
MYSQL_ROOT_PASSWORD=123456

看到secret通过env的方式，是以明文注入到pod里面的
另外，secret还可以用mount的方式注入pod中，这部分略，如需要请参考本小节的configmap的相关例子。 
```

# statefulSet

### (有状态应用集合控制器)

### 概述

1、在应用程序中，可以分为有状态应用和无状态应用，无状态应用更关注于群体，任何一个成员都可以被取代；而有状态的应用更关注于个体。
2、像我们之前的RC、Deployment、DaemonSet控制的nginx等都是属于无状态的；他们所管理的pod的IP、名字、启动停止顺序等都是随机的。
3、像mysql、redis，zookeeper等都属于有状态应用，他们有的还有主从之分、先后顺序之分。这时候就需要statefulSet，顾名思义为有状态的集合
4、statefulset控制器能实现有状态应用的管理，但实现起来也是非常麻烦的。需要把我们运维管理的过程写入脚本并注入到statefulset中才能使用。虽然互联网上有人做好了stateful的脚本，但是还是建议大家不要轻易的把redis、mysql等这样有状态的应用迁移到k8s上。
5、StatefulSet本质上是Deployment的一种变体，在v1.9版本中已成为GA版本，它为了解决有状态服务的问题，它所管理的Pod拥有固定的Pod名称，启停顺序，在StatefulSet中，Pod名字称为网络标识(hostname)，还必须要用到共享存储
6、在Deployment中，与之对应的服务是service，而在StatefulSet中与之对应的headless service，headless service，即无头服务，与service的区别就是它没有Cluster IP，解析它的名称时将返回该Headless Service对应的全部Pod的Endpoint列表。除此之外，StatefulSet在Headless Service的基础上又为StatefulSet控制的每个Pod副本创建了一个DNS域名，这个域名的格式为：

```
$(podname).(headless server name)   
FQDN:$(podname).(headless server name).namespace.svc.cluster.local
```

#### statefulSet主要管理的特效的应用

```
每一个Pod稳定且有唯一的网络标识符；
稳定且持久的存储设备；
要求有序、平滑的部署和扩展；
要求有序、平滑的终止和删除；
有序的滚动更新，应该先更新从节点，再更新主节点；
```
#### statefulSet由以下组件组成

```
headless service（无头的服务，即没名字）；
statefulset控制器
volumeClaimTemplate（存储卷申请模板，因为每个pod要有专用存储卷，而不能共用存储卷,会自动创建pvc，所以我们在没有存储类的情况下，我们需要提前创建好pv）
```

#### 查看statefulSet的定义

```
kubectl explain sts
KIND:     StatefulSet
VERSION:  apps/v1
DESCRIPTION:
     StatefulSet represents a set of pods with consistent identities. Identities
     are defined as: - Network: A single stable DNS and hostname. - Storage: As
     many VolumeClaims as requested. The StatefulSet guarantees that a given
     network identity will always map to the same storage identity.
FIELDS:
   apiVersion   <string>
   kind <string>
   metadata <Object>
   spec <Object>
   status   <Object>


[root@k8s-master ~]# kubectl explain statefulset.spec
KIND:     StatefulSet
VERSION:  apps/v1
RESOURCE: spec <Object>
DESCRIPTION:
     Spec defines the desired identities of pods in this set.
     A StatefulSetSpec is the specification of a StatefulSet.


[root@master statefulSet]# kubectl explain sts.spec
FIELDS:
   podManagementPolicy  <string>     #Pod管理策略,默认OrderedReady，有序进行0-5，有序删除5-0
   replicas <integer>                #副本数量
   revisionHistoryLimit <integer>    #历史版本限制
   selector <Object> -required-      #选择器，必选项
   serviceName  <string> -required-  #服务名称，必选项
   template <Object> -required-      #模板，必选项
   updateStrategy   <Object>         #更新策略
   volumeClaimTemplates <[]Object>   #存储卷申请模板，列表对象形式
```



#### 实验一

statefulSet

需要创建5个符合条件的 pv

```
apiVersion: v1
kind: Service
metadata:
  name: myapp-svc
  labels:
    app: myapp-svc
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: myapp-pod
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: myapp
spec:
  serviceName: myapp-svc
  replicas: 2
  selector:
    matchLabels:
      app: myapp-pod
  template:
    metadata:
      labels:
        app: myapp-pod
    spec:
      containers:
      - name: myapp
        image: ikubernetes/myapp:v1
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: myappdata
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates: #存储卷申请模板，可以为每个pod定义volume，可以为pod所在的名称空间自动创建pvc
  - metadata:
      name: myappdata #这里实质上是定义了pvc的名字
    spec:
      accessModes: ["ReadWriteOnce"]
      #storageClassName: "gluster-dynamic"
      resources:
        requests:
          storage: 2Gi

```

```
kubectl get pod,pv,pvc,sts,svc
NAME          READY   STATUS    RESTARTS   AGE
pod/myapp-0   1/1     Running   0          15m
pod/myapp-1   1/1     Running   0          10m

NAME                     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                       STORAGECLASS   REASON   AGE
persistentvolume/pv001   4Gi        RWO,RWX        Recycle          Available                               slow                    15m
persistentvolume/pv002   2Gi        RWO            Retain           Bound       default/myappdata-myapp-0                           15m
persistentvolume/pv003   1Gi        RWO,ROX        Retain           Available                                                       15m
persistentvolume/pv004   1Gi        ROX            Retain           Available                                                       15m
persistentvolume/pv005   3Gi        RWO,RWX        Retain           Bound       default/myappdata-myapp-1                           15m

NAME                                      STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/myappdata-myapp-0   Bound     pv002    2Gi        RWO                           15m
persistentvolumeclaim/myappdata-myapp-1   Bound     pv005    3Gi        RWO,RWX                       15m
persistentvolumeclaim/myappdata-myapp-2   Pending                                                     11m

NAME                     READY   AGE
statefulset.apps/myapp   2/2     15m

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   36d
service/myapp-svc    ClusterIP   None         <none>        80/TCP    15m

```

如果此时我们删除了pod，并不会删除了数据，因为pvc还在，所以再重新启动的时候数据还能恢复 

查看生成的dns

```
ubectl exec -it myapp-0 -- /bin/sh
/ # 
/ # nslookup myapp-0.myapp-svc.default.svc.cluster.local
nslookup: can't resolve '(null)': Name does not resolve

Name:      myapp-0.myapp-svc.default.svc.cluster.local
Address 1: 10.244.2.49 myapp-0.myapp-svc.default.svc.cluster.local
/ # nslookup myapp-1.myapp-svc.default.svc.cluster.local
nslookup: can't resolve '(null)': Name does not resolve

Name:      myapp-1.myapp-svc.default.svc.cluster.local
Address 1: 10.244.1.210 myapp-1.myapp-svc.default.svc.cluster.local
/ # exit

```

下面扩展myapp pod为5个：

```
kubectl scale sts myapp --replicas=5  
kubectl patch sts myapp -p '{"spec":{"replicas":5}}'
```

```
kubectl  get pod
NAME      READY   STATUS    RESTARTS   AGE
myapp-0   1/1     Running   0          39m
myapp-1   1/1     Running   0          39m
myapp-2   1/1     Running   0          36m
myapp-3   1/1     Running   0          36m
myapp-4   1/1     Running   0          37m
```

### 滚动更新

```
kubectl explain sts.spec.updateStrategy.rollingUpdate
```

Partitions：通过指定 .spec.updateStrategy.rollingUpdate.partition 来对 RollingUpdate 更新策略进行分区，如果指定了分区，则当 StatefulSet 的 .spec.template 更新时，具有大于或等于分区`序号`数的所有 Pod 将被更新 
具有小于分区的序数的所有 Pod 将不会被更新，即使删除它们也将被重新创建。如果 StatefulSet 的.spec.updateStrategy.rollingUpdate.partition 大于其 .spec.replicas，则其 .spec.template 的更新将不会传播到 Pod。在大多数情况下，不需要使用分区

```
更新策略
当前我们有五个pod，所以只会更新myapp-4
[root@master stateful]# kubectl patch sts myapp -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":4}}}}'
statefulset.apps/myapp patched
下面把镜像升级为v2版本
[root@master statefulSet]# kubectl set image sts/myapp myapp=registry.cn-hangzhou.aliyuncs.com/zhongma/nginx:v2
[root@master ~]# kubectl get sts -o wide
NAME      DESIRED   CURRENT   AGE       CONTAINERS   IMAGES
myapp     2         2         1h        myapp        ikubernetes/myapp:v2
[root@master ~]# kubectl get pods myapp-4 -o yaml
 containerStatuses:
 - containerID: docker://898714f2e5bf4f642e2a908e7da67eebf6d3074c89bbd0d798d191a2061a3115
    image: ikubernetes/myapp:v2
```

### 总结

#### 为什么要使用headless service无头服务

```
在用Deployment时，每一个Pod名称是没有顺序的，是随机字符串，因此是Pod名称是无序的，但是在statefulset中要求必须是有序 ，每一个pod不能被随意取代，pod重建后pod名称还是一样的。而pod IP是变化的，所以是以Pod名称来识别。pod名称是pod唯一性的标识符，必须持久稳定有效。这时候要用到无头服务，它可以给每个Pod一个唯一的名称 。
```
#### 为什么需要volumeClaimTemplate？

```
对于有状态的副本集都会用到持久存储，对于分布式系统来讲，它的最大特点是数据是不一样的，所以各个节点不能使用同一存储卷，每个节点有自已的专用存储，但是如果在Deployment中的Pod template里定义的存储卷，是所有副本集共用一个存储卷，数据是相同的，因为是基于模板来的 ，而statefulset中每个Pod都要自已的专有存储卷，所以statefulset的存储卷就不能再用Pod模板来创建了，于是statefulSet使用volumeClaimTemplate，称为卷申请模板，它会为每个Pod生成不同的pvc，并绑定pv，从而实现各pod有专用存储。这就是为什么要用volumeClaimTemplate的原因。
```
#### 查看pvc,这是k8s自己创建的

```
[root@master ~]# kubectl  get pvc
NAME                STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
myappdata-myapp-0   Bound    pv002    5Gi        RWO                           107m
myappdata-myapp-1   Bound    pv003    5Gi        RWO,ROX                       107m

如果集群中没有StorageClass的动态供应PVC的机制，也可以提前手动创建多个PV、PVC，手动创建的PVC名称必须符合之后创建的StatefulSet命名规则：(volumeClaimTemplates.name)-(pod_name)也就是如上
```
#### 规律

```
1、匹配Pod name(网络标识)的模式为：$(statefulset名称)-$(序号)，比如上面的示例：myappdata-myapp-0 myappdata-myapp-1

2、StatefulSet为每个Pod副本创建了一个DNS域名，这个域名的格式为： $(podname).(headless server name)，也就意味着服务间是通过Pod域名来通信而非Pod IP，因为当Pod所在Node发生故障时，Pod会被飘移到其它Node上，Pod IP会发生变化，但是Pod域名不会有变化

3、StatefulSet使用Headless服务来控制Pod的域名，这个域名的FQDN为：$(service name).$(namespace).svc.cluster.local，其中，“cluster.local”指的是集群的域名。

4、根据volumeClaimTemplates，为每个Pod创建一个pvc，pvc的命名规则匹配模式：(volumeClaimTemplates.name)-(pod_name)，比如上面的volumeMounts.name=myappdata,pod name=myappdata-app[0-1],因此创建出来的pvc为myappdata-myapp-0 myappdata-myapp-1

5、删除Pod不会删除其pvc，手动删除pvc将自动释放pv。
```
#### statefulSet的启停顺序

```
有序部署：部署StatefulSet时，如果有多个Pod副本，它们会被顺序地创建（从0到N-1）并且，在下一个Pod运行之前所有之前的Pod必须都是Running和Ready状态

有序删除：当Pod被删除时，它们被终止的顺序是从N-1到0。

有序扩展：当对Pod执行扩展操作时，与部署一样，它前面的Pod必须都处于Running和Ready状态。
```
#### statefulSet Pod 管理策略

```
在v1.7以后，通过允许修改Pod排序策略，同时通过.spec.podManagementPolicy字段确保其身份的唯一性。
OrderedReady：上述的启停顺序，默认设置。

Parallel：告诉StatefulSet控制器并行启动或终止所有Pod，并且在启动或终止另一个Pod之前不等待前一个Pod变为Running and Ready或完全终止。
```
#### statefulSet使用场景

```
稳定的持久化存储，即Pod重新调度后还是能访问到相同的持久化数据，基于PVC来实现。
稳定的网络标识符，即Pod重新调度后其PodName和HostName不变。
有序部署，有序扩展，基于init containers来实现。
有序收缩
```
#### 更新策略

```
在Kubernetes 1.7及更高版本中，通过.spec.updateStrategy字段允许配置或禁用Pod、labels、source request/limits、annotations自动滚动更新功能。

OnDelete：通过.spec.updateStrategy.type 字段设置为OnDelete，StatefulSet控制器不会自动更新
StatefulSet中的Pod。用户必须手动删除Pod，以使控制器创建新的Pod。

RollingUpdate：通过.spec.updateStrategy.type 字段设置为RollingUpdate，实现了Pod的自动滚动更新，如果.spec.updateStrategy未指定，则此为默认策略。
StatefulSet控制器将删除并重新创建StatefulSet中的每个Pod。它将以Pod终止（从最大序数到最小序数）的顺序进行，一次更新每个Pod。在更新下一个Pod之前，必须等待这个Pod Running and Ready。

Partitions：通过指定 .spec.updateStrategy.rollingUpdate.partition 来对 RollingUpdate 更新策略进行分区，如果指定了分区，则当 StatefulSet 的 .spec.template 更新时，具有大于或等于分区序数的所有 Pod 将被更新；

具有小于分区的序数的所有 Pod 将不会被更新，即使删除它们也将被重新创建。如果 StatefulSet 的 .spec.updateStrategy.rollingUpdate.partition 大于其 .spec.replicas，则其 .spec.template 的更新将不会传播到 Pod。在大多数情况下，不需要使用分区。
```













































