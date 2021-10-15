### FlatFileItemWriter
  - 2차원 데이터(표)로 표현된 유형의 파일을 처리하는 ItemWriter
  - 고정위치로 정의된 데이터 필드나 특수 문자에 의해 구별된 데이터의 행을 기록
  - Resource, LineAggregator 두 가지 요소가 필요

### Structure

        FlatFileItemWriter
  
    String encoding = DEFAULT_CHARSET
   (default: Charset.defaultCharset())

    boolean append = false
    = 대상 파일이 이미 있는 경우 데이터를 계속 추가할 것인가 

    Resource resource
    = 작성해야 할 리소스

    LineMapper<T> lineAggregator
    = Object를 String으로 변환

    FlatFileHeaderCallback headerCallback
    = 헤더를 파일에 쓰기 위한 콜백 인터페이스

    FlatFileFooterCallback footerCallback
    = 푸터를 파일에 쓰기 위한 콜백 인터페이스

* LineAggregator
  - item을 받아서 String으로 변환하여 리턴
  - FieldExtractor를 사용해서 처리할 수 있음
  
  구현체
  = PassThroughLineAggregator, DelimitedLineAggregator, FormatterLineAggregator

* FieldExtractor
  - 전달 받은 item 객체의 필드를 배열로 만들고, 배열을 합쳐서 문자열을 만들도록 구현하도록 제공하는 인터페이스

  구현체
  = BeanWrapperFieldExtractor, PassThroughFieldExtractor

  
                                              LineAggregator<T>
              ------------------------->                              <-----------------------
             |                            - String aggregate(T item)                          |
             |                       ## 객체를 인자로 받고, 문자열 반환                       |
             |                                         /|\                                    |
             |                                          |                                     |
  PassThroughLineAggregator                  DelimitedLineAggregator               FormatterLineAggregator 
 전달된 아이템을 단순히 문자열로 반환     전달된 배열을 구분자로 구분하여        전달된 배열을 고정길이로
                                                 문자열로 합침                     구분하여 문자열로 합침
                                                  
                                                        |                                     |
                                                        |                                     |
                                                        |                                     |
                                                         ----------> FieldExtractor <---------
                                                        |         Object[] extract(T item)    |
                                                        |    ## 객체를 인자로 받고 문자열 반환|
                                                        |                                     |
                                                  BeanWrapperFieldExtractor         PassThroughFieldExtractor
                                        
                                            전달된 객체의 필드들을 배열로 반환    전달된 Collection을 배열로 반환


        write(List<Item>)                       aggregate(Item)                 extract(Item)
  Step -------------------> FlatFileItemWriter ---------------->  LineAggregator ----------> FieldExtractor
                                              <-----------------                <-----------
                                                    String                    Fields Value(Object[])

### API
1. name
2. resource(Resource) ## 쓰기할 리소스 설정
3. lineAggregator(LineAggregator<T>) ## 객체를 String으로 변환하는 LineAggregator 객체 설정
4. append(boolean) ## 존재하는 파일에 내용을 추가할 것인지 여부 결정
5. fieldExtractor(FieldExtractor<T>) ## 객체 필드를 추출 -> 배열로 만드는 FieldExtractor 설정
6. headerCallback(FlatFileHeaderCallback) ## 헤더를 파일에 쓰기 위한 콜백 인터페이스
7. footerCallback(FlatFileFooterCallback) ## 푸터를 파일에 쓰기 위한 콜백 인터페이스
8. shouldDeleteIfExists(boolean) ## 파일이 이미 존재한다면 삭제
9. shouldDeleteIfEmpty(boolean) ## 파일의 내용이 비어있다면 삭제
10. delimited().delimiter(String delimiter) ## 파일의 구분자를 기준으로 파일을 작성하도록 설정
11. formatted.format(String format) ## 파일의 고정길이를 기준으로 파일을 작성하도록 설정
12. build

### example
**DelimetedLineAggregator**


                         ExtractorLineAggregator

                     - FieldExtractor<T> fieldExtractor ## 객체를 인자로 받고 배열반환

                   - abstract String doAggregate(Object[] fields)   ## 배열 필드를 문자열로 만들어서 반환
                                      /|\
                                       |
                                       |  
                        DelimitedLineAggregator
              
                    - String delimiter  ## 구분자 - default: ,
                 
                    - String doAggregate(Object[] fields) ## 배열 필드를 구분자로 구분해서 문자열을 만든 후 반환

 
* fields = this.fieldExtractor.extract(item)
    -> values.toArray()
    -> StringUtils.arrayToDelimitedString(fields, this.delimiter)
 
### in codes
1. FlatFileItemWriter.doWrite(List<? extends T> items)
   ```
    StringBuilder lines = StringBuilder()
    for (T item: items) {
        lines.append(this.lineAggregator.aggregator(item)).append(this.lineSeparator)
    }
   ```

2. ExtractorLineAggregator.aggregate(T item)
  ```
  Object[] fields = this.fieldExtractor.extract(item)

  Object[] args = new Object[fields.length]
  for (int i = 0; i < fields.length; i++) {
      if (fields[i] == null) {
          args[i] = ""
      } else {
          args[i] = fields[i]
      }
  }
    
  return this.doAggregate(args)
  ```

3. DelimitedLineAggregator.doAggregate(Object[] fields)
  - return StringUtils.arrayToDelimitedString(fields, this.delimiter)

### code example
```
@Bean
fun customItemWriter() = FlatFileItemWriterBuilder<Custom>()
    .name("flatFileWriter")
    .resource(FileSystemResource("/Users/soo/Desktop/inflearn/spring-batch/src/main/resources/customer.txt"))
    .append(true)
    .delimited()
    .delimiter("|")
    .names("id", "name", "age")
    .build()
```

**FormatterLineAggregator**

      
                          FormatterLineAggregator
      
                      - String format ## 포맷 설정
                  
                    - int maximumLength = 0 ## 최대 길이 설정

                    - int minimumLength = 0 ## 최소 길이 설정


```
@Bean
fun customItemWriter() = FlatFileItemWriterBuilder<Custom>()
    .name("flatFileWriter")
    .resource(FileSystemResource("/Users/soo/Desktop/inflearn/spring-batch/src/main/resources/customer.txt"))
    .formatted()
    .format("%-2d%-10s%-2d")
    .names("id", "name", "age")
    .build()
    

