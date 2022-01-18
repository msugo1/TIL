## Optimiser Switch Option 
(p. 318)

- 각 옵션은 default, on, off 중 하나 선택가능
- 글로벌/세션 모두 설정가능 or even 현재 쿼리 with `SET_VAR`

### MRR & batched_key_access
(Multi Ranged Read)

**Nested-loop join**
1. read one row from driving table
2. run join operations to the matching rows in driven tables

- 드라이빙 테이블 레코드 별로 드리븐 테이블의 레코드를 찾으면, 레코드를 찾고 읽는 스토리지 엔진에서 아무런 최적화를 수행할 수 없다.
    = 이러한 단점을 보완하기 위해 조인을 즉시 실행하지 않고 버퍼링
    (조인 버퍼에 레코드가 가득차면 MySQL엔진이 버퍼링 된 레코드를 스토리지 엔진으로 한 번에 요청)
    = 디스크의 데이터 페이지 읽기 최소화
        or even 버퍼풀 접근 최소화
    = MRR

- MRR을 응용해서 실행되는 조인방식
    = BKA
    = 부가적인 정렬작업이 필요해지면서 오히려 성능에 악영향을 미칠 수 있다.

### Block nested loop join
vs nested_loop_join
    = 조인버퍼 사용유무
    = 드라이빙/드리븐 테이블 조인순서


Optimiser는 성능향상을 위해 최대한 드리븐 테이블의 검색이 인덱스를 사용할 수 있게 실행계획을 수립.

However, 어떠한 방식으로라도 테이블/인덱스 풀 스캔을 피할 수 없다면?
1) 드라이빙 테이블에서 읽은 레코드를 메모리에 캐시
2) 드리븐 테이블과 이 메모리 캐시를 조인
- 이때 사용되는 메모리 캐시가 바로 `조인버퍼`

**NOTE**
- 조인버퍼를 사용하는 경우, 결과의 정렬 순서가 흐트러질 수 있다.
    = 드리븐 테이블을 먼저 읽고, 조인 버퍼에서 일치하는 레코드를 읽는 방식으로 처리하기 때문

### Index Condition Pushdown
**Using Where**
- 읽어온 레코드가 조건에 맞는지 검사하는 작업
- 성능에 영향을 미칠 수 있다.
    = ex. 읽어온 레코드가 10만건인데 일치하는 건은 1건이라면?

up to 5.5, 인덱스를 범위 제한조건으로 사용하지 못하는 경우, MySQL 엔진이 스토리지 엔진으로 전달X
    = 인덱스에 조건에 사용한 컬럼이 있었어도 테이블 레코드를 다시 읽어야 했다.

However, from 5.6, 인덱스를 범위 제한조건으로 사용하지 못하더라도, 인덱스에 포함된 컬럼의 조건이 있다면 모두 같이 모아서 스토리지 엔진으로 전달하게 개선
- 인덱스를 이용한 필터링이 가능해졌다. (테이블의 레코드를 읽을 필요가 없다.)
- **Using Index Condition**
- 쿼리의 성능을 대폭 향상시킬 수 있는 중요한 기능!

### Index Extensions (인덱스 확장)
: `use_index_extensions`

- secondary index에 자동으로 추가된 PK를 활용할 수 있도록 설정?
    = 옵티마이저가 클러스터링 된 PK의 존재를 인식하고, 이를 활용해 실행계획 수립
- 숨은 PK를 활용해 정렬 작업등도 filesort 없이 수행가능

## Index Merge
- 하나의 테이블에 대해 2개 이상의 인덱스를 이용해 쿼리 처리
- 쿼리에 사용된 각각의 조건이 서로 다른 인덱스를 사용할 수 있고, 그 조건을 만족하는 레코드가 많을 것으로 예상될 때 MySQL 서버가 이 실행계획 선택
- 각각의 결과를 어떤 방식으로 병합할지에 따라서 세 개의 세부 실행계획으로 분류

### 교집합(index_merge_intersection)
`Using Intersect`
- 여러 개의 인덱스를 각각 검색해서 그 결과의 `교집합`만 반환

### 합집합(index_merge_union)
`Using Union`
- WHERE 절의 2개 이상의 조건이 각각 인덱스 사용
    + OR 연산자로 연결
    = 인덱스 간의 합집합을 가져온다.

ex. first_name = 'Matt', hire_date='1987-03-31'
- ix_firsname, ix_hiredate에 위의 조건을 가진 row가 포함
    = 중복
