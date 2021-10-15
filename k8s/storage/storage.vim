## Reminder
* Docker Layers

  base layer
  each commands in Dockerfile

  - only changes are commited as a new layer
  (by docker build)
  - can reuse the same layers from the cache
    = new layers not from the cache will be actually built (save time and resources)

1. container layer & image layer
  1) container layer
    - a new commit on the base image
    - read write
    - modifications to read only will be applied as here this layear
    - will disappear when the container is deleted

  2) image layer
    - read only
    - base layers
    - shared by many

2. Volumes & (volume mount and bind mount)
  by docker volume create <name>
  - in order to persist data even after a container is removed

  * to use
  docker run -v <volume_name>:<container dir to mount> <container name>
  ### Volume Mount
    or

  docker run -v <complete path in host>:<container dir to mount> <container name>
  ### Bind Mount

    or even (new type)

  docker run  \
    --mount type=bind,source=<where to be stored in host>,target=<what dir to be stored from a container> <container name>

3. Stroage Drivers?
- docker uses storage drivers to enable the layerd architecture

  ex. AUFS, ZFS, BTRFS
(what is available depends on OS, environment, etc)

4. Volume Drivers

### storage in Docker
1. Storage Drivers
  - docker stores data in `/var/lib/docker` by defaults
    = containers: container-related
    = image: image-related
    ...

  - but such data stays alive only while its container is alive

  - `volume` comes to the resque to keep the data even after the container's gone.

  - storage drivers enable us to have the layerd architecture in docker

  - storage drivers help manage storage on images and containers

2. Volume Drivers

  - volumes are handled by volume driver plugins
  (default: local)
  
  - like storage drivers, various volume drivers are available with a variety of offers
  - a certain volume is used based on the needs & requirements

### Container Storage Interface (CSI)
- in the past 
  = k8s was embedded within docker
  (docker was the sole source)

- but now other container solutions have come in
  = now extend the range

* CRI(Container Runtime Interface)
- how orchestartion solutions like k8s communicate with container runtimes
  = with CRI, containers are not dependent on k8s alone
  (just implement the CRI, and it is supposed to work in harmony with k8s)
  = with CRI, k8s does not have to change its source code to switch among the container runtimes

* CSI in the same sense
- to support multiple storage solutions with ease
  = just to let them implement CSI
- universal standard (not k8s specific)
  = it should work with any orchestration tools 

### Volumes (in k8s)
- the same goes for k8s
  = to persist data
 
```
ex.
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
  - image: alpine
    name: alpine
    command: ["/bin/sh", "-c"]
    args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]

  volumes:
  - name: data-volume 
    hostPath:
      path: /data
      type: Directory
  ## to persist the numbers generated
  (otherwise would be gone when the container gets destryoed)
```

### Persistent Volume
- to use a volume, (or let a pod use a volume) the configuration must be specified in a yaml file
- but in a large environment with a lot of pods, it will be a hassle to write it down all the time
  = what if some changes are made?
    -> even with a small change, all the file related to the volume will have to be modified along
    (WTH)
  
- Now, it should be centralized for better maintanence!

* PV!
  - a cluster wide pool of storage volumes configured by an administrator to be used by users deploying applications on the cluster
  - users can now select stroage from the pool using PVC (persistnet volume claim)

```
ex.
(PV)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-voll
spec:
  accessModes:
      - ReadWriteOnce
  capacity:
      stprage: 1Gi
  hostPath:
    path: /tmp/data ## not to be used in a production
  <or>
  awsElasticBlockStore:
    volumeId: <volume-id>
    fsType: ext4

* supported accessModes?
1. ReadOnlyMany
2. ReadWriteOnce
3. ReadWriteMany

### PVC (Persistent Volume Claim)
- PV: created by an administrator
- PVC: created by a user to use a PV

* PVC, k8s binds the PV to PVC based on the requests and properties set on the volume.d

  with storage classes, it won't any longer be necessary to manually specify a PV definition 
  = PV and any associated storage are going to be created automatically when the storage class is created.

* for PVC to use the storage class configured 
```
  = PVC (one) <-> PV (one) 

* k8s tries to find a PV that has sufficient capacity as requested by the claim and any other request properteis such as access modes, volume modes, storage classes.
  - what if there's multiple matches?
    = labels & selectors to bind to the right volumes

  - a smaller claim may get bound to a larget volume if all other criteria matches with no better options
  (= waste)

* when no volumes are avaialbe?
  - PV remain pending until newer volumes are made availabe to the cluster
  
```
(PVC)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi

kubectl get persistentvolumeclaim
kubectl delete ~
``` 

* reclaimPolicy
= what happens when a binding PVC is deleted.
  1. Retain
    - remain until it is manually deleted by the administrator
    - not available for reuse by any other claims
  2. Delete
    - deleted by automatically
    - PV will be deleted when PVC gets deleted
  3. Recycle
    - data in the data volume will be scrubbed before making it available to other claims

* using PVC in Pods
- Once you create a PVC use it in a POD definition file by specifying the PVC Claim name under persistentVolumeClaim section in the volumes section like this:

```
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: myfrontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
        claimName: myclaim
```

The same is true for ReplicaSets or Deployments. Add this to the pod template section of a Deployment on ReplicaSet.

### Static Provisioning
- manually manually manually create a disk, pv, then pvc
- a hassle as the size grows bigger and bigger

### Dynamic Provisioning
  with storage classes, you can define a provisioer such as Google storage that can automatically provision storage on Google Cloud and attach that to pods when a claim is made

- achieved by creating a storage class object 
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd

  with storage classes, it won't any longer be necessary to manually specify a PV definition 
  = PV and any associated storage are going to be created automatically when the storage class is created.

* for PVC to use the storage class configured 
```
(PVC)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: google-storage
  resources:
    requests:
      storage: 500Mi

* to provisiers, you can pass additional parameters such as the type of the desk to provision, the replication type etc...

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard [ pd-standard | pd-ssd ]
  replication-type: none [ none | regional-pd ]

* VolumeBindingMode
  - WaitForFirstConsumer
    = delay the binding and provisioning of a PV until a Pod using the PVC is created

kubectl explain persistentvolume --recursive | less
