* container orchestration tool's 장점
- 여러 대의 서버를 묶어 리소스를 풀로 사용할 수 있다.
- 클러스터의 CPU or 메모리 등의 자원이 부족할 때, 필요한 용량만큼의 서버를 동적으로 추가 -> 수평적으로 확장할 수 있다.

* 스케일 아웃만큼 중요한 것 = 클러스터 내부의 컴퓨팅 자원 활용률

### 자원 활용률
- 서버 클러스터에서 자원을 얼마나 효율적으로, 빠짐없이 사용하고 있는지
  = 각 컨테이너의 자원 사용량을 적절히 제한하고, 남는 자원을 어떻게 사용할지 전략이 필요하다.

1. 컨테이너와 포드의 자원사용량 제한
  = Limits

compared to Docker
  (in docker) --memory, --cpus, --cpu-shares, --cpu-quota, --cpu-runtime
  = --cpu-shared: 비율로 CPU 제한

in k8s
1. 포드에 자원사용량 명시하기
```
apiVersion: v1
kind: Pod
metadata:
  name: resource-limit-pod
  labels:
  name: resource-limit-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
  resources:
    limits:
      memory: "256Mi"
      cpu: "1000m"

(자원 사용량 확인)
kubectl get pods -o wide
kubectl describe node (node-name)

* kube-system
- k8s의 핵심 컴포넌트를 담고 있는 네임스페이스
- 별도의 설정이 없어도 기본적으로 CPU와 메모리가 할당된다.

In short, Limits: 해당 포드의 컨테이너가 최대로 사용할 수 있는 자원의 상한선

### Requests
- 하한선
  = 적어도 이 만큼의 자원은 컨테이너에게 보장되어야 한다.
- k8s에서 자원의 오버커밋을 가능하게 만드는 기능

* over commit?
- 한정된 컴퓨팅 자원을 효율적으로 사용하기 위한 방법
- 사용할 수 있는 자원보다 더 많은 양을 가상머신이나 컨테이너에게 할당
  -> 전체 자원의 사용률을 높이는 방법

* 정적인 자원할당의 한계
- 상황에 따라서, 자원 사용률이 낮은 컨테이너에 불필요하게 많은 자원을 할당할 수 있다.
- 변화에 대응하기 힘들다.
  = 컨테이너가 실제로 얼마나 자원을 사용할지 예측하기 어려운 경우가 대다수


쿠버네티스에서는 오버커밋을 통해 실제 물리 자원보다 더 많은 양의 자원을 할당할 수 있다.
  = 실제 샤용량이 올라간다는 뜻이 아니다. (실제 자원은 한정되어 있기 때문)
  = 한 컨테이너가, 자원 사용률이 낮은 다른 컨테이너로부터 남는 자원을 기회적으로 사용할 수 있다.

But, 남는 자원이 없는데 더 사용하려고 한다면?
  = OOME 발생 and 시스템 can crash
  = How to solve?
    - 각 컨테이너가 사용을 보장받을 수 있는 경계선을 정하자
    (적어도 ~만큼은 사용할 수 있다.)
    - `Requests`

ex.
```
apiVersion:v1
kind: Pod
metadata:
  name: resource-limit-with-request-pod
  labels:
    name: resource-limit-with-request-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    resources:
      limits:
        memory: "256Mi"
        cpu: "1000m"
      requests:
        memory: "128Mi"
        cpu: "500m"

(interpretation: 최소 128Mi, 500m을 사용하며, 최대 256Mi, 1000m 까지 사용할 수 있다.)

- requests는 컨테이너가 보장받아야 하는 최소한의 자원
  = 따라서, 노드의 총 자원의 크기보다 더 많은 양의 requests를 할당할 수는 없음
  = k8s의 스케줄러는 포드의 requests만큼 여유가 있는 노드를 선택해 포드 생성
  = 포드를 할당할 때 사용되는 자원할당 기준은 requests(not limit)

### CPU 자원 사용량의 제한 원리
* k8s에서의 CPU requests와 limits
  = k8s에서는 CPU를 밀리코어 단위로 제한
  = 1개의 CPU는 1000m에 해당한다.

* what happpens to containers  when `resources.requests.cpu` is set 
  = CPU's requests = docker run --cpu-shares
  = CPU가 실제로 몇개가 있는지 상관 없이, `--cpu-shares`의 할당 비율에 따라서, 컨테이너가 사용할 수 있는 CPU 자원이 결정되는 옵션
  = 유휴 자원이 있다면, 한 컨테이너가 CPU를 전체 사용할 수도 있다.
  = under fullwork load, 정해진 비율만큼만 최대로 사용할 수 있음 (for each container)

* `--cpu-shares` with `--cpus(Limits)`
  = CPU 자원에 오버커밋을 적용할 수 있다.
