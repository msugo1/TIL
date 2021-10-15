### ItemWriter
  - 청크 단위로 데이터를 받아 일괄 쓰기위한 인터페이스
    (to file, XML/Json, DB, MQ, Mail and so on)
  - 아이템 리스트를 전달 받는다.
  - 필수요소 like ItemReader


      ItemWriter <T>
void write(List<? extends T> items) throws Exception

  - 출력 데이터를 아이템 리스트로 받아 처리
  - 출력이 완료되고 트랜잭션이 종료되면 새로운 청크 단위 프로세스로 이동
  - reader가 null을 반환하면 모든 프로세스가 종료

* 구현체
  - reader 구현체와 대부분 1:1 매칭
  - 역시 필요한 경우 사진을 찾아보자

  다수의 구현체들이 ItemWriter, ItemStream을 동시에 구현 중
