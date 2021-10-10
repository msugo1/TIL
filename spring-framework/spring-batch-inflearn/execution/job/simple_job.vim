### SimpleJob
- Step을 실행시키는 Job 구현체
- SimpleJobBuilder에 의해서 생성
- 여러 단계의 Step으로 구성
  = 구성된 Step은 순차적으로 실행
- 모든 스텝의 실행이 성공적으로 완료되어야 잡이 성공
- 맨 마지막에 실행한 Step의 BatchStatus가 잡의 `최종` BatchStatus

* API
- start, next (step)
  = 처음 실행 or 다음 실행할 Step 설정
  = start 메소드 호출 시 SimpleJobBuilder 반환
  = next에 설정된 모든 스텝이 종료되야 잡이 종료

- incrementer
  = JobParameter의 값을 자동증가해주는 incrementer 설정

- preventRestart
  = 잡의 재시작 가능여부 설정 (default: True)
  = false로 설정 시 재시작 불가

- validator
  = JobParameter를 실행하기 전 올바른 구성이 되었는지 검증
  = .validator(jobParameterValidator)

- listener
  = Job의 라이프사이클 특정시점에 콜백제공
    ex. job 실행 전/후
  = .listener(JobExecutionListener)

- build
  = SimpleJob 생성

나머지는 공식문서 참고

* 실행 순서
start(step)
  - SimpleJobBuilder(this).start(step)
  = SimpleJobBuilder 반환
  = this = jobBuilder
    jobBuilerHelper를 상속받고 있음
    -> 내부적으로 commonJobProperties 갖고 있음
    -> 설정한 항목들이 이곳에 저장
    -> 나중에 저장된 값들을 SimpleJob에 세팅
      (jobBuilderHeplper.enhance(job)

* start, next에 인자로 `step`을 주지 않는다면 `flow, flowJob`이 반환됨에 주의

### validator
- 잡 파라미터 검증
  = 검증에 성공한 파라미터에 대해서만 잡 수행

- `DefaultJobParametersValidator` 지원
  = 복잡한 제약조건이 있으면 인터페이스 구현도 가능

```kotlin
class CustomJobParametersValidator : JobParametersValidator {

    override fun validate(parameters: JobParameters?) {
        parameters?.let { params ->
            if (params.getString("name") == null) {
                throw IllegalArgumentException("a required parameter, 'name' is not found")
            }
        }
    }

}

JobParametersValidator
  = void  validate(@Nullable JobParameters parameters)


    SimpleJob --> JobParametersValidator (required or optionaKeys) --> validate 
```

- 이름에서 의미하듯이 required는 모두 있어야, optional은 없어도 상관x

* validation 수행시점
1. jobRepository의 기능이 시작하기 전
2. job이 시작하기 전

### DefaultJobParametersValidator
(what spring provides by default to validate job parameters)

- requiredKeys, optionalKeys as an Array
  = 등록한 key값들을 검증 

### prevent restart
- 잡의 재시작을 차단
  = 재시작 하려고 하면, `JobRestartException`
- 재시작과 관련있으므로, 처음 시작하는 것과는 아무런 관련이 없음

### incrementer
- jobParameters에서 필요한 값을 증가시켜, 다음에 사용될 JobParameters 오브젝트를 리턴
  = 기존 잡 파라미터 변경 없이 잡을 여러 번 시작하고자 할때
  (why? 동일한 잡 이름, 잡 파라미터로는 잡 인스턴스가 한 번만 생성되기 때문)
- `RunIdIncrementer` 지원
  = of course, 인터페이스 직접 구현가능
  JobParametersIncrementer
    jobParameters getNext(@Nullable JobParameters parameters)

* .incrementer(jobParametersIncrementer)

### SimpleJob Architecture
(Job -> Step -> Tasklet)
                                                                    
                                                         stepExecution --- executionContext (for each step)
                                                              |
        with job params                          --- loop --- | ----------------
               |                                | Step ---------------> Tasklet |
  JobLauncher ----------> SimpleJob ----------> | Step ---------------> Tasklet |
                   |                    |       | ...                           |
                   |                    |        -------------------------------
                   |                     ---
              JobInstance                   |
                   |                         --------- JobListener (JobExecutionListener.`beforeJob()`)
                   |
              JobExecution
                   |  
                   |
            ExcutionContext
(배치 상태 = STARTED by updateStatus(execution, BatchStatus.STARTED)


              <----------           <----------
                   |                      |
                   |                       ---------- JobListener (JobExecutionListener.`afterJob()`) 
                   |
              jobExecution
       (작업 단계를 마지막 Step 단계와 동일하게 업데이트)
      ```kotlin
       if (stepExecution != null) {
          execution.upgradeStatus(stepExecution.getStatus())
          execution.setExitStatus(stepExecution.getExitStatus())
       }
      ```

