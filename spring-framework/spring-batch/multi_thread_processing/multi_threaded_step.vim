### Multi-threaded Step
  - Step 내에서 멀티 스레드로 청크기반 처리가 이루어지는 구조
  - TaskExecutorRepeatTemplate이 반복자로 사용되며, 설정한 개수(throttleLimit) 만큼의 스레드를 생성하여 수행


                                                    (Runnable)
                                                            RepeatCallback
                                                          --------------------
                                                          ChunkOrientedTasklet
    Job ---> Step ----> TaskExecutorRepeatTemplate ---->  --------------------
                                                          (Thread-safe)
                                               ItemReader -> ItemProcessor -> ItemWriter
                                                |  |  |        |  |  |         |  |  |
                                            worker1 2 3 ,,, worker 1 2 3,,,,  worker 1 2 3,,,   


  = 각각의 thread가 reader, processor, writer에 독립적으로 접근/태스크 수행

              
                                TaskExecutorRepeatTemplate
                
                    - int throttleLimit = DEFAULT_THROTTLE_LIMIT(4)
                    - TaskExecutor taskExecutor = new SyncTaskExecutor() 
                    ## Thread를 조절 제한 수 만큼 생성하고 Task를 할당 (default: SyncTaskExecutor)
 
                                            |
                                            |
                                           \|/
                  
                                    ExecutingRunnable
                                                      
                          - RepeatCallback callback ## 반복기에 의해 호출되는 콜백
                          - ResultQueue<ResultHolder> queue ## 최종 RepeatStatus를 담고있는 Queue
                          - public void run() ## RepeatCallback 로직 수


### 주의
  - ItemReader가 Thread-safe 한지 확인하기
    (itemReader는 각각의 워커가 공유하기 때문!)
    = 데이터를 소스로부터 읽어오는 역할
    = 스레드마다 중복해서 데이터를 읽어오지 않도록, 동기화가 보장되어야 한다.

  - 스레드마다 새로운 Chunk가 할당되어 데이터 동기화가 보장된다.
    = 스레드끼리 Chunk를 서로 공유하지 않는다.

  


            Worker 1              Worker 2             Worker 3 ....
               \                      |                    /
                \                     |                   /
                 \                    |                  /  
                  \                   |                 /
                -----------------------------------------
                                  Runnable
                           ChunkOrientedTasklet
            

                               
### API
1. reader(ItemReader)
  = 쓰레드에 안전한 ItemReader가 필요

2. taskExecutor(taskExecutor)
  = 스레드 생성 및 실행을 위한 taskExecutor

### in codes
1. ChunkOrientedTasklet.execute(stepContribution, chunkContext)
  - inputs = chunkProvider.provide(stepContribution)
 
2. SimpleChunkProvider.provide(stepContribution)
  - Chunk<I> inputs = new Chunk<>() ## 각 스레드가 별도의 Chunk 새롭게 생성
                                    ## 별도의 스레드에 담으니 이슈가 발생하지 않음 (Reader만 thread-safe 하다면)

3. ChunkOrientedTasklet
  - chunkProcessor.process(contribution, inputs) ## 각 쓰레드별로 담아둔 Chunk를 가지고 여기 실행
                                                 ## 서로 중복된 데이터를 담고 있지 않다. (않아야 한다!!)

...

4. SimpleChunkProcessor.write(contribution, inputs, getAdjustedOutputs(inputs, outputs))
  
...

### examples
```
    @Bean
    fun step1() = stepBuilderFactory.get("step1")
        .chunk<Customer3, Customer3>(100)
        .reader(jdbcItemReader()) ## synchronized 처리되어 있는 pagingItemReader를 사용해서 안전성 보장
        .listener(CustomItemReadListener())
        .processor(ItemProcessor { ## 이 이후 부터는 별도의 Chunk를 가지고 있어서 안전성 보장
            it
        })
        .listener(CustomItemProcessListener())
        .writer(jdbcItemWriter())
        .listener(CustomItemWriterListener())
        .taskExecutor(taskExecutor())
        .build()

    @Bean
    fun taskExecutor() = ThreadPoolTaskExecutor().apply {
        this.corePoolSize = 4
        this.maxPoolSize = 8
        this.setThreadNamePrefix("ASYNC-THREAD")
      }
```

