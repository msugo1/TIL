### XML ItemReader

1. DOM
  - 문서전체를 메모리에 로드
  - Tree 형태로 변경
  - 이후 데이터 처리
    = 유연한 엘리먼트 제어 but 메모리... & 속도...

2. SAX(Simple Api Xml)
  - 문서의 항목을 읽을 때마다 이벤트 발생 (per element)
    = push 방식
  - 메모리 비용이 적고 속도가 빠르다 but 엘리먼트 제어가 어렵다.

3. StAX(Streaming API for XML)
  - SAX + DOM = push + pull 동시 제공
  - XML 문서를 읽고 쓸 수 있는 양방향 파서기 지원
  - XML 파일의 항목에서 항목으로 직접 이동하면서 Stax 파서기를 통해 구문분석

### 유형
1. Iterator API 방식
  - XMLEventReader의 `nextEvent` 호출
    = 이벤트 객체 반환
  - 이벤트 객체는 XML 태그 유형(요소, 텍스트, 주석 등)에 대한 정보를 제공함

2. Cursor API 방식
  - JDBC ResultSet 처럼 작동하는 API
    = XMLStreamReader - XML 문서의 다음 요소로 커서를 이동
  - 커서에게 직접 메서드를 호출하여 현재 이벤트에 대한 자세한 정보를 얻음

### Spring-OXM
  - XML <-> Object
  - Marshaller
    = Object to XML
  - UnMarshaller
    = XML to Object

스프링 배치는 스프링 OXM에게 처리를 위임
  = 구현체 선택해서 처리하도록 하면 된다.

### StAX 아키텍처
  - XML 전체 문서가 아닌, 조각 단위로 구문을 분석하여 처리
    = `fragment`
    = 조각을 읽을 때는 DOM의 pull 방식, 객체로 바인딩 할 때는 SAX의 Push 방식 사용

### API
- name
- resource
- addFragmentRootElements(String... rootElements)
  = Fragment 단위의 루트 엘리먼트 설정 (이 루트 조각 단위가 객체와 매핑하는 기준)
- unmarshaller(Unmarshaller)
- saveState(boolean)
- build

                
                                                    StaxEventItemReader<T>
                                        
                                               - FragmentEventReader fragmentReader
                              ## XML 조각을 독립형 XML 문서로 처리하는 것을 지원하는 이벤트 판독기

                                               - XMLEventReader eventReader
                              ## XML 이벤트 구문 분석을 위한 최상위 인터페이스

                                               - Unmarshaller unmarshaller
                              ## XML 문서를 객체로 직렬화하는 인터페이스

                                               - Resource resource
                              ## 다양한 리소스에 접근하도록 추상화 한 인터페이스

                                               - List<QName> fragmentRootElementNames
                              ## 조각 단위의 루트 엘리먼트 명을 담은 리스트 변수


### Process

  Step -- read --> StaxEventItemReader --- unmarshall ---> XStreamMarshaller  <-------> XMLEventReader <-- 조각 단위로 read --> file

                                      <-- 객체로 바인딩 <--------------------- DOM Tree --------------   

  * XStreamMarshaller
  - 맵으로 alias 지정가능
  - 첫번째 키는 루트 엘리먼트, 값은 바인딩 할 객체 타입
  - 두번째 부터는 하위 엘리먼트와 각 클래스 타입
