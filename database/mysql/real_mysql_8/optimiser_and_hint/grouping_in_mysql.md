* Group by -> Having
- Hainvg 절은 Group By 결과를 필터링
- Group By에 사용된 조건은 인덱스를 사용해 처리될 수 없다.
    = Having 절은 튜닝고민X

# Grouping

## GROUP BY

## Index 활용 가능(~ p. 308)
### 1. GROUP BY with tight index scan
(tight index scan)
- 인덱스를 모두 스캔해야 하지만, 이미 정렬된 인덱스를 읽는것
- 따라서, 쿼리 실행시점에 추가적인 정렬 or 내부 임시테이블 필요X

### 2. GROUP BY with loose index scan
- in Extra: `using index for group-by`
- 인덱스의 레코드를 건너 뛰면서 필요한 부분만 읽어서 가져오는 것
- 루즈 인덱스 스캔은 인덱스의 유니크한 값이 `적을수록` 성능향상
(일반 인덱스 레인지 스캔: 유니크한 값이 많을수록 성능향상)

## Index 활용 불가
- 필요한 경우 내부적으로 GROUP BY 컬럼들로 구성된 UK를 가진 임시테이블 생성
    = for 중복제거 & 집합함수 연산
    = ORDER BY가 함께 사용되면, 명시적으로 정렬작업도 수행
    (8.0 부터는 묵시적 정렬이 없으므로 ORDER BY NULL 사용 불필요)


## DISTINCT
- 특정 컬럼의 유니크 값 조회
- with 집합함수 vs without 집합함수
    ex. 집합함수 with Distinct but Distinct가 인덱스를 사용하지 못하는 경우 = 무조건 임시테이블 필요(but no using temporary printed on Extra)

### without 집합함수
- 조합 전체에 대한 유니크 SELECT (not just for one column)

### with 집합함수
- 집합 함수의 인자로 전달된 컬럼만 유니크하게 가져온다.


