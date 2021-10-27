### ChunkProvider
  - ItemReader 사용
  - 소스로부터 아이템을 Chunk Size만큼 읽어서 Chunk 단위로 만들어 제공
    = Chunk<I>
    = 내부적으로 반복문(iterator)을 만들어 itemReader.read() 계속 호출, 청크에 쌓기
  - 외부로부터 호출될 때마다 항상 새로운 청크가 생성
    = 한 사이클마다 하나의 Chunk 객체

  * 종료시점?
    - 청크 사이즈만큼 다 읽으면
      = chunkProcessor로 바톤 터치!
    - itemReader가 `null 반환 = 다 읽음`의 경우 반복문 종료 및 해당 Step의 반복문까지 종료

  * 기본 구현체
    - SimpleChunkProvider
    - FaultTolerantChunkProvider

ex.
                   ChunkProvider
 Chunk<T> provide(StepContribution contribution)
                         |
                         |
                         |
                 SimpleChunkProvider
                     
                ItemReader<I>
                RepeatOperations
              
                I read(StepContribution contribution, Chunk<I> chunk)
                = reader로부터 한 건씩 아이템을 읽음


```
(ChunkProvider.provide)

Chunk<I> inputs = Chunk<>() ## Item을 담을 청크 생성 - provide 호출 시마다
repeatOperations.iterate(RepeatCallBack() ## chunk 사이즈만큼 반복문 실행, read 호출
  ...
  item = read(contribution, inputs)
  ```
    doRead()
      listerner.beforeRead()

      I item = itemReader.read() ## 구현체 read 호출
      if (item != null) {
          listener.afterRead(item)
      }
      
      return item
  ```
  ...
  if (item == null) { ## null일 경우 소스의 끝에 도달했다는 의미, 전체 read 프로세스 종료
    inputs.setEnd()
    return RepeatStatus.FINISHED
  }
  inputs.add(item) ## reader로부터 받은 item을 청크 사이즈만큼 청크에 저장
  contribution.incrementReadCount()
  return RepeatStatus.CONTINUABLE   
