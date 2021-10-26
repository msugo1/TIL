* As the service grows, every time you introduce a new service, you have to reconfigure the load balancer
  -> then you even need to enable SSL for your application

### Ingress
- helps your users to access applications using a single externally accessible url that you can configure to route to different services within your cluster based on the url path

    + implement ssl security as well

### How to configure ingress
- deploy a solution with additional configurations

* solution
  = ingress controller

* rules configured
  = ingress resources

NOTE)
  ingress controllers are not installed by default.
    = only ingress resources won't make the magic happen

### Ingress Controller
- number of solutions available (ex. GCE, Nginx ... but the first two are maintained by k8s project)

an example with nginx
1. it is deployed just as a deployment in k8s

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-ingress-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      name: nginx-ingress
  template:
    metadata:
      labels:
        name: nginx-ingress
    spec:
      containers:
        - name: nginx-ingress-controller    
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.21.0

      args:
        - /nginx-ingress-controller
        - --configmap=$(POD_NAMESPACE)/nginx-configuration
      
      env: ## also pass two env variables that carry the pod name and namespaces
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACES
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace

      ports: ## specify the ports used by the ingress controller  
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
```

2. a configmap object that contains a set of configurations
  - to decouple the data

ex. err-log-path, keep-alive, ssl-protocols

```
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
```

  - then pass it onto the configuration file above

3. then need a service that exposes the ingress controller specified above to the external world
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  - port: 443
    targetPort: 443
    protocol: TCP
    name: https
  selector:
    name: nginx-ingress
```

4. an ingress controller has additional intelligence built-in to them to monitor the k8s cluster for ingress resources
   = it can be achieved with a service account (with correct roles and role bindings)

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
```

* in short, requirements = deplyment, service, configmap, auth(sa)



### Ingress Resource
- a set of rules and configurations applied on the ingress controller
 
ex. forward all incoming traffic to a single application
  or route the traffic to various applications based on the url
  ...

* in detail
  - ingress resources are created with a k8s definition file

ex. ingress-wear.yaml
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-wear
spec:
  backend: ## where the traffic would be routed to
    serviceName: wear-service
    servicePort: 80

kubectl create -f ingress-wear.yaml
kubectl get ingress
``

* but rules to route traffic based on different conditions

ex.
  www.my-online-store.com = rule 1
  www.wear.my-online-store.com = rule 2
  www.watch.my-online-store.com = rule 3
  everything else = rule 4


rule1
  - path: www.my-online-store.com/wear, /watch, /listen
    = meaning '/' would be NOT FOUND

rule2
  - http://www.wear.my-online-store.com/
  - http://www.wear.my-online-store.com/returns
  - http://www.wear.my-online-store.com/support

rule3
  - www.watch.my-online-store.com/
  - www.watch.my-online-store.com/movies
  - www.watch.my-online-store.com/tv

rule4
  ex. http://www.listen-my-online-store.com/
      http://www.eat.my-online-store.com/
      http://www.drink.my-online-store.com/tv 
      ...
  
      anything else not specified in rule1, 2, 3 above


(configuration)
```
1. ingress-wear-watch.yaml

apiVersion: extensions/v1beta1
kind: Ingress
meatadata:
  name: ingress-wear-watch
spec:
  rules:
  - http:
    ## speicify different paths = array
    paths:
      - path: /wear
        backend:
          serviceName: wear-service
          servicePort: 80
      - path: /watch
        backend:
          serviceName: watch-service
          servicePort: 80

kubectl describe ingress ingress-wear-watch
```

* default backend?
  - when a user tries to access a url that does not match any of the rules, the user is directed to the service specified as the default backend

(with domain names)
```
apiVersion: extensions/v1beta1
kind: Ingress
meatadata:
  name: ingress-wear-watch
spec:
  rules:
  - host: wear.my-online-store.com ## without any host field specified, it will simply consider it as a start  
    http:                          ##   or accept all the incoming traffic through that particular rule 
      paths:                       ##      without matching the hostname
        - backend:
          serviceName: wear-service
          servicePort: 80

  - host: wear.my-online-store.com
    https:
      paths:
        - backend:
          serviceName: watch-service
          servicePort: 80


