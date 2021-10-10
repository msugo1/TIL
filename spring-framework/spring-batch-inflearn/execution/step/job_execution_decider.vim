### JobExecutionDecider
 for transition without manipulating ExitStatus nor registering StepExecutionListener

- step, transition의 역할을 명확히 분리
- step은 exitStatus 대신
    jobExecutionDecider의 `FlowExecutionStatus` 상태값을 새롭게 설정해서 반환

* normal flow job
  = ExitStatus ---> FlowExecutionStatus ---> JobFlow ---> DB

* but for jobExecutionDecider
  = (No ExitStatus considered) FlowExecutionStatus ---> JobFlow ---> DB

### Structure
```
FlowExecutionDecider decide(jobExecution: JobExecution, stepExecution: StepExecution)
```

```kotlin
@Bean
fun batchJob() = jobBuilderFactory.get("batchJob")
    .start(step1())
    .next(decider())
    .from(decider()).on("ODD").to(oddStep())
    .from(decider()).on("EVEN").to(evenStep())
    .end
    .build()

@Bean
fun decider() = OddDecider()

class OddDecider : JobExecutionDecider {

    var count = 0

    override fun decide(jobExecution: JobExecution, stepExecution: StepExecution?): FlowExecutionStatus {
        count++
        return if (count % 2 == 0) {
            FlowExecutionStatus("EVEN")
        } else {
            FlowExecutionStatus("ODD")
        }
    }
}
```

### in code
1. SimpleFlow.start

2. (SimpleFlow)
  - state.handle(executor)
  (state has a decider)

3. decider.decide(executor.getJobExecution())
  - 구현한 decide 호

4. state.handle 결과 -> status
  - status를 기준으로 실행 플로우 판단
  = SimpleFlow stateTransition.matches(exitCode)
  = PatternMatcher.match(pattern, status)



