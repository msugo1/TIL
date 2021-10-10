### JobRepository

- 배치 작업 중의 정보를 저장하는 저장소
- 모든 metadata 저장
  ex. when job is executed, done, how many times it is executed, execution result, and so on
  = JobLauncher, Job, Step 구현체 내부에서 CRUD 기능을 처리함

                                           ----------> ItemReader
                                          |
  JobLaucher ------> Job ------> Step ---------------> ItemProcessor
      |               |           |       |
      |               |           |        ----------> ItemWriter
      |               |           |
     CRUD           CRUD        CRUD
      |               |           |
      ------------------------------
             JobRepository
      ------------------------------

  = 매 시점마다 CRUD 작업이 발생한다.
    ex. 매 스텝이 끝날 때마다

* 메소드
1. boolean isJobInstanceExists(String jobName, JobParameters jobParameters)

2. JobExecution createJobExecution(String jobName, JobParameters jobParameters)

3. JobExecution getLastJobExecution(String jobName, JobParameters jobParameters)

4. void update(JobExecution jobExecution)
  = Job의 실행정보 업데이트

5. void update(StepExecution stepExecution)
  = Step의 실행정보 업데이트

6. void add(StepExecution stepExecution)
  = 실행 중인 해당 Step의 새로운 stepExecution 저장

7. void updateExecutionContext(stepExecution stepExecution)
  = Step의 공유 데이터 및 상태정보를 담고 있는 ExecutionContext 업데이트

8. void updateExecutionContext(JobExecution jobExecution)
  = Job의 공유 데이터 및 상태정보를 담고 있는 ExecutionContext 업데이트

9. StepExecution getLastStepExecutionContext(JobInstance jobInstance, String stepName)
  = 해당 Step의 실행 이력 중 가장 최근의 StepExecution 반환

### JobRepository 설정
- @EnableBatchProcessing 어노테이션만 선언하면 JobRepository가 자동으로 빈으로 생
- BatchConfigurer 인터페이스를 구현 or BasicBatchCongiruer를 상속해서 JobRepository의 설정을 커스터마이징 가능

ex. JDBC
  = JobRepositoryFactoryBean
  - AOP로 트랜잭션 처리
  - SERIALIZABLE 격리 수준(배치는 여러 사용자의 동시다발적인 요청 처리를 하는 것이 아니므로 문제X, 변경가능)
  
```kotlin
override fun createJobRepository(): JobRepository =
    JobRepositoryFactoryBean().apply {
        this.setDataSource(dataSource)
        this.setTransactionManager(transactionManager)
        this.setIsolationLevelForCreate("ISOLATION_SERIALIZABLE")
        this.setTablePrefix("SYSTEM_") - 기본값: BATCH
        this.setMaxVarCharLength(1000) - 기본값: 2500
    }
}
```

