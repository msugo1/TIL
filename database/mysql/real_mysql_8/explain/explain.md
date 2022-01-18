## 실행계획 확인
- 8.0부터는 EXTENDED, PARTITIONS 통합
- 포맷변경가능 (ex. JSON...)
- EXPLAIN ANAYLZE 추가
    = 실행계획 및 단계별 소요시간 정보포함
    = 실제 쿼리를 실행하고 사용된 실행계획과 소요된 시간 표시
    = 실행계획이 아주 나쁜 경우 EXPLAIN으로 튜닝 후 사용할 것!

## 실행계획 분석
(몰랐거나 까먹은 부분만 notes)

### Id
- 실행순서를 나타내지는 않는다.
    = 실행순서가 궁금하면 `EXPLAIN FORMAT=TREE` 등 depth를 확인하는 방법이 있다.

### Materialization
- 쿼리의 내용을 임시테이블로 생성
    = 서브 쿼리의 내용을 구체화 & Join

### partitions
- 파티션이 여러 개인 테이블에서 불필요한 파티션을 빼고 쿼리를 수행하기 위해 접근해야 할 것으로 판단되는 테이블만 골라내는 과정
    = 파티션 프루닝(Partition Pruning)
- partitions: 쿼리 처리를 위해 필요한 파티션들의 목록의 집합
- 파티션은 물리적으로 개별 테이블처럼 별도의 저장공간을 가진다.
    = partitions 값 존재 & type: ALL인 경우, 해당 파티션 공간을 풀 테이블 스캔한 것

### type(= Access Type)
**eq_ref**
- 여러 테이블이 조인되는 쿼리에서 등장
- 조인에서 처음 읽은 테이블의 칼럼 값을, 그 다음 읽어야 하는 테이블의 프라이머리 키 or 유니크 키 컬럼의 검색조건에 활용할 때
- 조인에서 두 번째 이후에 읽는 테이블에서 반드시 1건만 존재해야 한다.

**unique_subquery**
- 서브쿼리에서 중복되지 않는 `유니크`한 값만 반환

**index_subquery**
- 서브쿼리 결과의 중복된 값을 인덱스를 이용해서 제거할 수 있을 때

### key_len
- 다중 컬럼으로 이루어진 인덱스 중, 쿼리 처리 시 인덱스의 `몇 개 컬럼`까지 사용했는가
    = 몇 바이트까지 사용했는가?
- NULLABLE 컬럼의 경우 1바이트를 추가로 사용

### rows
- 예측했던 레코드 건수
    = 통계정보를 참조해 옵티마이저가 산출한 `예상`값 (정확X)
- 쿼리를 처리하기 위해 얼마나 많은 레코드를 읽고 체크해야 하는가

### filtered
- 필터링 되고 남은 레코드의 비율
- filtered 컬럼에 표시되는 값이 얼마나 정확히 예측될 수 있는지에 따라 `조인 성능` 결정

### Extra
- 중요한 정보들이 표시된다. (모르는 것만 notes)

**Distinct**
- 테이블 조회 후, 꼭 필요한 것만 조인
    = 불필요한 것은 무시!
- 이때 표시되는 것이 Distinct

**FirstMatch**
- 조인 최적화 전략 중 `FirstMatch` 사용
    = FirstMatch(기준 테이블)

**Full scan on NULL key**
- `col1 IN (SELECT col2 FROM ...)` 등의 조건을 가진 쿼리에서 자주발생
    = col1 IS NULL의 경우를 만나면 차선책으로 서브쿼리 테이블에 대해 `풀 테이블 스캔` 실시
- `col1 IS NOT NULL` 지정 시, 해당 조건은 사용되지 않음

**No matching rows after partition pruning**
- 파티션된 테이블에 대한 UPDATE or DELETE 명령의 실행계획에서 표시
    = 대상 파티션이 없을 때

**Not exists**
- 테이블 조인 시, 옵티마이저가 테이블의 레코드가 존재하는지 아닌지만 판단하는 것

**Plan is not ready yet** (feat. EXPLAIN FOR CONNECTION <id>)
- 해당 커넥션에서 아직 쿼리 실행계획을 수립하지 못했는데 `EXPLAIN FOR CONNECTION` 이 실행됨

**Range checked for each record(index map: N)**
- 각 row마다 읽어야 하는 조건 레코드의 수가 변할 때
    ex. id = 1일 때 1억 개, id = 1억일 때, 1개 ...
- 처음에 풀 테이블 스캔을 실행하고 점점 바꿔간다.
    = 레코드마다 인덱스 레인지 스캔여부 체크
- `index map: N`
    = 사용할지 말지를 판단하는 후보 인덱스의 순번
    = 이진수로 바꿔서 판단

