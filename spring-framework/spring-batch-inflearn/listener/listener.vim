### Listenener
  - Job, Step, Chunk 단계의 실행 전후에 발생하는 이벤트를 받아 용도에 맞게 활용할 수 있도록 제공하는 인터셉터 개념의 클래스
    ex. 각 단계별 로그기록 남기기, 소요시간 계산하기, 실행상태 정보들 참조 및 조회

  - 이벤트를 받기 위해서는 Listener 등록이 필요. 등록은 각 API 설정에서 각 단계별로 지정

### Types
1. Job
  - JobExecutionListener: 잡 실행 전후

2. Step
  - StepExecutionListener: Step 실행 전후
  - ChunkListener: Chunk 실행 전후 (or Tasklet 실행 전후), 오류 시점
  - ItemReaderListener: itemReader 실행 전후, 오류 시점, item이 null일 경우 호출x
  - ItemProcessorListener: itemProcessor 실행 전후, 오류 시점, item이 null일 경우 호출x
  - ItemWriterListener: itemWriter 실행 전후, 오류 시점, item이 null일 경우 호출x

3. SkipListener
  - 읽기, 쓰기, 처리 Skip 실행 시점, Item 처리가 Skip될 경우, Skip 된 아이템 추적

4. RetryListener
  - Retry 시작, 종료, 에러 시점

### Implementations
1. Annotations
  - Before/After + Step, Chunk, Read, Process, Write
  - OnRead/Process/WriteError
  - AfterChunkError

2. 인터페이스 방식
  
### Architecture

                 ------> JobExecutionListener
                |
  JobLauncher -----> Job
              <----




                 ------>  StepExecutionListener       ---------> ChunkListener
                |                                     |
        Job   ----->  Step  ----->  Tasklet ------------------> Chunk
              <----         <-----          <-----------------
                              |
                               ------> RepeatListener




                 ------> ItemReadListener                        ---------> ItemWriteListener
                |                                               |
        Chunk ----->  ItemReader  ----->  ItemProcessor ------------------> ItemWriter
              <----               <-----          <-----------------
                                     |
                                      ------> ItemProcessListener


# ChunkListener

    ## 트랜잭션이 시작되기 전에 호출
    ## ItemReader.read() 호출 전
    - void beforeChunk(chunkContext)
    
    ## Chunk가 커밋된 후 호출
    ## ItemWriter.writer() 호출 후
    ## 롤백 시 호출 X
    - void afterChunk(chunkContext)
    
    ## 오류발생 및 롤백이되면 호출
    - void afterChunkError(chunkContext)


# ItemReadListener

  ## read() 메소드 호출 전 매번 호출
  void beforeRead()

  ## read() 메소드 호출이 성공할 때마다 호출
  void afterRead(T read)

  ## 읽는 도중 오류 발생 시 호출
  void onReadError(Exception ex)

= ItemProcessor, ItemWriter도 유사하므로 생략


# in codes

1. ItemReaderListener
* doRead (ItemReader)

  try {
    listener.beforeRead()
    ...
  } catch(Exception ex) {
      ...
      listener.onReadError(e)
  }
  
## Processor, Writer 내부 리스너도 비슷하게 동작!

2. ChunkListener
* TaskletStep
  
  chunkListener.beforeChunk(chunkContext)
 
  ...

  (청크 종료 후)
  chunkListener.afterChunk(chunkContext)


  (or 중도 에러 발생 시)
  chunkListener.afterChunkError

 

# SkipListener

    ## read 수행 중 스킵이 발생할 경우
    void onSkipInError(Throwable t)

    ## write 수행 중 스킵이 발생할 경우
    void onSkipInWrite(S item, Throwable t)
    
    ## process 수행 중 스킵이 발생할 경우
    void onSkipInProcess(T item, Throwable t)




 (3번 read 중 예외)                          (6번 process 중 예외)                  (9번 write 중 예외)
    ItemReader -------------------------------- ItemProcessor --------------------------- ItemWriter ------------------------- DB
       |          1, 2, 4, 5, 6, 7, 8, 9, 10          |         1, 2, 4, 5, 7, 8, 9, 10        |        1, 2, 4, 5, 7, 8, 10
       |                                              |                                        |
   SkipListener                               SkipListener                                SkipListener


= 스킵이 모두 수행된 후 호출됨에 주의


# RetryListener

    ## 재시도 전 매번 호출, false를 반환할 경우 retry를 시도하지 않음
    - boolean open(context, RetryCallback<T, E> callback)

    ## 재시도 후 매번 호출
    - void close(retryContext, RetryCallback<T, E> callback, Throwable throwable)

    ## 재시도 실패 시 마다 호출
    - void onError(retryContext, RetryCallback<T, E> callback, Throwable throwable)


    RetryTemplate
         |
         | execute()
        \|/                                            y                                                          n
   RetryListener ---------> RetryCallback ---> Error? ---> Retry Process -----> RetryListener ----> RetryLimit? ------> RetryListener
         |                                       |                                    |                  |                    |
         |                                       | n                                  |                  |y                   |
        \|/                                     \|/                                  \|/                \|/                  \|/
      open()                                Chunk Process                         onError()         RecoveryCallback        close()


## in codes
1. RetryTemplate.doExecute(RetryCallback, RecoveryCallback, RetryState)
  - doOpenInterceptor
  
2. doOpenInterceptor
  - listener.open(context, callback) && result
    = true인 경우만 재시도

...

3. FaultTolerantChunkProcessor.doWithRetry(retryContext)
  - output = doProcess
    
  with errors
    * doCloseInterceptors(retryCallback, retryContext, throwable)
      -  listener.close(context, callback, throwable)

### open & close는 재시도 할 때마다 실행됨

    * doOnErrorsInterceptor(retryCallback, retryContext, throwable)
      - listener.onError(retryContext, retryCallback, throwale)

### onError는 실제 에러가 발생할 때만 호출

