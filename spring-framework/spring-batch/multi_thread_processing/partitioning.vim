### Partitioning
  - MasterStep이 SlaveStep을 실행시키는 구조
    = SlaveStep은 각 스레드에 의해 독립적으로 실행
    = SlaveStep은 독립적인 StepExecution 파라미터 환경을 구성
    = SlaveStep은 ItemReader, ItemProcessor, ItemWriter 등을 가지고 동작하며, 작업을 독립적으로 병렬처리

    MasterStep = PartitionStep
    SlaveStep = TaskletStep, FlowStep ...


  MainThread ----
|       
|       Job
|   
|       Step          ------------------> SlaveStep (worker)
|        |           |
|       \|/          |
|    MasterStep    ---------------------> SlaveStep (worker)
|        |           |
|       \|/          |
|       Step          ------------------> SlaveStep (worker)

  
  * 마스터 스텝은 Step 분배
  * 슬레이브 스텝은 각각의 ItemReader, Processor, Writer를 가지고 별도의 스레드(워커 스레드)에서 실행


### 핵심 컴포넌트
      
                                            PartitionStep
            
                               - PartitionHandler partitionHandler
                         - StepExecutionSplitter stepExecutionSplitter
                        - StepExecutionAggregator stepExecutionAggregator

        ## 파티셔닝 기능을 수행하는 스텝 구현체
        ## 파티셔닝 수행 후 StepExecutionAggregator를 통해 StepExecution 정보 최종집계



                                          PartitionHandler

   - Collection<StepExecution> handle(StepExecutionSplitter, StepExecution: masterStepExecution)

        ## PartitionStep에 의해서 호출
          = 스레드를 생성해서 WorkStep을 병렬로 실행
        ## WorkStep에서 사용할 StepExecution 생성은 StepExecutionSplitter, Partitioner에 위임
        ## WorkStep을 병렬로 실행 후, 최종 결과를 담은 StepExecution을 PartitionStep에 반환

                                          
                                           
                                          StepExecutionSplitter

                      - Set<StepExecution> split(masterStepExecution, int gridSize)

        ## WorkStep 에서 사용할 stepExecution을 gridSize만큼 생성
          (gridSize = thread 개수)
        ## Partitioner를 통해 ExecutionContext를 얻어서 stepExecution에 매핑
          
  

                                               Partitioner
                         
                            - Map<String, ExecutionContext> partition(int gridSize)
           ## StepExecution에 매핑 할 ExecutionContext를 gridSize만큼 생성
           ## 각 ExecutionContext에 저장된 정보는 WorkStep을 실행하는 스레드마다 독립적으로 참조 및 활용가능


### in codes
1. PartitionStep.doExecute(stepExecution)
  - Collection<StepExecution> executions = partitionHandler.handle(stepExecutionSplitter, stepExecution)
  
2. PartitionHandler.handle(stepExecutionSplitter, masterStepExecution)
  - Set<StepExecution> stepExecutions = stepSplitter.split(masterStepExecution, gridSize)

3. StepExecutionSplitter.split(masterStepExecution, gridSize) 
  ## 여기서 slave Step 생성, masterStepExecution을 전달해 마스터 스텝의 정보를 활용할 수 있도록

  ...
  if (context.isDirty()) {
      jobRepository.updateExecutionContext(stepExecution)
      result = partitioner.partition(splitSize) ## partitioner 호출
  }
      
4. Partitioner.partition(int gridSize) 
  ```
    Map<String, ExecutionContext> map = new HashMap<>(gridSize)
    for (int i = 0; i < gridSize; i++) {
        map.put(PARTITION_KEY + i, new ExecutionContext())
    }

    return map
  ```

5. PartitionHandler.handle
  - return doHandle(masterStepExecution, stepExecutions) ## WorkerStep 들이 실행할 최종 StepExecution 생성

## Step을 실행하기 위해서는 StepExecution, ExecutionContext가 쌍으로 필요하다
  - 위 1 ~ 5까지는 슬레이브 스텝들에 대한 준비작업