ex.
```
CREATE TABLE tb_member(
    ...

    PRIMARY KEY (mem_id),
    INDEX ix_nick_name (mem_nickname, mem_name),
    INDEX ix_nick_region (mem_nickname, mem_region),
    INDEX ix_nick_gender (mem_nickname, mem_gender),
    INDEX ix_nick_phone (mem_nickname, mem_phone),
);

index map: 0x19
- 1 1 0 0 1 = ix_nickphone, ix_nick_gender, ix_nick_region, ix_nick_name, PK
- 각 자릿수가 1인 인덱스를 후보로 선정
```
- 실제 어떤 인덱스가 사용되었는지는 알 수 없음

**Recursive**
- CTE(Common Table Expression)을 이용한 재귀쿼리 지원 from 8.0
    = with 
    ```
    WITH RECURSIVE cte (n) AS
    (
        SELECT 1
        UNION ALL
        SELECT n + 1 FROM cte WHERE n < 5
    )
    SELECT * FROM cte;
    ```

**Rematerialize**
- LATERAL JOIN 시 조인되는 테이블은 선행 테이블의 레코드 별로 서브쿼리를 실행해서 그 결과를 임시 테이블에 저장
    = `Rematerializing`
- 레코드마다 새로 내부 임시 테이블 생성

**Start temporary, End temporary**
- Duplicate Weed-out 최적화 전략이 사용된 경우
    = 위 최적화 전략은 불필요한 중복건을 제거하기 위해 `내부 임시테이블`을 사용한다.
    = 조인되어 내부 임시 테이블에 저장되는 테이블을 식별할 수 있게, 조인의 첫 테이블에는 `Start temporary`, 끝나는 부분에는 `End Temporary`

**Using filesort**
- ORDER BY가 적절한 인덱스를 사용하지 못할 때
- 정렬을 위해 레코드를 읽어 Sort Buffer에 복사 -> 정렬 후 결과 반환
- 부하를 많이 일으키므로 가능한 쿼리튜닝!

**Using index condition**
- 옵티마이저가 `인덱스 컨디션 푸시다운 최적화`를 사용한 경우

**Using join buffer**
(with hash join, block nested loop, batched key access)
- 조인: 드리븐 테이블의 인덱스 여부가 성능을 크게 좌우
    = 드리븐 테이블 검색을 위한 적절한 인덱스가 없다?
    = 조인 버퍼!

**Using MRR**
(Multi Range Read)
- 스토리지 엔진 레벨에서는 쿼리 실행의 전체적인 부분을 알지 못한다.
    = it is MySQL 엔진 that 실행계획 수립
    = 따라서, 스토리지 엔진은 MySQL 엔진이 넘겨주는 키 값을 기준으로 레코드를 `한건 한건` 읽어야 한다.
    = 최적화의 한계점
    (매번 읽어서 반환하는 레코드가 동일 페이지에 있어도, 레코드 단위의 API 호출이 필요)
- MRR
    = 여러 개의 키 값을 한 번에 스토리지 엔진으로 전달
    = 스토리지 엔진은 넘겨 받은 키 값들을 정렬 -> 최소한의 페이지 접근으로 레코드를 읽도록 최적화

**Using sort_union(), Using union(), Using intersect()**
- index_merge 접근 방법인 경우 두 인덱스로 읽은 결과를 어떻게 병합했는지
    = using intersect: 각각의 인덱스를 사용할 수 있는 조건이 AND로 연결된 경우, 교집합 추출
    = using union: 각각의 인덱스를 사용할 수 있는 조건이 OR로 연결된 경우, 합집합 추출
    = using sort_union: like using union but 그거로는 처리 불가능한 경우(대량의 range 조건들) - PK읽어서 정렬, 병합 후 레코드 읽어서 반환

**Using Temporary**
extra에 표시는 안되도 실제로 내부에서 임시테이블을 만드는 경우

1. FROM절의 서브쿼리
2. COUNT(DISTINCT ~) 쿼리가 인덱스를 사용할 수 없을 때
3. UNION/UNION DISTINCT가 사용된 쿼리의 결과를 병합할 때
4. 인덱스를 사용하지 못하는 정렬작업은 임시 버퍼 공간을 필요로 한다.
- 정렬해야 할 레코드가 많아지면 결국 디스크를 사용한다.
- 정렬에 사용되는 버퍼의 실체도 사실은 임시테이블

`SHOW STATUS LIKE 'Created_tmp%'`
- 임시테이블 확인

**Using where**
- MySQL 엔진 레이어에서 별도의 가공을 통해 필터링을 처리한 경우
    = 체크조건 처리 시

**Zero Limit**
- 데이터 값이 아닌 쿼리 결괏값의 메타데이터만 필요한 경우
    ex. 쿼리의 결과가 몇 개의 컬럼을 가지는지, 각 컬럼의 타입은 무엇인지 ...
- 이런 경우 쿼리의 마지막에 LIMIT 0
    = 실제 테이블 읽는 것 없이 결과 값의 메타데이터만 반환
    = in Extra, Zero Limit


