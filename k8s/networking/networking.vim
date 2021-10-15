### Cluster Networking
- each node must have at least 1 interface connected to a network
- each interface must have an address configured
- the host must have a unique hostname set, as well as a unique MAC address
  = note this especially if you created the VMs by cloning from existing ones.

- some ports that need to be opened
  = used by various components in the control plane
  ex. master should accpet connections on 6443 from the API server
  (worker nodes, kubectl tool, external users, and all other control plane components access the kube-api server via this port

- kubelets on the master and worker node listen on 10250
- kube-scheduler requires port 10251 to be open.
- kube-controller-manager requires port 10252 to be open.
- the worker nodes expose services for external access on ports 30000 to 32767
- the ETCD server listens on port 2379
 
## with multiple nodes, the same goes
## additionally, port 2380 should be opened so the ETCD clients can communicate with each other.

```
### helpful commands

ip link
ip addr
ip addr add 192.168.1.10/24 dev eth0
ip route
ip route add 192.168.1.0/24 via 192.168.2.1

cat /proc/sys/net/ipv4/ip_forward
arp
netstat -plnt (netstat -nplt)
route
```

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#steps-for-the-first-control-plane-node
= the exact command to deploy weave network addon

### Solution (Explore Environment)
kubectl get nodes
ip a (or ifconfig -a)
cat /etc/network/interfaces
ip link

ifconfig -a
ifconfig ens3

ip link
ssh node01 ifconfig ens3
ssh node01 ifconfig -a
ssh node01 ip link
ip r
netstat -natulp | grep kube-scheduler
netstat -natulp | grep etcd | grep LISTEN

### Pod Networking
* how numerous pods in differnet clusters communicate?
(inside and out)

* kubernets has no buil-in solutions for pod networking though
  = it expects you to implement them

**Networking Model**
- k8s expects every single should have an unique IP Address
  = every pod should be able to reach every other pod within the same node, using that ip address
  = every pod should be able to reach every other pod on other nodes, using the same ip address

```
ip link add v-net-0 type bridge
ip link set dev v-net-0 up
ip addr add 192.168.15.5/24 dev v-net-0
ip link add veth-red type veth peer name veth-red-br
ip link set veth-red netns red
ip -n red addr add 192.168.15.1 dev veth-red
ip -n red link set veth-red up
ip link set veth-red-br master v-net-0
ip netns exec blue ip route add 192.168.1.0/24 via 192.168.15.5
iptables -t nat -A POSTROUTING -s 192.168.15.0/24 -j MASQUERADE
```

* create a bridge network in each node
  - ip link add v-net-0 type bridge

* bring them up
- ip link set dev v-net-0 up 

* choose ip address for each node, send the ip address to the bridge interface
  - ip addr add 10.244.1.1/24 dev v-net-0 (and 10.244.2.1/24, 10.244.3.1/24)

### assign ip addresses to containers
= to attach containers to the network, we need a pipe, or virtual network cable

1. create veth pair
ip link add ...

2. attach veth pair (one end to the container, and the other to the bridge) 
ip link set ...

3. assign ip address
ip -n <namespace> addr add ...
ip -n <namespace> route add ...

4. bring up interface
ip -n <namespace> link set ...


* add route to node's route table to route traffic to attempt to reach
  ex. ip route add 10.244.2.2 via 192.168.1.12

  - once the route is added, a pod is able to ping across

* configure route on all hosts to the other hosts with information regarding respective networks within them

= only works within a simple environment 

### instead of having to configure routes on each server, a better solution?
= do that on a router if you have one in your network
  - point all hosts to use that as a default gateway

= for scripts, CNI comes to the rescue (CONTAINER NETWORK INTERFACE)
  ```
  ADD) ## take care of adding containers to the network
  
  DEL) ## take care of deleting container interfaces from the network & freeing the ip address and so on
  
* kubelet on each node is responsible for creating containers 
  - once containers are created, kubelet looks at the cni configuration, passed as a command line argument, identifies our scripts name
  - it then looks at the cni's bin directory to find our script, and execute the script with add command  
  ex. ./net-script.sh add <container> <namespace>

### CNI
- CNI defines the responsibilities of container runtime

* container runtime must create network namespace
* identify network the container must attach to
* container runtime to invoke network plugin (bridge) when container is added
* container runtime to invoke network plugin (bridge) when contaeinr is deleted

- CNI plugin must be invoked by the component, within k8s that is responsible for creating containers
  = that component then must invoke appropriate network plugins after the container is created

- the CNI plugin is configured in the kubelet.service on each node in the cluster

ex.
```
kubelet.service

ExecStart=/usr/local/bin/kubelet \\
  ...
  --network-plugin=cni \\
  --cni-bin-dir=/opt/cni/bin \\
  --cni-conf-dir=/etc/cni/net.d \\  

ps -aux | grep kubelet
```

ls /opt/cni/bin
  = cni bin dir has all the supprotive cni plugins as executable

ls /etc/cni/net.d
  = cni config dir has a set of a config file

```
ex. 10-bridge.conf

cat /etc/cni/net.d/10-bridge.conf
{
  "cniVersion": "0.2.0", 
  "name": "mynet",
  "type": "bridge",
  "bridge": "cn10",
  "isGateway": true,
  "isMasq": true,
  "ipam": {
      "type": "host-local", ## a section to specify a subnet or the range of ip address that will be assigned to pods, and any necessary routes
      "subnet": "10.22.0.0/16",
      "routes": [
          { "dst": "0.0.0.0/0" }
      ]
  }
}

* send packet one port to the other
- one node, through a router, to another node
  = works well in a small network but what if it grows huge?!
  = routing table may not support such humongous entries  
### shiping analogy
1. place an agent on each node (sight)
  - agent: managing all transferringa activities among sights.


* send packet one port to the other
- one node, through a router, to another node
  = works well in a small network but what if it grows huge?!
  = routing table may not support such humongous entries  
### shiping analogy
1. place an agent on each node (sight)
  - agent
    = managing all transferringa activities among sights.
    = check they are well connected with one another

    = when a traffic is sent with where it comes from and its destination, the agent intercepts the traffic, and looks at the dest 
    (the agent should know where it is located)

    = each agent or peer stores the topology of the entire setup
      -> they know pods and their ips on the other node

2. send a packet with information on where it comes from, and where it is meant to be

3. the agent intercepts the traffic and then send it to the target dest


-- in the middle --
  = when a pakcet is sent from one pod to another, it is intercepted and then identified whether it is heading to a diffent network
  = once it is figured out that it is going to another network, it is encapsulated into a new one with new source and destination

(so, pod -> agent: encapsulate a packet into a new one with a new source and destination -> another agent: retrieves and decapsulates the packet -> routes the packet to the right pod)


4. once it is arrived, it is again intercepted by an agent that is in charge of that sight.   

5. the agent opens, and retrieves the original packet

6. then delivers the packet to the right dest

* single pod can be attached to multiple bridge networks  ```
  kubectl exec busybox ip route
  default via 10.244.1.1 dev eth0
  ```

### Solution (Explore CNI Weave)
ps -aux | grep kublet | grep cni
ls /opt/cni/bin
cd /etc/cni/net.d/

### Solution (Deploy Network Solution)
kubectl get pods
kubectl describe pod <name>
kubectl -n kube-system get pods

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl verison | base64 | tr -d '\n')"

