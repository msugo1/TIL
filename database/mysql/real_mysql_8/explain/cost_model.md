## 코스트 모델

### MySQL 서버의 쿼리 처리
1. 디스크 or 메모리(버퍼 풀)로부터 데이터 페이지 read
2. 인덱스 키 비교
3. 레코드 평가
4. 메모리 or 디스크 임시테이블 작업

### 코스트 모델?
- 전체 쿼리의 비용을 계산하는데 필요한 단위 작업들의 비용
- 5.7 전에는 이 비용들이 상수로 박혀있었음
    = 최적화의 걸림돌
- 5.7부터는 DBMS관리자가 조정할 수 있도록 개선
    = still, 비용계산과 관련된 부분 정보부족
- 8.0부터는 실행계획 수립에 직접적으로 사용되기 시작
    with 히스토그램, 각 인덱스 별 메모리에 적재된 페이지 비율 관리

**server_cost**
- 인덱스를 찾고, 레코드를 비교하고, 임시 테이블 처리에 대한 비용관리

**engine_cost**
- 레코드를 가진 데이터 페이지를 가져오는데 필요한 비용관리

```
EXPLAIN FORMAT=TREE
SELECT * FROM employees WHERE first_name='Matt'\G;

or

EXPLAIN FORMAT=JSON
SELECT * FROM employees WHERE first_name='Matt'\G;
```

- 코스트 모델에서 중요한 것?
    = 각 단위 작업에 설정되는 비용값이 커지면, 어떤 실행계획들이 고비용으로 바뀌고, 어떤 실행계획들이 저비용을로 바뀌는지 파악하기
    = trade-off

ex.
1) key_compare_cost
- 옵티마이저가 가능하면 정렬을 수행하지 않는 방향의 실행계획을 선택할 가능성 증가

2) row_evaluate_cost
- 풀 스캔을 실행하는 쿼리들의 비용증가
    = 인덱스 레인지 스캔을 사용하는 실행계획을 선택할 가능성 증가

3) disk_temptable_create_cost & disk_temptable_row_cost
- 디스크에 임시테이블을 만들지 않는 방향의 실행계획 선택 가능성 증가

4) memory_temptable_create_cost & memory_temptable_row_cost
- 메모리에 임시테이블을 만들지 않는 방향의 실행계획 선택 가능성 증가

5) io_block_read_Cost
- 가능하면 버퍼풀에 데이터 페이지가 많이 적재되어 있는 인덱스를 사용하는 실행계획 선택가능성 증가

6) memory_block_read_cost
- 버퍼풀에 적재된 데이터 페이지가 상대적으로 적다고 하더라도 그 인덱스를 사용할 가능성이 높아진다.

**주의**
- MySQL 서버가 사용하는 하드웨어에 대한 지식, 서버 내부적인 처리방식에 대한 깊이 있는 지식 없이는 함부로 바꾸지 말자



