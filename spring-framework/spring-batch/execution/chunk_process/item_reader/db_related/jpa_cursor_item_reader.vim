### JpaCursorItemReader
(since SpringBatch 4.3)

- Cursor-based JPA implementation
- EntityManagerFactory is required
- JPQL is used for queires

### API
1. name
2. queryString
3. EntityManagerFactory
4. parameterValue(Map<String, Object> parameters) 
  =  쿼리 파라미터
5. maxItemCount(int count)
  = 조회할 최대 item 수
6. currentItemCount(int count)
  = 조희 Item의 시작지점
7. build


### Process



                                                 -----> create EntityManager
                                                |
            ----> ItemStream ---> Open Cursor --------> create Query ----> `resultList` ---
          /             |                       |                                          |
    open /              |                        -----> create ResultStream <--------------
        /               |                      (resultList -> stream -> iterator: 여기는 아래서)
       /               \|/
  Step -- read --> JpaCursorItemReader ---- doRead ----> ResultStream ----> Iterator ## DB 접근X
       \                               <---- object ----              <----          ## 이미 위에서...
        \
   close \                                          
          \                                        
            -----> ItemStream ---> Close Cursor  --------> Close EntityManager
                                                  
                                                 

### example
```
@Bean
fun customerJpaItemReader() = run {
    val parameters = mapOf(
        "first_name" to "S%"
    )

     JpaCursorItemReaderBuilder<Customer>()
        .name("jpaCursorItemReader")
        .entityManagerFactory(entityManagerFactory)
        .queryString("SELECT c FROM Customer c WHERE first_name like :first_name")
        .parameterValues(parameters)
        .build()
}
```

### in code

1. JpaCursorItemReader.doOpen()
  - this.entityManager = this.entityManagerFactory.createEntityManager()
  - Query query = createQuery()
  ...
  - this.iterator = query.getResultStream().iterator()
  ## 이제 iterator에서 아이템을 하나 씩 가져올 수 있다.
  ## iterator에 청크 사이즈 만큼 아이템이 담겨있으므로, 더 이상 DB와 통신할 필요가 없다.

2. .update(executionContext)
  - super.update(executionContext)
  - this.entityManager.clear()

3. .doRead()
  - return this.iterator.hasNext() ? this.iterator.next : null

  ## chunkSize 만큼 반복

