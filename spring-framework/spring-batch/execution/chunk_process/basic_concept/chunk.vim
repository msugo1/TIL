### Chunk
  - 여러 개의 아이템을 묶은 하나의 덩어리, 블록
    = 하나씩 아이템을 read -> process
    = chunk 단위의 덩어리로 쌓는다.
    = then write
    (청크 단위로 트랜잭션을 처리한다. = chunk 단위의 commit & rollback)
  - 더 이상 처리할 데이터가 없을 때까지 반복해서 입출력


  Source -- read item --> ItemReader --> Chunk<I> items --> ItemProcessor -- transform --

--> Chunk<O> items --> ItemWriter

  = read one item each, but send item`s` to the writer

* Chunk<I, O>
  - Input & Output
  - ItemProcessor에서 가공하기 때문에, Output이 다를 수 있다.

### in detail

* (until ItemProcessor)
                          List<Item> -------------- inputs
                              |                       |
       read           item    |                       |
Source ---> ItemReader ---> Chunk<I> -- chunkSize? -- Yes --> ItemProcessor
                |                           |
                 -------------------------- No

* (from ItemProcessor)
                              List<Item> ---- output --
 from ItemReader                  |                    |
  --------- ItemProcessor --- transform ---> Chunk<O> ---> ItemWriter --- items -->
                |  |
 iterator.next  |  |  item
                |  |
               inputs

* 스프링 배치 자체적으로 chunk 를 트랜잭션 별로 처리한다.
  - 별도의 처리 불필요
  - 청크별로 commit & rollback 
    = 재시작 시 처리 유용

* ItemReader, ItemProcessor는 Chunk 내 개별 아이템을 처리한다.
* ItemWriter는 Chunk 별로 일괄처리

### Architecture
                                         Iterator
                                            |
                                            |
    Iterable -----------------------> ChunkIterator 
       |                          Iterator<W> iterator = items.iterator()
       |                        (chunk 내 아이템을 추출하기 위함)
     Chunk
  - List items
  - List<SkipWrapper> skips
  - List<Exception> errors
  - ChunkIterator iterator(return new ChunkITerator(items))
    = InnerClass  

### in codes
1. ChunkOrientedTasklet
  - execute
  ```
  Chunk<I> inputs = chunkContext.getAttribute(INPUT_KEY) ### for inputs
  
  if (inputs == null) {
      inputs = chunkProvider.provide(contribution)
      ...
  } 
  
  ```

2. SimpleChunkProvider
  - provide
  ```
  Chunk<I> inputs = new Chunk<>()
  repeatOperations.iterate(RepeatCallback() {
      ...
      item = read(contribution, inputs)
  } 

3. read ### call read from the registered ItemReader implementation
  - one by one
  - then, add in chunk (inputs.add(item))
  
  return inputs (chunk) when read is done

4. chunkProcessor.process(contribution, inputs)
SimpleChunkProcessor

  - Chunk<O> outputs = transform(contribution, inputs)
  
5. transform
  ```
  - outputs = Chunk<>()
  
  for (Chunk<I>.ChunkIterator iterator = inputs.iterator; iterator.hasNext();) {
      I item = iterator.next()
      ...
      output = doProcess(item) ### item 별로 
  }

6. doProcess ### call process from the registered ItemProcessor implementation
  - one by one
  - then add in chunk (outputs.add(item))
  
  return outputs

7. write(contribution, inputs, getAdjustedOutputs(inputs, outputs))
  - doWrite(outputs.getITems()) ### call write from ...
