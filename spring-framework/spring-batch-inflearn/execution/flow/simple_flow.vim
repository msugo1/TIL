### SimpleFlow
  - 스프링 배치에서 제공하는 Flow의 구현체
    = 각 요소(Step, Flow, JobExecutionDecider)들을 담고 있는 `State` 실행
  - FlowBuilder를 사용해서 생성
  - with Transition, 여러 개의 Flow 및 중첩 Flow 구성가능 in a Job


                  Flow

- State getState(String stateName
  = State 명으로 State 타입 반환

- FlowExecution start(FlowExecutor executor)
  = Flow를 실행시키는 메소드
  = FlowExecutor 넘겨주어 실행위임
  = 실행 후 FlowExecution 반환

- FlowExecution resume(String startName, FlowExecutor executor)
  = 다음에 실행할 State를 구해서 FlowExecutor에게 실행 위임

- Collection<State> getStates()
  = Flow가 가진 모든 State Collection 타입반환
                 / \
                  |
                  |

               SimpleFlow
- String name (flow name)

- State startState 
= 처음 실행할 State

- Map<String, Set<StateTransition>> transitionMap
  = State 명으로 매핑되어 있는 Set<StateTransition>

- Map<String, State>
  = State 명으로 매핑되어 있는 State 객체

- List<StateTransition> stateTransitions
  = State와 Transition 정볼르 가진 리스트

- Comparator<StateTransition> stateTransitionComparator

### Flow를 외부에서 구성하면 재사용이 가능

### in code
* SimpleFlow (top)
  = has `State`
  
  -> State has each element
    = executed by SimpleFlow

  -> Simple state runs flows or steps or such components in it

```
1. FlowBuilder.createState
    & all the components are made (Configuration)

* FlowJob
  - SimpleFlow
  - SimpleFlow has flows, steps 

2. SimpleFlow.start(executor)
  - state.handle(executor)
    = 각각의 state 안에 있는 스텝 or 플로우 실행
  ex. FlowState.flow.start(executor)
  - 모든 flow, step이 실행되면 전체적인 플로우 끝

### Flow 장점?
- 하나의 플로우에 또다른 플로우 중첩사용 가능
  = 중첩된 플로우가 다른 스텝 or 플로우 가질 수 있음
(복잡하지만 다양한 상황에 대한 플로우를 손쉽게 구성할 수 있다.)

```kotlin
(example)

@Configuration
class JobConfiguration(

    private val jobBuilderFactory: JobBuilderFactory,

    private val stepBuilderFactory: StepBuilderFactory,

    private val customJobParametersValidator: CustomJobParametersValidator
) {

    @Bean
    fun flowJob(): Job {
        return jobBuilderFactory.get("flowJob")
            .start(flow1())
            .on("COMPLETED").to(flow2())
            .end()
            .build()
    }

    @Bean
    fun flow1(): Flow {
        return FlowBuilder<Flow>("flow1").start(step1())
            .next(step2())
            .end()
    }
    
    @Bean
    fun step1(): Step {
        return stepBuilderFactory.get("step1")
            .tasklet { contribution, chunkContext -> 
                println("step1 has been executed")
                RepeatStatus.FINISHED
            }
            .build()
    }

    @Bean
    fun step2(): Step {
        return stepBuilderFactory.get("step2")
            .tasklet { contribution, chunkContext ->
                println("step2 has been executed")
                RepeatStatus.FINISHED
            }
            .build()
    }

    @Bean
    fun step4(): Step {
        return stepBuilderFactory.get("step4")
            .tasklet { contribution, chunkContext ->
                println("step has been executed")
                RepeatStatus.FINISHED
            }
            .build()
    }
    
    @Bean
    fun step5(): Step {
        return stepBuilderFactory.get("step5")
            .tasklet { contribution, chunkContext ->
                println("step5 has been executed")
                RepeatStatus.FINISHED
            }
            .build()
    }

    @Bean
    fun step6(): Step {
        return stepBuilderFactory.get("step6")
            .tasklet { contribution, chunkContext ->
                println("step6 has been executed")
                RepeatStatus.FINISHED
            }
            .build()
    }

    @Bean
    fun flow2(): Flow {
        return FlowBuilder<Flow>("flow2")
            .next(step5())
            .next(step6())
            .end()
    }
    
    @Bean
    fun flow3(): Flow {
        return FlowBuilder<Flow>("flow3")
            .next(step4())
            .end()
    }
}
``` 


             Job
      ------------------
     |       Flow       |
     |   ------------   |
     |  |    Flow1   |  |
     |  |   -------  |  |
     |  |  | Step1 | |  |
     |  |  | Step2 | |  |
     |  |   -------  |  |
     |   ------------   |
     |  |    Flow2   |  |
     |  |   -------  |  |
     |  |  | Step3 | |  |
     |  |  | Step3 | |  |
     |  |   -------  |  |
     |  |    Step5   |  |
     |  |    Step6   |  |
     |   ------------   |
      ------------------

* 어떤 타입이 인자로 주어지냐에 따라서 다른 state를 저장한다.

from FlowBuilder, with start, next, from

1. step - stepState
2. flow - flowState
3. decider - decisionState

then with executor - splitState
              |
              |
   now `StateTransition`
      1. state 
        = 현재 state
      2. pattern
      3. next
        = 다음 state
              |
              |
         in SimpleFlow
 1. Map<String, State> stateMap
 2. State startState
 3. Map<String, Set<StateTransition>> transitionMap
 **4. List<StateTransition> stateTransitions**
    = 위에서 생성한 StateTransition이 여기 저장된다.

* transition은 구체적인 것부터 그렇지 않은 순서로 적용된다.
* simpleFlow를 구성하고 있는 모든 step 들이 transition에 따라 분기되어 실행
* simpleFlow 내 simpleFlow를 2중, 3중으로 중첩해서 복잡하게 구성가능

              
          CurrentState ------- StateTransition ------- NextState
                                    /|\
                                     |
                                     |        
        SimpleFlow ---- 실행---->  State
                  
                            1. String getName()
              2. FlowExecutionStatus handle(FlowExecutor executor)
                          3. boolean isEndState()
      
              * Step, Flow, JobExecutionDecider 의 각 요소들을 저장
              * Flow를 구성하면 내부적으로 생성되어 Transition과 연동
              * handle() 메소드 실행 후 FlowExecutionStatus 반환
                = on(pattern)의 pattern 값과 매칭여부 판단
                = 마지막 실행상태가 FlowJob의 최종상태

                                    /|\
                                     |
                                     |
                               AbstractState
                                     |
                                     |
          --------------------------------------------------------------
         |               |               |              |               |
     StepState       FlowState     DecisionState     EndState      SplitState

       step            flow           decider                         flows





  
                                     executor.executeStep()  stepHandler.handleStep(step)
                               --> StepState --> JobFlowExecutor --> StepHandler --> Step
                              / 
                             / 
   FlowJob ----> SimpleFlow -  state.handle(executor)
    flow.start(executor)     \
                              \       flow.start(executor)      
       return FlowExecution    --> FlowState --> SimpleFlow --> FlowState --> SimpleFlow 
                              |                            |
                              |                             --> StepState
                              |                            |
                              |                             --> DecisionState
                              |                            |
                              |                             --> SplitState
                              |
                               --> DecisionState ----> JobExecutionDecider
                              |      decider.decide(jobExecution, stepExecution)
                              |
                              |
                               --> SplitState ---> SimpleFlow ---> FlowState
                                             |
                                              ---> SimpleFlow ---> StepState
                                  (multi-threaded)


= SimpleFlow 
  - StepMap에 저장되어 있는 모든 State 들의 handle 메서드 호출
    (모든 스텝들이 실행될 수 있도록)
  - 현재 호출되는 State가 어떤 타입인지 모르고 관심도 없음
    (단지 handle 메소드 실행 후 상태 값만 얻어온다.)
 
### execution
                                          처음 실행 될 StartState 지정 후 실행
                                             ----> start()
                           start()          |
  FlowJob ---> FlowExecution ---> SimpleFlow ------------> (loop) resume()
                                      |     |    - 현재 state 실행 후 다음 state 실행
                                      |     |    - 실행 순서는 설정/조건에 따라 결정
                                      |     |         (순차적 x)
                                      |     |    - state == null or 실행불가능하면 종료
                                      |     |
                                      |      ------------> nextState()
                                   *stateMap*       stateMap에서 다음 실행할 state 선택
                                   StepState
                                   FlowState
                                   DecisionState

* from `start`

          start() <-----
                        |    ---> StepState ---> Step
                        |   |
                    resume() ---> FlowState ---> Flow
                        |   |
                        |    ---> StepState ---> Step
        nextState() <---
            |
 <----------
* lookup StateMap

### in code
1. on
  -> steps iteration (steps registered)
  -> builder.next or builder = new JobFlowBuilder(new FlowJobBuilder(this), step)

2. start
  -> doStart

3. createState
  -> this.currentState = createState(input)
    = StepState 객체 생성 & 맵에 저장

4. on, to
  (Transition)
  next = parent.createState(step)
  parent.addTransition(pattern, next)
  parent.currnetState = next
  retrun parent

  * addTransition
    = transitions.add(StateTransition.createStateTransition(currentState, pattern, next.getName()))
    = if (transitions.size() == 1) 인 경우 추가처리
    = if (next.isEndState()) 인 경우 추가처

** 위의 과정 반복 **

5. finally, flow = SimpleFlow(name)
  with end()

then execute 
FlowJob 
  -> flow.start(executor)
    = start `startState`, which is the first step or flow registered
  -> resume(stateName, executor)
    = 맨 첫 state를 얻어와서 resume 호출
    = 계속해서 현재 상태, 다음 상태가 무엇인지 알아내서 실행

SimpleFlow
  -> state.handle(executor)
     
  -> nextState?
     exitCode = status.getName
     = 종료코드 매칭 확인
     = stateTransition.isEnd 여부 확인
      (종료일 경우 return null, 아닐 경우 반복 by next = stateTrainsition.getNext()

StepState
  -> return FlowExecutionStatus(executor.executeStep(step))

