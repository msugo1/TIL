### ChunkProcessor
  - ItemProcessor를 사용해 Item을 변형, 가공, 필터링
  - ItemWriter를 사용해 Chunk 데이터를 저장, 출력
    = Chunk<O> 생성
    = 앞에서 넘어온 Chunk<I>의 아이템을 한 건씩 처리
    = 다시 Chunk<O>에 저장
    
    * 외부로부터 호출될 때마다 새로운 Chunk 생성

  - ItemProcessor == optional
    = 없을 시 전달된 Chunk<I>가 그대로 Chunk<O>에 저장
    = 있을 시 Chunk<O>에 있는 처리 완료 데이터를 writer에 전달 List<Item>
  
  - ItemWriter 처리 종료 시, Chunk 트랜잭션 종료
    = Step 반복문에서 새롭게 ChunkOrientedTasklet 실행
   
  - ChunkSize 만큼 데이터 커밋 
    = therefore, chunkSize == commitInterval
    
  * 기본 구현체
  SimpleChunkProcessor, FaultTolerantChunkProcessor

  ex.
                              ChunkProcessor<I>
                  void process(StepContribution, Chunk<I>)
                                      |
                                      |
                                      |
                            SimpleChunkProcessor<I, O>
                
                        ItemProcessor<I, O>
                        ItemWriter<O>
    
                 Chunk<O> transform(StepContribution, Chunk<I>)
                 void write(StepContribution, Chunk<I>, Chunk<O>)

### in source codes
```
(ChunkProcessor.process(StepContribution contribution, Chunk<I> inputs)

...
if (isComplete(inputs)) {
    return
}

...
Chunk<O> outputs = transform(contribution, inputs) ## 가공처리 된 아이템 청크 반환
  ```
  (transform)
  Chunk<O> outputs = Chunk<>()
  
  for (inputs.iterator().hasNext()) {
      item = iterator.next()
      ...
      output = doProcess(item) ## 한 건 씩 프로세싱
      
      ```
      (doProcess)
      
      if (itemProcessor == null) {
          return item ## 아이템 프로세서가 없으면 가공 없이 바로 반환
      }
    
      ...
      listener.beforeProcess(item)
      O result = itemProcessor.process(item) ## 구현된 process 메소드 호출
      listener.afterProcess(item, result)
      return result
  }

contribution.incrementFilterCount(getFilterCount(inputs, outputs)
  ## ItemProcessor에서 필터링 된 아이템 개수 저장

write(contribution, inputs, getAdjustedOutputs(inputs, outputs) 
  ## 가공처리 된 Chunk<O>의 List<Item>을 ItemWriter에게 전달
  ```
  (write)
  ...
  doWrite(outputs.getItems())
  
    ```
    (doWrite)
    if (itemWriter == null) {
        return  ## 아이템 writer는 필수 컴포넌트 -> 따라서 없으면 그냥 종료
    }

    ...
    listener.beforeWrite(items)
    writeItems(items) ## 아이템을 한 번에 처리
      ```
      (writeItems)
      if (itemWriter != null) {
          itemWriter.write(items) ## 구현체의 write 메소드 호출
      }
      ```
    doAfterWrite(items)
    ```
  ```