```
* requests -> cpu shares 변환
(CPU m in requests * 1024) / 1000 = CPU share 값
ex. 500m
500m * 1024 / 1000 = 512

* full workload 시
  = 각 컨테이너에게 requests에 설정된 값이 각각 보장된다.
- then, how `limits` works with cut-throat competitions for more CPU resources among containers?
  = CPU throttle!

### Qos 클래스와 메모리 자원 사용량 제한원리
- CPU는 오버커밋된 자원을 사용하는 경우
  = 이미 모든 컨테이너가 최대치를 사용하고 있어서, 남는 자원이 없는 경우 throttling이 발생한다.
  (That's all!)
- However, for Memory
  = 메모리는 이미 데이터가 메모리에 적재되어 있다.
  = means 압축 불가능한 자원(Incompressible)
  = 따라서, k8s가 가용 메모리를 확보하기 위해, `우선순위가 낮은` 포드 or 프로세스 부터 강제로 종료한다.
  = 강제로 종료된 포드는 다른 노드로 옮겨가게 된다. -> called eviction

* How to calculate priorities?
  = 포드의 컨테이너에 설정된 Limits, Requests의 값
    + 3가지 종류의 QoS(Quality of Service) 클래스 identified on Pods

* k8s 노드에는 각종 노드의 이상 상태 정보를 의미하는 `Conditions` 값이 존재한다. 
  = 이상 상태의 종류에는 MemoryPressure, DiskPressure 등이 있다.
 
* kubelet이 노드의 자원 상태를 주기적으로 체크 -> 값을 주기적으로 갱신
```
kubectl describe node | grep -A9 Conditions

* Memory Pressure
  = by default: 노드의 가용 메모리가 100Mi 이하일 때 발생
  = 발생 시, 해당 노드에서 실행중인 모든 포드에 대해 순위를 매긴다.
  = then, 우선순위가 낮은 포드부터 다른 노드로 Evict
  = In addition, MemoryPressure = True인 노드에 대해서는 새로운 포드를 할당하지 않음

* 갑작스럽게 메모리 사용량이 많아진다면? (Even no time for kubelet to detect Memory Pressure)
  = by Linux, OOM Killer
  (위 기능이 우선순위 점수가 낮은 컨테이너의 프로세스를 강제 종료하게 만들 수 있음)
  = OOM 우선순위 점수에 해당하는 것
  1. oom_score_adj
  2. oom_score
  = OOM Killer는 2번 사용 
  = OOM Killer는 리눅스에 기본적으로 내장된 기능 -> 아무것도 설정하지 않아도 모든 프로세스에 자동으로 OOM 점수가 매겨진다.
  
주의: 우선순위 점수가 높을 수록 강제 종료될 확률이 높아진다.(낮은 경우가 아님!)

ex.
```
ps aux | grep dockerd
ls /proc/<process number>/
cat /proc/<process number>/oom_score_adj
  =  도커 데몬은 기본적으로 -999의 점수를 가진다. = 거의 종료될 위험이 없다.

### QoS 클래스의 종류
= QoS 클래스는 자동으로 설정된다.
= kubectl describe로 포드 조회시 확인가능하다
```
kubectl describe pod resource-limit-pod | grep QoS

1. Guaranteed
- 포드의 컨테이너에 설정된 Limits == Requests (completely identical)
- Limits만 정의하면 Requests 값 또한 Limits와 동일하게 설정된다.
- `Limits == Requests`이므로, 할당받은 자원을 아무런 문제 없이 사용할 수 있다.
  = 자원의 오버커밋 허용x == 할당받은 자원의 사용이 안정적으로 Guranteed!
- OOM 점수 for objects in Guaranteed?
  = -998 == 거의 종료되지 않는다고 봐야한다.

2. BestEffort
- Limits, Requests가 아예 설정되지 않은 포드에 할당되는 클래스
(no resources section in a yaml file)
- 상한선 설정 x = 제한 없이 모든 자원 사용
- 사용을 보장받는 자원이 없다. = 때에 따라서, 자원을 전혀 사용하지 못할 수 있다.

3. Burstable
- Limits > Requests (= Overcommit)
- 1, 2에 속하지 않으면 무조건 3
- Requests < 자원 사용량 < Limits 범위의 경우,ㄷ 다른 포드와 자원 경합이 발생할 수도 있다.
  = Requests 보다 더 많은 자원을 사용하고 있는 포드나 프로세스의 우선순위가 더 낮게 설정된다.

### OOM & Post Process
- 포드가 Evict 된 경우?
  = 단순히 다른 노드에서 포드가 다시 생성됨
- OOM Killer에 의해 포드 컨테이너의 프로세스가 종료된 경우?
  = 해당 컨테이너는 포드의 재시작 정책에 의해 다시 시작

* 기본적인 우선순위(= 종료순서)
- BestEffort > Burstable > Guaranteed
(항상 절대적이지는 않다.)
- 가장 중요한 것?
  = 포드가 메모리를 얼마나 많이 사용하는가?
  = the more, the riskier
  (Guaranteed는 애초에 사용되는 자원이 정확히 보장되기 때문에, 우선순위가 높다. However, 다른 두 클래스의 경우 메모리 사용량이 올라갈수록 우선순위가 낮아진다. = Evict or OOM Killed 될 확률이 올라간다.)

### Resource Quota & Limit Range
- k8s를 여러 팀이 사용하고 있다면, 각 네임스페이스에서 할당할수 있는 자원의 최대 한도 or 범위를 설정할 필요가 있을 것
- Resource Quota
  = 네임스페이스의 자원 사용량 제한
- Limit Range
  = 자원 할당의 기본값 or 범위 설정

1. Resource Quota
- 특정 네임스페이스에서 사용할 수 있는 자원 사용량의 합을 제한할 수 있는 k8s object
  = literally, 네임스페이스에서 할당할 수 있는 자원(CPU, Memory, PVC Size, Temp Storage in a container, and so forth) 총합을 제한
- or 네임 스페이스에서 생성할 수 있는 리소스의 개수를 제한
- Resource Quota is also a name-spaced object
  = 네임스페이스 별로 생성이 필요


