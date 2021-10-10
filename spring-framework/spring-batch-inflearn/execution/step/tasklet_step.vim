### Tasklet Step
- 스프링 배치에서 제공하는 Step의 구현체
- Tasklet을 실행시키는 도메인 객체
  = RepeatTemplate를 사용해서 Tasklet의 구문을 트랜잭션 경계 내에서 반복실행
  (based on RepeatStatus)
- Tasklet based, Chunk based

* Task vs Chunk based
1. Chunk based
  - 하나의 큰 덩어리를 n개씩 나눠서 실행
    = 대량처리를 하는 경우 효과적으로 설계
  - ItemReader, Processor, Writer를 사용
  - 청크 기반 전용 tasklet인 ChunkOrientedTasklet 구현체 제공
                                                                        in Transaction
                                            ------ (loop) ------------------------------------------------------
  Job --> TaskletStep --> RepeatTemplate --> ChunkOrientedTasklet --> ItemReader -> ... Processor -> ... Writer
                                            --------------------------------------------------------------------

2. Task 기반
  - 단일 작업기반으로 처리되는 것이 더 효율적인 경우
  - Tasklet 구현체를 만들어 사용
  - 대량처리를 하는 경우 chunk 기반에 비해 더 복잡한 구현 필요
    = 이러한 경우 chunk based 가 더 효율적
                                                          in Transaction
                                                 ----------------------------------
  Job --> TaskletStep --> RepeatTemplate -----> | (loop) tasklet -> business logic |
                                                 ----------------------------------
                                                 RepeatStatus를 조정해 반복종료

* 대표적인 API
- startLimit
  = 실행횟수 설정 
  (설정한 횟수만큼만 실행, 초과시 오류 발생 default: Integer.MAX_VALUE)

- allowStartIfComplete
  = 스텝의 성공, 실패와 상관 없이 항상 스텝을 실행하기 위한 설정
  (이미 성공한 스텝은 pass by default)

- listener(stepExecutionerListener)
  = step의 실행 전 후에 콜백 제공

- build 
  = taskletStep 생성

* execution order

1. stepbuilderFactory.get(stepName)
  - `stepBuilder` 반환

2. `.tasklet`
  - `TaskletStepBuilder(this = stepBuilder).tasklet(tasklet)`
 
3. build
  - taskletStep 생성 with the step name above

4. super.enhance 
  from 부모 클래스 AbstractTaskletStepBuilder
  - set jobRepository
  - set allowStartIfComplete
  - set startLimit
  - set executionListener
  - set transactionManager (트랜잭션 경계 내에서 처리하기 위함)

  - set(or create) stepOperations = RepeatTemplate
    = 반복 수행을 위해서
  (optional: multi-threaded operations? -> set taskExecutor, throttleLimit on the repeat template above)

  - set exceptionHandler
  - create Tasklet 
    = 2번에서 이미 설정되어 있는 tasklet을 가져다 쓴다.

5. execution in AbstractStep
  - execute(stepExecution) (by SimpleJob)

  - 속성 변경
    setStartTime
    setStatus: BatchStatus.STARTED
    jobRepository.update(stepExecution)
    
    exitStaus.EXECUTING

  - doExecute(stepExecution)
    1) update stepExecutionContext
    2) create semaphore
    3) stepOperations.iterate(StepContextRepeatableCallback(stepExecution))
      = repeatStatus - CONTINUABLE
      = executeInternal
        while 문을 돌면서 tasklet 실행

  - doInChunkContext 
    create a transactionTemplate for opertaions in one transaction

    then execute
    (doInTransaction)
      - tasklet.execute(contribution, chunkContext)
        = 여기서 구현한 tasklet 동작 
    
    RepeatStatus -> Finished or result == null
      - 스텝 실행 종료   

    when exceptions thrown -> rollbackOnException

  (for chunkOrientedTasklet)
  chunkProcessor & chunkProvider are activated
 
  1) chunkProvider.provide(contribution)
    - item = read(contribution, inputs)
      ** from itemReader implementation registered **
      
      doRead -> itemReader.read()
      (iterate till the chunkSize)

  2) chunkProcessor.process(contribution, inputs)
    - output = doProcess(item)
      ** now itemProcessor implementation **
    
      doProcess -> itemProcessor.process()

  3) write(contribution, inputs, getAdjustedOutputs(inputs, outputs))
      ** itemWriter implmentation **
      
      doWrite -> itemWriter.write()

