### ChunkOrientedTasklet
  - Tasklet의 구현체 provided by SpringBatch basically
  - Chunk 지향 프로세싱을 담당하는 도메인 객체
  - works with ItemReader, Processor, Writer
  - TaskletStep에 의해 반복적으로 실행
    = ChunkOrientedTasklet이 실행될 때마다 매번 새로운 트랜잭션이 생성되어 처리
    (별도 트랜잭션 처리를 위한 구문처리가 필요가 없음)
    = exception 발생 시 해당 chunk는 롤백처리
      -> 이전에 커밋한 chunk는 완료상태 유지
  - chunkProvider = handles ItemReader
  - chunkProcessor = handles ItemProcessor, ItemWriter

### How it works internally

TaskletStep ChunkOrientedTasklet ChunkProvider ChunkProcessor ItemReader Processor Writer
     |               |                |             |           |           |         |
     |        ### Transaction ###########################################################
 execute      #      |                |             |           |           |         |
     |--------#----->|                |             |           |           |         |
     |        #      |                |             |           |           |         |
     |        #   provide ----------->|             |           |           |         |
     |        #      |                |             |           |           |         |
     |        #      |                |---------read----------->|           |         |
     |        #      |                |    chunkSize만큼 반복   |           |         |
     |        #      |                |<------------------------|           |         |
     |        #      |                |             |           |           |         |
     |        #      |                |             |           |           |         |
     |        #   process(inputs) ----------------> |           |           |         |
     |        #      |                |             |           |           |         |
     |        #      |                |             |---------process------>|         |
     |        #      |                |             | chunkSize만큼 반복    |         |
     |        #      |                |             |<----------------------|         |
     |        #      |                |             |           |           |         |
     |        #      |                |             |---------write(items)----------->|
     |        #      |                |             |           |           |         |
     |        #      |                |             |           |           |         |
     |        #      |<---------------------------------------------------------------|
     |        # 더 이상 읽을 아이템이 없을 때까지 Chunk 단위로 반복 (from source)
     |        ############################################################################


### 예외 발생시!
- chunkContext.getAttribute(INPUT_KEYS)
  * INPUT_KEYS?
    = 버퍼에 담아놓았던 데이터를 가지고 옴(다시 데이터를 읽지 않는다.)
    = 재시도 시 여기부터 처리

* chunkContext.setAttribute(INPUT_KEYS, inputs)
  = chunk를 캐싱하기 위해 chunkContext 버퍼에 담기
  = chunk 단위 입출력이 완료되면, 버퍼에 저장한 chunk는 삭제한다.
    (chunkContext.removeAttribute(INPUT_KEYS)

* RepeatStatus.continueIf(!inputs.isEnd())
  = 읽을 아이템이 존재하면 더 읽고, 아니면 종료

### API
1. chunk<I, O>(chunkSize)
  = chunkSize 설정
  = chunkSize == commitInterval

2. chunk<I, O>(completionPolicy)
  = chunk 프로세스를 완료하기 위한 정책설정 클래스 지정
  ex. 조건에 부합하면 가공 전달

3. reader

4. writer

5. processor
  = Optional

6. stream(ItemStream())
  = 재시작 데이터를 관리하는 롤백에 대한 스트림 등록
  = 내부적으로 executionContext를 가진다.
    -> 현재 처리하는 내용을 저장, 관리
  ex. 재시작 시 DB에서 해당 값을 불러와서 활용 (전체 재시작을 막아준다.)

7. readerIsTransactionalQueue
  = default: false
  = 트랜잭션이 외부의 메시지 큐 등에는 적용이 안되는 것이 기본값
    -> true로 설정 시 외부까지 트랜잭션, 캐시?
  
8. listener

9. build
