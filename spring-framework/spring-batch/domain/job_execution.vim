### JobExecution
- job instance에 대한 한 번의 시도를 의미하는 객체
  = job instance 가 실행될 때마다 생성
- Job 실행 중에 발생한 정보들을 저장하고 있는 객체

in relation with job instance?
  = job의 실행 결과 상태를 가지고 있다. ex. FAILED, COMPLETED
    -> COMPLETED의 경우 job instance의 실행이 완료된 것으로 간주 (재실행 불가)
    -> FAILED의 경우 똑같은 job instance로 재실행 가능하다.
      (물론, 별도의 job execution 객체가 매번 생성된다.)  
    job execution의 실행 상태 결과가 completed가 될 때까지 하나의 job instance 내에서 여러 번의 job execution이 있을 수 있음

  = job instance (1) : job execution (N)

in Job Execution
1. jobParameters
2. jobInstance
3. executionContext
  = 실행 동안 유지해야 되는 데이터를 담고 있음
4. batchStatus
  = 실행 상태를 나타내는 enum
  = COMPLETED, STARTING, STARTED, STOPPING, STOPPED, FAILED, ABANDONED, UNKNOWN
5. exitStatus
  = 실행 결과를 나타내는 클래스 (종료코드 포함)
  = UNKNOWN, EXECUTING, COMPLETED, NOOP, FAILED, STOPPED
6. failureExceptions
7. startTime
8. createTime
9. endTime
10. lastUpdate

