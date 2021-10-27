### Step
- 배치 잡을 구성하는 독립적인 하나의 단계
  = 실제 배치처리를 정의하고 컨트롤하는데 필요한 모든 정보를 가지고 있는 도메인 객체
  = 각자의 스텝은 `독립적`
  = 단순한 단일 테스크 or 입력/처리/출력과 관련된 복잡한 비즈니스 로직을 포함하는 모든 설정들을 담고 있음
  = 모든 Job은 하나 이상의 step으로 구성

* 기본 구현체
1. Tasklet Step
  = 가장 기본이 되는 클래스 
  = Tasklet 타입의 구현체들을 제어

2. Partition Step
  = 멀티 스레드 방식으로 Step을 여러개로 분리해서 실행

3. JobStep
  = Step 내에서 Job을 실행
  = chain 식으로 구성 (Job -> Step -> Job -> Steps)

4. FlowStep
  = Step 내에서 Flow 실행

                    
                                                 Step
                                        - execute(stepExecution)
                                                   |
                                                   |
                                              AbstractStep
                                              - name
                                              - startLimit = 스텝 실행 제한횟수
                                              - allowStartIfComplete = 스텝 실행 완료후에도 재실행?
                                              - stepExecutionListener = 스텝 이벤트 리스너
                                              - jobRepository = 스텝 메타데이터 저장소
                                                   |
                                                   |
                    ------------------------------------------------------------------
                    |                   |                          |                  |
                  JobStep           TaskletStep                 FlowStep          PartitionStep
                  - job             - steps                    - Flow             - stepExecutionSplitter
                  - jobLauncher     - tasklet                                     - partitionHandler









    ----- execute --> step1 -----> tasklet or chunk(itemReader, itemProcessor, itemWriter)
    |
    |
Job ----- execute --> step2
    |
    |
    ----- execute --> step3
        
            ...

참고) 스텝 내부에서 Tasklet & chunk 기반 클래스는 동시에 설정할 수 없다.


* How tasklet Step gets executed internally?
TaskletBuilder
  - set a tasklet
  - create a taskletStep

  -> build a Job
    - set steps
    - create a job

  -> launch a job
    - job.execute(jobExecution)
      = iterate steps and then run each

  -> run each step
    - stepHandler.handleStep(step, jobExecution)
    - step.execute(currentStepExecution)
    - doExecute(stepExecution)
  
  -> execute taskletStep
    - stepOperations.iterate(new StepContextRepeatCallback(stepExecution)
    - tasklet.execute(contribution, chunkContext)
    here are the tasklets we register

 