```
kubectl get quota
kubectl get resourcequota

(resource-quota.yaml)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota-example
  namespace: default
spec:
  hard:
    requests.cpu: "1000m"
    requests.memory: "1000m"
    limits.cpu: "1500m"
    limits.memory: "1000Mi"

kubectl apply -f resource-quota.yaml
kubectl describe quota

* ResourceQuota에 설정된 제한을 넘는 포드 생성시?
  = 에러 발생
* 그렇다면 deployment로 생성시?
  = 디플로이먼트는 생성되지만, 포드는 생성되지 않는다.
(참고: 이때, 포드를 생성하는 주체? ReplicaSet
  = 에러 로그는 ReplicaSet에 남아있을 것)

```
kubectl get replicasets
kubectl describe rs deployment-over-memory-~

* Resource 개수 제한하기
```
개수를 제한할 수 있는 대상
1. deployment, pod, service, secret, configmap, pvc 등
2. nodeport 타입의 서비스 개수, LB 타입의 서비스 개수
3. QoS 클래스 중 BestEffort 클래스에 속하는 포드의 개수

ex
```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota-example
  namespace: default
spec:
  hard:
    requests.cpu: "1000m"
    requests.memory: "500Mi"
    limits.cpu: "1500m"
    limits.memory: "1000Mi"
    count/pods: 3
    count/services: 5

- 특정 Api Group에 속하는 리소스의 개수를 제한한다.
  = `count/<object name>/<api group name>
(코어 그룹은 apigroup name이 생략된다.)
```
...
spec:
  hard:
    count/resourcequotas: 3
    count/secrets: 5
    count/configmaps: 5
    count/services.loadbalancers: 1
    count/services.nodeports: 3
    count/services.loadbalancers: 1
    count/deployments.apps: 0

* BestEffort 클래스의 포드 개수 제한하기 with resource quota
```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: besteffort-quota
  namespace: default
spec:
  hard:
    count/pods: 1
  scopes:
    - BestEffort

- 해당 스코프에 위의 값을 적용한다.
  = BestEffort, NotBestEffort, Terminating, NotTerminating 등을 적용할 수 있다.

* ResourceQuota에 limits.cpu or limits.memory 등을 이용해 네임스페이스 에서 사용가능한 자원의 합을 설정했다?
  = 포드를 생성할 때 반드시 해당 항목을 함께 정의해줘야 함.
  (or 에러!)

### Limit resource usage with `Limit Range`
* Limit Range
- 특정 네임스페이스에서 할당되는 자원의 범위 또는 기본 값을 지정할 수 있는 쿠버네티스 오브젝트

* used where?
- 포드의 컨테이너에 CPU or 메모리 할당량이 설정되어 있지 않은경우 
  = 컨테이너에 자동으로 기본 Requests or Limits 값을 설정할 수 있다.
- 포드 or 컨테이너의 CPU, 메모리, PVC 크기의 최솟값/최댓값을 설정할 수 있다.

```
kubectl get limitranges
= kubectl get limits

apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-rnage
spec:
  limits:
  - default: (자동으로 설정될 기본 Limits 값)
    memory: 256Mi
    cpu: 200m
  defaultRequest: (자동으로 설정될 기본 Requests 값)
    memory: 128Mi
    cpu: 100m
  max: (자원 할당량의 최댓값)
    memory: 1Gi
    cpu: 1000m
  min: (자원 할당량의 최솟값)
    memory: 16Mi
    cpu: 50m
  type: Container (각 컨테이너에 대해서 적용)

= min, max의 범위를 벗어나는 포드의 컨테이너는 생성할 수 없다.

* `maxLimitRequestRatio`를 사용해 오버커밋되는 자원에 대한 비율을 제한할 수도 있음
```
apiVersion: v1
kind: LimitRange
metadata:
  name: limitrange-ratio
spec:
  limits:
  - maxLimitRequestRatio:
    memory: 1.5
    cpu: 1
  type: Container

= ex. maxLimitRequestRatio.memory: 새롭게 생성되는 포드의 Limits, Requests의 비율은 1.5보다 반드시 작아야 한다.
= 비율을 1로 설정해서 반드시 Guaranteed 클래스의 포드만을 생성하도록 강제할 수도 있다.

* 포드 단위로 자원 사용량의 범위 제한하기
```
apiVersion: v1
kind: LimitRange
metadata:
  name: pod-limit-range
spec:
  limits:
  - max:
      memory: 1Gi
    min:
      memory: 200Mi 
    type: Pod

= 포드의 사용량 == 포드에 존재하는 모든 컨테이너의 자원의 합
  (합이 최소 200Mi to 최대 1000Mi)

### ResourceQuota, LimitRange with Admission Controller
* Admission Controller?
- user -> (kubectl ~) -> HttpHandler -> Authentication -> Authorization -> Mutating Admission Controller -> Validating Admission Controller
- 사용자의 API 요청이 적절한지 검증 & 필요에 따라 변형
  = 검증 & 변형의 두 단계로 나뉜다. (in Admission Controller)
- 필요한 경우 Admission Controller를 직접 구현할 수도 있다.
  (ex. for a sidecar pattern or port correction metioned by the book)

### 쿠버네티스 스케줄링
- 가상머신과 같은 인스턴스를 새롭게 생성할 때, 그 인스턴스를 어느 서버에 생성할 것인지 결정하는 일
  (ex. for 특정 목적에 최대한 부합하는 워커 노드를 선택) 
