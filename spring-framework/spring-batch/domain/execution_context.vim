### StepContribution
- job, step 관련 도메인과 연관지어 이해하면 된다.

- 프레임워크에서 유지 및 관리하는 키/값으로 된 컬렉션 (Map)
- stepExecution or jobExecution 객체의 상태를 저장하는 공유객체
  = DB에 직렬화 한 값으로 저장됨(JSON)
 
* 공유 객체
  = 여러 곳에서 공유해서 참조할 수 있다.

* execution context 공유 범위
- step execution context
  = 각 step의 stepExecution에 저장된다.
  = 각 step간 서로 공유 안됨
    (해당 스텝만 참조가 가능하다.)

- job execution context
  = 각 잡의 jobExecution에 저장
  = job 간 서로 공유가 안된다.
    but, `job의 스텝 간`에는 공유가 가능하다.

!!!
  = job 재시작 시 이미 처리한 row 데이터는 건너뛰고, 이후로 수행하도록 할 때 상태정보로 활용
    -> 실패할 당시의 데이터들을 execution context에 저장
    -> 잡 재시작 시 위에서 저장한 값을 참조, 처리한 부분은 스킵


         ------> jobExecution (from stepExecution) -----> executionContext --- put --> key, value
        |
Step ----------> stepExecution -------------------------> executionContext --- put ---> key, value




