### JobExplorer

  - JobRepository's readonly version
  - 실행중인Job의 실행정보인 JobExecution or Step의 실행정보인 StepExecution 조회가능


    
                                                JobExplorer

                     List<JobInstance> getJobInstances(String jobName, int start, int count)
         
                                 JobExecution getJobExecution(Long executionId)

                     StepExecution getStepExecution(Long jobExecutionId, Long stepExecutionId)

                                    JobInstance getJobInstance(Long instanceId)
 
                          List<JobExecution> getJobExecutions(JobInstance jobInstance)
    
                           Set<JobExecution> findRunningJobExecutions(String jobName)
      
                                            List<String> getJobNames()
                                      ## 실행가능한 Job들의 이름을 얻는다.
        


### JobRegistry

  - 생성된 잡을 자동으로 등록, 추적 및 관리하여 여러 곳에서 잡을 생성한 경우 ApplicationContext에서 잡을 수집해서 사용할 수 있음

  - 기본 구현체로 map 기반의 MapJobRegistry 클래스 제공
    = jobName - key, job - value

  - Job 등록
    = JobRegistryBeanPostProcessor - BeanPostProcessor 단계에서 bean 초기화 시 자동으로 JobRegistry에 Job을 등록시켜 준다.



                                                    JobRegistry

                                        void register(JobFactory jobFactory)
      
                                             void unregister(String name)

                                               void getJob(String name)

                                              Set<String> getJobNames()


### JobOperator

  - jobExplorer, jobRepository, jobRegistry, jobLaucher를 포함하고 있으며, 배치의 중단, 재시작, job 요약 등의 모니터링이 가능

  - 기본 구현체로 SimpleJobOperator 클래스 제공


                                              JobOperator

                             Set<String> getJobNames()
                             ## 실행가능한 Job들의 이름을 얻는다. 

                             int getJobInstancecount(String jobName)
                             ## JobInstance 개수를 얻는다.

                             List<JobInstance> getJobInstances(String jobName, int start, int count)
                             ## start 인덱스부터 count 만큼의 jobInstances의 id들을 얻는다.

                             List<Long> getRunningExecutions(String jobName)
                             ## jobName을 이용하여 실행중인 Job의 JobExecutions의 id를 얻는다.

                             Properties getParameters(long executionId)
                             ## Job의 Execution id를 이용하여 Parameters를 얻는다.

                             start(String jobName, Properties jobParameters)                              
                             ## Job 이름, Job Parameter를 이용하여 Job을 시작한다.

                             restart(long executionId, Properties restartParameters)
                             ## JobExecutionId를 이용하여, 정지되었거나 이미 종료된 Job 중 재실행 가능한 Job을 재시작한다.   

                             Long startNextInstance(String jobName)
                             ## 항상 새로운 잡을 실행시킨다. 잡에 문제가 있거나 처음부터 재시작할 경우에 적합

                             stop (long executionId)
                             ## JobExecutionId를 이용하여, 실행 중인 job을 정지시킨다.
                             ## graceful하게 동작

                             JobInstance getJobInstance(long executionId)
                             ## JobExecutionId를 이용하여 JobInstance를 얻는다.

                             List<JobExecution> getJobExecutions(JobInstance instance)
                             ## JobInstance를 이용하여, JobExecution을 얻는다.

                             JobExecution getJobExecution(long executionId)
                             ## JobExecutionId를 이용하여 JobExecution을 얻는다.

                             List<StepExecution> getStepExecutions(long jobExecutionId)
                             ## JobExecutionId를 이용하여 StepExecution들을 얻는다.

## in codes
1. JobRegistryBeanPostProcessor.postProcessAfterInitialization(Object bean, String beanName)
  ```
  if (bean instanceof Job) {
      Job job = (Job) bean
      try {
          ...
          RefrenceJobFactory jobFactory = new RefrenceJobFactory(job)
          ...
          jobRegistry.register(jobFactory)
          ```
            ...
            jobFactory previousValue = map.putIfAbsent(name, jobFactory)
          ```
          jobNames.add(name)
      }
  }


### examples
```
@Configuration
class JobOperationConfiguration(

    val jobBuilderFactory: JobBuilderFactory,

    val stepBuilderFactory: StepBuilderFactory,

    val jobRegistry: JobRegistry
) {
    @Bean
    fun job1() = jobBuilderFactory.get("opJob")
        .incrementer(RunIdIncrementer())
        .start(opStep1())
        .next(opStep2())
        .build()

    @Bean
    fun opStep1() = stepBuilderFactory.get("opStep1")
        .tasklet { contribution, chunkContext ->
            println("step1 has been executed")
            Thread.sleep(10000)
            RepeatStatus.FINISHED
        }
        .build()

    @Bean
    fun opStep2() = stepBuilderFactory.get("opStep2")
        .tasklet { contribution, chunkContext ->
            println("step2 has been executed")
            Thread.sleep(10000)
            RepeatStatus.FINISHED
        }
        .build()

    @Bean
    fun jobRegistryBeanPostProcessor() = JobRegistryBeanPostProcessor().apply {
        this.setJobRegistry(jobRegistry)
    }
}

@RestController
class JobController(

    private val jobRegistry: JobRegistry,

    private val jobExplorer: JobExplorer,

    private val jobOperator: JobOperator
) {
    @PostMapping("/batch/start")
    fun start(@RequestBody jobInfo: JobInfo): String {

        jobRegistry.jobNames.forEach {
            val job = jobRegistry.getJob(it) as SimpleJob
            println("jobName: ${job.name}")
            jobOperator.start(job.name, "id=${jobInfo.id}")
        }

        return "batch has been started"
    }

    @PostMapping("/batch/stop")
    fun stop(): String {

        jobRegistry.jobNames.forEach {
            val job = jobRegistry.getJob(it) as SimpleJob
            println("jobName: ${job.name}")

            val jobExecutions = jobExplorer.findRunningJobExecutions(job.name)
            jobExecutions.forEach { jobExecution ->
                jobOperator.stop(jobExecution.id)
            }
        }

        return "batch has been started"
    }

    @PostMapping("/batch/restart")
    fun restart(): String {

        jobRegistry.jobNames.forEach {
            val job = jobRegistry.getJob(it) as SimpleJob
            println("jobName: ${job.name}")

            jobExplorer.getLastJobInstance(it)?.let { lastInstance ->
                jobExplorer.getLastJobExecution(lastInstance)?.let { lastExecution ->
                    jobOperator.restart(lastExecution.id)
                }
            }

        }

        return "batch has been restarted"
    }
}

data class JobInfo(

    val id: String
)
```
