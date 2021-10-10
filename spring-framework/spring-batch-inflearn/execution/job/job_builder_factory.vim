### JobBuilderFactory & JobBuilder
* JobBuilderFactory
  - JobBuilder를 생성하는 팩토리 클래스
  - `get(String name)` 메소드 존재
    = "jobName"은 스프링배치가 Job을 실행시킬 때 참조하는 Job의 이름
    (이름은 DB에도 저장이 된다.)

* JobBuilder
  - Job을 구성하는 설정 조건에 따라 두 개의 하위 빌더 클래스 생성, 실제 잡 생성 위임
  
1. SimpleJobBuilder
  - SimpleJob을 생성하는 Builder 클래스
  - Job 실행과 관련된 여러 설정 API 제공

* 제공하는 API
- start(step)
- next(step)
- on(String pattern) -> TransitionBuilder
- start(decider) -
                  |
- next(decider)  ------> FlowBuilder
- split(taskExecutor) -> SplitBuilder

2. FlowJobBuilder
  - FlowJob을 생성
  - 내부적으로 FlowBuilder 반환 -> Flow 실행과 관련된 여러 설정 API 제공

* API
- on(String pattern) -> TransitionBuilder
- start(step or flow)
- next(step or flow)
- from(step or flow)
- start(decider)
- next(decider)
- from(decider)
  = FlowExecutionDecider
- split(taskExecutor) -> SplitBuilder

### Architecture
                                                          1
                                                 ---> start(step) ---> simpleJobBuilder
                                                |                      (simpleJob 생성)
                                                |               2
  JobBuilderFactory --- get(jobName) ------ JobBuilder ---> start(flow) ---
                                                |                          |
                                                |                          |
                                                | (flowJob 생성) ---- FlowJobBuilder                           
                                                |                         / \
                                                |                          |
                                                |                          |
                                                |               3          |
                                                 ----------> flow(step)----

= 총 3가지의 경우가 존재
= 어떤 API를 설정하느냐에 따라 무엇이 생성되는지가 결정된다.

                                                    FlowBuilder
                                                        / \
                                                         |
                                                         |
    FlowJobBuilder ---- start(flow or step) -----> JobFlowBuilder
                                                         |
                                                         |
                                                         |
                                                      Flow 생성


### 클래스 상속구조

                            JobBuilderFactory
                                   |
                                   |                                                - JobInstanceDao
                                  \ /                                              |
  CommonJobProperties <------ JobBuilderHelper -------------> SimpleJobRepository --- JobExecutionDao
                              /   / \    \                              |          |
                             /     |      \                             |           - StepExecutionDao
                            /      |       \                            |          |
                           /       |        \                           |          - ExecutionContextDao
                          /   JobBuilder     \                          |
                         /         |          \                         |
                        /        (create)      \                        |
                       /           |            \                       |
                SimpleJobBuilder <- ------> FlowJobBuilder              |
                        |                         |                     |
                       \ /                       \ /                    |
                     SimpleJob                  FlowJob                 |
                       / \                       / \                    |
                        |                         |                     |
                         -----------------------------------------------
     
= JobRepository는 빌더 클래스를 통해 Job 객체에 전달
-> 메타데이터를 기록하는데 사용된다.
             
* CommonJobProperties
  - 잡의 실행과 관련된 공통 속성을 가지고 있음

* 잡이 생성되는 시점부터 전달되어 (JobRepository) 메타데이터들을 저장하기 위한 초기화 작업을 함

* JobFlowBuilder - Flow 생성
  FlowJobBuilder - FlowJob 생성

* xxxBuilderFactory
  - SimpleBatchConfiguration에서 빈으로 생성
    = 따로 빈 설정이 필요없다.

