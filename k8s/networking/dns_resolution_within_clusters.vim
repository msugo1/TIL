* k8s deploys a built-in DNS server by default when a cluster is set up.
  
# how does it help other pods resolve other pods and services?

* whenever a service is created, k8s DNS service creates a record for the service
  - it maps the service name to the IP address
  (now within the cluster, any pod can now reach the service using its service name)

  ## what if what you are about to access is in a different namespace?
  - add the namespace after `.`
  
  ex. what was `curl http://web-service`
        now becomes `curl http://web-service.app`
                                ------------ ---
                              (service name) (namespace)

* For each namespace, the DNS server creates a subdomain
  - all the services are grouped together into another subdomain called SVC
 (Firstly, pods, and subdomains are grouped together into a subdomain, then all the services are into SVC)

  so, now `curl http://web-service.apps.svc`

  (Then, again all the services and pods are grouped together into a root domain for the cluster, which is set to `cluster.local` by default)

  = `curl http://web-service.apps.svc.cluster.local`
  = fully qualified domain name for the service

* for pods?
  - records for pods are not created by default (in the DNS table)
    = but it can be enabled explictly
  - for each pod, k8s generates its name by replacing `.` with `-` 
      then, namespace, type: pod, root domain: cluster.local
    
    ex. `curl http://10-244-2-5.apps.pod.cluster.local`




# How k8s implements DNS?
* given two pods with two ip addresses?
  - how could it be possible?
  1. add an entry into each of their `/etc/hosts`  

  ## but what if 1000 ~ 10000 pods are there and even they are created, and deleted every single second

  2. move the entries into a central DNS server, and then point these pods to the DNS server by adding an entry into their `/etc/resolv.conf`

  = though, k8s creates entries for services (not for pods)
  
* k8s deploys a DNS server within the cluster
  - prior to v1.12, the DNS was known as `kube-dns`
  - now `CoreDNS` is recommended

## CoreDNS
* CoreDNS is deployed also as a pod in the kube-system namespace
  - deployed as two pods for redundancy as a part of a replicaset
  - actually a replicaset within a deployment 

* the CoreDNS pod runs the coreDNS executable, the same executable that we ran when we deployed CoreDNS ourselves

* CoreDNS requires a configuration file
  - `cat /etc/coredns/Corefile`
  - within this file, a number of plugin is configured.
    = errors, health, kubernetes, prometheus, proxy, cache, reload, etc

  - the plugin that makes CoreDNS works with k8s? `the kubernetes plugin`
    = where the top level domain name of the cluster is set
  
  ex.
  ``` 
  kubernetes cluster.local in-addr.arpa ip6.arpa {
      pods insecure
      upstream
      fallthrough in-addr.arpa ip6.arpa
  }

  1. pods
    - what is responsible for creating a record for PODs in the cluster
    (any record that the DNS server can't resolve, it is forwarded to the name space specified in the CoreDNS pods  /etc/resolv.conf
    - then the file is set to use the namespace from the k8s node
    - the core file is passed into the pod as a configmap object
      = if any modification occurrs, only editing the configmap object would do
  ```
* what address to the pods is used to reach the DNS server
  - when a coredns pod is deployed, it also creates a service to make it avaialbe to other components within the cluster 
    = `kube-dns` by default
  - its ip address is configured as a nameserver on pods
    = a dns configuration on pods are done by k8s automatically when they are created   
      |
      |
       ----> kubelet takes responsibility here!
      ```
      cat /var/lib/kubelet/config.yaml
      
      ...
      clusterDNS:
      - 10.96.0.10
      clusterDomain: cluster.local
      ```

* host <web-service> will return the fully qualified domain name
  - how is it possible?
    = by the search entry in `/etc/resolve.conf`

  - it only has search entries for services
    (not for pods! - pods are required a fqdn)


