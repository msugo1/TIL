## Internal Temporary Table
1. MySQL 엔진이 스토리지 엔진으로부터 받아온 레코드를 정렬 or 그루핑 할 때 사용
2. `CREATE TEMPORARY TABLE` 명령으로 생성한 테이블과는 다르다.
3. 메모리에 생성되었다가 테이블의 크기가 커지면 디스크로 이를 옮긴다. (처음부터 디스크에 생성되는 경우도 있다.)
4. 내부적인 처리가 종료되면 바로 삭제된다.
5. from 8.0 메모리 임시테이블: TempTable, 디스크 임시 테이블: InnoDB
(before, MEMORY, MyISAM)
- now, TempTable 가변길이 타입 지원(이전에는 가변길이 타입을 위해 최대 길이만큼 메모리를 할당해서 사용해야 했다.)
- 디스크에 만들어진 임시테이블에도 트랜잭션이! (or MMAP 파일로 디스크에 기록할 수도 있다고 한다.)
    = `temptable_use_nmap`: ON by default 
        why? InnoDB로 전환하는 것보다 오버헤드가 적다.
    = 곧바로 디스크에 임시테이블을 만드는 경우는 `internal_tmp_disk_storage_engine`에 지정된 스토리지 엔진으로 만든다.
    (default: InnoDB)

## 임시 테이블이 필요한 쿼리?
1. ORDER BY, GROUP BY에 명시된 컬럼이 다른 쿼리
2. ORDER BY or GROUP BY에 명시된 컬럼이 조인의 순서상 첫 번째 테이블이 아닌 쿼리
3. DISTINCT, ORDER BY가 동시에 존재할 때, DISTINCT가 인덱스로 처리되지 못하는 쿼리
4. UNION or UNION DISTINCT가 사용된 쿼리
5. DERIVED
6. 이외 엔딕스를 사용하지 못할 때 자주 임시테이블을 생성

## 임시 테이블이 디스크에 생성되는 경우?
1. UNION or UNION ALL에서 SELECT 되는 컬럼 중 길이가 `512바이트` 이상인 컬럼이 있는 경우
2. GROUP BY or DISTINCT 컬럼에서 길이가 `512바이트` 이상인 컬럼이 있는 경우
3. 메모리 임시테이블 크기가 `tmp_table_size` or `max_heap_table_size` 시스템 변수보다 클 때(or `temptable_max_ram` in TempTable)

## 임시 테이블 관련 상태변수
### Using Temporary
- but it doesn't display neither whether it's processed in memory or disk
    nor how many temp tables are exploited
- 메모리 or 디스크 생성여부 확인
```kotlin
FLUSH STATUS; // 세션상태 초기화

SELECT ~ FROM ~ GROUP BY ~; // 실제 쿼리 실행

SHOW SESSIONS STATUS LIKE 'Created_tmp%'; // 상태조회
```
1. `Created_tmp_tables`: 누적 임시테이블의 개수(메모리 or 디스크 구분X)
2. `Created_tmp_disk_tables`: 디스크에 만들어진  임시 테이블개수 누적

 







