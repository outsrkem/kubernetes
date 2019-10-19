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

### 资源清单的组成部分

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

---

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


### 标签命令
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



####  pod打标签
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
####  node打标签

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
### 节点选择器

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

#### 创建pod

初始化容器

容器探测：

​	liveness

​	readiness



#### 以下也是spec资源属性配置中比较重要
```
restartPolicy:    # 容器策略，以下三种
  Always          # 默认的：如果挂了总是重启
  onfailure       # 只有状态为错误时才重启
  never           # 从不重启 挂了就挂
```

---

### Pod中的容器监控检测
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

## 2019年10月13日

### Pod 控制器

此前直接创建的Pod 叫做自助式 pod 删除之后不会重建，是直接向apiserver请求创建的，并非由控制器管理

代替用户创建Pod 副本

#### Pod 控制器：

作用：使我们创建的资源一直处于我们所期望的状态，帮助我们管理Pod，分为以下几种

- ReplicationController:  老版的，基本上废弃 

- ReplicaSet: 新的，主要帮用户管理无状态的pod资源，精确反应用户所定义的目标数量它由三个组件组成 

  - 1、用户期望的副本数
  - 2、标签选择器，以便选定由自己管理和控制的pod副本。如果说通过标签选择器选到的副本数量小于指定数量，那么它将用第三个组件来完成pod资源的新建
  - 3、Pod资源模板template
- Deployments: 工作再ReplicaSet之上，它控制ReplicaSet,通过ReplicaSet管理pod，支持replicaSet所有功能，并且支持滚动升级等，它目前是管理无状态pod最好的控制器 

- DaemonSet: (用来确保集群每一个节点只运行一个特定的Pod 副本【特定的系统级任务】)

- Job：任务完成就退出，不会重启新的pod，一次性的pod
- Cronjob：周期性运行，和Job都是无需持续性运行的pod
- StatefulSet：管理有状态的，比如redis  mysql挂了 重启之后需要重新导入数据的

#### 控制器示例

 - ReplicaSet
    可以通过以下命令查看所需要的字段
```
#ReplicaSet可以简称为rs
kubectl explan rs.spec
#他的一级标签也是apiVersion、kind、metadata、spec、status
replicas:副本数 默认是1
selector：标签选择器（非常重要）
template：pod模板
```
 - ReplicaSet示例
```
vim rs-myapp.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
    name: myapp
    namespace: default
spec: #这里是指的是控制器的spec
    replicas: 2 #几个副本
    selector: #标签选择器
        matchLabels: #攥着键值对模式
            app: myapp
            release: canary
    template: #pod模板
        metadata:
            name: myapp-pod
            labels: #要跟标签选择器是一样的
                 app: myapp
                 release: canary
        spec: #这里是pod的spec
            containers:
            - name: myapp-container
              image: registry.cn-hangzhou.aliyuncs.com/zhongma/nginx:v1
              imagePullPolicy: IfNotPresent
              ports:
              - name: http
                containerPort: 80
            imagePullSecrets: #定义私库拉取镜像
            - name: myhub
              ...(根据需求定义)
扩容：数量从2扩容至5
kubectl edit rs myapp 
也可以通过命令行更改
比如更换镜像：
kubectl set image命令，用法 --help
更改里面的字段用打补丁的方式：
kubectl patch --help查看用法
#需要认为干预的去滚动升级

#创建一个svc，便于查看实验结果
vim rs-svc.yaml
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
#写一个死循环：
[root@master rs]# while true;do curl 10.10.10.20:30090;sleep 1;done
#杀死pod观察
```

#### ReplicaSet的更新升级总结
    滚动升级改镜像文件的版本，但是正在运行的还是旧版本，杀了重启之后就会变了，需要人为参与，不智能

---

#### Deployment
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
    strategy: #更新策略
        rollingUpdate:  #默认更新力度由于replicas为3,则整个升级,pod个数2-4个之间
            maxSurge: 1      #滚动升级时会先启动1个pod
            maxUnavailable: 1 #滚动升级时允许的最大Unavailable的pod个数3
    selector: #标签选择器
        matchLabels: #攥着键值对模式
            app: myapp
            release: canary
    template: #pod模板
        metadata:
            name: myapp-pod
            labels: #要跟标签选择器是一样的
                 app: myapp
                 release: canary
        spec: #这里是p3od的spec
            containers:
            - name: myapp
              image: registry.cn-hangzhou.aliyuncs.com/zhongma/nginx:v1
              imagePullPolicy: IfNotPresent
              ports:
              - name: http
                containerPort: 80
            imagePullSecrets: #定义私库拉取镜像
            - name: myhub
---
#为验证实验结果，我创建了svc可以通过访问网页查看
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
[root@master deployment]# kubectl  get pod
NAME                           READY   STATUS    RESTARTS   AGE
myapp-deploy-f5885857b-mssmh   1/1     Running   0          5m52s
myapp-deploy-f5885857b-mwmvv   1/1     Running   0          5m52s
```
修改清单文件，把replicas数字改为3，然后执行kubectl apply -f deploy-demo.yaml 即可使配置文件里的内容生效
```
#查看事件
[root@master ~]# kubectl describe deploy myapp-deploy
#-l使用标签过滤 -w是动态监控
[root@master deployment]# kubectl  get rs -o wide
NAME                     DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                                               SELECTOR
myapp-deploy-f5885857b   3         3         3       16m   myapp        registry.cn-hangzhou.aliyuncs.com/zhongma/nginx:v1   app=myapp,pod-template-hash=f5885857b,release=canary
```
查看滚动更新的历史
```
[root@master deployment]# kubectl  rollout  history deployment myapp-deploy
deployment.extensions/myapp-deploy 
REVISION  CHANGE-CAUSE
1         <none>
```
 下面我们把deployment改成5个：我们可以使用vim  deploy-demo.yaml方法，把里面的replicas改成5。当然，还可以使用另外一种方法，就patch方法，举例如下。
```
 [root@master deployment]# kubectl  patch deployment myapp-deploy -p '{"spec":{"replicas":5}}'