- k8s는 다양한 스케줄링 방법을 제공한다. 
  (복잡한 스케줄링 전략을 직접 구현해서 사용할 수도 있다.)

### 포드가 실제로 노드에 생성되기 까지
* 포드 생성 요청 (with kubectl or through API) 
  -> SA, RoleBinding 등을 통해 요청한 사용자에 대한 인증, 인가 수행
  -> Admission Controller가 해당 요청을 적절히 변형 & 검증
  -> 검증을 통과한 경우, 포드 승인이 생성되었다면 k8s는 해당 포드를 워커 노드 중 한 곳에 생성
(포드 스케줄링은 3 번째 단계에서 수행)

* 스케줄링에 관여하는 컴포넌트?
  = kube-scheduler & etcd

### Etcd?
- 분산 코디네이터
- 여러 컴포넌트가 정상적으로 상호 작용할 수 있도록 데이터를 조정하는 역할 담당
- 클러스터 운용에 필요한 정보를 여기에 저장 (k8s case)
  ex. 현재 생성된 디플로이먼트나 포드의 목록과 정보 or 클러스터 자체의 정보 등 (대부분의 데이터)
- etcd에 저장된 데이터는 무조건 API 서버를 통해서만 접근할 수 있다.
  ex. kubectl -> API Server -> Etcd -> 명령 수행 후 결과 반환

* nodeName (stored in Etcd)
- 해당 포드가 어느 워커 노드에서 실행되고 있는지
- kubectl get pods my pod -o yaml | grep -F3 nodeName

* 인증, 인가, AC 단계를 모두 거쳐 포드 생성 요청 최종 승인
  -> etcd에 포드 데이터 저장
  (스케줄링 전으로, nodeName 항목은 설정되어 있지 않음)
  -> kube-scheduler is invoked by API Server, Watch (nodeName이 비어있다!!)
  -> scheduler가 포드를 할당할 적절한 노드 선택, API 서버에게 해당 노드 & 포드 바인딩 요청
  -> 이후, nodeName 항목 값에 선택된 노드이름 설정
  -> kubelet notices the update by `Watch` in the API Server
  -> 해당 nodeName에 해당하는 노드의 kubelet이 컨테이너 런타임을 통해 포드 생성   

### How Scheduler selects a Proper Node?
- 노드 필터링 then 노드 스코어링

* 노드 필터링?
- 포드를 할당 가능한 노드를 찾는다. (Filtering)
  ex. 가용자원이 존재하지 않는 노드, 마스터 노드, 장애 발생한 노드 등 cut off 
- 필터링을 통과한 노드들은 스코어링 단계로 전달
* 노드 스코어링
- k8s source code에 미리 정의된 알고리즘의 가중치에 따라 노드 점수 계산
  ex. 포드가 사용할 도커 이미지가 이미 있는 경우, 빠르게 포드를 생성할 수 있으므로 스코어 증가
    가용자원이 많을 수록 스코어 증가 (Least Requested)
- 알고리즘들의 값을 합산하여 후보 노드들의 점수 계산
- 가장 점수가 높은 노드를 최종적으로 선택
(노드 스코어링은 k8s에 내장된 로직에 의해 계산된다. = 수정할 일이 많지 않다.
대부분 스케줄링 조건을 포드의 YAML 파일에 설정 -> 노드 필터링 단계에 적용될 수 있도록 구성)

### Node Selector, Node Affinity, Pod Affinity
(노드 필터링 단계에서 사용할 수 있는 방법)

1. nodeName & nodeSelector
- 특정 워커노드에 포드를 할당하는 가장 확실한 방법 = 포드의 YAML 파일에 노드 이름 직접 명시하기
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeName: <node name>
  containers:
  - name: nginx
    image: nginx:latest

- 다른 환경에서 해당 YAML 파일을 사용하는 것이 힘들다(보편적이지 않다. 유연하지 않다.)
- 따라서, 라벨을 대신 사용한다.
  = 특정 라벨이 존재하는 노드에만 포드 할당
- kubectl get nodes --show-labels
  = `kubernetes.io/` 로 시작하는 라벨 = 쿠버네티스에 의해 미리 예약되어 사용
- 라벨 추가
  = `kubectl label nodes <node name> <label to add>`
  ex. kubectl label nodes ip-10-43-0-30.ap-northeast-2.compute.internal mylabel/disk=ssd
- 라벨 삭제
  = `kubectl label nodes <node name> <lable to delete>-`
  ex. kubectl label nodes ip-10-43-0-32.ap-northeast-2.compute.internal mylabel/disk-

in a yaml
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-nodeselector
spec:
  nodeSelector:
    mylabel/disk: hdd
  containers:
  - name: nginx
    image: nginx:latest

