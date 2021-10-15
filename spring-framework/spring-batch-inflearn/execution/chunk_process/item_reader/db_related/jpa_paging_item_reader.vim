### JpaPagingItemReader
- Paging 기반의 Jpa 구현체
  = EntityManagerFactory 객체가 필요하다.
  = JPQL을 사용한다.

### API
1. name
2. pageSize 
  = 페이지 크기 설정
  = 쿼리 당 요청할 레코드 수
3. quieryString(String JPQL)
  = ItemReader가 조회할 때 사용할 JPQL 문장 설정
4. entityManagerFactory(entityManagerFactory)

5. parameterValue(Map<String, Object> parameters)
  = 쿼리 파라미터 설정

6. build

### Process


            ----> ItemStream -----> create EntityManager
          /             |
    open /              |
        /               |
       /               \|/
  Step -- read -> JdbcPagingItemReader -- doReadPage --> EntityManager -- createQuery() ----> Query
       \               /|\                                                                      |    
        \               |                                                                       |
         \               ------------ return List ------------- ResultList ---------------------
          \
     close \
            \
              -----> ItemStream ---> close EntityManager


### example
```
@Bean
fun jpaPagingItemReader() = JpaPagingItemReaderBuilder<Customer>()
    .name("jpaPagingItemReader")
    .entityManagerFactory(entityManagerFactory)
    .pageSize(10)
    .queryString("SELECT c FROM Customer c")
    ## this should be `SELECT c FROM Customer c fetch join c.address` to prevent N+1 problem
    .build()
```

### in codes
1. JpaPagingItemReader.doOpen
  - entityManagerFactory.createEntityManager(jpaPropertyMap)
 
2. AbstractItemCountingItemStreamItemReader.update(executionContext) ## 현재 값 업데이트

3. AbstractPagingItemReader.doRead
  - doReadPage()
  ```
  if (transacted: default = true) {
      tx = entityManager.getTransaction()
      tx.begin()
    
      entityManager.flush()
      entityManager.clear()
  }

  Query query = createQuery().setFirstResult(getPage() * getPageSize()).setMaxResults(getPageSize())
  
  if (parameterValues != null) {
      for (Map.Entry(String, Object> me : parameterValues.entrySet()) {
          query.setParameter(me.getKey(), me.getValue())
      }
  }

  if (results == null) {
      results = new CopyOnWriteArrayList<>()
  } else {
      results.clear()
  }

  if (!transacted) {

  } else {
      results.addAll(query.getResultList())
      tx.commit()
  }
  ```

4. close()
  - doClose()
