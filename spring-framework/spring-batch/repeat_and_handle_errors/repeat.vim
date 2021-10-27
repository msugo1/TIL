### Repeat
  - SpringBatch = 얼마나 작업을 반복해야 하는지 알려줄 수 있는 기능 제공 (RepeatTemplate)
    = 특정 조건이 충족될 때까지 or 특정조건이 아직 충족되지 않았을 때 Job or Step을 반복하도록 배치 애플리케이션 구성가능

### Structure

                    (iterate)                            (iterate)
  Job -----> Step -----> RepeatTemplate -----> Tasklet -----> RepeatTemplate -----> Chunk
                                                  |
                                            (with while)
                                      ex. Chunk Oriented Tasklet
                                      - ChunkProvider.repeatTemplate
                                        = ItemReader에게 반복해서 데이터를 읽어오도록

### 반복을 종료할 것인지 여부를 결정하는 세 가지 항목
1. RepeatStatus
  - 스프링 배치의 처리가 끝났는지 판별하기 위한 열거형 (enum)
    1) CONTINUABLE: 작업이 남아있음 -> 반복 o
    2) FINISHED: 더 이상의 반복X

2. CompletionPolicy
  - RepeatTemplate의 iterate 메소드 안에서 반복을 중단할지 결정
  - 실행횟수 또는 완료시기, 오류발생 시 수행할 작업에 대한 반복여부 결정
  - `정상종료`를 알리는데 사용

3. ExceptionHandler
  - RepeatCallback 안에서 예외 발생 시 RepeatTemplate가 ExceptionHandler를 참조해서 예외를 다시 던질지 여부 결정
    = 예외를 받아서 다시 던지게 되면 반복종료 
  - `비정상 종료`를 알리는데 사용

  3. ExceptionHandler
  - RepeatCallback 안에서 예외 발생 시 RepeatTemplate가 ExceptionHandler를 참조해서 예외를 다시 던질지 여부 결정
    = 예외를 받아서 다시 던지게 되면 반복종료 
  - `비정상 종료`를 알리는데 사용

  3. ExceptionHandler
  - RepeatCallback 안에서 예외 발생 시 RepeatTemplate가 ExceptionHandler를 참조해서 예외를 다시 던질지 여부 결정
    = 예외를 받아서 다시 던지게 되면 반복종료 
  - `비정상 종료`를 알리는데 사용

### Structure


                                                        RepeatOpeartions
          
                                            - RepeatStatus iterate(RepeatCallback callback)
                                            ## RepeatCallback을 반복 호출

                                                              /|\
                                                               |
                                                               |
                                                               |
                                                               |
                                                               |
                        
                                                        RepeatTemplate 
                    
                                                               |
                                                               | ## 반복을 종료할 때까지 콜백 호출  
                                                              \|/

                                                       RepeatCallback
                                                                                                   ## 상태정보 저장
                         RepeatStatus <-------- RepeatStatus doInIteration(RepeatContext) ----------> RepeatContext - 일시적으로 사용할 필요가 있는 데이터 저장
                      FINISHED, CONTINUABLE   ## 비즈니스 로직 구현                                                 - 반복종료와 함께 데이터 삭제
                      ## 반복 상태

### in execution

                                iterate()                 doInIteration()
    Step -----> RepeatTemplate ----------> RepeatCallback --------------> tasklet <-------
                    /|\                                                     |             |
                     |                                                      |             |
                     |                                                     \|/            |
                     |------------------- ExceptionHandler <--- Yes ---- Exception        |
                     | ## 예외정책에 따라 반복여부 결정가능                 |             |
                     |                                                      No            |
                     |                                                      |             |
                     |                                                     \|/            |
                     |                                               CompletionPolicy     |
                     |                                                      |             |
                     |                                                      |             |
                     |                                                     \|/            |   반복문 유지
                     |-------------------------------------- Yes ------ Complete?         |
                     |## 종료정책에 따라 반복여부 결정가능                  |             |
                     |                                                     No             |
                     |                                                      |             |
                     |                                                      |             |
                     |                                                     \|/            |
                     |                                                 RepeatStatus       |
                     |                                                      |             |
                     |                                                      |             |
                     |                                                     \|/            |
                      ------------------------------------ Yes -------- FINISHED --- No --

### CompletionPolicy

                    CompletionPolicy
      
          - boolean isComplete(RepeatContext, RepeatStatus)
          ## 콜백의 최종 상태 결과를 참조, 배치가 완료되었는지 확인

          - boolean isComplete(RepeatContext)
          ## 콜백이 완료될 때까지 기다리지 않음

