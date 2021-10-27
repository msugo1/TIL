### JobInstance

- Job이 실행될 때, 
  생성되는 Job의 논리적 실행단위
  = 고유하게 식별 가능한 작업실행
- Job의 설정 및 구성은 동일하지만 Job이 실행되는 시점에 처리하는 내용이 각각 다르므로, Job의 실행을 구분해야 한다.
  ex. daily batch job - 매일 실행되는 각각의 job이 각 job instance

* JobLauncer가 Job을 실행할 때
  = launcher(job, jobParameters)
- 처음 시작하는 job + jobParametes인 경우?
  = 새로운 jobInstance 생성
- 이전과 동일한 job + jobParameters인 경우?
  = 이미 존재하는 jobInstance 리턴
  (내부적으로 jobName + jobKey(jobParameters의 해시 값)을 가지고 jobInstance 객체를 얻는다.

* job (1): jobInstance(N)

* BATCH_JOB_INSTANCE 테이블과 매핑
  = JOB_NAME + JOB_KEY가 동일한 데이터는 중복해서 저장할 수 없음
  (unique!)

                                 JobLauncher
                                      |
                             Job, JobParameters
                                      |
                                      |
                            run(job, jobParameters)
                                      |
                                      |
 DB <--job & jobParameters ------ jobRepository
    ---------------------> return
                                      |
                                    exists? ---- Yes ----> 기존 JobInstance 리턴
                                      |  
                                     No?
                                 : 새로운 JobInstance 생성

* 기존 JobInstance가 성공한 경우 예외발생 (동일한 내용의 JobInstance로는 재실행 불가)

* BATCH_JOB_INSTANCE에 각각의 job instance를 저장