= 이제 해당 라벨을 가진 노드로 할당된다.
= 해당 라벨을 가진 노드가 두개 이상이라면 그 중에서 하나가 선택된다.
(적어도 노드의 이름에 종속적이지 않게 YAML 파일을 작성할 수 있다.)
= 각 포드에 단일 수행된다. 
(레플레카 셋에 묶여있어도 각 포드마다 따로 적용된다. = 같은 레플리카엣에 있는 포드가 다른 노드에 할당될 수 있다.)
2. Node Affinity
- 단순히 라벨의 카-값이 같은지만 비교해 노드를 선택하는 방법은 활용이 제한적
- 이를 보완하기 위해 쿠버네티스는 Node Affinity 스케줄링 방법을 제공
- 반드시 충족해야 하는 조건(Hard), 선호하는 조건(Soft)를 별도로 정의할 수 있음

  1) requiredDuringSchedulingIgnoredDuringExecution
  ```
  ...
  spec:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: mylabel/disk
              operator: In
              values:
              - ssd
              - hdd
              (values의 값 중 하나만 만족하면 된다. = opeartor: In)

  = 여러 개의 키-값 쌍을 정의한 뒤 operator를 통해 별도의 연산자를 사용
    (ex. In, NotIn, Exists, DoesNotExist, Gt, Lt, and so on)
    -> nodeSelector 보다 더 다양하게 활용할 수 있다.
  = 반드시 만족해야 하는 제약조건을 정의하는데 쓰인다. (required)

  2) preferredDuringSchedulingIgnoredDuringExecution 
  = 선호하는 제약조건
  (반드시 만족시킬 필요는 없고, 해당 조건을 만족하는 노드가 있으면 그 노드를 좀 더 선호하겠다.)
  ```
  ...
  spec:
    affinity:
      nodeAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchEcpressions:
            - key: mylabel/disk
              operator: In
              values: 
              - ssd
    containers:
    - name: nginx
      image: nginx:latest
  
  = weight: 가중치 (can be set between 1 and 100)
  (할당 가능한 모든 노드를 필터링한 뒤 수행하는 노드 스코어링 단계에서 적용)

- 이러한 스케줄링 조건은 포드를 할당할 당시에만 유효
  = 일단 포드가 할당되면, 노드의 라벨이 변경되더라도 다른 노드로 포드가 옮겨가는 Eviction이 발생하지 않는다.
  (IgnoredDuringExecution)
- 다만 접미어를 바꾼다면 ex. requiredDuringSchedulingRequiredDuringExecution - 스케줄링에 영향을 주는 노드 라벨이 포드가 실행된 뒤에 변경된다면 포드가 다른 노드로 옮겨가게 된다.

### Pod Affinity in Scheduling
- NodeAffinity: 특정 조건을 만족하는 노드를 선택하는 방법
- PodAffinity: 특정 조건을 만족하는 포드와 함께 실행되도록 스케줄링

ex.
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-podaffinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
        matchExpressions:
        - key: mylabel/database
          operator: In
          values: 
          - mysql
        topologyKey: failure-domain.beta.kubernetes.io/zone
  containers:
  - name: nginx
    image: nginx:latest

= `mylabel/database=mysql` 라벨을 가진 포드와 함께 위치하도록 스케줄링할 것
- topologyKey?
  = 해당 라벨을 가지는 토폴로지 범위의 노드를 선택한다는 것
  = k8s의 노드들은 topologyKey에 설정된 라벨의 키-값에 따라 여러 개의 그룹으로 분류될 수 있음
  = 스케줄링 시, matchExpression의 라벨 조건을 만족하는 포드가 위치한 그룹의 노드 중 하나에 포드를 할당
  = 따라서, 조건을 만족하는 포드와
  1. 동일한 노드에 할당될 수 있다.
  2. 해당 노드와 동일한 그룹에 속하는 다른 노드에 포드가 할당될 수도 있다.

ex. 응답 시간을 최대한 줄여야 하는 두 포드를 동일한 가용 영역(Available Zone = AZ) or 리전(Region)에 할당하는 경우에 사용

** 토폴로지 키를 호스트 이름으로 지정한다면?
```
...
    - matchExpressions:
      - key: mylabel/database
        operator: In
        values:
        - mysql
      topologyKey: kubernetes.io/hostname

= 모든 노드의 호스트 이름은 고유하다
= 따라서, 하나의 토폴로지에 두 개 이상의 노드가 존재할 수 없다.
= 하나의 노드가 하나의 토폴로지에 대응하게 된다. (모든 토폴로지 = 하나의 노드로만 구성)
= 따라서, 반드시 matchExpression을 만족하는 포드가 있는 노드를 선택하게 된다.
      
### Pod Anti-affinity in Scheduling
= Pod Affinity와 반대로 동작
(특정 포드와 같은 토폴로지의 노드를 선택하지 않는 방법)
ex. 고가용성을 보장하기 위해 포드를 여러 가용 영역 or 리전에 멀리 퍼뜨리는 전략을 사용할 수 있음

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-antiaffinity
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
        matchExpressions:
        - key: mylabel/database
          operator: In
          values:
          - mysql
      topologyKey: failure-domain.beta.kubernetes.io/zone
  containers:
  - name: nginx
    image: nginx:latest

* Pod Affinity & Anti-Pod Affinity도 모두 Soft 제한을 사용할 수 있다. (like Node Affinity)

### Taints & Tolerations
* Taints
  = 특정 노드에 얼룩을 지정 -> 해당 노드에 포드가 할당되는 것을 막는다.
* Tolerations
  = 포드에 특정 Taints에 대한 Tolerations을 지정해야만 해당 노드에 할당할 수 있다.

매우 다양한 종류의 Taints가 존재한다.
```
(add taints)
kubectl taint nodes nodename key=value:effect

kubectl taint node ip-10-43-0-30.ap-northeast-2.compute.internal \
  alicek106/my-taint=dirty:NoSchedule

(delete taints)
kubectl taint nodes nodename key:effect-

