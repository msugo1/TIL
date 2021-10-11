### Architecture

    Job
     |
     |
    \|/
TaskletStep --> RepeatTemplate --> ChunkOrientedTasklet


   ### In Transcation (트랜잭션 경계 from here)
(ChunkOrientedTasklet)
  |                                           (Begin Transaction) ## actual transaction
  |  ### In Chunk (iterate based on chunkSize)       |
  |                                                  |
  |---> SimpleChunkProvider -> RepeatTemplate -> --------> ItemReader -- read --> source
  |                       repeatTempalte here as well                      |
  |                                |                                       |
  |                                |                `FINISHED`--- Yes -- null? - No --
  |                                |                                                  |
  |                        ChunkSize만큼 iterate                                      |
  |                                |                             ---------------------
  |                                |                            |
  |                                |                         Chunk<I>
  |                                |                            |
  |                                 -- No --- Limit Chunk Size?-
  |                                                        |
   ---> SimpleChunkProcessor <---- inputs 전달 ----- Yes --
          |
          |
           ---> ItemProcessor -------> Chunk<O> --- write(List<Item>) ------> ItemWriter
                   |    /|\                                                       |
          iterator |     | process(item)                                          |
                  \|/    |                                                        |
                                                                                  |
                   inputs                                                         |
                                                 Commit Transaction <--- DB <-----

  ### Commit 이후
  - 처음 RepeatTemplate으로 돌아와 Chunk 단위의 프로세스 다시실행
  (이전 트랜잭션은 종료)
    = 청크 단위마다 새로운 트랜잭션 생성
    = 트랜잭션 내 청크 프로세스 반복
  
  ### 청크 작업 도중 예외 발생 시는 Rollback
  - 청크 단위 별로 트랜잭션이 유지되므로, 롤백 트랜잭션 이전의 커밋까지는 유지
  - 작업 추적은 ItemStream 구현으로 가능
    = open 후, 매 커밋마다 update를 호출해서 진행 상황을 ExecutionContext에 담기 때문
    = 실패 후 재시작 시ExecutionContext에 담긴 내용을 가져와 거기부터 재진행이 가능하게 된다.

참고)
  ItemReader, ItemProcesser
  - 아이템 단위로 개별처리
    = 처리 후 chunk 단위가 될 때까지 chunk에 모은다.
  - 전달시만 ChunkSize로 전달
  
