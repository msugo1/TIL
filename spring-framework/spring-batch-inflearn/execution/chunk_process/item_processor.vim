### ItemProcessor
  - 데이터를 출력하기 전에 데이터를 가공, 변형, 필터링하는 역할
  - ItemReader, Writer와 분리되어 비즈니스 로직 구현
  - 받은 아이템을 특정 타입으로 변환해서 Writer에 넘겨줄 수도 있다.
    (or 필터링 해서 원하는 아이템만 골라 넘겨줄 수도 있다. = process return null)
  - 선택요소 


      ItemProcessor<I, O>

  O process<@NonNull I item> throws Exception

  - I: ItemReader로 부터 받을 타입
  - O: ItemWriter에 넘겨줄 타입
  - 하나씩 가공 처리
    = null 리턴 시 청크에 저장되지 않음 = Writer에 넘기지 않는다.

  * ItemStream을 구현하지 않는다.
  * 대부분 커스터마이징 -> 기본적으로 제공되는 구현체가 적음

  representatives?
  ValidatingItemProcessor<T>, ClassifierCompositeItemProcessor<I, O>
     = 검증                       = 분류에 따른 선택적 처리

  CompositeItemProcessor<I, O>
     = 아이템 프로세서 chaining
 