### IPAM (IP Address Management)
  - not about ip addresses assigned to the nodes in the network
  = instead, how are the virtual bridge networks in the nodes assigned an ip subnet
  + how are the pods assigned an ip
  + where is this information stored
  + who is responsible for ensuring there are no duplicate IP is assigned
   
1. Who
  - CNI says it is the responsibility of the CNI plugin , the network solution provider to take care of assigning IPs to the containers.
  - k8s does not care about how, but only doing it by making sure we do not assign any duplicate ips manage it properly
  - an easy way: store the list of IPs in a file and make sure we have necessary code in our script to manage this file properly
    = this file would be placed on each host and manages the ips of pods on those nodes 
    = instead of coding that ourselves in our script, CNI comes with two built-in plugins to which you can outsource this task. 

  1. host-local plugin 
  (for managing ip address locally on each host)
  - still out responsibility to invoke of that plugin in our script
    or we can make our script dynamic to support different kinds of plugins
  - the CNI configuration file has a section called IPAM in which we can specify the type of plugin to be used, the subnet and route to be used
    = this details ca be read from our script to invoke the appropriate plugin instead of hardcoding it to use host-local everytime

* diffent network solutions do it in a different way
  
ex. weave
  - by default, allocates the ip range, `10.32.0.0/12` for the entire network  
    = availble from 10.32.0.1 to 10.47.255.254
    = about 1,048,574

  - the peers decide to split the ip address equally among them and assign one portion to each node
    = pods created on these nodes will have ips in the range above
    = this range is configurable with additional options  while deploying the weave plugin to a cluster. 

### Solution (Networking Weave)
kubectl get nodes
cd /etc/cni/net.d/
ls
kubectl get pods -n kube-system -o wide | grep weave
ifconfig -a
ip addr show weave
kubectl run busybox --image=busybox --command sleep 1000 --dry-run=client -o yaml > pod.yaml

  then, add nodeName: node01 on a spec section

kubectl exec -it busybox -- bash/sh
ip r