deployment.extensions/myapp-deploy patched
```
查看
```
[root@master deployment]# kubectl  get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
myapp-deploy   5/5     5            5           23m

[root@master deployment]# kubectl  get pods
NAME                           READY   STATUS    RESTARTS   AGE
myapp-deploy-f5885857b-8xd74   1/1     Running   0          59s
myapp-deploy-f5885857b-bqspv   1/1     Running   0          59s
myapp-deploy-f5885857b-htmcg   1/1     Running   0          12m
myapp-deploy-f5885857b-mssmh   1/1     Running   0          23m
myapp-deploy-f5885857b-mwmvv   1/1     Running   0          23m
```
下面更改策略：
```
[root@master deployment]#  kubectl patch deployment myapp-deploy -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavaliable":0}}}}'
deployment.extensions/myapp-deploy patched
strategy：表示策略
maxSurge：对应更新过程中，最多能超出我们定义的目标副本数有几个pod；可以定义数量，也可以定义百分比
maxUnavaliable：表示更新过程种最多有几个pod不可用，可以定义数量，也可以定义百分比
```
查看更新事件：
```
kubectl describe deployment myapp-deploy
RollingUpdateStrategy:  25% max unavailable, 1 max surge
```
下面用set image命令，将镜像myapp升级为v2版本，并且将myapp-deploy控制器标记为暂停。被pause命令暂停的资源不会被控制器协调使用，可以使“kubectl rollout resume”命令恢复已暂停资源。
```
 kubectl set image deployment myapp-deploy myapp=registry.cn-hangzhou.aliyuncs.com/zhongma/nginx:v2 && kubectl rollout pause deployment myapp-deploy
 kubectl get pod -w #监控
 
 这个时候新开一个终端打开，另一个终端执行
 [root@master ~]# kubectl rollout resume deployment myapp-deploy #停止暂停
deployment.extensions/myapp-deploy resumed
  kubectl rollout status deployment myapp-deploy #监控更新过程（删除一个更新一个）
 [root@master deployment]# kubectl  rollout status deployment myapp-deploy
Waiting for deployment "myapp-deploy" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment spec update to be observed...
Waiting for deployment spec update to be observed...
Waiting for deployment "myapp-deploy" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "myapp-deploy" rollout to finish: 4 of 5 updated replicas are available...
deployment "myapp-deploy" successfully rolled out
```
查看rs会发现多了一个控制器：
```
[root@master deployment]# kubectl get rs
NAME                      DESIRED   CURRENT   READY   AGE
myapp-deploy-5546569785   5         5         5       17m
myapp-deploy-f5885857b    0         0         0       73m
```
查看更新历史记录
```
#这里一开始应该是1和2，我多搞了几变成这个了
[root@master deployment]#  kubectl rollout history deployment myapp-deploy
deployment.extensions/myapp-deploy 
REVISION  CHANGE-CAUSE
3         <none>
4         <none>
```
下面回归到上一个版本，不指定就是上一个版本
```
[root@master deployment]# kubectl  rollout undo deployment myapp-deploy --to-revision=3
deployment.extensions/myapp-deploy rolled back

再次查看：
[root@master deployment]#  kubectl rollout history deployment myapp-deploy
deployment.extensions/myapp-deploy 
REVISION  CHANGE-CAUSE
4         <none>
5         <none>
```
查看版本：
```
[root@master deployment]# kubectl  get rs -o wide
NAME                      DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                                               SELECTOR
myapp-deploy-5546569785   0         0         0       20m   myapp        registry.cn-hangzhou.aliyuncs.com/zhongma/nginx:v2   app=myapp,pod-template-hash=5546569785,release=canary
myapp-deploy-f5885857b    5         5         5       77m   myapp        registry.cn-hangzhou.aliyuncs.com/zhongma/nginx:v1   app=myapp,pod-template-hash=f5885857b,release=canary
```
 - 通过Deployment创建出来的资源，默认会自动创建出ReplicaSet，因为Deployment是通过管理ReplicaSet再来管理Pod的
```
 kubectl get rs查看或者-o wide查看更详细
 #假如此时更新，我们可以给上面清单改个镜像，这个时候我们通过命令查看会发现我们多了一个ReplicaSet控制器，一个老的一个新的，方便回滚
 
 回滚步骤：
 #1、查看历史版本
 kubect rollout  deployment myapp-deploy
 #2、回滚
 kubectl rollout undo deployment myapp-deploy （默认回滚至上一版本）
 kubectl rollout undo  deployment myapp-deploy --to-revision=前面查到的
 
 #更新可以查看过程
 kubectl rollout status  deployment myapp-deploy
  3、此时如果发现正常 我们可通过命令实现全部更新
  kubectl rollout resume deployment  myapp-deploy
  查看更新状态
  kubectl rollout status  deployment myapp-deploy
  或者：
  kubectl  get pods -l app=myapp -w 
```

 - 定义一个金丝雀发布场景
```
  1、通过修改yml文件，我们把镜像设置为新的镜像，并且把更新策略换为定义0个不可用，更新过程种有可超出的有一个
  2、通过命令kubectl set image deployment myapp-deploy myapp=ikubernetes/myapp:v3 && kubectl rollout pause deployment myapp-deploy
  #后面表示暂停更新过程，就实现了金丝雀，新版本启动了一个，老版本还没有动，金丝雀发布
  
```