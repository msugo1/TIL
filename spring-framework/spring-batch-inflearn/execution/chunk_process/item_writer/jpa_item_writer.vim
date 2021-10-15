### JpaItemWriter
  - JPA Entity 기반으로 데이터 처리
    = EntityManagerFactory를 주입 받아 사용
  - Entity를 하나씩 chunk 크기만큼 insert or merge 한 다음 flush
  - ItemReader or ItemProcessor로부터 아이템을 전달받을 때, Entity 클래스 타입으로 받아야 한다.

### API
1. usePersist(boolean) ## entity를 persist() 할 것인지 여부(false: merge)
2. entityManagerFactory(EntityManagerFactory)
3. build
                                
                                      Step
                                       |
                                       | write(List<Item)
                                       |
                                      \|/
                                  JpaItemWriter
                                       |
                                       |
                                      \|/
                                 EntityManager() ----- Entity
                                       |
                                       |
                                      \|/
            persist <---- Yes ---- userPersist ---- No ----> merge
                                       |
                                       | flush
                                      \|/
                                    DataBase

### example
```
@Bean
fun customItemWriter() = JpaItemWriterBuilder<Customer2>()
    .usePersist(false)
    .entityManagerFactory(entityManagerFactory)
    .build()
```
