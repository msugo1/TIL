### Spring Batch Test
  since 4.1 (Spring Batch)

`@SpringBatchTest`
- 자동으로 애플리케이션 컨텍스트에 테스트에 필요한 여러 유틸 빈을 등록해주는 어노테이션

1. JobLauncherTestUtils
  - launchJob(), launchStep()과 같은 스프링배치 테스트에 필요한 유틸성 메소드 지원

2. JobRepositoryTestUtils
  - jobRepository를 사용해서, jobExecution 생성/삭제 기능 메소드 지원

3. StepScopeTestExecutionListener
  - `@StepScope` 컨텍스트 생성해주며, 해당 컨텍스트를 통해 JobParameter 등을 단위 테스트에서 DI 받을 수 있음

4. JobScopeTestExecutionListener
  - `@JobScope` 컨텍스트를 생성해주며, 해당 컨텍스트를 통해 JobParameter 등을 단위 테스트에서 DI 받을 수 있음


                    

                            JobLauncherTestUtils

            @Autowired
          - void setJob(Job job)
          ## 실행할 Job을 자동으로 주입받음
          ## 한개의 Job만 받을 수 있음 (Job 설정 클래스를 한개만 지정해야 함)

          - JobExecution launchJob(JobParameters jobParameters)
          ## Job을 실행시키고 JobExecution 반환


          - JobExecution launchStep(String stepName)
          ## Step을 실행시키고 JobExecution 반환






                            JobRepositoryTestUtils

          - List<JobExecution> createJobExecutions(String jobNames, String[] stepNames, int count)
          ## JobExecution 생성 - job 이름, step 이름, 생성 개수

          - void removeJobExecution(Collection<JobExecution> list)
          ## JobExecution 삭제 - JobExecution 목록
 

ex.

@ExtendWith(SpringExtension::Class.java)
@SpringBatchTest
@SpringBootTest(classes = [BatchJobConfiguration:class, TestBatchConfig::class])
class BatchJobConfigurationTest {

}

  @SpringBatchTest 
  - JobLauncherTestUtils, JobRepositoryTestUtils 등을 제공

  @SpringBootTest(classes = )
  - Job 설정 클래스 지정, 통합테스트를 위한 여러 의존성 빈들을 주입받기 위한 어노테이션




@Configuration
@EnableAutoConfiguration
@EnableBatchProcessing
class TestBatchConfig


  @EnableBatchProcessing 
  - 테스트 시 배치환경 및 설정 초기화를 자동 구동하기 위한 어노테이션

  
  - 테스트 클래스마다 선언하지 않고, 공통으로 사용하기 위함


@ExtendWith(SpringExtension::class)
@SpringBatchTest
@SpringBootTest(classes = [RetryConfiguration::class, TestBatchConfig::class])
class SimpleJobTest {

    @Autowired
    lateinit var jobLauncherTestUtils: JobLauncherTestUtils

    @Autowired
    lateinit var jdbcTemplate: JdbcTemplate

    @BeforeEach
    fun clear_before() {
        jdbcTemplate.execute("DELETE FROM customer4")
    }

    @Test
    fun simple_job_test() {
        // given
        val jobParameters = JobParametersBuilder()
            .addString("name", "user1")
            .addLong("date", Date().time)
            .toJobParameters()

        // when
//        val jobExecution = jobLauncherTestUtils.launchJob(jobParameters)
        val stepExecutions = jobLauncherTestUtils.launchStep("simpleStep1").stepExecutions

        // then
//        assertEquals(jobExecution.status, BatchStatus.COMPLETED)
//        assertEquals(jobExecution.exitStatus, ExitStatus.COMPLETED)

        stepExecutions.forEach { stepExecution ->  
            assertEquals(stepExecution.commitCount, 15)
            assertEquals(stepExecution.readCount, 1400)
            assertEquals(stepExecution.writeCount, 1400)
        }
    }


    @AfterEach
    fun clear_after() {
        jdbcTemplate.execute("DELETE FROM customer4")
    }

}


@Configuration
@EnableAutoConfiguration
@EnableBatchProcessing
class TestBatchConfig