6. PartitionHandler.doHandle(managerStepExecution, Set<StepExecution> partitionStepExecutions): Set<StepExecution>

  ```
    ...

    Set<Future<StepExecution>> tasks = HashSet<>(getGridSize())
    Set<StepExecution> result = HashSet<>()

    ## 실제 스텝을 실행시킴 (slave steps)
    for (stepExecution: partitionStepExecutions) {
        ## slave step 은 사실 하나, 각 스레드마다 별도의 stepExecution, executionContext를 가짐
        ##    각각 독립적으로 존재하기 때문에 스텝을 공유하더라도 동시성 문제가 발생하지 않는다.
        FutureTask<StepExecution> task = createTask(step, stepExecution)
        
        try {
            ## 병렬로 실행
            taskExecutor.execute(task)
            tasks.add(task)
        } 
    }
    ...

    for (Future<StepExecution> task : tasks) {
        result.add(task.get())  ## 실행 후 정보를 담고 있는 각 StepExecution을 Set에 저장 후 반환
    }

    return result
  ```

### Architecture

            Job
             |
            \|/
        PartitionStep
          (Master)
             |
             |
   -------------------------------------------------------------------
  |                                         |                         |
 \|/                                       \|/        handle         \|/            split()    gridSize
StepExecutionAggregator              PartitionHandler ------> StepExecutionSplitter ------->  Partitioner -----
 /|\                                        |                                                      |           |
  |                                        \|/                                                     |           |
  | ## 실행결과 취합                  StepExecutions <---------------------------------------------            |
  |                                         |       ## gridSize 만큼 stepExecution, ExecutionContext 생성      |
  |                                        \|/      ## gridSize 만큼 태스크 및 스레드 생성                     |
  |                                   TaskExecutor  ## ExecutionContext에 각 스레드가 공유할 데이터 설정       |
  |                               -------------------                                                          |
  |                              |      Worker       |                                                         |
  |                              | ----------------- |                                                         |
   ------------------------------||   FutureTask    ||                                                         |
                                 ||-----------------||                                                         |
                                 ||TaskletStep(Slave)|                                                         |
                                 | ----------------- |                                                         |
                                  -------------------                                                          |
                                            |                                                                  |
                                            |                                                                  |
                                             -------------> 스레드별로 독립적으로 StepExecution 실행<----------
                                                      
                                                        StepExecution(ExecutionContext) Data 1 ~ 50
                                                        StepExecution(ExecutionContext) Data 51 ~ 100
                                                        StepExecution(ExecutionContext) Data 101 ~ 150
                                                                 

### Partitioning
  - 각 스레드는 자신에게 할당된 StepExecution을 가지고 있다.
  - 각 스레드는 자신에게 할당된 청크 클래스를 참조한다.
  - Thread-safe를 만족한다.


                                                Partitioning
                                                     |
                                                    \|/
                                        StepExecutions (gridSize 만큼)
                                                     |
                                                    \|/
                                                TaskExecutor
                                                     |
                             -------------------------------------------------
                            |                        |                        |
                        Worker 1                  Worker 2                Worker 3
                            |                        |                        |
                             ---------------------->\|/<----------------------
                                                     |
                                                     |
                                                FutureTask
                                               (TaskletStep)
                                                     |
                                                    \|/
         --------------------------------- ChunkOrientedTasklet --------------------------------------
        |                                            |                                                |
       \|/            Chunk<Inputs>                 \|/              Chunk<Outputs>                  \|/
SimpleChunkProvider ----------------------> SimpleChunkProcessor -------------------------> SimpleChunkProcessor
        |                                            |                                                |
       \|/                                          \|/                                              \|/
ItemReaderProxy                             ItemProcessorProxy                                  ItemWriterProxy
          |                                          |                                                |
     ------------------------- 
    |             |           |
ItemReader1  ItemReader2  ItemReader3    ......


## Scope를 기억하는가?
 @JobScope, @StepScope

- 스코프를 붙여놓으면, 프록시 객체를 대신 생성해서 넣어놓는다.
- 해당 스텝 or 잡이 호출될 때마다 스코프 빈을 별도로 생성한다.
- 여기서도 똑같은 개념이 사용된다.
  = Proxy 객체는 모든 워커스레드가 공유한다.
  = 그래고 나눠진 stepExecution, stepExecutionContext를 실행할 때 별도의 Reader, Writer, Processor가 만들어진다.


### API
1. partitioner("slaveStep", new ColumnRangePartitioner()) ## slaveStep + Partitioner 구현체
                                                          ## 주어진 이름으로 슬레이브 스텝 생성
