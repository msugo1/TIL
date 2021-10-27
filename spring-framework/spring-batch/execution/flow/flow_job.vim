### FlowJob
for more flexible job configuration!

- 순차적 구성 x, 특정 상태에 따라 흐름을 전환하도록 구성
  = created by FlowJobBuilder

  ex. step fails, but it doesn't necessarily mean its job fails too
    
      step 성공 시 다음에 실행해야 할 step 구분해서 실행
    
      특정 step은 전혀 실행되지 않도록 구성

- Flow, Job은 흐름을 구성하는데만 관여
  = 실제 비즈니스 로직은 Step에서 이루어진다.

- 내부적으로 SimpleFlow 객체를 포함
  = Job 실행시 호출

ex.
                    Flow Job
                       |
                       |
                    Success?
                       /\
                      /  \
                    Yes  No
                    /      \
                  Flow    Step B

  = 성공과 실패 시 모두 잡이 성공하게 된다.

### API
* JobBuilderFactory > JobBuilder > JobFlowBuilder > FlowBuilder > FlowJob
(단순한 Step으로 생성하는 SimpleJob 보다 생성 구조가 더 복잡하고 많은 API를 제공)

- start(flow or step)

- on(String pattern)
  = Step의 실행 결과로 돌려받는 종료 상태(= ExitStatus) catch -> which pattern matches
  = TransitionBuilder 반환

- to(step)
  = 다음으로 이동할 스텝 지정
  = on 다음에 무엇을 할 것인지

- stop() / fail() / end() / stopAndRestart()
  = Flow를 중지, 실패, 종료하도록

- from(step)
  = 이전 단계에서 정의한 Step의 Flow를 `추가적`으로 정의

- next(step)
  = 다음으로 이동할 Step 지정

- end()
  = build 앞에 위치하면 FlowBuilder 종료, SimpleFlow 객체 생성

- build
  = FlowJob 생성 & flow 필드에 SimpleFlow 저장

* start, from, next
  = 흐름을 정의하는 역할

* on, to, stop/fail/end/stopAndRestart
  = 조건에 따라 흐름을 전환시키는 역할

### FlowBuilder
- FlowJob을 생성할 때, 핵심 컴포넌트

* FlowBuilder.on 호출 시 `TransitionBuilder` 작동
  -> Step 간 조건부 전환을 구성할 수 있게된다.

 
    TransitionBuilder - to, stop, end, fail, stopAndRestart
    = 위의 메소드 호출 시 FlowBuilder 반환
    = 다시 API 전환
      -> start, next, from, split 등을 사용할 수 있게 된다.

```kotlin
    @Bean
    @Primary
    fun batchJob() = jobBuilderFactory.get("batchJob")
        .start(step1())
        .on("COMPLETED").to(step3())
        .from(step1())
        .on("FAILED").to(step2())
        .end()
        .build()
```

* execution
1. start
  - simple job builder (same as before)

2. on
  1) new JobFlowBuilder(new FlowJobBuilder(this), step))
    - FlowJobBuilder
      = 최종적으로 Job 생성
    - JobFlowBuilder
      = Flow 생성, 관리, 제어
  2) new TransitionBuilder<>(this, pattern)
  
3. to, ~

4. end
  - build
  - SimpleFlow 생성

SimpleFlow가 잡 실행
  = JobFlowExecutor 


---
* start
  - start(flow)
  = JobFlowBuilder

  - start(step)
  = SimpleJobBuilder

* next(step or flow or jobExecutionDecider)

```kotlin
@Bean
    @Primary
    fun batchJob() = jobBuilderFactory.get("batchJob")
        .start(flowA())
        .next(step3())
        .next(flowB())
        .next(step6())
        .end()
        .build()
```
- flow로 여러 스텝을 담아 흐름을 묶을 수 있다는 장점이 있다.
- 하지만 여전히 한 스텝이 실패하면 전체 Job이 Fail 한다는 것은 알아두자!

### Architecture
                            updateStatus(execution, BatchStatus.STARTED)
                                         ExecutionContext
                                                |
                                                |          (beforeStep)
              JobParameters   JobsInstance  JobExecution    JobListener
                    |               |           |                |
                    |               |           |                |
  JobLauncher --------------------------------------> FlowJob ---------> FlowExecutor ----
              <-------------------------------------         <----------              <---
                                 |                               |
                                 |                               |
                            JobExecution                    JobListener
                                                            (afterStep)
                ```
                jobExecution.status = flowExecution.status
                exitStatus.and(ExitStatus(flowExecution.status.name)
                jobExecution.exitStatus = exitStatus

                (flowExecutionStatus 상태로 업데이트)
                ```


flowExecution
      |                                 (State)
      |                                   Step
--------------> SimpleFlow --------->     Flow
---------------            <---------    Decider
      |                         |
      |                         |
  FlowExecution <------- FlowExecutionStatus
     작업 상태를 FlowExecution에 업데이트
    * result = FlowExecution(stateName, status)

### in code
- almost identical
- classes that are handled are different


