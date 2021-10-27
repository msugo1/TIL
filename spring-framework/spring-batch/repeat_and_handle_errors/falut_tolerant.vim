### FaultTolerant

  - Job 실행 중에 오류가 발생할 경우, 장애를 처리하기 위한 기능 제공
  = 복원력 향상
  = 오류 발생 시에도 Step이 즉시 종료되지 않고, Retry or Skip 
  (내결함성 서비스 possible)

  * Skip
  - ItemReader, ItemProcessor, ItemWriter에 적용가능
  
   * Retry
   - ItemProcessor, ItemWriter에 적용가능

  - FaultTolerant 구조는 청크 기반의 프로세스 기반 위에 Skip, Retry 기능이 추가되어 재정의 되어 있음

### Structure

  SimpleStepBuilder     SimpleChunkProcessor
          |                      |
  FaultTolerant ~

### API
- reader
- writer

with .falutTolerant()
- skip(Class<? extends Throwable> type)
  ## Skip 할 예외 타입 설정

- skipLimit(int skipLimit)
  ## Skip 제한 횟수 설정)

- skipPolicy(skipPolicy)
  ## Skip을 어떤 조건과 기준으로 적용할 것인지 정책 설정

- noSkip(Class<? extends Throwable> type)
  ## 예외 발생 시 스킵하지 않을 예외 타입  

- retry(Class<> extends Throwable> type)
  ## retry할 예외 타입 설정

- retryLimit(int retryLimit)
  ## retry 제한 횟수 설정

- retryPolicy(retryPolicy)
  ## retry 적용할 정책 설정 (조건, 기준)

- backOffPolicy(backOffPolicy)
  ## 다시 retry 하기까지 지연시간

- noRetry(Class<? extends Throwable> type)
  ## retry 하지 않을 예외 타입

- noRollback(Class<? extends Throwable> type)
  ## rollback 하지 않을 예외 타입

### in codes
1. FalutTolerantStepBuilder.createChunkProvider
  - FalutTolerantChunkProvider 객체 생성
  - FalutTolerantChunkProcessor 객체 생성

2. FaultTolerantChunkProvider
  *예외 발생*
  if (shouldSkip(skipPolicy, exception, contribution.getStepSkipCount()))     
  yes?
  - contribution.incrementReadSkipCount()
  - chunk.skip(e)   

 (retry도 비슷한 과정을 거친다.)

### Skip
  - 데이터를 처리하는 동안 설정된 예외 발생 시, 해당 데이터 처리를 건너뛰는 기능
    = 사소한 오류에 대해 Step의 실패처리 대신 Skip 활용
    = 배치수행의 빈번한 실패를 줄일 수 있게 한다.

  ItemReader ---- Skip ---- ItemWriter
                   |
                   |
               ItemProcessor
 

  with ItemReader
  - 예외 발생 시 해당 아이템만 스킵하고 계속 진행

  with ItemProcessor, ItemWriter
  - 예외 발생 시 Chunk의 처음으로 돌아가서 스킵된 아이템을 제외한 나머지 아이템을 가지고 처리
  = ItemReader로부터 아이템을 다시 받는다.
  = ItemReader는 캐시에 해당 청크 데이터를 가지고 있으므로 DB에 다시 접근하지는 않는다.

  = ItemWriter에서도 수행시 똑같다. 
(internally, itemProcessor 1건 씩 itemWriter에 전달
  -> ItemWriter는 아까 예외가 발생한 아이템인지 판단
    yes: 스킵
    no: 처리
(결론적으로는, 예외 발생한 아이템을 스킵하는 것)

* 내부적으로 SkipPolicy를 통해서 구현

* Skip 가능여부 판별기준
  - 스킵 대상에 포함된 예외인지
  - 스킵 카운터를 초과했는지

  Skip -----> RepeatTemplate -----> Chunk -----> Exception -----> SkipPolicy (스킵 정책검사)

  SkipPolicy -----> Classifier 스킵정책 선택, 스킵여부 결정 -----> Skip? 
## skippableException && skipCount > skipLimit  둘다 true인 경우만 skip
  
  skip이 일어나지 않는 경우 = 스텝종료

* SkipPolicy
  - 스킵 정책에 따라 아이템의 skip 여부를 판단하는 클래스
  - 필요시 직접 생성해서 사용가능
  - 내부적으로 Classifier 클래스들 활용


   SkipPolicy

boolean shouldSkip(Throwable t, int skipCount)

1. AlwaysSkipItemPolicy
  = 항상 skip

2. ExceptionClassifierSkipPolicy
   = 예외대상을 분류하여 스킵여부 결정

3. CompositeSkipPolicy
  = 여러 스킵 정책을 탐색하면서 스킵여부 결정

4. LimitCheckingItemSkipPolicy (default)
  = Skip 카운터 및 예외 등록 결과에 따라 스킵여부 결정

5. NeverSkipItemSkipPolicy
   = 스킵을 하지 않는다.

### example
```
@Bean
fun batchStep1() = stepBuilderFactory.get("batchStep1")
    .chunk<ProcessorInfo, ProcessorInfo>(2)
    .reader {
        i++
        if (i > 10) {
            null
        } else if (i == 1) {
            throw IllegalArgumentException("예외 발생 - 스킵 ")
        } else {
            ProcessorInfo(id = i)
        }
    }
    .processor(ItemProcessor {
        if (i in listOf(6, 9)) {
            throw SkippableException("Item can't be processed but it will be skipped")
        } else {
            println("Item Processor has been called: $it")
            it
         }
    })
    .writer(itemWriter())
    .faultTolerant()
    .skip(IllegalArgumentException::class.java)
    .skipLimit(2)
        .retry(IllegalStateException::class.java)
        .retryLimit(2)
        .build()

```

* skipLimit의 경우 각 컴포넌트 별로 따로 적용되는 것이 아니라, 모두 합한 값이 적용된다.
  - ex. Skip 1 in ItemWriter, and Skip 2 in ItemProcessor = total 3 skips



