### JsonItemReaader
  - Json 데이터의 Parsing, Binding을 JsonObjectReader 인터페이스 구현체에 위임 & 처리
  - JasksonJsonObjectReader, GsonJsonObjectReader

                          
                                                   JsonItemReader<T>

                                                   Resource resource
                                              ## 다양한 리소스 접근 추상화


                                            JsonObjectReader jsonObjectReader
                                             ## Json 구문을 객체로 변환

                                                           |
                                                           |
                                                           |

                                             JacksonJsonObjectReader<T>

                                            Class<? extends T> itemType
                                         ## Json 데이터를 매핑할 객체타입

                                            JsonParseer jsonParser 
                                         ## Json 구문을 분석하는 파서기


                                            ObjectMapper mapper
                                         ## Json을 Object로 매핑하는 매퍼

                                           InputStream inputStream 
                                         ## Json 파일로부터 읽는 입력 스트림


### 프로세스
    
ChunkOrientedTasklet -- read --> JsonItemReader -- read --> JsonObjectReader <----> ObjectMapper -- readValue(jsonParser, Class) -> file

### in codes

1. jsonItemReader.doReade()

2. jsonObjectReader.read() ## 구현체의 메소드 호출
  ```
  if (this.jsonParser.nextToken() == JsonToken.START_OBJECT) {
      return this.mapper.readValue(this.jsonParser, this.itemType) ## 아이템 타입은 설정한 클래스 타입
  }


### example
```
@Bean
fun jsonItemReader() = JsonItemReaderBuilder<Customer>()
    .name("jsonReader")
    .resource(ClassPathResource("customer.json"))
    .jsonObjectReader(JacksonJsonObjectReader(Customer::class.java))
    .build() 
```