- 내부적으로 MySQL이 중복제거
    HOW?
    = 각각의 결과가 PK로 이미 정렬되어 있음
    = PK가 중복된 건들을 정렬 없이 걸러낼 수 있다.
    = Priority Queue 사용

**NOTE**
- `OR` 연산의 경우, 하나라도 인덱스를 타지 못하면 테이블 풀스캔으로 처리할 수밖에 없다.

### 정렬 후 합집합(index_merge_sort_union)
`Using sort_union`
- 인덱스 머지 중 결과 정렬이 필요한 경우
- `Sort Union` 알고리즘을 사용
    = 결과 정렬 후 중복제거

### 세미 조인(semijoin)
- 다른 테이블과 실제 조인을 수행하지는 않고, 단지 다른 테이블에서 조건에 일치하는 레코드가 있는지 없는지만 체크

**`= subquery` and `in subquery` 최적화**
1) 세미 조인 최적화
- `Table Pull-out`, `Duplicate Weed-out`, `First Match`, `Loose Scan`, `Materialization`

Table Pull-out
- `Table Pull-out` 최적화 전략은 항상 세미조인보다 좋은 성능을 낸다.
    = 옵티마이저에서 별도로 제어 옵션을 제공하지 않는다.
    = 서브쿼리에 사용된 테이블을 아우터 쿼리로 끄집어 낸 후, 쿼리를 조인 쿼리로 재작성
    (서브쿼리 최적화 도입 전 수동으로 튜닝하던 방법)
    = 실행계획 출력 시 id가 1
    = 모든 형태의 서브쿼리에 사용될 수 있지는 않다.

    **LIMIT**
    ```
    (1) 세미조인 서브쿼리에서만 사용가능
    (2) 서브쿼리 부분이 유니크 인덱스나, PK lookup으로 결과가 1건인 경우에만
    (3) 서브쿼리의 모든 테이블이 아우터 쿼리로 나올 수 있는 경우, 서브쿼리 자체가 없어진다.
    ```
- 8.0부터는 위의 과정을 알아서 해주므로, 수동 튜닝이 필요없다.

First Match
- `IN`형태의 세미조인을 `EXISTS` 형태로 튜닝한 것과 유사
- 일치하는 레코드 1건만 찾으면 더 이상 해당 테이블에서 검색X(= Short-cut path)
    = 조인으로 풀어서 실행하면서 일치하는 첫 번째 레코드만 검색
    = 서브쿼리가 참조하는 모든 아우터 테이블이 먼저 조회된 이후, 서브 쿼리가 실행
- `FirstMatch(table-N)`
- 상관 서브 쿼리에서도 사용할 수 있다.
- 여러 테이블이 조인되는 경우, 원래 쿼리에 없던 동등 조건을 옵티마이저가 추가할 수 있다.
    = 조인형태로 처리되므로, 서브쿼리 뿐 아니라 아우터 쿼리의 테이블에도 `동등조건 전파`가 이루어질 수 있다.
    = 더 많은 조건이 주어지므로, 더 나은 실행계획을 수립할 수 있게된다.
- `IN-to-EXISTS`전략과는 다르게, 서브 쿼리의 모든 테이블에 대해 FirstMatch를 수행할 지, 일부에만 수행할지를 결정할 수 있다.
    
    **LIMIT**
    ```
    (1) GROUP BY or 집합 함수가 사용된 서브쿼리에는 사용불가
    (2) optimizer_switch 변수 중, semijoin, firstmatch 옵션이 모두 ON이어야 한다.
    ```

Loose Scan
- 루스 인덱스 스캔과 비슷한 읽기 방식 차용
    = 그루핑 해서 유니크한 값들만 읽어 효율적으로 서브쿼리 실행!
    = 내부적으로는 조인처럼 처리
- `LooseScan`
- 루스 인덱스 스캔으로 서브쿼리 테이블 읽기 -> 아우터 테이블을 드리븐으로 사용해서 조인 수행
    = 서브 쿼리 부분이 루스 인덱스 스캔을 사용할 조건을 갖추고 있어야 한다.

Materialization (구체화)
- 세미 조인에 사용된 서브쿼리를 통째로 구체화해서 최적화
- 구체화 == 내부 임시테이블 생성
- 서브쿼리 내에 GROUP BY절 or 집합함수가 있어도 최적화가능

    (LIMIT)
    ```
    (1) IN subquery 형태의 경우는 비상관 쿼리만 가능
    ```

Duplicated Weed-out(중복제거)
- 원본 쿼리를 `INNER JOIN + GROUP BY` 절로 변경하는 것과 동일한 처리를 한다.
    = 조인 실행 -> 결과 임시테이블에 저장 -> 중복제거 -> 남은 레코드 반환
