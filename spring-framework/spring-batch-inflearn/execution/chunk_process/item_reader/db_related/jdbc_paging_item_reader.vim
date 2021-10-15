### JdbcPagingItemReader
  - Paging 기반
    = offset & limit
    = 스프링 배치에서 페이지 크기에 맞게 자동으로 생성
      -> 페이징 단위로 데이터를 조회할 때마다 새로운 쿼리가 실행된다.

  - 페이지 마다 새로운 쿼리를 실행
    = order by 구문이 작성되어 결과데이터의 순서를 보장해야 한다.

  - thread-safe

* PagingQueryProvider
  - 쿼리 실행에 필요한 쿼리문을 ItemReader에게 제공하는 클래스
  - DB마다 페이징 전략이 다르므로, 각 DB 벤더마다 다른 PagingQueryProvider를 사용한다.
    = 스프링 배치에서 DB 엔진의 유형에 맞게 내부적으로 처리해준다. (분석 후)
  - select, from, sortKey는 필수로 설정 & where, group by 절은 선택


### API
1. pageSize
  = 쿼리 당 요청할 레코드 수

2. dataSource

3. queryProvider(PagingQueryProvider)

4. rowMapper(Class<T>)
  = 쿼리 결과로 반환되는 데이터 <-> 객체 매핑

5. selectClause(String)                      |
6. fromClause(String)                        |
7. groupClause(String)                        ----> PagingQueryProvider
8. sortKeys(Map<String, Order> sortKeys)     |
  = 정렬을 위한 유니크한 키 설정             |

9. maxItemCount(int count)
  = 조회할 최대 아이템 수

10. currentItemCount(int count)
  = 조회 item의 시작지점

11. maxRows(int maxRows)
  = ResultSet 오브젝트가 포함할 수 있는 최대행 

### Process

 
            ----> ItemStream --- update ---> ExecutionContext
          /             |                       
    open /              |                      
        /               |
       /               \|/
  Step -- read -> JdbcPagingItemReader -- doReadPage --> JdbcTemplate -- query --> ResultSet -- next --> DB
       \               /|\                                                             |      <-- data --
                        |                                                              |
                         ------------ return List ------------- List <--- rowMapper --
        \
   close \                             
          \                           
            -----> ItemStream ---> Close Paging
                                        
                                       
### example
```
    @Bean
    fun jdbcPagingItemReader() = JdbcPagingItemReaderBuilder<Customer>()
        .name("jdbcPagingItemReader")
        .pageSize(10)
        .dataSource(dataSource)
        .rowMapper(BeanPropertyRowMapper(Customer::class.java))
        .queryProvider(createQueryProvider())
        .build()

    @Bean
    fun createQueryProvider() = SqlPagingQueryProviderFactoryBean().apply {
        this.setDataSource(dataSource)
        this.setSelectClause("id,first_name,last_name,birth_date")
        this.setFromClause("from customer")
        this.setWhereClause("where first_name like :first_name")
        this.setSortKeys(mapOf("id" to Order.ASCENDING))
    }.`object`
```

### in codes
1. JdbcPagingItemReader.afterPropertiesSet 
  (this ItemReader has implemented InitializingBean)
  - create a jdbcTemplate & set the fetchSize
  - jdbcTemplate.setMaxRows(getPageSize())
  - queryProvider.init(dataSource) ## 쿼리 생성
  
2. AbstractItemCountingItemStreamItemReader.update(executionContext)
  - 상태정보 업데이트

3. AbstractPagingItemReader.doRead()
  - synchronized 처리 되어 있음
  - doReadPage() in JdbcPagingItemReader
    ```
    if (results == null) {
        results = CopyOnWriteArrayList<>()
    } else {
        results.clear() ## 두번째 이후부터는 리스트에 값이 있으므로 초기화
    } 

    ...
    query = getJdbcTemplate().query(firstPageSql, rowCallback)
  
  page++
  if (current >= pageSize) {
      current = 0 ## current 초기화
  }
  
  int next = current++
  if (next < results.size()) {
      return results.get(next) ## 아이템을 하나씩 반환
  } else {
        return null
  }
  