### API details
1. tasklet
  - tasklet 타입의 클래스 설정
  (Tasklet - for 단일 태스크)
  - TaskletStep에 의해서 반복적으로 수행
    = RepeatStatus에 따라 반복 수행이 결정됨
    Finished, Continuable
    = or null로 반환하면 Finished로 해석된다.
  ** 무한 루프에 주의한다. **
    = Finished or null이 리턴되거나 예외가 던져지기 전까지는 계속 반복

  - 익명 클래스 or 구현 클래스로 사용가능
  - 위 메소드 실행 시 `TaskletStepBuilder` 반환
    = 관련 API 설정 가능해진다.

  - 스텝에 오직 하나만의 Tasklet 설정이 가능하다.
    = 두 개 이상을 설정한 경우 마지막에 설정한 객체가 실행된다

```
Tasklet

RepeatStatus execute(stepContribution, chunkContext)
```

2. startLimist
  - Step의 실행횟수를 조정할 수 있다.
  - Step 마다 설정가능 (independent)
    = 설정 값을 초과해서 실행 시 = `StartLimitExceedException`
    = default: Integer.MAX_VALUE

3. allowStartIfComplete
  - 재시작 가능한 job에서, step의 이전 성공 여부와 상관없이 항상 step을 실행하기 위한 설정
    ex. 실행마다 유효성을 검증하는 step or 사전 작업이 꼭 필요한 step 등을 위해 사용
    = default false
  - true로 설정 시 항상 재시작

### TaskletStep Architecture

                          ------------------------ tasklet 반복 ------------------------- CONTINUABLE
                         |                                                                    |
                        \|/           ------------------------- loop ------------------------ | -----
  Job --> Step --> RepeatTemplate --> Tasklet --> Business Logic --> exception -- no --> RepeatStatus
          / \                         -----------------------------------|--------------------|
           |                                                            yes                   |
           |                                                             |                 FINISHED
            ---------------- 반복문 종료 & step 종료 --------------------                     |
           |                                                                                  |
           |                                                                                  |
            -------------------------- 반복문 종료 & step 종료--------------------------------



   ExecutionContext
          |
          |
    stepExecution
          |
          |                                      StepListener
          |                       (CompositeStepExecutionListener.beforeStep())
          |                                           |
  updateStatus(execution, BatchStatus.STARTED)        |
  exitStatus = ExitStatus.EXECUTING                   | 
          |                                           |                RepeatStatus.CONTINUABLE
          |                                           |                         |
  Job ---------> taskletStep --------------------------- RepeatTemplate -----------------> (loop) Tasklet
     <---------              <--------------------------                <-----------------
                                   |              |                             |
                                   |              |                    RepeatStatus.FINISHED
                                   |        StepListener
                                   | (CompositeStepExecutionListener.afterStep())
                                   |
                                   | 
                             StepExecution
         exitStatus = ExitStatus.COMPLETED.and(stepExecution.getExitStatus())
         stepExecution.upgradeStatus(BatchStatus.COMPLETED)


* stepExecutionListener 호출 후 추가적인 exitStatus 상태 업데이트 가능
  - exitStatus = exitStatus.and(getCompositeListener().afterStep(stepExecution))

### in code
1. SimpleJob.doExecute
  - forEach with steps registered

2. SimpleStepHandler.handleStep(step, jobExecution)
  - get currentStepExecution
  - shouldStart(lastStepExecution, execution, step)
    = 실행 조건판단
  - execution.createStepExecution(step.getName)
    = stepExecution 생성
  - currentStepExecution.setExecutionContext(new ExecutionContext(executionConetxt))

3. step.execute(currentStepExecution) in SimpleStepHandler
  
4. in AbstractStep
  - getCompositeListener().beforeStep(stepExecution)
    = beforeStep 리스너 등록시 호출먼저
  - doExecute(stepExecution)
    = 스텝 실행

5. in TaskletStep
  - stepOperation(RepeatTemplate).iterate(new StepContextRepeatCallback(stepExecution))
    = 콜백 클래스를 통해 반복
    = that callback has `doInChunkContext` and `doInIteration`

  - new TransactionTemplate(transactionManager, transactionAttribute)
    = 반복 처리 중 트랜잭션 처리를 위해
    (스프링 배치가 기본적으로 제공해주므로 별도의 처리가 필요가 없다.)

  - tasklet.execute
    = 생성해서 등록한 tasklet 실행

  - 실행 후 RepeatStatus or 예외발생 여부에 따라 종료 처리

6. 종료처리
  - exitStatus = ExitStatus.COMPLETED.and(stepExecution.getExitStatus())
  - stepExecution.upgradeStatus(BatchStatus.COMPLETED)

  - finally 블록에서 종료 코드와 배치 상태 확인
    = 커스텀 한 exit status 코드 추가 시 여기서 추가작업이 이루어진다.

  - afterStep 리스너가 등록되어 있으면 여기서 호출한다.
    (exitStatus.and(getCompositeListener().afterStep(stepExecution))

* taskletStep의 경우 등록된 스텝을 모두 수행할 때까지 위의 과정을 반복한다.
  = 물론 중간에 예외가 발생하면 거기서 멈추겠지!


