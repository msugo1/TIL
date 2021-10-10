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