- `Start temporary`, `End temporary`
- 서브쿼리가 상관쿼리여도 사용할 수 있다.
- 서브쿼리의 테이블을 조인으로 처리하므로, 최적화 할 수 있는 여지가 많다.

    (LIMIT)
    ```
    (1) 서브쿼리가 GROUP BY or 집합함수와 함께 사용된 경우, 불가
    ```

Condition_fanout_filter (컨디션 팬아웃)
- `filtered` 값을 예측한다. 
    = 더 정확한 예측으로 더 빠른 실행계획을 만들 수 있게 도와준다.
- WHERE 조건 절에 사용된 컬럼에 인덱스가 있다면 or 히스토그램이 존재한다면, 조건을 만족하는 레코드 비율을 찾을 수 있다.
- 정확하지만 그 만큼 더 많은 자원 사용
    = 오버헤드가 발생할 수 있으니, 미리 성능비교!

```
NOTE

옵티마이저가 실행계획을 수립할 때, 다음 순서대로 사용가능한 방식을 선택
(not just 테이블 or 인덱스의 통계정보)

(1) 레인지 옵티마이저(Range Optimiser)를 이용한 예측
    - 가장 높은 우선순위
    - 실제 인덱스의 데이터를 살펴보고, 레코드 건수 예측
    (= 실제 쿼리 실행 전 빠르게 소량의 데이터 읽어보기)
    - 인덱스를 이용해서 쿼리가 실행될 때
(2) 히스토그램을 이용한 예측
(3) 인덱스 통계를 이용한 예측
(4) 추측에 기반한 예측
```

2) IN-to-EXISTS 최적화
3) MATERIALIZATION 최적화

**`<> subquery` and `not in subquery` 최적화** (anti-semi join)
1) IN-to-EXISTS 최적화
2) MATERIALIZATION 최적화

### 파생 테이블 머지
up to 5.7
- FROM 절에 사용된 서브쿼리: 먼저 실행해서 결과를 임시테이블로 만든다. -> 이후 외부 쿼리부분 처리
    = derived table
    = 해당 값을 읽어서 임시 테이블 생성 -> 데이터 INSERT -> 다시 필요한 레코드만 필터링
    (레코드가 많아지면 디스크로 간다... less and less performance)

since 8.0
- 파생 테이블로 만들어지는 서브쿼리를 외부 쿼리와 병합해서 서브쿼리를 제거하자
    = `derived_merge`

    (LIMIT): 옵티마이저가 자동최적화 X인 경우 == 수동 최적화 필요
     ```
     (1) SUM(), MIN(), MAX() 같은 집계 함수와 윈도우 함수가 사용된 서브쿼리
     (2) DISTINCT가 사용된 서브쿼리
     (3) GROUP BY or HAVING이 사용된 서브쿼리
     (4) LIMIT이 사용된 서브쿼리
     (5) UNION or UNION ALL을 포함한 서브쿼리
     (6) SELECT 절에 사용된 서브쿼리
     (7) 값이 변경되는 사용자 변수가 사용된 서브쿼리
     ```

### 인비저블 인덱스(use_invisible_index)
- MySQL8.0 부터는 인덱스 가용상태 제어가능(인덱스가 있어도 삭제하지 않고 사용하지 못하게 설정)
- `ALTER TABLE .. ALTER INDEX .. [ VISIBLE | INVISIBLE ]`
ex.
```
SET optimizer_switch = 'use_invisible_indexes = on'; (default: off) - on이어야 invisible 상태 파악가능

ALTER TABLE employees ALTER INDEX ix_hiredate INVISIBLE;
ALTER TABLE employees ALTER INDEX ix_hiredate VISIBLE;
```

### 스킵 스캔(skip_scan)
- 선행 컬럼 없이 후행컬럼만으로도 인덱스 활용가능하도록 변경
    = A, B가 있고 B만 조건으로 주어졌을 때, 둘 다 사용하는 것처럼 컬럼을 들고와 최적화
- 인덱스의 선행 컬럼이 매우 다양하다면 비효율적
    = 선행컬럼이 소수의 유니크한 값을 가질 때만 인덱스 스킵 스캔 최적화 사용

### 해시 조인
- 첫 번째 레코드를 찾는 데 시간이 많이 걸린다. (compared to 네스티드 루프 조인)
- but, 마지막 레코드는 더 빨리 찾는다.

해시조인: Best Throughput
네스티드 루프 조인: Best Response-time

