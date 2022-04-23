This is a PoC for test the [KEDA](https://keda.sh/) component in a mock cluster with the objective of improve the latency time in a traffic surge.

In this demo we use Locust for make a load test and simulate a common traffic surge in the ingress controller (ingress-nginx), for more details of how works [KEDA](https://keda.sh/) internally please visit your [official site](https://keda.sh/docs/2.6/concepts/#architecture).

## Getting started
### Requirements
* [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
### Installation
#### 1. Create a new cluster of k8s with kind 

``` sh
❯ kind create cluster
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.21.1) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a nice day! 👋

❯ kubectl config use-context kind-kind
```
Make sure that the Kubernetes node is ready:
```
❯ kubectl get nodes
NAME                 STATUS   ROLES                  AGE     VERSION
kind-control-plane   Ready    control-plane,master   3m25s   v1.21.1
```
And that system pods are running happily:
```
❯ kubectl -n kube-system get pods
NAME                                         READY   STATUS    RESTARTS   AGE
coredns-558bd4d5db-thwvj                     1/1     Running   0          3m39s
coredns-558bd4d5db-w85ks                     1/1     Running   0          3m39s
etcd-kind-control-plane                      1/1     Running   0          3m56s
kindnet-84slq                                1/1     Running   0          3m40s
kube-apiserver-kind-control-plane            1/1     Running   0          3m54s
kube-controller-manager-kind-control-plane   1/1     Running   0          3m56s
kube-proxy-4h6sj                             1/1     Running   0          3m40s
kube-scheduler-kind-control-plane            1/1     Running   0          3m54s
```
#### 2. Run terraform for install keda helm chart

``` sh
❯ make apply
```
#### 3. Verify of all deployments is working correctly

Create a port-forward of ingress nginx service

``` sh
❯ kubectl port-forward service/nginx-ingress-nginx-ingress -n ingress-nginx 8080:80
``` 
Make a simple curl for check if the app response with a HTTP 200
``` sh
❯ curl hello-app.local:8080 --resolve hello-app.local:8080:127.0.0.1
``` 
### Keda ScaledObject
Now, in your cluster you can see a new Object of KEDA  and these autoscaling the hello-app deployment throught metrics of **[nginx controller (active_connections)](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx#prometheus-metrics)**

``` yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    kind: Deployment
    name: {{ include "chart.fullname" . }}
  minReplicaCount: 1
  maxReplicaCount: 20
  cooldownPeriod: 30
  pollingInterval: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-server.prometheus.svc.cluster.local
      metricName: nginx_connections_active_keda
      query: |
        sum(avg_over_time(nginx_ingress_nginx_connections_active{app="nginx-ingress-nginx-ingress"}[1m]))
      threshold: "100"
```
### Simulate traffic surge with Locust
Deploy Locust with the next command
``` sh
❯ kubectl apply -f locust/locust.yaml 
```
Now create a port-forward and then you can access in your browser with `http://localhost:7070`
``` sh
❯ kubectl port-forward service/locust -n default 7070:8089 
```
Return to the Locust server in your browser. Enter the following values in the fields and click the Start swarming button:

- Number of users – 500
- Spawn rate – 100
- Host – http://nginx-ingress-nginx-ingress.ingress-nginx.svc.cluster.local

Now you can see how KEDA and HPA start to autoscaling the nginx pods with a better way for attend the traffic surge with a minor latency vs the traditional way.

## Documentation
1. [Keda Official Docs](https://keda.sh/docs/2.6/)
2. [NGINX Tutorial: Reduce Kubernetes Latency with Autoscaling](https://www.nginx.com/blog/microservices-march-reduce-kubernetes-latency-with-autoscaling/)

## How contribute? :rocket:

Please feel free to contribute to this project, please fork the repository and make a pull request!. :heart:

## Share the Love :heart:

Like this project? Please give it a ★ on [this GitHub](https://github.com/EnriqueTejeda/k8s-autoscaling-with-keda)! (it helps me a lot).

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) 

See [LICENSE](LICENSE) for full details.

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
