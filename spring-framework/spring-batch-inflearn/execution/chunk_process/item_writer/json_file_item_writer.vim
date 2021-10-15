### JsonFileItemWriter
  - 객체를 받아 JSON String으로 변환하는 역할

### API
1. name
2. resource
3. append(boolean)
4. jsonObjectMarshaller(JsonObjectMarshaller) ## JsonObjectMarshaller 객체 설정
5. headerCallback(FlatFileHeaderCallback) ## 헤더를 파일에 쓰기 위한 콜백 인터페이스
6. footerCallback(FlatFileFooterCallback) ## 푸터를 파일에 쓰기 위한 콜백 인터페이스
7. shouldDeleteIfExists(boolean) ## 파일에 이미 존재한다면 삭제
8. shouldDeleteIfEmpty(boolean) ## 파일의 내용이 비어있다면 삭제
9. build



        write(List<Item)                      marshall(item)
  Step -----------------> JsonFileItemWriter ---------------> JacksonJsonObjectMarshaller
                                                                          |
                                                                          |
                                                                          |
                                                                          |
                                                                          |
                                                                          |
                                                                          |
                File      <----------------------------------------- ObjectMapper
                                    writeValueAsString(Item)

### example
@Bean
fun customItemWriter() = JsonFileItemWriterBuilder<Custom>()
    .name("jsonFileWriter")
    .append(true)
    .resource(FileSystemResource("/Users/soo/Desktop/inflearn/spring-batch/src/main/resources/custom.json"))
    .jsonObjectMarshaller(JacksonJsonObjectMarshaller<Custom>())
    .build()

