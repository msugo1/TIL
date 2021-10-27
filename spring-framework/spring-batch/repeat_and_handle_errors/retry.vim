### Retry

기본개념
- ItemProcessor, ItemWriter에 설정된Exception이 발생한 경우
  = 지정한 정책에 따라 데이터 처리를 재시도


    Step 
                --------- 재시도 ---------> Retry ----------  ItemWriter
RepeatTemplate                                |                 /
      \                                       |                /
       \  chunk <inputs> cached               |               /   chunk<outputs>
        \                                     |              /
          ----------------------------> ItemProcessor ------
     
  = 오류 발생 시 재시도 설정에 의해서 `Chunk` 단계의 처음부터 다시 시작
  = 아이템은 ItemReader에서 `캐시`로 저장한 값을 사용

    vs Skip
    - Retry는 아예 스텝의 처음 단계로 이동
    - Skip 보다는 심플 (예외 발생 시 처리과정이 달라지는 점이 없다.)



                                         RetryOperations (while loop)
                                
                                      - T execute(RetryCallback<T, E>)
                                 ## RetryCallback을 재시도 설정 만큼 반복호출

                                - T execute(retryCallback, recoveryCallback)
                       ## RetryCallback 재시도 호출이 모두 소진되면 RecoveryCallback 호출
                                                      /|\
                                                       |
                                                       |
                                                 RetryTemplate
                                                       /\
                                                      /  \
                                                     /    \
                                          RetryCallback  RecoveryCallback
            
                                T doWithRetry(RetryContext) T recover(RetryContext)
                                              ## 비즈니스 로직구현

* Retry 기능은 내부적으로 RetryPolicy를 통해서 구현되어 있다.
  
  판별기준
1. 재시도 대상에 포함된 예외인지 여부
2. 재시도 카운터를 초과했는지 여부

                           - 재시도 정책을 검사                       - ItemProcessor
                           - 최초 1회는 무조건 실행                   - ItemWriter
  Step ---> RepeatTemplate ---> RetryTemplate ---> RetryCallback ---> Chunk ---> Exception ---> RetryPolicy
   |             /|\                  |                /|\             /|\                          |
   |              |                   |                 | Yes           |                           |
   |              |                    --- Retry? ------|               |                           |
   |              |                                     | No            |                         Retry ---- No
   |              |                                    \|/              |                           | Yes    |
   |              |                              RecoveryCallback ------                      BackOffPolicy  |
   |              |                                                                                 |        |
   |               ------------------------------ Yes (Step 반복문 처음부터 다시 시작한다.) --------         |
   |                                                                                                         |
    ----------------------------------- No (Step 종료) ------------------------------------------------------


  * retry 기준
    - retryableException && retryCount > retryLimit
  (identified by subclassifier)

  * BackOffPolicy
    - retry 전 지연시간


      RetryPolicy

boolean canRetry(RetryContext)
RetryContext open(RetryContext)
void close(RetryContext)
void registerThrowable(RetryContext, Throwable)

## 구현체
- AlwaysRetryPolicy
- ExceptionClassifierRetryPolicy
  = 예외대상을 분류하여 재시도 여부를 결정
- CompositeRetryPolicy
  = 여러 RetryPolicy를 탐색하면서 재시도여부 결정
- SimpleRetryPolicy (default)
  = 재시도 횟수 및 예외 등록 결과에 따라 재시도여부 결정
- MaxAttemptsRetryPolicy
  = 재시도 횟수에 따라 재시도여부 결정
- TimeoutRetryPolicy
  = 주어진 시간동안 재시도 허용
- NeverRetryPolicy
  = 최초 한 번만 허용, 그 이후로는 허용X

## in codes
1. FaultTolerantChunkProcessor
  - RetryCallback, RecoveryCallback
    = 각 아이템이 retry, recovery callback을 가지고 있음 (공유x)

2. BatchRetryTemplate.execute(retryCallback, recoveryCallback, retryState)
  - regular.execute(retryCallback, recoveryCallback, retryState)

  * regular = retryTemplate

3. RetryTemplate.execute(retryCallback, recoveryCallback, retryState)
  - doExecute(retryCallback, recoveryCallback, retryState)

