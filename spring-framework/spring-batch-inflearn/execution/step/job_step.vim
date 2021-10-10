### JobStep
- job에 속하는 Step 중 외부의 Job을 포함하고 있는 스텝
  = job을 품은 스텝
  = a job in a step

- 외부 job 실패 -> job을 품은 step 실패 -> 기본 job 최종 실패
- 모든 메타데이터는 기본 Job, 외부 Job 별로 각각 저장된다.
  = 스텝에 속한 잡도 별도의 독립적인 잡
  = 스텝은 단순히 잡을 실행시켜주는 역할

- 커다란 시스템을 작은 모듈로 쪼개고, 잡의 흐름을 관리하고자 할 때 사용

### StepBuilderFactory -> StepBuilder -> JobStepBuilderFactory -> JobStep
```kotlin
fun jobStep() = stepBuilderFactory.get("jobStep")
    .job(job) - jobStepBuilder 반환
    .launcher(jobLauncher) - job 을 실행할 jobLauncher 설정
    .parametersExtractor(jobParametersExtractor) - step의 executionContext를 job 실행에 필요한 jobParameters로 변환
    .build()
```
