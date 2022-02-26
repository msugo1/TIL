### Thread
- CPU 이용의 기본단위
    = 스레드 ID, PC, 레지스터 집합, 스택으로 구성
    = 같은 프로세스에 속한 달느 스레드와 코드, 데이터 섹션, 열린 파일 or 신호와 같은 운영체제 자원 `공유`
- 프로세스 생성 per request?
    = 많은 시간/자원 소비
    = 새 프로세스가 기존 프로세스와 할 일이 동일하다면 오버헤드를 감수해야 할까?
    = 스레드의 등장!

**kthreadd(pid = 2)**
- 다른 모든 커널 스레드의 부모

### 멀티 스레드 프로그래밍의 장점
1. 응답성
2. 자원공유
- 명시적으로 자원 공유를 해야하는 멀티 프로세스와는 달리 스레드는 자동으로 프로세스의 자원, 메모리 공유
3. 경제성
- 컨텍스트 스위칭이 더 경제적(compared to multi processes)
    = 일반적으로 스레드 생성 < 프로세스 생성
4. 규모 적응성(scalability)

### critical point?
1. 태스크 인식
- 요청을 분석하여 독립된 병행가능 태스크로 나눌 수 있는 영역을 찾는 작업이 필요하다.
(ideal: 태스크는 서로 독립적)

2. 균형
- 찾아진 부분들이 전체 작업에 균등한 기여도를 가지도록 태스크로 나누는 것

3. 데이터 분리
- 태스크가 접근하고 조작하는 데이터 또한 개별 코어에서 사용할 수 있도록 나뉘어야 한다.

4. 데이터 종속성
- 동기화의 필요(둘 이상의 태스크 사이에 종속성이 있는가)

5. 시험 및 디버깅
- 병렬로 실행 시, 다양한 실행 경로가 존재할 수 있음
    = 단일 스레드보다 디버깅이 힘듦.

### 사용자 스레드 vs 커널 스레드
1. 사용자 스레드
- 사용자 수준의 스레드
- 커널 위에서 지원(커널의 지원 없이 관리)

2. 커널 스레드
- 운영체제에 의해 직접 지원, 관리

1) 다대일 모델
- 많은 수의 사용자 스레드 to 하나의 커널 스레드
- 스레드 관리 by 사용자 공간의 `스레드 라이브러리`
- 한 스레드가 커널에 blocking call할 경우 전체 프로세스 block
    = 한 번에 하나의 스레드만 커널에 접근할 수 있으므로, 
    = 결국 다중코어의 이점을 살릴 수 없어 지금은 거의 존재하지 않는다.

2) 일대일 모델
- one by one (one user thread to one kernel thread)
    = 하나가 blocking call 하더라도, 여전히 다른 커널 스레드에 요청보낼 수 있음(좀 더 높은 병렬성)
- 사용자 스레드마다 커널 스레드를 만들어야 하므로 시스템 성능에 부담을 줄 수 있다.
- Linux, Windows

3) 다대다 모델
user threads -> one point <- kernel threads
- 일대일과 다대일의 단점 보안
- 구현하기가 어렵다...
- 대부분의 시스템에서 처리 코어수가 증가 -> 커널 스레드 수를 제한하는 것의 중요성 저하
    = 대부분의 OS는 이제 일대일 모델 사용

### Executor (in Java)
- producer <-> consumer 모델 기반
    = 스레드 생성을 실행에서 분리
    = 병행하게 실행되는 작업간의 통신 기법 제공
    ex. Callable
    = 자바에는 전역 데이터에 대한 개념이 없으므로, Runnable 구현체에 매개변수는 전달할 수 있으나, `반환 값`을 받을 수 없다.
    = Callable에서는 `Future`을 반환한다.

ex.
```java
class Summation implements Callable<Integer> {

    private int upper;
    
    public Summation(int upper) {
        this.upper = upper;
    }

    /* the thread will execute in this method */
    public Integer call() {
        int sum = 0;
        for (int i = 1; i <= upper; i++) {
            sum += i;
        }
        
        return new Integer(sum);
    }
}

public class Driver {

    public static void main(String[] args) {
        int upper = Integer.parseInt(args[0]);
        ExecutorService pool = Executors.newSingleThreadExecutor();
        Future<Integer> result = pool.submit(new Summation(upper));

        try {
            System.out.println("sum = " + result.get());
        } catch (InterruptException | ExecutionException ie) {
            ...
        }
    }
}
```
- execute() vs submit()
    = execute: 결과반환X
    = submit: 결과반환 via Future

