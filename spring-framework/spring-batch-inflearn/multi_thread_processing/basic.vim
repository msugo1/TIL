### 멀티 스레드 프로세싱 - 기본개념
  - 프로세스 내 특정작업을 처리하는 스레드가 여러 개일 경우
  
  * 선택기준?
    - 싱글 스레드 vs 멀티 스레드
      = 어떤 방식이 자원을 효율적으로 사용하고, 성능처리에 유리한가?

  ex. 복잡한 처리 or 대용량 데이터를 다루는 작업
    = 멀티 스레드를 사용하는 것이 `전체 소요시간` 및 `성능상의 이점`을 가져온다면 멀티 스레드 방식 선택!

    - 멀티 스레드 처리 방식은 데이터 동기화 이슈가 존재한다.
      = 최대한 고려해서 결정하자
    
      * 스레드 관련 커스터마이징을 할 수 있는 범위는 굉장히 제한적 
        & 스프링 배치가 제공하는 부분은 내부적으로 동기화 처리를 해준다.
        = 다만 스프링 배치와 다른 무언가를 연동할 때 문제가 발생할 수 있다.




                                                  main 
                                                 thread
                                                  / | \
                                                 /  |  \
                                                /   |   \
                                               /    |    \
                                            worker1 2    3
                                               |    |    |
                                               |    |    |
                                            taskA   B    C


### Structure

    Step  --------------------> TaskExecutorRepeatTemplate --------------------> TaskExecutor
                                              |                                       |
                                              |                                       | execute()
                      ----- Runnable take()   |              ThreadPool              \|/ (FutureTask)
                     |                        |              ---------------------------------------------------
              RepeatStatus                    |               Thread1             Thread2             Thread3
                                              |                  |                   |                   |
                                              |                   \                  |                  /
                                              |                     -----------------|-----------------
                                              |                                      | run()
                                              |                     ------------------------------------
                                              |                    |        ExecutingRunnable           |
                                              |                    |              run()                 |
                                              |      put(Runnable) |                                    |
                                     BlockingQueue <---------------|   - RepeatCallback callback        |
                                 (ensure thread-safety)            |- ResultQueue<ResultHolder> queue   |
                                                                   |    - RepeatStatus result           |
                                                                   |                                    |
                                                                    ------------------------------------
                                                                                      |
                                                                                      | execute()
                                                                                     \|/
                                                                            ChunkOrientedTasklet
                                                                                      |
                                                                        ------------------------------
                                                                       |              |               |
                                                                  ItemReader     ItemProcessor     ItemWriter
                    

  * 각각의 스레드가 run() 호출
    = 각각의 RepeatCallback이 실행된다.

  * 기존의 ChunkOrientedTasklet과 똑같이 Reader -> Processor -> Writer의 과정을 거친다.
  * 실행 결과로 RepeatStatus가 반환되며, 이를 판별하기 위해 자기 자신(thread)을 BlockingQueue에 넣는다.
  * 나중에 take로 가져와 RepeatStataus를 보고 반복 여부를 확인한다.

### 스프링 배치 스레드 모델
  - 기본적으로 단일 스레드 방식으로 작업처리
  - 성능향상과 대규모 데이터 작업을 위한 비동기 처리 및 Scale out 기능을 제공
  - Local & Remote 처리를 지원한다.

1. AsyncItemProcessor/AsyncItemWriter
  - ItemProcessor에 별도의 스레드를 할당해 작업처리
  - 처리된 작업을 받아서 다시 처리하는 것이 AsnycItemWriter

2. Multi-threaded Step
  - Step 내 청크 구조인 ItemReader, ItemProcessor, ItemWriter 마다 여러 스레드가 할당되어 실행하는 방법

3. Remote Chunking
  - 분산환경처럼 Step 처리가 여러 프로세스로 분할되어 외부의 다른 서버로 전송되어 처리하는 방식

4. Parallel Steps
  - Step 마다 스레드가 할당되어 여러 개의 스텝을 병렬로 실행

5. Partitioning
  - Master/Slave 방식으로 Master가 데이터를 파티셔닝 한 다음 각 파티션에게 스레드를 할당하여 Slave가 독립적으로 작동하는 방식