* 구현체
1. TimeoutTerminationPolicy
  = 반복시점부터 현재시점까지 소요된 시간이 설정된 시간보다 크면 반복종료

2. SimpleCompletionPolicy
  = 현재 반복횟수가 Chunk 갯수가 크면 반복종료

3. CountingCompletionPolicy
  = 일정한 카운트를 계산 및 집계해서 카운트 제한 조건이 만족하면 반복종료

### CompletionPolicy

                    CompletionPolicy
      
          - boolean isComplete(RepeatContext, RepeatStatus)
          ## 콜백의 최종 상태 결과를 참조, 배치가 완료되었는지 확인

          - boolean isComplete(RepeatContext)
          ## 콜백이 완료될 때까지 기다리지 않음

* 구현체
1. TimeoutTerminationPolicy
  = 반복시점부터 현재시점까지 소요된 시간이 설정된 시간보다 크면 반복종료

2. SimpleCompletionPolicy
  = 현재 반복횟수가 Chunk 갯수가 크면 반복종료

3. CountingCompletionPolicy
  = 일정한 카운트를 계산 및 집계해서 카운트 제한 조건이 만족하면 반복종료

### ExceptionHandler

                        ExceptionHandler
      
          - void handleException(RepeatContext, Throwable)
          ## 예외를 다시 던지기위한 전략을 허용하는 핸들러

* 구현체
1. RethrowOnThresholdExceptionHandler
- 지정된 유형의 예외가 임계 값에 도달하면 다시 발생

2. LogOrRethrowExceptionHandler
- 예외를 로그로 기록할지 아니면 다시 던질지 결정

3. SimpleLimitExceptionHandler
- 예외 타입 중 하나가 발견되면 카운터가 증가
  = 한계가 초과되었는지 여부를 확인하고 Throwable을 다시 던짐

### in codes
  code execution in Repeat Template 
    -> isComplete
    -> repeat or end

### example (completionPolicy)
1. simpleCompletionPolicy
  = 지정된 청크사이즈에 도달할 경우 반복을 종료한다.

```
.processor(object : ItemProcessor<ProcessorInfo, ProcessorInfo> {

        val repeatTemplate = RepeatTemplate()

        override fun process(item: ProcessorInfo): ProcessorInfo {
            repeatTemplate.setCompletionPolicy(SimpleCompletionPolicy(3))
            repeatTemplate.iterate {
                println("test repeatTemplate")
                Thread.sleep(1000)
                RepeatStatus.CONTINUABLE
            }

            return item
        }
    })
```

2. timeoutCompletionPolicy
.processor(object : ItemProcessor<ProcessorInfo, ProcessorInfo> {

      val repeatTemplate = RepeatTemplate()

      override fun process(item: ProcessorInfo): ProcessorInfo {
          repeatTemplate.setCompletionPolicy(TimeoutTerminationPolicy(3000))
          repeatTemplate.iterate {
              println("test repeatTemplate")
              Thread.sleep(500)
              RepeatStatus.CONTINUABLE
          }

                return item
            }
        })

3. compositeCompletionPolicy
## 여러 policy 조합
## 조건에 먼저 부합하는 것에 맞춰 반복 종료

.processor(object : ItemProcessor<ProcessorInfo, ProcessorInfo> {

    val repeatTemplate = RepeatTemplate()

    override fun process(item: ProcessorInfo): ProcessorInfo {
        val compositeCompletionPolicy = CompositeCompletionPolicy().apply { 
            this.setPolicies(arrayOf(
                SimpleCompletionPolicy(5),
                TimeoutTerminationPolicy(3000)
            ))
        }

        repeatTemplate.setCompletionPolicy(compositeCompletionPolicy)
        repeatTemplate.iterate {
            println("test repeatTemplate")
            Thread.sleep(500)
            RepeatStatus.CONTINUABLE
        }


        return item
    }
})

### in codes (ExceptionHandler)
  throw Exception
    -> ExceptionHandler.handleException(RepeatContext, Throwable)
    -> delegate.handleException(context, throwable)

  ```
  if (count > threshold) {
      throw Throwable
  } 

  or repeat till threshold surpasses the count set
  ```
  
   at later time the thrown exception reaches here

in RepeatTemplate

    catch (Throwable handled) {
        deferred.add(handled)
    }
    
    ...

    if (... || deferred.isNotEmpty()) {
        running = false ## deffered 안에 예외가 들어가면 not empty가 되므로, 반복이 종료된다!
    }


### example (Exception Handler)
 
