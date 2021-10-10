### Transition
- 상태 전이

* 배치 상태 유형
1. BatchStatus
  - JobExecution, StepExecution의 속성
    = Job과 Step의 종료 후 최종 결과 상태가 무엇인지 정의

SimpleJob
  - 마지막 Step의 BatchStatus 값을 잡의 최종 BatchStatus 값에 반영
  - Step이 실패할 경우 해당 Step이 마지막 Step

FlowJob
  - 플로우 내 스텝의 ExitStatus 값을 FlowExecutionStatus 값으로 저장
  - 마지막 Flow의 FlowExecutionStatus 값을 잡의 최종 BatchStatus 값으로 반영

상태 값
- COMPLETED, STARTING, STARTED, STOPPED, STOPPING, FAILED, ABANDONED, UNKNOWN

* ABANDONED?
  - 처리를 완료했지만 성공하지 못한 경우
    or 재시작 시 건너 뛰어야하는 단계

2. ExitStatus
  - Job과 Step 실행 후 어떤 상태로 종료되었는지?
  (기본 적으로 ExitStatus == BatchStatus)

SimpleJob
  - 마지막 Step의 ExitStatus 값을 Job의 최종 ExitStatus로 반영

FlowJob
  - Flow 내 Step의 ExitStatus 값을 FlowExecutionStatus 값으로 저장
  - 마지막 Flow의 FlowExecutionStatus 값을 Job의 최종 ExitStatus 값으로 반 

상태 값
- UNKNOWN, EXECUTING, COMPLETED, NOOP, FAILED, STOPPED
  = ExitStatus(exitCode: String)

3. FlowExecutionStatus
  - FlowExecution의 속성
  - Flow 실행 후 최종결과 상태가 무엇인지 정의
  - Flow 내 스텝이 실행되고 나서 ExitStatus 값을 FlowExecutionStatus 값으로 저장
  - FlowJob의 배치 결과상태에 관여

상태 값
- COMPLETED, STOPPED, FAILED, UNKNOWN

### in code (FlowJob)
1. doExecute
  - executor.updateJobExecutionStatus(flow.start(executor).getStatus())
    = 결과 값을 반영
  
  execution.setStatus(findBatchStatus(status))
  exitStatus = exitStatus.and(ExitStatus(status.getName()))
  execution.exitStatus = exitStatus

### Transition
  - Flow 내 Step의 조건부 전환 정의
    = Flow 내 다른 Flow or Step이 있을 수 있음
    = 조건에 따라 ~ 호출
  - `on` 호출 시 TransitionBuilder 반환 
    = prerequisite for transition flows
  - Step 종료상태가 어떤 pattern과도 매칭되지 않는 경우?
    = 예외 발생 -> Job 실패
  - transition은 구체적인 것부터 그렇지 않은 순서로 적용

* on(pattern: String)
  - 스텝의 실행결과(ExitStatus)에 매칭하는 패턴 스키마
    != BatchStatus
  - 일치하는 패턴에 대해 다음 실행 대상 지정 (with `to`)
  - 특수문자는 `*` or `?`만 허용
    = *: 0개 이상의 문자 매칭
    = ?: 정확히 1개 매칭

  ex.
  c?t - cat(true), count(false)
  c*t - cat(true), count(true)
 
* to()
  - 다음으로 실행할 단계

* from()
  - 이전 단계에서 정의한 transition을 새롭게 추가 정의

### Job을 중단하거나 종료하는 Transition API
  - flow 실행 시 flowExecutionStatus에 상태값 저장 -> 이후 최종적으로 Job의 BatchStatus와 ExitStatus에 반영
  - Step의 BatchStatus or ExitStatus에는 아무런 영향 없음
    = Job의 상태만을 변경

* stop()
  - FlowExecutionStatus = STOPPED 상태로 종료
  - Job의BatchStatus, ExitStatus = STOPPED

* fail()
  - FlowExecutionStatus = FAILED 상태로 종료
  - Job의BatchStatus, ExitStatus = FAILED 

* end() 
  - FlowExecutionStatus = COMPLETED 상태로 종료
  - Job의BatchStatus, ExitStatus = COMPLETED
    = Step.ExitStatus == FAILED인 경우에도 BatchStatus == COMPLETED 가 가능하도록 함
    = 이때 Job의 재시작은 불가능

* stopAndRestart(step or flow or jobExecutionDecider)
  - stop() transition과 기본 흐름은 동일
  - 특정 step에서 작업 중단 설정 
    -> 중단 이전까지의 step만 `COMPLETED`
    (이후 스텝은 `STOPPED`)
    -> Job이 다시 실행됐을 때 실행해야 할 step을 restart 인자로 넘길 시, COMPLETED 처리 된 스텝은 skip
    (중단된 지점 이후 step 부터 다시 시작)

ex.
- step 1~4

```
conditions

1. 단계 1을 실행해서 종료 상태가 "FAILED"인 경우
  -> 단계 2 실행
  -> 단계 2 가 성공하면 종료 상태와 관계없이 작업중단(stop)

2. 단계 1을 실행해서 종료상태와 상관없이 단계 3실행
  -> 단계 3 성공 시 단계 4 실행
  -> 단계 4 실행 후 종료상태와 상관없이 작업종료


@Bean
fun batchJob = jobBuilderFactory.get("batchJob")
    .start(step1())
      .on("FAILED").to(step2())
      .on("*").stop()
    .from(step1())
      .on("*").to(step3())
      .next(step4())
      .on("*")
      .end()
    .end()
    .build()

TIP: 패턴 매칭은 구체적인 것이 우선순위!
  ex. COMPLETED > *
```


