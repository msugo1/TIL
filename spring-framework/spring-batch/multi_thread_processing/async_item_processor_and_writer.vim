### AsyncItemProcessor / AsyncItemWriter
  - Step 안에서 ItemProcessor가 비동기적으로 동작하는 구조
  - AsyncItemProcessor, AsnycItemWriter가 함께 구성되어야 한다.
    = 둘이 연결되서 실행되기 때문
    = AsyncItemProcessor는 List<Future<T>>를 반환
    = 비동기 실행이 완료될 때까지 대기?

  - spring-batch-integration 의존성이 필요



            --------> ItemReader
           |                |
           |               \|/                    delegate               (new Thread)
      Step  --------> AsyncItemProcessor --------------------------> ItemProcessor
           |                | (List<Future>)
           |                |
           |               \|/         delegate
            --------> AsyncItemWriter ----------> ItemWriter
  


            AsyncItemProcessor

  ## 실제 process를 수행하는 ItemProcessor
  - ItemProcessor<I, O> delegate

  ## Thread를 생성하고 Task를 할당
  - TaskExecutor taskExecutor = new SyncTaskExecutor()

  ## Thread가 수행하는 Task. Callable를 실행시키고 결과를 Future<V>에 담아 반환
  - FutureTask<O> task = new FutureTask<>(Callable  <V>)


                         Job
                          |
                         \|/
                     TaskletStep
                          |
                         \|/
                ChunkOrientedTasklet
                          |
                          |
   --------------------------------------------------
  |                       |                          |
ItemReader ------> AsyncItemProcessor ------> AsyncItemWriter
        Chunk<inputs>     |       List<Future<T>>    |
                          |                          |
                          | delegate                 | delegate
                          |                          |
                          |                          |
                    TaskExecutor                ItemWriter                    ------> 비동기 실행 결과값을 모두
                                                                             |        받아오기까지 대기
                    WorkerThread                   List                      |
                    -----------                 ----------               write(list)
                     FutureTask                   Future    -----------------------------------> DB
                     ----------                   ------
                   ItemProcessor                    Item

 
### examples
    @Bean
    fun job() = jobBuilderFactory.get("batchJob")
        .incrementer(RunIdIncrementer())
        .start(asyncStep1())
        .listener(StopWatchJobListener())
        .build()

    @Bean
    fun step1() = stepBuilderFactory.get("step1")
        .chunk<Customer3, Customer3>(100)
        .reader(jdbcItemReader())
        .processor(customItemProcessor())
        .writer(jdbcItemWriter())
        .build()

    @Bean
    fun asyncStep1() = stepBuilderFactory.get("asyncStep1")
        .chunk<Customer3, Future<Customer3>>(100)
        .reader(jdbcItemReader())
        .processor(asyncItemProcessor())
        .writer(asyncItemWriter())
        .build()

    @Bean
    fun asyncItemProcessor() = AsyncItemProcessor<Customer3, Customer3>().apply {
        this.setDelegate(customItemProcessor())
        this.setTaskExecutor(SimpleAsyncTaskExecutor())
    }

    @Bean
    fun asyncItemWriter() = AsyncItemWriter<Customer3>().apply {
        this.setDelegate(jdbcItemWriter())
    }

    @Bean
    fun customItemProcessor() = ItemProcessor<Customer3, Customer3> {
        Thread.sleep(30)
        Customer3(it.id, it.first_name.uppercase(), it.last_name.uppercase(), it.birthdate)
    }
    
    @Bean
    fun jdbcItemReader() = JdbcPagingItemReaderBuilder<Customer3>()
        .name("jdbcItemReader")
        .dataSource(dataSource)
        .fetchSize(100)
        .beanRowMapper(Customer3::class.java)
        .queryProvider(MySqlPagingQueryProvider().apply {
            this.setSelectClause("id, first_name, last_name, birthdate")
            this.setFromClause("FROM customer3")
            this.sortKeys = mapOf(
                "id" to Order.ASCENDING
            )
        })
        .build()

    @Bean
    fun jdbcItemWriter() = JdbcBatchItemWriterBuilder<Customer3>()
        .dataSource(dataSource)
        .sql("""
            INSERT INTO customer4 VALUES (:id, :first_name, :last_name, :birthdate)
        """.trimIndent())
        .itemSqlParameterSourceProvider(BeanPropertyItemSqlParameterSourceProvider())
        .build()

### in codes
1. ChunkOriengedTasklet
  - chunkProcessor.process(contribution, inputs)

2. AsyncItemProcessor.process(I item)
  ```
  FutureTask<T> task = new FutureTask<>(new Callable<T>() {
      public call() {
          ...
          try {
              return delegate.process(item)
          }
      }
  })
  taskExecutor.execute(task)
  ```
  = 별도 스레드를 만들어 Callable 부분 실행
  = 메인스레드는 해당 FutureTask 리턴 먼저!

  = 차후 write할 때, 값이 반환될 때까지 기다림 .get()
