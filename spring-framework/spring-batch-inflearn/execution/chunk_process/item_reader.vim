### ItemReader
  - 다양한 입력으로부터 데이터를 읽어서 제공하는 `인터페이스`
  - 종류 ~Reader
    = FlatFile, XML/Json, Database, JMS, RabbitMQ, or even custom reader
    = custom reader 구현 시 멀티 스레드 환경에서 thread-safe 하게 구현해야 한다.
  - ChunkOrientedTasklet 실행 시 필수요소


      ItemReader<T>
  
T read() throws Exception, UnexpectedInputException, ParseException, NonTransientResourceException

  - 입력데이터를 읽고 다음데이터로 이동
    = 아이템 하나 리턴 
    (db one row, file one line, or xml one element)
    = 더 이상 읽을 아이템이 없으면 null 리턴

* 정말 다양한 구현체가 있다.
  - 필요하면 사진을 찾아보자... 이건 수동으로 못하겠다.

대표적인 것들?
  - FlatFileItemReader (file)
  - Jdbc/JpaCursor (or Paging) ItemReader (DB)
  ...

### 대다수의 구현체들이 ItemReader & ItemStream 동시에 구현
especially `ItemStream`
  - 파일의 스트림을 열거나 종료, DB 커넥션을 열거나 종료, 입력장치 초기화 등
  - ExecutionContext에 read 관련된 여러가지 상태정보 저장
    = `재시작`시 다시 참조하도록 지원

  (ItemReader 자체는 read 메소드밖에 없다.)