2. step(slaveStep()) ## 슬레이브 역할을 하는 스텝설정
3. gridSize(int) ## 파티션 몇개로 나눌 것인
4. taskExecutor(ThreadPoolTaskExecutor()) ## 스레드 생성, 풀 관리

### examples
```
@Configuration
class RetryConfiguration(

    val jobBuilderFactory: JobBuilderFactory,

    val stepBuilderFactory: StepBuilderFactory,

    val dataSource: DataSource
) {

    @Bean
    fun job() = jobBuilderFactory.get("batchJob")
        .incrementer(RunIdIncrementer())
        .listener(StopWatchJobListener())
        .start(masterStep())
        .build()

    @Bean
    fun masterStep() = stepBuilderFactory.get("masterStep")
        .partitioner(slaveStep().name, partitioner())
        .step(slaveStep())
        .gridSize(4)
        .taskExecutor(SimpleAsyncTaskExecutor())
        .build()

    @Bean
    fun partitioner() = ColumnRangePartitioner(dataSource = dataSource, column = "id", table = "customer3")

    @Bean
    fun slaveStep() = stepBuilderFactory.get("slaveStep")
        .chunk<Customer3, Customer3>(1400)
        .reader(jdbcItemReader(null, null))
        .writer(jdbcItemWriter())
        .build()

   @Bean
    fun taskExecutor() = ThreadPoolTaskExecutor().apply {
        this.corePoolSize = 2
        this.maxPoolSize = 4
        this.setThreadNamePrefix("ASYNC-THREAD")
      }

    @Bean
    @StepScope
    fun jdbcItemReader(
        // 각각의 StepExecution 이 자신만의 min/maxValue 를 가지고 있다!
        // 따라서 아래의 세팅이 가능하다
        @Value("#{stepExecutionContext['minValue']}") minValue: Long?,
        @Value("#{stepExecutionContext['maxValue']}") maxValue: Long?,
    ): ItemReader<Customer3> {
        println("reading item from $minValue to $maxValue")
        return JdbcPagingItemReaderBuilder<Customer3>()
            .name("jdbcItemReader")
            .dataSource(dataSource)
            .fetchSize(1400)
            .beanRowMapper(Customer3::class.java)
            .queryProvider(MySqlPagingQueryProvider().apply {
                this.setSelectClause("id, first_name, last_name, birthdate")
                this.setFromClause("FROM customer3")
                this.setWhereClause("WHERE id >= $minValue and id <= $maxValue")
                this.sortKeys = mapOf(
                    "id" to Order.ASCENDING
                )
            })
            .build()
    }

    @Bean
    @StepScope
    fun jdbcItemWriter() = JdbcBatchItemWriterBuilder<Customer3>()
        .dataSource(dataSource)
        .sql("""
            INSERT INTO customer4 (id, first_name, last_name, birthdate) VALUES (:id, :first_name, :last_name, :birthdate)
        """.trimIndent())
        .itemSqlParameterSourceProvider(BeanPropertyItemSqlParameterSourceProvider())
        .build()

data class Customer3(
    var id: Int = 0,
    var first_name: String = "",
    var last_name: String = "",
    var birthdate: String = ""
)

class ColumnRangePartitioner(
    dataSource: DataSource,
    private val jdbcTemplate: JdbcTemplate = JdbcTemplate(dataSource),
    private val table: String,
    private val column: String
) : Partitioner {

    override fun partition(gridSize: Int): MutableMap<String, ExecutionContext> {
        val min = jdbcTemplate.queryForObject("""
            SELECT MIN($column) FROM $table
        """.trimIndent(), Int::class.java) ?: 0

        val max = jdbcTemplate.queryForObject("""
            SELECT MAX($column) FROM $table
        """.trimIndent(), Int::class.java) ?: 0

        val targetSize = (max - min) / gridSize

        val result = hashMapOf<String, ExecutionContext>()
        var number = 0
        var start = min
        var end = start + targetSize - 1

        while (start <= max) {
            val value = ExecutionContext()
            result["partition$number"] = value

            if (end >= max) {
                end = max
            }

            value.putInt("minValue", start)
            value.putInt("maxValue", end)
            start += targetSize
            end += targetSize
            number++
        }

        return result
    }
}
```
