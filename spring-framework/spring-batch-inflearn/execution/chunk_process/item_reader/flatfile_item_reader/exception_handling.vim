### ExceptionHandling
  - 라인을 읽거나 토큰화할 때 발생하는 파싱 예외를 처리할 수 있도록 예외 계층 제공
  - `strict = false` 설정 시, 파싱 예외가 발생하지 않는다.

1. FlatFileParseException : ItemReaderException
  - itemReader에서 파일을 읽어들이는 동안 발생하는 예외

2. FlatFileFormatException
  - LineTokenizer에서 토큰화 하는 도중 발생하는 예외
  (more concrete than FlatFileParseException)

3. IncorrectTokenCountException : FlatFileFormatException
  - DelimitedLineTokenizer로 토큰화 할 때,
  컬럼 개수와 실제 토큰화 한 컬럼의 수가 다를 때 발생하는 예외
  
  ex.
  ```
  tokenizer.setNames(listOf("A", "B", "C", "D")) ## 토큰 컬럼 4개
  
  try {
      tokenizer.tokenize( "a, b, c") ## 라인컬럼 3개
  }
  
  = 예외발생
  ```

4. IncorrectLineLengthException
  - FixedLengthLineTokenizer으로 토큰화할 때 전체 길이와, 컬럼 길이의 총합과 일치하지 않을 때

  ex.
  ```
  tokenizer.setColumns(listOf(Range(1, 5), Range(6, 10), Range(11, 15)) ## 총 길이 15

  try {
      tokenizer.tokenize("12345") ## 라인길이 5
  }
   
  = 예외발생
  ```

### tokenizer.setStrict(false)
  - 라인 길이, 토큰 갯수 등을 검증하지 않음
    = 일치하지 않는 부분은 빈 값 등이 채워진다.

  ```
  @Bean
  fun itemReader() = FlatFileItemReaderBuilder<Customer>()
      .name("flatFile")
      .resource(FileSystemResource("/Users/soo/Desktop/inflearn/spring-batch/src/main/resources/customer.txt"))
      .fieldSetMapper(BeanWrapperFieldSetMapper())
      .targetType(Customer::class.java)
      .linesToSkip(1)
      .fixedLength()
      .strict(false)
      .addColumns(Range(1, 5))
      .addColumns(Range(6, 9))
      .addColumns(Range(10, 11))
      .names("name", "year", "age")
      .build()
  ```
  !! strict의 위치가 중요하다.
    = fixedLength() 위에 뒀을 때는, 계속 예외가 발생했다.
    = 아래로 위치 시키자 예외가 해결됬다.
