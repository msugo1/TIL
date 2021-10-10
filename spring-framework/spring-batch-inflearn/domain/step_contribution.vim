### StepContribution

- 청크 프로세스의 변경 사항을 버퍼링 -> StepExecution 상태를 업데이트하는 도메인 객체
  = 청크 커밋직전에 stepExecution.apply 메서드 호출 -> 상태 업데이트
  = ExitStatus의 기본 종료코드 외 사용자 정의 종료코드를 생성해서 적용할 수 있음

* structure
1. readCount
  - 성공적으로 read한 아이템의 수
2. writeCount
  - 성공적으로 write한 아이템의 수
3. filterCount
  - itemProcessor에 의해 필터링 된 아이템의 수
4. parentSkipCount
  - 부모 클래스인 stepExecution의 총 skip 횟수
5. readSkipCount
  - read에 실패해서 skip된 횟수
6. writeSkipCount
  - write에 실패해서 skip된 횟수
7. processSkipCount
  - process에 실패해서 skip된 횟수
8. exitStatus
  - 실행결과를 나타내는 클래스 
  = 종료코드 포함: UNKNOWN, EXECUTING, COMPLETED, NOOP, FAILED, STOPPED
9. stepExecution
  = stepExecution 객체 저장

                                                 --------------5. apply(contribution)-----------
                                                |                                               |
                                                |                                               |
                                               \ /                                              |
TaskletStep --------- 1. create ---------> stepExecution ---------- 2. create --------> stepContribution
    |                                                                                          / \
    |                                                                                           |
3. execute(contribution, chunkContext)                                                          |
    |                                                                                           |
    |                                                                                           |
    |                                                                                           |
   \ /                                                                                          |
ChunkOrientedTasklet                                                       4. 청크 프로세스의 변경사항 버퍼링
    |                                                                                           |
    |                                                                                           |
    |                                                                                           |
     ------------------------------> ItemReader ------- readCount, readSkipCount ----------------
                                          |                                                     |
                                          |                                                     |
                                          |                                                     |
                                    ItemProcessor -------- filterCount, processSkipCount --------
                                          |                                                     |
                                          |                                                     |
                                          |                                                     |
                                      ItemWriter --------- writeCount, writeSkipCount-----------

* stepExecution이 완료되는 시점에 apply 메서드를 호출, 속성들의 상태를 최종 업데이트
  
### Order
1. TaskletStep.doInTransaction
  stepExecution.createStepContribution
  = new StepContribution(stepExecution) 

  * stepContribution 생성시점?
  - tasklet이 수행되는 과정
  - then, 청크 기반의 프로세스를 처리하는 시점
  - 실제 DB에 커밋하기 직전
 
-> 2. tasklet.execute(contribution, chunkContext)
-> 3. stepExecution.apply(contribution)
```
readSkipCount += contribution.getReadSkipCount()
writeSkipCount += contribution.getWriteSkipCount()
processSkipCount += contribution.getProcessSkipCount() 
filterCount += contribution.getFilterCount()
readCount += contribution.getReadCount()
writeCount += contribution.getWriteCount()
exitStatus = exitStatus.and(contribution.getExitStatus())
```
  = 버퍼링 된 내용 반영하기
  = 이후 DB에 저장
(해당 count 들은 stepExecution을 찾아보면 된다.)
  = 이게 chunkBased 작업에서 실패 시 실패한 청크 부터 다시 시작할 수 있게 해주는 이유일까?
