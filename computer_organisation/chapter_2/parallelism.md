parallelism for cooperating tasks
- jeopardy for data race (race condition)
- synchronization in need
    by lock
    = 하나의 프로세서만이 작업할 수 있는 영역 생성
    = mutual exclusion
- 멀티 프로세서에서 동기화를 구현하기 위해서는 메모리 주소에서 읽고 수정하는 것을 `원자적`으로 처리할 능력을 가진 하드웨어 프리미티브가 있어야 한다.
    = 메모리에서 읽고 쓰는 중간에 아무것도 끼어들 수 없어야 한다.

### 1. atomic exchange or atomic swap
: 원자적 교환

교환 프리미티브를 사용해서 동기화를 구현
- 교환 여러 개가 동시에 발생하더라도 하드웨어에 의해 순서가 결정된다.
- 여럿이 동시에 자기가 성공했다고 생각하는 경우는 있을 수 없다.

1) 단일 원자적 메모리 연산을 하기 위해서는, 메모리 읽기와 쓰기를 방해가 불가능한 `명령어 하나`로 처리해야 한다.
    = 프로세서 설계 난이도 급증!

2) 명령어 두 개로 처리하기
    = 두 명령어가 한 쌍의 명령어처럼 실행되었는지 나타내는 값을 반환
    = 이 쌍이 실질적으로 원자적이면, 다른 어느 프로세서도 두 명령어 사이에서 값을 바꿀 수 없다.

**load linked** & **store conditional**
- 이 명령어 쌍은 순차적으로 사용된다.
- load linked에 의해 명시된 메모리 주소의 내용이 같은 주소에 대한 store conditional 명령어가 실행되기 전에 바뀐다?
    = store conditional 명령어 실패
- load linked 주소에 또 다른 저장이 시도되거나, 예외가 일어나면 store conditiaonl 실패
    = 두 명령어 사이에 들어갈 명령어들을 고르는데는 신중해야 한다.
    (레지스터 - 레지스터) 명령어는 안심하고 사용해도 된다.
    = 다른 명령어들은 계속 `페이지 부재`를 일으켜서 프로세서가 sc를 완료할 수 없는 `dead lock` 상태를 일으킬 수 있다.
    = ll <-> sc 사이에 들어가는 명령어가 되도록 적게 하자!

store condntional
- 레지스터 값을 메모리에 저장 + 성공 시 레지스터 값을 1, 0으로 바꾼다.
    = two operations simultaneously 

```
again: addi $t0, $zero, 1 // copy locked value
   ll       $t1, 0($s1) // load linked
   sc       $t0, 0($s1) // store conditional
   beq      $t0, $zero, again // branch if store fails(0)
   add      $s4, $zero, $t1 // put load value in $s4
```
- ll <-> sc 사이에 메모리 값 수정시 0을 반환
    = reiterate till it returns 1
    = eventually atomic
- `atomic compare and swap` or `atomic fetch-and-increment` 같은 다른 동기화 프리미티브들을 만드는데 사용이 가능하다.

