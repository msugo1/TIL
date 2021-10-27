### ItemStream
  - ItemReader, ItemWriter 처리 과정 중 상태를 저장
    = 오류 발생 시 해당 상태를 참조, 실패한 곳에서 재시작 하도록 지원
  - 리소스를 열고 닫아야 하며, 입출력 장치의 초기화 등의 작업을 해야 하는 경우
    = open, close
  - ExecutionContext를 매개변수로 받아, 상태정보를 업데이트
    = Key, Value
  - ItemReader, ItemWriter는 ItemStream을 구현해야 한다.

        ItemStream
  
  void open(ExecutionContext executionContext) throws ItemStreamException
    = read, write 메서드 호출 전 파일이나 커넥션이 필요한 리소스에 접근하도록 초기화

  void update(ExecutionContext executionContext) throws ItemStreamException
    = 현재까지 진행된 모든 상태를 저장
    = 매번 호출된다. (청크 사이즈 만큼 처리 후 in chunk based)

  void close() throws ItemStreamException
    = 열려 있는 모든 리소스를 안전하게 해제 or 닫기




          ----> ItemStream.open(executionContext)
         |          |   (리소스 열고 초기화. 최초1회)
         |          |
         |         \|/
          ----> ItemReader
         |          |
         |          |
         |         \|/
         |----> ItemStream.update(ExecutionContext) ------------------> DB <----
         |              (현재 상태정보 저장. chunkSize 만큼 반복)               |
         |                                                                      |
         |                                                                      |
Step ---------> ItemProcessor                                                   |
         |                                                                      |
         |                                                                      |
         |                                                                      |
          ----> ItemStream.open(executionContext)                               |
         |          |   (리소스 열고 초기화. 최초1회)                           |
         |          |                                                           |
         |         \|/                                                          |
          ----> ItemWriter                                                      |
         |          |                                                           |
         |          |                                                           |
         |         \|/                                                          |
          ----> ItemStream.update(ExecutionContext) ----------------------------
                        (현재 상태정보 저장. chunkSize 만큼 반복)
 
### in codes
1. AbstractStep.execute(stepExecution) ## parent of TaskletStep
  - open(stepExecution.getExecutionContext()) 
    -> stream.open(executionContext) ## stream = CompositeItemStream
                                     ## 등록한 ItemStream을 담고 있음
    1. reader's open
    2. writer's open

  - update(stepExecution.getExecutionContext()) ## update는 반복적으로 실행 per chunkSize
  
2. ChunkOrientedTasklet
  - tasklet.execute(contribution, chunkContext)
    = itemReader.read(contribution, inputs)
    = doProcess
    = write

3. 반복
  - 반복 시작 전에 `stream.update(stepExecution.getExecutionContext()) 호출
    = 데이터 update!

* close 는 실패 or 종료 등의 이유로 자원을 닫을 때 호출

* 실패 후 재시작 시 `open`에 재시작 처리가 되어 있다면...
  = update가 반영된 마지막 지점부터 다시 시작(마지막 chunk 이후 부터 다시 시작할 수 있는 이유) 

