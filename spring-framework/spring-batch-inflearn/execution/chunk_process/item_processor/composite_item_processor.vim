### CompositeItemProcessor
  - chain and run each item processor
  - 이전 item processor 반환 값 -> 다음 item processor input

### API
1. delegates(ItemProcessor<?, ?>... delegates)
2. build

                                           CompositeItemProcessor
                            --------------------------------------------------
      ItemReader  --------> ItemProcessor1, ItemProcessor2 ... ItemProcessor N  -------->  ItemWriter
                            ------ | ------------ | ---------------- | -------
                                 item  ------->  item  --- ... -->  item 

= ItemProcessor 간 체이닝하면서 Item을 가공/처리

### example
```
@Bean
fun batchStep1() = stepBuilderFactory.get("batchStep1")
    .chunk<String, String>(10)
    .reader {
        i++
        if (i > 10) {
            null
        } else {
            "item"
        }
    }
    .processor(CompositeItemProcessorBuilder<String, String>()
        .delegates((listOf(
            CustomItemProcessor1(),
            CustomItemProcessor2()
        )))
        .build()
    )
    .writer(itemWriter())
    .build()
```

### ClassifierCompositeItemProcessor
- add examples at another time

(in codes)
1. ClassifierCompositeItemProcessor.process
  return processoItem(classifier.classify(item), item)

2. processItem

  ```
  private <T> O processItem(ItemProcessor<T, ?extends O> processor, I input) throws Exception {
      return processor.process((T) input)
  }
  ```

  -> classify를 통해 조건에 부합하는 Processor 선택 후, 해당 프로세서로 아이템 처리 및 반환


