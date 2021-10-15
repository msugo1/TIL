### XML StaxEventItemWriter
  - XML 쓰는 과정은 읽기 과정에 대칭적
  - Resource, Marshaller, RootTagName이 필요

### API
1. name
2. resource
3. rootTagName ## 조각 단위의 루트가 될 이름 설정
4. overwriteOutput(boolean) ## 파일이 존재하면 덮어 쓸지
4. marshaller(Marshaller)
5. headerCallback()
6. footerCallback()
7. build

### Process

       write(List<Item>)                      marshall(Item)
  Step -----------------> StaxEventItemWriter ---------------> XStreamMarshaller 
                                                                       |
                                                                       |
                                                                       |
                                                                       |
                                                                       |
                                                                       |
                                                                       |
                                                                      \|/
                 File <---------------------------------------- XMLEventWriter
                                  조각 단위로 쓰기

* XStreamMarshaller
- StaxEventItemREader와 동일한 설정
- 맵으로 alias 지정가능
- 첫번째 키는 조각의 루트 엘리먼트, 값은 바인딩할 객체 타입
- 두번째 부터는 하위 엘리먼트와 각 클래스 타입

### example
```
@Bean
fun customItemWriter() = StaxEventItemWriterBuilder<Customer>()
    .name("staxEventWriter")
    .marshaller(itemMarshaller())
    .resource(FileSystemResource("/Users/soo/Desktop/inflearn/spring-batch/src/main/resources/customer.xml"))
    .rootTagName("customer")
    .build()

@Bean
fun itemMarshaller() = XStreamMarshaller().apply {
    val aliases = mapOf(
        "customer" to Customer::class.java,
        "id" to Long::class.java,
        "firstName" to String::class.java,
        "lastName" to String::class.java,
        "birthdate" to String::class.java,
    )

    this.setAliases(aliases)
}
```