= `key=value` 뒤에 effect를 추가로 명시한다.
= Taint 효과는 Taint가 노드에 설정되었을 때, 어떠한 효과를 낼 것인지 결정한다.

### Taint Effect
1. NoSchedule
  = 포드를 스케줄링하지 않는다.
2. NoExecute
  = 포드의 실행 자체를 혀옹하지 않는다.
  (NoExecute를 설정할 시 해당 노드에서 실행 중인, Tolerations가 설정되어 있지 않은 포드를 종료 시킨다.
    vs NoSchedule: 종료시키지 않는다. 단, 포드가 ReplicaSet or Deployment 등 포드를 관리하는 리소스에 의해 생성되었다? = 다른 노드로 Evicted)
3. PreferNoSchedule
  = 가능하면 스케줄링하지 않는다.

* How to set tolerations on a pod
```
apiVersion: v1
kind: Pod
metadata:
  name: ngnix-toleration-test
spec:
  tolerations:
  - key: alicek106/my-taint
    value: dirty
    operator: Equal
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx:latest

= 해당 Taints를 용인할 수 있다. != 반드시 해당 노드에 스케줄링 한다.

```
API 서버 포드의 정보를 YAML 파일 포맷으로 출력하기

kubectl get pod kube-apiserver-ip-10-43-0-20... -n kube-system -o yaml | grep -F2 toleration

* Operators for Tolerations
1. Equal
2. Exists
  = Taint에 대한 와일드 카드로서 동작(= key, value, effect 항목의 값에 상관 없이 모두 용인 -> 항목이 명시되지 건에 대해서) 

