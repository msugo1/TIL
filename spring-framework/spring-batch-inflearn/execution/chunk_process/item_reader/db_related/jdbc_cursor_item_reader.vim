### JdbcCursorItemReader
  - Cursor 기반의 Jdbc 구현체
    = ResultSet과 함께 사용
    = Datasource에서 커넥션을 얻어와서 SQL 실행
    
  - Thread 안정성 보장x
    = 멀티 스레드 환경에서 사용할 경우, 동시성 이슈가 발생하지 않도록 동기화 처리가 별도로 필요

### API
1. name

2. fetchSize - 한 번에 메모리에 할당할 크기
  = 한 번에 몇개나 가져올 것인가

3. dataSource
  = DB에 접근할 data source

4. rowMapper(RowMapper)
  = 쿼리 결과로 반환되는 데이터와 객체를 매핑하기 위한 Mapper

5. beanRowMapper(Class<T>)
  = 클래스 타입을 설정하면 해당 객체에 자동으로 매핑

6. sql(String sql)
  = ItemReader가 DB에 조회 시 사용할 쿼리
  = String으로 쿼리 등록

7. queryArguments(Object ...args)
  = 쿼리 파라미터

8. maxItemCount(int count)
  = 조회할 최대 item 수

9. currentItemCount(int count)
  = 조회 item의 시작 지점

10. maxRows(int maxRows)
  = ResultSet 오브젝트가 포함할 수 있는 최대 행 수

11. build

### Process



                                                 -----> DB Connection
                                                |
            ----> ItemStream ---> Open Cursor --------> PreparedStatement
          /             |                       |
    open /              |                        -----> ResultSet 
        /               |
       /               \|/
  Step -- read -> JdbcCursorItemReader -- readCursor --> RowMapper ---> ResultSet -- next --> DB
       \                               <---- object ---            <---           <----------
        \
   close \                                          -----> Close ResultSet
          \                                        |
            -----> ItemStream ---> Close Cursor  --------> Close PreparedStatement
                                                   |
                                                    -----> Close Connection


### example
```
@Bean
fun customerItemReader() = JdbcCursorItemReaderBuilder<Customer>()
    .name("jdbcCursorItemReader")
    .fetchSize(10)
    .sql("""
        SELECT id, first_name, last_name, birth_date FROM customer
        WHERE first_name like ?
        ORDER BY last_name, first_name
    """.trimIndent())
    .beanRowMapper(Customer::class.java)
    .queryArguments("S%")
    .dataSource(dataSource)
    .build()
```

### in codes

1. builder.build

2. AbstractCursorItemReader.doOpen()
  - initilizeConnection() ## dataSource.getConnection()
 
3. JdbcCursorItemReader.openCursor(connection)
  - connection.preparedStatement
  - then apply settings
    = setFetchSize, MaxRows, QueryTimeout

4. preparedStatement.executeQuery()
  - getResultSet

5. AbstractItemCountingItemStreamItemReader.update(executionContext)
  - executionContext.putInt(getExecutionContextKey(READ_COUNT), currentItemCount) ## 현재 지점 update

6. AbstractCursorItemReader.doRead()
  ```
  if (!rs.next()) {
      return null
  }
  
  int currentRow = getCurrentItemCount()
  T item = readCursor(rs, currentRow)
    ```
    (JdbcCursorItemReader)
    return rowMapper.mapRow(rs, currentRow)
      = default (BeanPropertyRowMapper) ## 클래스만 지정해주면 자동 매핑
    ```
  verifyCursorPosition(currentRow)

Then, 반복 till it gets the whole size (chunkSize based)

7. doClose()
  - JdbcUtils.closeResultSet(this.rs)
  - cleanUpOnClose(connection)
  ...
  ## close 작업

