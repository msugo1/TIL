### ExitStatus
- 존재하지 하지 않는 exitCode 새롭게 정의해서 설정
  = stepExecutionListener afterStep() 메서드에서 Custom exitCode 생성
      then, 새로운 exitStatus 반환

- Step 실행 후 완료 시점에서 현재 exitCode를 사용자 정의 exitCode로 수정

```kotlin
ex.

@Bean
fun step1() = stepBuilderFactory.get("step1")
    .tasklet { contribution, chunkContext ->
        RepeatStatus.FINISHED
    }
    .listener(PassCheckingListener())
    .build

class PassCheckingListener : StepExecutionListener {

    override fun afterStep(stepExecution: StepExecution) =
        stepExecution.exitStatus.exitCode.run {
        if (this == ExitStatus.FAILED.exitCode) {
            ExitStatus("Do Pass")
        } else {
            null
        }
    }
}

* How ExitStatus is acquired?
```kotlin
exitStatus.and(stepExecution.getExitStatus())

stepExecution.exitStatus = exitStatus

exitStatus.and(getCompositeListener().afterStep(stepExecution))
```

### 주의
@Bean
fun batchJob() = jobBuilderFactory.get("batchJob")
    .start(step1())
    .on("FAILED").to(step2())
    .on("PASS").stop()
    .end()
    .build()

= step2 에서 on("PASS") 외에는 아무런 처리를 안해주고 있다.
  -> 스프링 배치가 PASS 외에 다른 상태코드가 반환되면 FAILED로 자동처리한다.


