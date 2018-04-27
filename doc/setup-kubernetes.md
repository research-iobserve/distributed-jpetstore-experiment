# Kubernetes Setup

Start Kubernetes
- `kubectl create -f account-deployment.yaml`
   deployment "account" created
- `kubectl create -f order-deployment.yaml`
   deployment "order" created
- `kubectl create -f catalog-deployment.yaml`
   deployment "catalog" created
- `kubectl create -f frontend-deployment.yaml`
   deployment "frontend" created

Check if they are up and running:
- `kubectl get deployments`
   Potential output
```
NAME       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
account    1         1         1            0           1m
catalog    1         1         1            0           44s
frontend   1         1         1            0           39s
order      1         1         1            0           53s
```
- No deployment is available, this indicates a serious error
- `kubectl get pods`
```
NAME                        READY     STATUS             RESTARTS   AGE
account-85f7bf47f4-q4ldg    0/1       ImagePullBackOff   0          3m
catalog-5988d7b5c8-l7jmg    0/1       ImagePullBackOff   0          2m
frontend-8498964d44-9tp9d   0/1       ImagePullBackOff   0          2m
kiekerdemo                  1/1       Running            0          6d
kuard                       1/1       Running            0          8d
order-6c5fbb96f5-rq6dv      0/1       ImagePullBackOff   0          2m
```
- This shows that they cannot get an image loaded. Note that the id part of the
  name may be different.
- Use `kubectl describe pods/account-85f7bf47f4-q4ldg` to get more info on the
  issue
```
Name:           account-85f7bf47f4-q4ldg
Namespace:      default
Node:           nc08/192.168.48.38
Start Time:     Fri, 27 Apr 2018 12:58:09 +0200
Labels:         io.kompose.service=account
                pod-template-hash=4193690390
Annotations:    <none>
Status:         Pending
IP:             10.244.4.8
Controlled By:  ReplicaSet/account-85f7bf47f4
Containers:
  account:
    Container ID:   
    Image:          account
    Image ID:       
    Port:           <none>
    State:          Waiting
      Reason:       ImagePullBackOff
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-gp5t2 (ro)
Conditions:
  Type           Status
  Initialized    True 
  Ready          False 
  PodScheduled   True 
Volumes:
  default-token-gp5t2:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-gp5t2
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason                 Age                From               Message
  ----     ------                 ----               ----               -------
  Normal   Scheduled              7m                 default-scheduler  Successfully assigned account-85f7bf47f4-q4ldg to nc08
  Normal   SuccessfulMountVolume  6m                 kubelet, nc08      MountVolume.SetUp succeeded for volume "default-token-gp5t2"
  Normal   SandboxChanged         6m                 kubelet, nc08      Pod sandbox changed, it will be killed and re-created.
  Normal   Pulling                5m (x3 over 6m)    kubelet, nc08      pulling image "account"
  Warning  Failed                 5m (x3 over 6m)    kubelet, nc08      Failed to pull image "account": rpc error: code = Unknown desc = Error response from daemon: pull access denied for account, repository does not exist or may require 'docker login'
  Warning  Failed                 5m (x3 over 6m)    kubelet, nc08      Error: ErrImagePull
  Warning  Failed                 4m (x7 over 6m)    kubelet, nc08      Error: ImagePullBackOff
  Normal   BackOff                53s (x22 over 6m)  kubelet, nc08      Back-off pulling image "account"
```
- Most relevant form this output is the list of events at the bottom.
- As you can see the image account could not be found. This is usually the case
  as the image is named `jpetstore-account-service` locally and in the repository
  `blade1.se.internal:5000/jpetstore-account-service`

