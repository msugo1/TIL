### StepExecution
- Step에 대한 한번에 시도를 의미
- Step 실행 중에 발생한 정보들을 저장하고 있는 객체
  (job <-> jobExecution) 의 관계와 비슷하다.
  = 담고 있는 프로퍼티도 비슷
- 각 스텝 별로 생성된다.
- 잡이 재시작 하더라도 이미 성공적으로 완료된 스텝은 실행하지 않는다.
  = 설정을 변경하면 이미 성공한 스텝도 다시 재시작 할 수 있게 만들 수 있긴 하다.
- 이전 단계 Step이 실패해서 현재 Step을 실행하지 않았다면, StepExecution을 생성하지 않는다.
  = 실제로 스텝이 시작된 경우만 StepExecution을 생성한다.

### in relation with JobExecution
- Step의 StepExecution이 모두 정상적으로 완료되어야 JobExecution 도 정상적으로 완료된다.

### BATCH_STEP_EXECUTION
- jobExecution (1) <-> stepExecption(n)
  = 하나의 job에 여러 개의 step 이 있는 경우?
  (각 stepExecution은 하나의 jobExecution을 부모로 가진다.)
- schema is similar to jobExecution 