* k8s는 특정 문제가 발생한 노드에 대해서 자동으로 Taint를 추가한다.
ex. NotReady(노드가 아직 준비되지 않은 상태), Unreachable(네트워크가 불안정한 상태), memory-pressure(메모리 부족), disk-pressure(디스크 공간부족) 등
- especially, NotReady or Unreachable은 노드 자체에 장애가 생겼을 수 있다.
  (따라서 k8s는 `node.kubernetes.io/not-ready:NoExecute, node.kubernetes,io/unreachable:NoExecute)의 두 Taint를 추가한다.

* tolerationSeconds
- 포드가 실행 중인 노드에 Taint가 추가되었을 때 해당 Taint를 용인할 수 있는 최대시간
ex. 노드에 장애가 생겨서 위의 Taint가 추가된 경우
  = 기본적으로 300s 유예기간이 생김(300초 동안 노드가 정상적으로 돌아오지 않아, Taint가 없어지지 않는다면 해당 노드에서 실행 중인 포드들은 다른 노드로 옮겨간다. )

kubectl get pod <pod name> -o yaml | grep -F4 tolerationSeconds

### Cordon, Drain & PodDisruptionBudger
1. cordon
kubectl cordon <node name>
  = 해당 노드에 더 이상 포드가 스케줄링 되지 않는다. (명시적인 방법)
  = Taint가 자동으로 추가된다. with unschedulable to `true`
kubectl uncordon (cordon 해제)
 
- cordon 자체는 해당 노드에 이미 실행 중인 포드에는 아무런 영향을 미치지 않는다.
  = why? NoSchedule효과가 있는 Taint를 추가하기 때문에

2. drain
- 노드에서 기존에 실행 중이던 포드를 evict (everything else is similar to `cordon`)
- 해당 노드에 더 이상 포드가 실행되지 않으므로, 커널 버전 업그레이드 or 유지 보수 등으로 잠시 노드를 중지해야 할 때 유용
kubectl drain <node name>
- to damonSet pods or pods that aren't created and managed by Deploymenet, Replicaset, Job, StatefulSet and so on 
  = drain 명령어의 실패 원인
why? 해당 포드들을 drain 한다면, 다시 생성해주는 관리 오브젝트가 없으므로 영원히 제거되기 때문
(force를 사용할 수 있긴 하다.)

3. PodDisruptionBudget
- drain 후 포드가 종료되고, 다른 노드에 생성되는 시점에 downtime이 발생 가능 (or 트래픽 처리 총량 저하)
- 이러한 상황에 대처하기 위해 제공하는 옵션
- 쿠버네티스의 오브젝트 = can be inquired by `kubectl get poddisruptionbudgers
- 포드 eviction 시 특정 개수 or 비율만큼의 포드는 반드시 정상적인 상태를 유지

apiVersion: policy/v1beta1
kind: PodDisruptionBudger
meatadata:
  name: simple-pdb-example
spec:
  maxUnavailable: 1
  # minAvailable: 2
  selector:
    matchLabels:
      app: webserver

* maxUnavailable
- 노드의 포드가 종료될 때, 최대 몇 개까지 동시에 종료될 수 있는지
- 비율로도 나타낼 수 있다. (ex. 30%, 50%)
* minAvailable
- 최소 몇 개의 포드가 정상 상태를 유지해야 하는가

두 옵션 모두 비슷한 맥락이므로, 둘 중 하나만 지정할 수 있다.

...
  metadata:
    name: my-webserver
    labels:
      app: webserver
    spec:
      containers:
      - name: my-webserver

= 적용될 `포드`의 라벨을 입력한다. (not like deploymenet)

### 커스텀 스케줄러 및 스케줄러 확장
* k8s는 kube-system 네임스페이스에 존재하는 기본 스케줄러 외에도, 여러 개의 스케줄러를 동시에 사용할 수 있도록 지원한다.
- (in normal) 포드 생성 시 기본 스케줄러를 사용
  = based on 기본 스케줄러, node filtering & node scoring -> then schedule

kubectl get pod <pod name> -o yaml | grep scheduler

- schedulerName 항목을 지정하지 않으면, 기본적으로 `default-scheduler` 값을 생성
  = 기본 스케줄
  = 별도의 스케줄러를 쓰려면 `schedulerName`을 명시하면 된다.

```
apiVersion: v1
kind: Pod
metadata:
  name: customer-scheduled-pod
spec:
  schedulerName: my-custom-scheduler
  containers:
  - name: nginx-container
    image: nginx
```

- 커스텀 스케줄러를 사용하면, 내부 알고리즘(노드 필터링, 노드 스코어링 등)을 모두 직접 구현해야 하므로, 필요한 경우가 아니라면 기본 스케줄러를 사용하는 것이 바람직하다.

### 쿠버네티스 애플리케이션의 상태와 배포
1. Rolling Update through Deployment
- 포드를 생성할 때 Deployment를 사용하는 이유?
  = 레플리카셋의 변경사항을 저장하는 Revision을 디플로이먼트에서 관리
  = 애플리케이션의 배포를 쉽게 하는 것이 그 목적
- 디플로이먼트에서 변경 사항이 생기면 새로운 레플리카셋이 생성된다.
  = 그에 따른 새로운 버전 애플리케이션이 배포된다.
  = `--record` 옵션을 추가해 디플로이먼트의 변경 사항을 적용하면, 이전에 사용하던 레플리카셋의 정보는 디플로이먼트 히스토리에 기록된다.
  = revision을 이용해 언제든지 원하는 버전의 애플리케이션으로 롤백할 수 있다.

```
kubectl apply -f deployment-v2.yaml --record
kubectl rollout history deployment nginx-deployment
```
- 기본적으로 레플리카셋의 리비전은 10개까지만 히스토리에 저장된다.
  = 필요하다면 디플로이먼트를 생성할 때 `revisionHistoryLimit` 항목을 직접 설정하여, 리비전의 최대 개수를 지정할 수 있다.
ex.
```
kind: Deployment
metadata:
  name: deployment-history-limit
spec:
  revisionHistoryLimit: 3

* 롤링 업데이트 설정
- downtime이 있어도 되는 애플리케이션의 경우, `recreate`로 충분
  = 기존 버전의 포드를 모두 삭제하고, 새로운 버전의 포드를 생성
- `strategy.type` in a yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-recreate
spec:
  replicas: 3
  strategy:
    type: Recreate
```
- 하지만, 다운타임이 허용되지 않는 경우에는 Recreate는 적합하지 않다.
  = 포드를 조금씩 삭제하고 생성하는 `RollingUpdate`를 지원한다.
  = 기존 버전의 포드를 몇 개씩 삭제할 것인지, 새로운 버전의 포드는 몇 개씩 생성할 것인지 직접 설정할 수 있다.
```
...
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 2
```
- maxSurge, maxUnavailable 두 가지 옵션이 있으며, 이 옵션을 적절이 섞어 롤링 업데이트의 속도를 조절할 수 있다.
  = 옵션의 값은 숫자, 비율을 값으로 사용할 수 있다.
  (maxSurge, maxUnavailable의 값이 둘 다 0인 경우 업데이트가 불가능하므로 해당 설정은 불가능)
- 롤링 업데이트는 한 시점에 기존 및 새로운 애플리케이션의 버전이 공존할 수 있다.
  = 따라서, 애플리케이션과 통신하는 기존 컴포넌트 들은, 기존 버전과 새로운 버전 중 어떤 버전과 통신해도 전체 시스템에 문제가 발생해서는 안된다.

2. 블루 그린 배포
- 기존 버전의 포드는 그대로 놔둔다.
- 새로운 버전의 포드를 미리 생성한 뒤, 라우팅만 변경하는 배포방식
  = downtime이 없다.
  = 두 버전의 애플리케이션이 공존하지 않는다.
  = replicas * 2 개수만큼의 포드가 일시적으로 생성되므로, 순간적으로 전체 자원을 많이 사용할 수 있다.
- 쿠버네티스가 자체적으로 지원하지는 않는다.

### 포드의 생애 주기
- 디플로이먼트를 이용해 새로운 버전의 애플리케이션으로 롤링 업데이트를 진행할 때는, 기존 포드가 정상적으로 종료됐는지, 새로운 포드가 사용자의 요청을 처리할 수 있도록 준비되었는지 확인하는 것이 좋다.
  = Running 상태라고 하더라도, 애플리케이션 초기화 등의 작업으로 인해 사용자의 요청을 아직 처리할 준비가 안된 상태일 수도 있다.
  = + 기존의 포드를 종료할 때는 애플리케이션이 처리 중인 요청을 전부 제대로 완료한 뒤에 포드를 종료시켜야 한다.
(위의 부분을 신경쓰지 않으면, 디플로이먼트를 통해 업데이트를 진행할 때 사용자의 요청이 제대로 처리되지 않은 상태로 포드가 종료되는 상황이 발생할 수 있다.)
- k8s 자체적으로 포드가 시작되면, 애플리케이션이 준비됐는지 확인하거나 or 애플리케이션의 graceful shutdown이 가능하도록 지원해준다.

1. 포드의 상태와 생애주기
  1) Pending
  - 포드를 생성하는 요청이 API 서버에 의해 승인됨
  - 어떠한 이유로 아직 실제로 생성이 되지 않은 상태
  ex. 포드가 아직 노드에 스케줄링 되지 않았을 때
  2) Running
  - 포드에 포함된 컨테이너들이 모두 생성되어 포드가 정상적으로 실행된 상태
  3) Completed
  - 포드가 정상적으로 실행되어 종료됐음을 의미
  - 포드 컨테이너의 init 프로세스가 종료 코드 0을 반환한 경우
  4) Error
  - 포드가 정상적으로 실행되지 않은 상태로 종료됐음을 의미
  - init 프로세스가 0외의 status 코드를 반환한 경우
  5) Terminating
  - 포드가 삭제 or eviction 되기 위해 삭제 상태에 머물러 있는 경우

