### JobLauncher
- 배치 Job을 실행시키는 역할
- Job, Job Parameters를 파라미터로 받음
- 요청된 배치 작업 수행 후 최종 client에게 JobExecution 반환
- 스프링 부트 배치 구동 시 JobLauncher 빈이 자동생성
  = DI 받으세요

* Job 실행
  - JobLauncher.run(Job, JobParameters)
    = 스프링 부트 배치에서는 JobLauncherApplicationRunner 가 자동으로 JobLauncher 실행

  동기적 실행
  - taskExecutor = SyncTaskExecutor (Default)
  - JobExecution 획득 -> 배치 처리 최종완료 -> JobExecution 반환
    = 스케줄러에 의한 배치처리에 적합 (처리시간이 길어도 상관 없는 경우)

 
  Client           JobLauncher          Job          Business
    |      run          |                |               |
    |-----------------> |    execute     |               |
    |                   |--------------->|               |
    |                   |                |-------------->|
    |<------------------|<---------------|<--------------|
         JobExecution        ExitStatus
      (Finished or Failed)
  
  비동기적 실행
  - AsyncTaskExecutor
  - JobExecution을 획득한 후 Client에게 바로 JobExecution 반환 후 배치처리 완료
    = HTTP 요청에 의한 배치처리에 적합
    (배치처리 시간이 길 경우 응답시간이 늦어지지 않도록)

  Client           JobLauncher          Job          Business
    |      run          |                |               |
    |-----------------> |                |               |
    |   JobExecution    |                |               |
    |    (Unknown)      |   execute      |               |
    |<----------------- |--------------->|               |
    |                   |                |-------------->|
    |                   |<---------------|<--------------|
                             ExitStatus
      
### in code
BatchAutoConfiguration.jobLauncherApplicationRunner
  = create JobLauncherApplicationRunner
  
-> runner.run
-> run(jobArguments)
-> launchJobFromProperties
-> executeLocalJobs, executeRegisterJobs
-> execute(job, jobParameters)
  


  
    
