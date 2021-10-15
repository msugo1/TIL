### FixedLengthTokenizer
  - 한 개 라인의 String을 사용자가 설정한 고정길이 기준으로 나누어 토큰화
  - 범위를 문자열 형식으로 설정할 수 있음
    ex. 1-4, 7-10 and so on

    = 마지막 범위가 열려있으면 - ex. 7 ~ - 나머지 행이 해당열로 읽혀짐
    (literally from the min to the last = Range(1), Range(5) 등록되어 있을 시 1 ~ 끝, 5 ~ 끝)
      -> 다음 등록된 범위 고려 x
                  
                            FixedLengthTokenizer
        
                              Range[] ranges ## 열의 범위를 설정
          
                            int maxRange = 0 ## 최대 범위 설정
  
                           Boolean open = false ## 마지막 범위가 열려있는지 여부

ex.
  00000A1000002016 ---> 00000, A1, 00000, 2016
  ```
  tokenizer.setColumns(
     Range(1-5),  
     Range(6-7),  
      ...
  )
  ```

### in codes
```
    @Bean
    fun itemReader() = FlatFileItemReaderBuilder<Customer>()
        .name("flatFile")
        .resource(FileSystemResource("/Users/soo/Desktop/inflearn/spring-batch/src/main/resources/customer.txt"))
        .fieldSetMapper(BeanWrapperFieldSetMapper())
        .targetType(Customer::class.java)
        .linesToSkip(1)
        .fixedLength()
        .addColumns(Range(1, 5))
        .addColumns(Range(6, 9))
        .addColumns(Range(10, 11))
        .names("name", "year", "age")
        .build()
``` 
