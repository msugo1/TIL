### Job

* Job
  - 하나의 배치작업 (최상위 개념)
  - Job Configuration을 통해 생성되는 객체단위
  - 배치작업을 어떻게 구성하고 실행할 것인지 전체적으로 설정 & 명세해 놓은 객체
  - 배치 Job을 구성하기 위한 최상위 인터페이스
    = 스프링 배치가 기본 구현체 제공
  - 여러 Step을 포함하고 있는 컨테이너
    = 반드시 하나 이상의 Step으로 구성되어야 함

* 기본 구현체
  1) SimpleJob
  - 순차적으로 Step을 실행시키는 Job
  - 모든 Job에서 유용하게 사용할 수 있는 표준기능을 갖고 있음

  2) FlowJob
  - 특정 조건과 흐름에 따라 Step을 구성하여 실행시키는 Job
  - Flow 객체를 실행시켜서 작업을 진행
    = Flow 객체를 가지고 있다.
    (vs SimpleJob - Step 객체를 가지고 있음)

* 클래스 구조
  JobParameters
        |
        |
        |
  JobLauncher ---- run(job, parameters) ----> Job ------> execute() (steps)


    Job - execute(jobExecution)
     |
     |
 AbstractJob - name, restartable(default: true = 재시작여부), jobRepository, jobExecutionListener, jobParametersIncrementer, jobParametersValidator, simpleStepHandler
     |
     |
     |
SimepleJob (Step)
    
    or

FlowJob (Flow)

* 실행 순서
관련 core 객체들 생성 (seems like it's to do with @EnableBatchProcessing)
  -> SimpleJobBuilder.start 
    = 스템 저장
    = 잡 생성 후 job.setSteps(steps)
  ...
  -> JobLauncherApplicationRunner 생성
  -> runner.execute(job, jobparameters)
    jobExecution = jobLaucnehr.run(job, parameters)
  -> job.execute(jobExecution)
    doExecute(execution)
      = simpleJob 실행
    handleStep(step, execution - jobExecution)
  -> stepHandler.handleStep(step, jobExecution)
    여기서 각각 스텝 실행 후 결과로 stepExecution 리턴
      = 스텝은 각각이 가진 tasklet or chunk를 실행

