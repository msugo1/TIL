# select_type column
1. SIMPLE
- no UNION nor SUBQUERY
- 일반적으로 제일 바깥 쪽 SELECT 쿼리의 select_type이 SIMPLE

2. PRIMARY
- UNION or SUBQUERY가 포함된 SELECT 쿼리의 실행 계획 중 가장 바깥쪽 쿼리

3. UNION
- UNION 결합하는 단위 SELECT 쿼리 중, 첫 번째를 제외한 두 번째 단위 이후 부터

4. DEPENDENT UNION
- 3과 같지만, UNION or UNION ALL로 결합된 단위쿼리가 외부에 영향을 받을 때

5. UNION RESULT
- UNION 결과를 담아두는 테이블
    = UNION or UNION ALL 모두 결과를 임시 테이블로 생성ㅅ
    = 요 임시 테이블을 가리킨다.

6. SUBQUERY
- FROM 절 이외의 서브쿼리 
(FROM절은 DERIVED)

7. DEPENDENT SUBQUERY
- 바깥쪽 SELECT 쿼리에서 정의된 칼럼을 사용하는 경우

8. DERIVED
- FROM절의 서브쿼리

9. UNCACHEABLE SUBQUERY
- 비상관 서브쿼리는 바깥쪽의 영향을 받지 않는다.
    = 처음 한 번 실행 후 캐시해서 사용
- 상관 쿼리는 바깥쪽 쿼리의 칼럼의 값 단위로 캐시해서 사용
    = row 별 캐시
- 캐시 자체가 불가능한 경우 UNCACHEABLE SUBQUERY
    = with 사용자 변수 in SUBQUERY, NON-DETERMINISTIC 속성의 스토어드 루틴, UUID() or RAND() 처럼 결과 값이 호출마다 달라지는 경우

10. UNCACHEABLE UNION


# type(기억 안나는 것만 다시 정리)
* index_merge
- 2개 이상의 인덱스를 이용해 각각 검색 결과를 만들어 낸다.
    -> 결과를 병합한다.
    
    1) 여러 인덱스를 읽어야 해서, range 접근 방식보다 효율성이 낮다.
    2) AND/OR 연산이 복잡하게 연결된 쿼리에서는 제대로 최적화되지 못할 때가 많다.
    3) 전문 검색 인덱스를 사용하는 쿼리에는 적용X
    4) 항상 2개 이상의 집합이 결과로 나온다. = 중복제거와 같은 부가작업 필요


# key
vs possible_key: 검색 시 사용 후보

- 실행 계획에서 사용하는 인덱스(최종 선택)
- key 칼럼에 의도한 인덱스가 들어있는지 확인!


# key_len
- 매우 중요한 정보중 하나
    why? 실무에서는 다중 칼럼으로 만들어진 인덱스가 사용되기 때문
- 다중 칼럼으로 구성된 인덱스에서, 몇 개의 컬럼을 사용했는가


# extra
- 이름과 달리, 쿼리의 실행계획에서 성능에 관련된 중요한 내용이 자주 표시되는 곳
* FULL SCAN ON NULL KEY
    = `col1 IN ( ... )` 에서, co1 == NULL이 될 가능성이 있는 경우
    = NULL이 있거나, 서브쿼리에 개별적으로 WHERE 조건이 지정되어 있으면 심각한 성능문제가 발생할 수 있다고 한다.

* Impossible WHERE/HAVING
    = WHERE/HAVING 절의 조건을 만족하는 레코드가 없는 경우

* NO matching min/max row
    = MIN, MAX 같은 집합함수가 있는 쿼리의 조건절에 일치하는 레코드가 단 한건도 없는 경우

* Range checked for each record(index map: N)
ex.
```
EXPLAIN
SELECT *
FROM employees e1, employees e2
WHERE e2.emp_no >= e1.emp_no
```
- e1 or e2 뭘 먼저 읽어야 좋을지 옵티마이저가 판단할 수 없다.
    why? 레코드를 읽을 때마다, emp.no의 값이 바뀌므로, 어느 것이 효율적인지 판단 불가...
- emp_no in 1 .. 10억
    = e1.emp_no == 1인 경우에는 10억 개 다 읽어야 한다.
    = emp_no가 증가할 수록, e2.emp_no를 위해 읽어야 할 row 수는 줄어든다.
    = e1.emp_no = 10억이면 e2.emp_no는 하나만 읽어도 된다.
- 즉, 첨엔 풀스캔으로 시작해서 갈수록 인덱스 레인지 스캔이 가능해진다.
    = 위 문구는 `매 레코드마다 인덱스 레인지 스캔을 체크`함을 의미
- type 칼럼에는 `ALL`로 표시됨에 주의
- index_map: 0x.. 
    = 요걸 이진수로 바꾼다.
    = 인덱스의 자리에 해당하는 값이 1인 인덱스를 사용후보로 둔다.
    = 어떤 인덱스가 사용되었는지는 알 수 없다.

