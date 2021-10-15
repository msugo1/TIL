### JdbcBatchItemWriter
  - JdbcCursorItemReader 설정과 마찬가지로 datasource, sql 쿼리 설정
  - JDBC의 Batch 기능을 사용하여, bulk insert/update/delete 방식으로 처리
  - 단건 처리가 아닌 일괄 처리이기 때문에, 성능에 이점을 가진다.

### API
1. name
2. dataSource
3. sql(String sql) ## ItemWriter가 사용할 쿼리문장 설정
4. assertUpdates(boolean) ## 트랜잭션 이후 적어도 하나의 항목이 행을 업데이트 혹은 삭제하지 않으면 예외발생 여부
5. beanMapped() ## Pojo 기반으로 InsertSQL Values를 매핑
6. columnMapped() ## Key, Value 기반으로 Insert SQL Values를 매핑
7. build

# Process

                                                Step
                                                  |
                                                  | write(List<Item)
                                                  |
                                                 \|/
                                           JdbcBatchItemWriter
                                                  |
                                                  |
                                                  |
               -------------- columnMapped() --- map? -------- beanMapped() -----
              |                                                                  | 
             \|/                                                                \|/
ColumnMapItemPreparedStatementSetter                            BeanPropertyItemSqlParameterSourceProvider
              |                                                                  | 
              |                                                                  | 
               --------------------------> JdecTemplate <------------------------
                                                |
                                                |
                                                | batchUpdate(sql)
                                                |
                                               \|/
                                            Database

### in code
1. JdbcBatchItemWriterBuilder.beanMapped()
  - this.mapped = this.mapped.setBit(1) ## columnMapped: 0

2. .build()

3. writer.setSql(this.sql)
  with other properties set
  = sqlParameterSourceProvider, preparedStatementSetter

4. mappedValue == 1 -> writer.setItemPreparedStatementSetter(ColumnMapItem ~)
   mappedValue == 2 -> writer.setItemSqlParameterSourceProvider(BeanPropertyItemSqlParameterSourceProvider)

5. JdbcBatchItemWriter.write(List<? extends T> items)
  ```
  ## parameter with names (ex. :name, :age)
  if (usingNamedParameters) {
      if (items.get(0) instanceof Map && this.itemSqlParameterSourceProvider == null) {
          updateCounts = namedParameterJdbcTemplate.batchUpdate(sql, items.toArray(new Map[items.size()]))
      } else {
          SqlParameterSource[] batchArgs = SqlParameterSource[items.size()]
          int i = 0
          for (T item : items) {
              batchArgs[i++] = itemSqlParameterSourceProvider.createSqlParameterSource(item)
          }
          updateCounts = namedParameterJdbcTemplate.batchUpdate(sql, batchArgs)
      }
  } else { ## parameter with ?
    updateCounts = namedParameterJdbcTemplate.getJdbcOperations().execute(sql, PreparedStatementCallback<int[]>()
        @Override
        public int[] doInPreparedStatement(PreparedStatement ps) throws SQLException, DataAccessException {
            for (T item : items) {
                itemPreparedStatementSetter.setValues(item, ps)
                ps.addBatch()
            }
            return ps.executeBatch() 
        }  
      

  }