- 빌드 단계: 레코드가 적은 건을 골라서 메모리에 해시테이블 생성(건 수가 더 적은 테이블)
    = 빌드 테이블
- 프로브 단계: 나머지 테이블의 레코드를 읽어서 해시 테이블의 일치 레코드를 찾는다.
    = 프로브 테이블
- 기본적으로는 조인 버퍼를 사용해 메모리에 해시 테이블을 저장
    = but, 버퍼 사이즈를 능가하면 디스크에 청크로 나눠서 저장한다.
    = 빌드/프로프 테이블이 각각 나뉘어 저장된다.


### prefer_ordering_index
- 옵티마이저가 order by를 위한 인덱스에 너무 가중치를 부여하지 않도록 OFF로 설정가능


## 조인 최적화 알고리즘

### 1. Exhaustive 검색 알고리즘
- FROM 절에 명시된 모든 테이블의 조합에 대해 실행계획 비용 계산 -> 최적의 조합 1개를 찾는다.
- 테이블이 늘어날 수록 경우의 수도 n! 비례
    = 매우 느림

### 2. Greedy 검색 알고리즘
- Exhaustive 알고리즘의 시간 소요를 해결하기 위함(since 5.0)
- `optimizer_search_depth` 변수에 정의된 개수의 테이블로, 가능한 조합 생성
    -> 최소비용의 실행계획 선정
    -> 해당 파트를 부분 실행계획의 첫 테이블로 선정
    -> 다시 정의된 개 테이블로 가능한 조인조합 생성
    -> 생성된 조인조합들을 하나씩 부분실행계획에 대입해 비용계산
    -> 다시 최소 비용으로 두번째 파트 산정
    (반복)
    = 각 파트에 대해 최소 비용의 것들만 선정
    
**optimizer_search_depth**
- Greedy vs Exhaustive 중 선택
- 0 ~ 62 사이의 값을 선택할 수 있다.
    = 1 ~ 62 사이의 값이 설정되면, Greedy 검색 대상을 지정된 개수로 한정
    = 0이면 옵티마이저가 자동선택
    (optimiszer_search_depth < 조인 테이블 개수인 경우, depth만큼은 exhaustive and then greedy) 
    (기본값은 62임에 주의)

**optimizer_prune_level**
- 휴리스틱 검색 작동제어
- 1: on or 0: off
- 현재 계산 중인 경로의 조인 비용이 이전보다 크면 바로 검색 포기

MySQL 8.0 조인 최적화는 많이 개선되었음
- `optimizer_search_depth` 변수의 값에는 크게 영향받지 않는다.
- `optimizer_prune_level`을 0으로 설정 시, depth 변화에 따라 실행계획 수립시간이 가파르게 증가!

## Query Hint
- MySQL 버전 업그레이드 및 통계정보/옵티마이저 최적화의 다양화로 쿼리 실행계획 최적화가 성숙해짐
- But, 여전히 MySQL이 100% 우리의 서비스를 이해하지 못함
- 실행계획을 어떻게 수립할 지 알려줄 필요가 있다.

### 1. 인덱스 힌트
ex. `STRAIGHT_JOIN`, `USE INDEX`
- MySQL 서버에 옵티마이저 힌트가 도입되기 전에 사용되던 기능
    = ANSI-SQL 표준X
    = 가능하면 옵티마이저 힌트 추천
- SELECT, UPDATE 명령에만 사용가능

**STRAIGHT_JOIN**
- 옵티마이저 힌트인 동시에, 조인 키워드
- 여러 테이블 조인 시 (in SELECT, UPDATE, DELETE) 조인순서 고정
    = 기본적으로 옵티마이저는 드라이빙, 드리븐 테이블을 그때 그때 통계정보 및 쿼리 조건을 기반으로 판단

ex.
```
SELECT /*! STRAIGHT_JOIN */
    e.first_name, e.last_name, d.dept_name
FROM employees e, dept_emp de, departments d
WHERE e.emp_no = de.emp_no
    AND d.dept_no = de.dept_no;
```

다음 기준에 맞게, 조인 순서가 결정되지 않는 경우 `STRAIGHT_JOIN`으로 순서 조정
1) 임시 테이블 JOIN 일반 테이블
- 거의 일반적으로 임시 테이블을 드라이빙 테이블로 선정
- 옵티마이저가 실행계획을 제대로 수립하지 못해서 심각한 성능 저하가 있는 경우에만 힌트를 쓰자

2) 임시 테이블끼리 JOIN
- 임시 테이블 들은 항상 인덱스가 없으므로, 어느 테이블을 먼저 읽어도 무관
    = 크기가 작은 테이블을 드라이빙 테이블로!

