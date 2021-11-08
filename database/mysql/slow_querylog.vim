row_examined, row_sent
  - row_examined: 쿼리가 처리되기 위해 몇 건의 레코드에 접근했는지
  - row_sent: 실제 몇 건의 처리 결과를 클라이언트에게 보냈는지

    = row_examined는 매우 많은데, row_sent가 적다면 튜닝 건수가 있다.
    (though, when they are not from GROUP BY, COUNT(), MIN(), MAX(), AVG() 등 집합함수가 아닌 쿼리)