* Select tables optimised away
- MIN(), MAX() only in SELECT or GROUP BY with MIN(), MAX() - but with no proper indices
    = 오름차순 혹은 내림차순으로 1건만 읽는 형태는 최적화 적용가능
    = select tables optimised away
    (where 절에 조건이 있으면, 이런 최적화 사용불가)

* `Using filesort`
- order by를 처리하기 위해 적절한 인덱스를 사용하지 못하는 경우,
    = MySQL서버가 조회된 레코드를 한 번 더 정렬해야 한다.
    1) 조회된 레코드를 정렬용 메모리 버퍼에 복사 (sort buffer)
    2) 퀵 소트 알고리즘 수행
- order by가 사용된 쿼리의 실행 계획에서만 나타날 수 있다.

* Using Index
- 인덱스 만으로 쿼리를 수행할 수 있을 때(ex. 인덱스에 해당하는 값만 검색, InnoDB의 인덱스는 인덱스 값 + 나머지 레코드 주소로 구성되어 있으므로) 
    = 인덱스 레인지 스캔을 사용하지만, 쿼리의 성능이 만족스럽지 못한 경우 인덱스에 있는 칼럼만 사용하도록 쿼리를 변경하면 성능향상!
참고: InnoDB의 모든 테이블은 클러스터링 인덱스로 구성되어 있음
    = InnoDB 테이블의 모든 보조 인덱스는 데이터 레코드의 주소 값으로 PK 값을 가짐(보조 인덱스 값 + PK)
    = 커버링 인덱스를 사용하게 해서 성능최적화를 이룰 수 있다.
    = 다만, 무리하게 인덱스를 여러개로 늘리지 말자
    (과도하게 인덱스 칼럼이 많아지면, 인덱스의 크기가 커져서 메모리 낭비가 심해지고, 레코드를 저장/변경하는 작업이 매우 느려질 수 있다.)

* loose index scan with group by
1. where 조건 절이 없는 경우
- group by와 조회하는 컬럼이 루스 인덱스 스캔을 사용할 수 있는 조건만 갖추면 된다.

2. where 조건절이 있지만, 검색을 위해 인덱스를 사용하지 못하는 경우
    = where은 인덱스 사용불가, but group by는 사용가능
- 먼저 group by를 위해 인덱스를 읽고 -> where 조건의 비교를 위해 레코드를 읽어야 한다.
    = 루스 인덱스 스캔 사용불가

3. where 절의 조건이 있으며, 검색을 위해 인덱스를 사용하는 경우
    = where and order by 모두 인덱스 사용가능
- where 절의 조건이 검색하는데 사용했던 인덱스를, group by 처리가 다시 사용할 수 있을때만!
    = 그렇더라도, 건수가 적으면 그냥 다 읽는게 처리속도가 빠를 수 있다. 이럴 때는 루스 인덱스 스캔X
    = 결국 옵티마이저의 재량
- where, order by가 각각 사용하는 인덱스가 다르다면 옵티마이저는 where에 우선순위 부여!
```
EXPLAIN
SELECT emp_no
FROM salaries WHERE emp_no BETWEEN 10001 AND 20000
GROUP BY emp_no;
```

# Using Join Buffer



# 성능 상 주의
1. 상관 서브쿼리
- 비상관 서브쿼리는 외부 쿼리보다 서브 쿼리가 먼저 처리된다.
    = 효율적

- But, 상관 서브쿼리는 외부 쿼리보다 먼저 실행될 수 없다.
    = 외부를 먼저 다 실행하고 나서 실행가능
    = 비효율적인 경우가 많다.

2. DERIVED SUBQUERY
- 결과를 메모리나 디스크에 임시 테이블로 생성
    = 파생 테이블엔 인덱스가 없어서, 다른 테이블과 조인할 때 성능상 불리할 때가 많다고 한다.
    = 조인으로 해결 가능하면 조인을 사용하자
(MySQL 6.0 이상부터는 최적화 개선되었다고 함)

3. table 컬럼의 <>
- 임시 테이블이 사용되었음을 의미한다.

4. 실행계획 type: index/ALL
* index
- 인덱스 풀 스캔을 의미
- range 처럼 필요한 부분의 인덱스만 읽는 것이 아님.

* ALL
- 어떠한 접근 방법으로도 처리할 수 없을 때 선택되는 가장 비효율적인 방법

* 쿼리 튜닝 != 무조건 인덱스 풀 스캔, 테이블 풀 스캔을 사용하지 못하도록 하는 것
    Why?
    = InnoDB는 대량의 I/O를 유발하는 위의 작업들에 대해, `Read Ahead` 제공
    (Read Ahead: 한 꺼번에 많은 페이지 읽어들이기, 최대 한 번에 64페이지 읽기)
    = 대용량 처리 쿼리에서 잘못 튜닝된 쿼리보다 성능이 좋을 수 있다.

5. 실행계획 extra: Using filesort
- 많은 부하를 일으킨다.
- 가능하다면 쿼리 튜닝 or 인덱스 생성