* restartPolicy = always?
  - 포드의 컨테이너가 종료되었을 때 자동으로 다시 재시작된다.
kubectl get pod <pod name> -o yaml | grep restartPolicy
  - always 외에도 Never or OnFailure도 지정 가능
    = 이름대로 Never은 재시작 x, OnFailure은 종료 코드가 0이 아닌 경우만 재시작
ex.
```
apiVersion: v1
kind: Pod
metadata:
  name: completed-pod-restrat-never
spec:
  restartPolicy: Never
  containers:`

* `CrashLoopBackOff`
- 어떠한 작업이 잘못되어 실패했을 때, 일정 간격을 두는 것 (Before retry)
- 실패 횟수가 늘어날 수록 backoff 타임도 늘어난다.

* Running 상태가 되기 위한 조건?
- k8s에서 애플리케이션을 배포할 때 포드의 Running 상태는 매우 중요한 의미를 갖는다.
  = 바람직한 상태, 포드의 컨테이너들이 정상적으로 생성됨
- 문제는, 포드를 생성했다고 무조건 Running 상태가 되는 것이 아니다.
  + Running이라고 해서 내부의 애플리케이션이 제대로 동작하고 있을 것이라는 보장이 없다.
- 따라서, k8s는 
  1. initContainer
  2. postStart
  3. livenessProbe, readinessProbe
기능을 제공한다.
  = 애플리케이션이 많고 복잡해질수록 이러한 기능들이 더 중요해진다.

1. initContainer
- 내부에서 애플리케이션이 실행되기 전 초기화를 수행하는 컨테이너
- 포드의 애플리케이션 컨테이너와 동일하지만, 이들보다 먼저 실행된다는 점이 다르다.
  = 포드의 애플리케이션 컨테이너가 실행되기 전 특정 작업을 미리 수행하는 용도로 사용할 수 있다.
- 1개 이상의 init 컨테이너를 정의한 경우 각 init 컨테이너가 순서대로 실행된다.
```
apiVersion: v1
kind: Pod
metadata: 
  name: init-container-example
spec:
  initContainers:
  - name: my-init-container
    image: busybox
    command: ["sh", "-c", "echo Hello World!"]
  containers:
  - name: nginx
    image: nginx
```
- Init 컨테이너가 하나라도 실패하면, 포드의 애플리케이션 컨테이너는 실행되지 않는다.
- 포드의 restartPolicy에 따라 Init 컨테이너가 재시작된다.
  = 이러한 성질을 이용해 init 컨테이너 내부에서 `dig` or `nslookup` 등의 명령어를 이용해, 다른 디플로이먼트가 생성되기를 기다리거나 애플리케이션 컨테이너가 사용할 설정파일을 미리 준비해둘 수 있다.

ex.
```
apiVersion: v1
kind: Pod
metadata:
  name: init-container-usecase
spec:
  containers:
  - name: nginx
    image: nginx
  initContainers:
  - name: wait-other-service
    image: busybox
    command: ['sh', '-c', 'until nslookup myservice; do echo waiting..; sleep 1; done;']

참고)
- init 컨테이너도 포드에 포함된 컨테이너이다.
  = 포드의 환경을 공유해 사용한다.
  = init 컨테이너에서 emptyDir 볼륨을 사용하거나 포드의 네트워크 정보 등을 가져올 수 있다.

2. postStart
(Running 상태가 되기 위한 조건)
- 포드의 컨테이너가 실행되거나 삭제될 때, 특정 작업을 수행하도록 라이플사이클 훅을 YAML 파일에서 정의할 수 있다.
- 훅에는 두가지 종류가 있다.
  = postStart(컨테이너 시작 시), preStop(컨테이너 종료 시)ㅁ

* postStart 사용
  1) HTTP
  - 컨테이너가 시작한 직후, 특정 주소로 HTTP 요청 전송
  2) Exec
  - 컨테이너가 시작한 직후, 컨테이너 내부에서 특정 명령어 실행

ex)
```
apiVersion: v1
kind: Pod
metadata: 
  name: poststart-hook
spec:
  containers:
  - name: nginx
    image: nginx
    lifecycle:
      postStart:
        exec:
          command: ["sh", "-c", "touch /myfile"]
```
주의)
postStart & container's EntryPoint = 비동기적으로 실행
(어떤 것이 먼저 실행될지 보장이 없다.)

* postStart의 명령어 혹은 HTTP 요청이 제대로 실행되지 않으면 컨테이너는 Running 상태로 전환되지 않는다.
  = init container와 마찬가지로 restartPolicy에 의해 해당 컨테이너가 재시작된다.