3) 일반 테이블끼리 JOIN
- 조인 컬럼에 인덱스가 없는 테이블을 드라이빙 테이블로
- 둘다 있으면 레코드 건수가 적은 테이블을 드라이빙 테이블로

NOTE)
레코드 건수의 의미는, WHERE 조건까지 포함해서 검색된 레코드의 갯수!

비슷한 힌트
- JOIN_FIXED_ORDER(= STRAIGHT_JOIN)
- JOIN_ORDER, JOIN_PREFIX, JOIN_SUFFIX
    = 일부 테이블의 조인순서에 대해서만 제안


**USE INDEX / FORCE INDEX / IGNORE INDEX**
- 조인의 순서를 변경하는 것 다음으로 자주 사용
- 사용하려는 인덱스를 가지는 테이블 뒤에 힌트를 명시
- 3~4개 이상의 컬럼을 포함한 비슷한 인덱스가 여러 개 있을 때, 가끔 옵티마이저가 실수를 한다.
    = 이때 강제로 특정 인덱스를 사용하도록 조정!

1) USE INDEX
- 특정 테이블의 인덱스를 사용하도록 권장
- 항상 이것을 사용하는 것은 아니다.

2) FORCE INDEX
- USE INDEX보다 강한영향
- USE INDEX로 지정한 인덱스를 사용하지 않는 경우, FORCE INDEX로도 사용X

3) IGNORE INDEX
- 특정 인덱스를 사용하지 못하게 하는 용도
- 때로는 풀 테이블 스캔을 유도하기 위해서 사용

용도도 선택이 가능(~ INDEX FOR JOIN, ORDER BY, GROUP BY)
    but, 옵티마이저가 대부분 용도는 최적으로 선택해주기 때문에 여기까지 고려할 필요는 없다.

ex.
```
SELECT * FROM employees FORCE INDEX(primary) ...
SELECT * FROM employees USE INDEX(ix_firstname) ...
```

주의
- 인덱스 사용법 or 좋은 실행계획을 판단할 수 없는 경우는, 힌트를 사용해서 강제로 실행계획을 조정해서는 안된다.
    = 오늘 최적은 내일의 최적이 아닐 수 있다.
    = 옵티마이저가 결정하도록 하는 것이 최고
- 가장 좋은 최적화
    = 문제가 되는 쿼리를 서비스에서 없앤다.
    or 튜닝할 필요가 없게 데이터를 최소화 시킨다.
    or 데이터 모델의 단순화를 통해 쿼리를 간결하게 만들고, 힌트를 필요없게
    = but 실무에서는 시간이 없으므로, 힌트에 의존하는 경우가 많다.

**SQL_CALC_FOUND_ROWS**
- 이 힌트를 포함한 쿼리는 LIMIT 수에 만족하는 쿼리를 찾았어도 계속 검색 수행
    = 반환은 여전히 제한된 수만큼
ex.
```
SELECT SQL_CALC_FOUND_ROWS * FROM employees LIMIT 5;

SELECT FOUND_ROWS() AS total_record_count; // 위 힌트로 몇 건을 검색했는지
```
- 성능향상을 위해 만들어진 힌트가 아니라, 개발자의 편의를 위해 만들어진 힌트
    = 사용X

### 2. 옵티마이저 힌트(p. 379)
영향 범위에 따라 다음 4개 그룹으로 나누어 볼 수 있다.

1. 인덱스
- 특정 인덱스의 이름을 사용할 수 있는 힌트

2. 테이블
- 특정 테이블의 이름을 사용할 수 있는 힌트
 
3. 쿼리 블록
- 특정 쿼리 블록에 사용할 수 있는 힌트
- 힌트가 명시된 쿼리 블록에 대해서만 영향

4. 글로벌
- 전체 쿼리에 대해서 영향을 미치는 힌트

**SET_VAR**
- 서버의 시스템 변수들 또한 쿼리의 실행계획에 상당한 영향을 미친다.
    ex. 조인버퍼의 크기에 따라 버퍼 사용여부 결정

```
EXPLAIN
SELECT /*+ SET_VAR(optimizer_switch='index_merge_intersection=off') */ *
FROM employees
...
```
- 실행계획 변동 외에도 값을 일시적으로 변경해서 대용량 쿼리 처리 성능 등의 향상을 도모할 수 있다.
    = 모든 시스템 변수는 아니지만, 다양한 시스템 변수 조정에 사용할 수 있다.





 