4. doExecute(retryCallback, recoveryCallback, retryState)
  (핵심파트)

  ```
  ...
  RetryContext context = open(retryPolicy, state) ## retry 시 필요한 상태정보를 담고 있는 Context
                                                    (재시도 최대 몇 번, 현재 몇 번 등)
    - 내부적으로 count 증가 
    - count, maxAttempty 비교
    
    ```
      Object key = state.getKey() ## 해당 key로 저장된 state 불러오기
      ...
      if (!this.retryContextCache.containsKey(key)) {
          return doOpenInternal(retryPolicy, state) 
      }
    
      ```
      (doOpenInternal)
        RetryContext context = retryPolicy.open(RetrySynchronizationManager.getContext())
        if (state != null) {
            context.setAttribute(RetryContext.STATE_KEY, state.getKey())
        }
        if (context.hasAttribute(GLOBAL_STATE) {
            registerContext(context, state)
        }
        return context
      ```
    ```
  ...
  RetrySynchronizationManager.register(context)
  ...
  
  boolean running = doOpenInterceptors(retryCallback, context) ## retry listener를 호출하는 쪽
                                                               ## 자매품 close, onErrorInterceptor도 존재

    - running = false 리턴 시, 재시도 예외발생

  ...
  backOffContext = backOffPolicy.start(context) 
  ...
  while (canRetry(retryPolicy, context && !context.isExhaustedOnly()) { ## 재시도 여부 파악 후 반복
    try {
        ...
        return retryCallback.doWithRetry(context) 
        ```
        (doWithRetry)
          ...
          count.incrementAndGet()
          ...
          output = doProcess(item) ## 처리 중 예외 발생 시 처음으로 다시 돌아간다.
        ```
    } catch (Exception e) {
        status = BatchMetrics.STATUS_FAILING
        if (rollbackClassifier.classify(e)) {
            throw e
        }     |
    }         |
  ```         |
    catch <---
      lastException = e
      
      try {
          registerThrowable(retryPolicy, state, context, e) ## 발생한 예외를 여기서 등록
          ```
          (RetryContextSupport.registerThrowable(throwable))
              this.lastException = throwable
              if (throwable != null) {
                  count++
              }
          ```
      }
  }
  ...
  ## 맨 처음으로 돌아간다.
    - while(canRetry ...) 의 판별식이 false가 나올 때까지 반복한다.
  
  ## false가 나오면 recoveryCallback 처리로 넘어간다.
  * handleRetryExhausted(recoveryCallback, context, state)
  ```
    context.setAttribute(RetryContext.EXHAUSTED, true)
    
    if (state != null && !context.hasAttribute(GLOBAL_STATE)) {
        this.retryContextCache.remove(state.getKey())
    }
    
    if (recoveryCallback != null) {
        T recovered = recoveryCallback.recover(context)
        ```
          (recover)
          ...
          if (shouldSkip(itemProcessSkipPolicy, e, contribution.getSkipCount()) { ## skip 동작여부 파악
              iterator.remove(e)
              contribution.incrementProcessSkipCount()
              ...
              ## 재시도가 소진되었어도 스킵 설정을 했다면, 해당 아이템들을 스킵하는 처리를 할 수 있다.
          } else {
              if (rollbackClassifier.classify(e)) { ## default: true
                  throw new RetryException(..., e) ## rollback
                  ## 여기 예외는 deferred에 담겨 RepeatTemplate의 스텝 반복 while 구문까지 타고 올라간다.
                  ## 여기서 deferred.isNotEmpty()가 되므로, running = false -> 반복이 불가능해진다.
              }
              iterator.remove(e)
          }
        ```
        context.setAttribute(RetryContext.RECOVERED, true)
        return recovered
    }
  ```

* retryContext
  - 아이템마다 개별 컨텍스트를 가진다.
   = 아이템마다 retryCount가 다를 수밖에...

  - 해당 item이 재시도 가능 = false로 바뀌면, `handleRetryExhausted(recoveryCallback, context, state)` 호출
    = 사후처리에 들어간다. (ex. skip)
    1. retryContextCache.remove(state.getKey()) ## 해당 컨텍스트는 더 이상 필요하지 않으므로 삭제한다.
    2. recoveryCallback.recoverretryContext)
      - shouldSkip == true?
        = 해당 아이템을 제거시킨다. & skipCount 증가
        = 시작지점으로 되돌아가 다시 시작한다. (제거된 것은 당연히 skip!)

### examples
```
@Configuration
class RetryConfiguration(

    val jobBuilderFactory: JobBuilderFactory,

    val stepBuilderFactory: StepBuilderFactory
) {

    @Bean
    fun job() = jobBuilderFactory.get("batchJob")
        .incrementer(RunIdIncrementer())
        .start(step1())
        .build()

    @Bean
    fun step1() = stepBuilderFactory.get("step1")
        .chunk<String, String>(5)
        .reader(reader())
        .processor(processor())
        .writer {
            it.forEach { item -> println(item) }
        }
        .faultTolerant()
        .skip(RetryableException::class.java)
        .skipLimit(2)
        .retry(RetryableException::class.java)
        .retryLimit(2)
        .retryPolicy(retryPolicy())
        .build()

    @Bean
    fun reader(): ListItemReader<String> {
        val items = ArrayList<String>()
        for (i in 0..30) {
            items.add(i.toString())
        }
        return ListItemReader<String>(items)
    }

    @Bean
    fun processor() = RetryItemProcessor()

    @Bean
    fun retryPolicy(): RetryPolicy {
        val exceptions = mapOf<Class<out Throwable>, Boolean>(
            RetryableException::class.java to true
        )

        return SimpleRetryPolicy(2, exceptions)
    }
}

class RetryItemProcessor : ItemProcessor<String, String> {

    var cnt = 0

    override fun process(item: String): String? {
        if (item == "2" || item == "3") {
            cnt++
            throw RetryableException()
        }

        return item
    }
}

class RetryableException(msg: String = "retryable") : Exception(msg)
```

### custom recover 로직이 필요한 경우?
  - 직접 구현해야 한다.


