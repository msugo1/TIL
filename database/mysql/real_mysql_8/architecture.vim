# Architecture
Application -> MySQL Engine -> Storage Engine - Handler via Handler API)
    = MySQL이 읽기/쓰기를 스토리지 엔진에게 명령하려면 핸들러를 통해야 한다.

# MySQL Engine
: consists of SQL Interface, Parser, Optimiser, and Cache & Buffer
- DBMS의 두뇌역할
- 읽기, 쓰기를 제외한 대부분의 작업이 MySQL Engine에 의해 처리
    = ex. 데이터를 읽어온 후, group by or order by 작업은 쿼리 실행기에서 처리 in MySQL Engine


# Storage Engine
- 실제 데이터 저장/읽기 등

# Handler API
- 스토리지 엔진이 보내는 요청 = 핸들러 요청
- 이때 사용되는 API = 핸들러 API

# MySQL 스레딩 구조
= Foreground + Background Thread
```
확인

SELECT thread_id, name, type, processlist_user, processlist_host
FROM performance_schema.threads ORDER BY type, thread_id;
```
- 동일한 이름의 스레드가 2개 이상? 여러 스레드가 동일 작업을 병렬로 처리하는 경우 
    = it depends on the server's configuration

* Foreground Thread
- MySQL 서버에 접속한 클라이언트 수만큼 생성
- 커넥션 종료 시, 스레드는 캐시로 돌아간다. (일정 개수 이상이 이미 캐시에 있으면 종료!)
    = `thread_cache_size`
- 데이터를 MySQL 데이터 버퍼나, 캐시로 가져온다.
- 버퍼, 캐시에 없을 경우 직접 디스크의 데이터나 인덱스 파일로부터 데이터를 읽어와서 작업을 처리한다.
    = InnoDB는 데이터 버퍼/캐시 작업까지만 Foreground가 담당한다.

* Background Thread
(heart of InnoDB)
- 여러 작업이 백그라운드 스레드에 의해 수행된다.
    ex. Insert Buffer 병합 스레드, 로그를 디스크로 기록하는 스레드, 버퍼 풀의 데이터를 디스크에 기록하는 스레드, 데이터를 버퍼로 읽어오는 스레드, 잠금이나 데드락을 모니터링 하는 스레드 ...

    읽기 스레드 개수 지정: `innodb_read_io_threads`
    쓰기 스레드 개수 지정: `innodb_write_io_threads`
        = 읽는 작업은 클라이언트 스레드에서 처리되어, 많이 설정할 필요X
        = but, 쓰기 스레드는 아주 많은 작업을 백그라운드로 처리하므로, 충분히 설정이 필요하다.


# 메모리 영역
1. 글로벌 메모리 영역
- assigned by OS
    = 시스템 변수로 설정해둔 만큼 할당(한번에 or 나눠서, which is up to OS)
- 클라이언트 수와 무관하게 하나만 존
    = 모든 스레드에 의해 공유

    "테이블 캐시, InnoDB 버퍼 풀, InnoDB 어뎁티브 해시 인덱스, InnoDB 리두로그 버퍼"

2. 로컬(세션) 메모리 영역
- 클라이언트 스레드가 쿼리를 처리하는데 사용
- 공유 X, as many as clients currently active in the server
- 로컬 메모리 영역의 적절한 크기 설정도 중요하다(or 서버 Crash)
- 필요할 때만 공간 할당(필요하지 않으면 할당X)
    = ex. sort buffer, join buffer ...
- 커넥션이 열려 있는 동안 계속 할당: Connecion or Result Buffer
    vs 쿼리를 실행하는 순간에만 할당: Sort or Join Buffer

    "Sort Buffer, Join Buffer, Binary log cache, Network Buffer


# 쿼리 실행구조
    Query Parser --> Pre-Processor --> Optimiser --> 실행 엔진 --> Handler

* Query cache has been invalidated in 8.0!
    = due to 성능 저하 and 버그 (ex. 테이블의 데이터가 변경되면, 캐시에서 해당 테이블과 관련된 부분 모두 삭제필요 -> 성능저하)


# 스레드 풀 p. 93


# InnoDB Architecture
- 레코드 기반의 잠금을 제공하는 스토리지 엔진


* features
1. PK에 의한 클러스터링
- PK 순서대로 디스크에 저장
- 모든 Secondary 인덱스는 PK 값을 논리적인 주소로 활용(레코드 주소 대신에)
    ex. when a secondary index is name

        name    PK              실제 record
        soo     1   ---------->     1(PK), 나머지 데이터 ....

    = therefore, range scan with PK boosts the performance


# MVCC
: with undo log for consistent read without locks
    = 하나의 레코드, 여러 개의 버전
    = 필요에 따라 보여지는 데이터가 달라진다. and what determines this is isolation level

- 읽어올 때, 자신의 버전보다 낮은 버전을 가진 트랜잭션의 데이터만 읽어올 수 있다.
- 변경 전 데이터는 undo log에 기록되며 필요한 경우 여기 데이터를 가져다 보여준다.
    = 트랜잭션이 길어지면 undo 영역이 저장되는 시스템 테이블 스페이스 공간 증가 -> 문제가 생길 수 있다.
    = 필요로 하는 트랜잭션이 모두 없어져야 undo 영역의 데이터가 삭제될 수 있다.
    = 롤백 시 언두 영역의 데이터를 가져다 복구한다. (언두 영역의 데이터 -> InnoDB 버퍼 풀)

- MVCC 덕에 잠금 없는 일관적인 읽기가능


# deadlock detection
- 기본적으로 데드락 감지 스레드가 있고, 정해진 시간마다 데드락 감지
- 트래픽이 많아질 경우, 데드락 감지 하느라 성능저하 가능성
    = 이제 on, off가 가능한데 trade-off: 성능을 챙기는 대신, 데드락이 생기면 요거를 해제해 줄 스레드가 없으므로... 무한정 대기
    

# InnoDB 버퍼풀
- 디스크의 데이터 파일이나, 인덱스 정보를 메모리에 캐시해두는 공간
    + 쓰기작업 지연 & 일괄처리용 버퍼 = 랜덤한 IO 줄이기

(캐시 & 버퍼 역할 모두 수행)

- since 5.7, 동적으로 크기조절 가능(사용량 보면서 판단)
    ex. 약 50%정도를 InnoDB 버퍼 풀을 위해, 그리고 나머지 메모리 공간은 MySQL 서버, 운영체제, 다른 프로그램을 위해 두고 써가면서 조절

    * 주의
    : 버퍼풀의 크기를 변경하는 작업은 크리티컬하다.
        = 서버가 한가한 시점을 골라 작업
        = 특히, 버퍼풀의 크기를 줄이는 작업은 영향도가 크므로 시전X

- 이제 버퍼풀을 여러개의 인스턴스로 나눠서 관리가 가능하다. (잠금 경합 유발을 줄이기 위해)

# 버퍼 풀 구조
- 버퍼 풀 = 거대한 메모리 공간
- 이거를 페이지 크기에 맞게 조각조각
- 스토리지 엔진이 데이터를 필요로 할 때, 해당 페이지를 읽어서 각 조각에 저장

* 버퍼 풀의 조각관리
- LRU(with MRU) + Flush + Free List로 구성
    = Least Recently Used, Most ... 
    = 한 번 읽어온 데이터를 최대한 오랫동안 버퍼 풀에 유지하기 위함 -> 디스크 읽기 최소화

    # LRU list
    1) 필요한 레코드가 저장된 데이터 페이지가 버퍼풀에 있는지 검사
    - search for the page with InnoDB adaptive hash index
    - search for the page with B-tree index of the target table
    - 버퍼 풀에 이미 데이터 페이지가 있었다면?
        해당 페이지 포인터를 MRU 방향으로!
        (데이터가 실제로 사용되지 않으면 이동X)
    - 없었다면?
        디스크에서 필요한 데이터를 버퍼풀에 적재 and then 적재된 페이지에 대한 포인터는 LRU 헤더 부분에

    2) managed by `Age`
    - 버퍼풀에 있는 데이터가 오랫동안 사용되지 않으면 Aging, and 결국 제거
        = 사용될 때마다 age 초기화, and moved to the header or MRU

    3) 필요한 데이터가 자주 접근되면 해당 페이지의 인덱스 키를 adaptive hash 인덱스에 추가

    # Flush list
        = dirty page
    - 디스크로 동기화 전인 데이터를 가진 데이터 페이지
        = 변경시점 기준
    - 데이터가 변경되면, redo log + buffer pool's data page 변경내용 반영
        = 어디가 먼저 기록될지 순서는 보장X
        = 체크포인트를 발생 시켜 결국 동기화 시키긴 한다.
        (어디가 앞선 상태를 반영하는지에 따라 복구시점이 달라질 수 있음)

* Buffer Pool & Redo log
- 버퍼 풀은 캐시 + 쓰기 버퍼 기능을 동시에 수행
    = 일정 사이즈까지는 커질 수록 성능증가! But, 얘만 늘리면 캐시기능만 향상시킴
    = 쓰기 버퍼는?
- for 쓰기 버퍼, clean page + dirty page
    = dirty page: INSERT, UPDATE, DELETE 등으로 변경이 되었지만 아직 반영되지 않은 상태.
    (버퍼 풀에 있지만, 무한정 거기에 있을 수는 없다.)

redo log
    = InnoDB에서 redo log는 1개 이상의 고정크기 파일을 연결, 순환 고리처럼 사용한다.
    (기존 엔트리가 새로운 엔트리로 덮어 씌워지는 형태)
    = 재사용 가능한 공간 + 재사용 불가능한 공간
        Active Redo log: 재사용 불가능한 공간
    = 공간은 순환되어 사용되지만, 매번 기록될 때마다 로그 포지션은 계속 `증가`
        : LSN(Log Sequence Number)
    = 체크 포인트 이벤트 발생 시, 리두 로그 & 버퍼 풀의 더티페이지를 디스크로 동기화
        이때, 이전 체크포인트 중 가장 최근의 것이 Active Redo log 시작점 (변경 반영 시작점)
        : 변경 반영 시점의 마지막 리두로그 엔트리 LSN - 가장 최근 체크포인트 LSN = `Checkpoint Age` = 활성 리두로그 공간의 크기
    (체크포인트 LSN보다 작은 LSN을 가진 엔트리들은 모두 디스크에 동기화 되어 있어야 한다.)

* 리두로그는 변경분만, 버퍼 풀은 데이터를 통째로 가진다.
    = 데이터 변경이 발생해도, 리두 로그는 훨씬 작은 공간을 필요로 한다.


# Buffer pool flush = Flush list + LRU list flush
1. 플러시 리스트 플러시
- 리두 로그 공간 재사용을 위해, 주기적으로 오래된 리두로그 엔트리가 사용하는 공간을 비워야 한다.
    = 오래된 리두 로그 공간이 지워지려면 반드시 InnoDB 버퍼 풀 더티페이지가 먼저 디스크로 동기화 되어야 한다.

cleaner thread: 더티페이지를 디스크로 동기화(managed by innodb_page_cleaners)
    = InnoDB 버퍼 풀은 여러 개의 인스턴스를 가질 수 있다.
    = `innodb_buffer_pool_instances` > `innodb_page_cleaners`
        : 클리너 스레드의 많은 부담 (여러 개의 인스턴스  플러시를 담당해야 하므로)
        : 동일한 값으로 설정해주는 것이 필요!

NOTE) 관련 시스템 변수 (p. 132)
1. innodb_max_dirty_pages_pct
- 더티 페이지 비율 조정 변수(default: 전체 크기의 90%)
- 버퍼 풀의 크기가 클수록, 디스크 IO를 줄일 수 있으므로, 가능한 기본값이 좋다.

2. innodb_io_capacity
- InnoDB 버퍼풀에 더티 페이지가 많을 수록, 디스크 쓰기 폭발이 발생할 가능성이 증가
    = 디스크 기록 더티 페이지 수 < 더티 페이지 발생 수, 요 경우가 되면 급작스럽게 디스크 쓰기가 폭증
    = innodb_max_dirty_pages_pct_lwm
        : 일정 수준 이상의 더티페이지 발생 시, 더티 페이지를 디스크로 기록
        default - 10% 수

- innodb_io_capacity & innodb_io_capacity_max
    전자: 일반적인 상황에서 디스크가 적절히 처리할 수 있는 수준의 값
    후자: 디스크가 최대 성능을 발휘할 때, 어느 정도의 디스크 읽고 쓰기가 가능한지
    (여기 지정한 값 만큼 디스크 쓰기를 보장하는 것은 아니고, 내부 최적화 알고리즘에 의해 적절히 계산된 값이 사용된다.)

    * adaptive_flush
    - depends on `innodb_adaptive_flushing_lwm`
    (default: 10%)
    - 활성 리두 로그의 공간이 해당 %를 넘어가면 adaptive flush 알고리즘 동작

- innodb_flush_neighbours
    디스크 기록 시, 인접한 페이지 중 더티페이지가 있으면 함께 flush
    = SSD를 사용한다면 설정X, HDD는 1 ~ 2로 활성화


# LRU 리스트 플러시
- 사용 빈도가 낮은 데이터 페이지들을 제거(새로운 페이지를 읽어올 공간마련)
- LRU list의 끝부분 ~ innodb_lru_scan_dept 크기 만큼 페이지 스캔
    -> 더티 페이지 동기화 & 클린 페이지 to free list immediately
- 모든 버퍼 풀 인스턴스에 적용


# 버퍼 풀 백업
- 잘 warm up 된 서버(= 버퍼 풀에 데이터가 담겨있는 DB)
    vs 안된 서버
    = 성능차이가 꽤 난다.
    = 5.6부터 shutdown시 버퍼 풀 백업, startup시 백업 활성화가 가능


# 버퍼 풀의 적재내용 확인
up to 5.7, information_schema.innodb_buffer_page
    = 버퍼 풀이 큰 경우 조회가 부하를 일으킨다.
    = 서비스 쿼리가 느려진다.

in 8.x information_schema.innodb_cached_indexes (개선)
    = 테이블의 인덱스 별로 데이터 페이지가 얼마나 InnoDB 버퍼 풀에 적재되어 있는지 파악가능

```
SELECT
    it.name table_name,
    ii.name index_name,
    ici.n_cached_pages n_cached_pages
FROM information_schema.innodb_tables it
    INNER JOIN information_schema.innodb_indexes ii ON ii.table_id.it_table_id
    INNER JOIN information_schema.innodb_cached_indexes ici ON ici.index_id = ii.index_id
WHERE it.name=CONCAT('employees', '/', 'employees');

p. 120 - 테이블 전체 페이지 중 대략 어느 정도의 비율이 InnoDB 버퍼 풀에 적재되어 있는지
```


# Double Writer Buffer
- InnoDB는 리두 로그 공간의 낭비를 막기 위해, 페이지의 변경된 내용만 기록
    = 디스크로 더티페이지 플러쉬 시 일부가 증발하면 복구할 방법이 없다.
    = partial-page, torn-page (일부만 기록되는 것)
    = 하드웨어 오작동 or 시스템의 비정상 종료 등에 발생

- 실제 데이터 파일에 변경 내용을 기록하기 전, 더티페이지를 묶어서 한 번의 디스크 쓰기로 시스템 테이블 스페이스의 `Double Writer Buffer`에 기록
- 이후 각 더티 페이지를 파일의 적당한 위치에 랜덤쓰기

- 기록 도중 비정상 종료 시, InnoDB가 시작될 때 항상 Double Writer 버퍼 내용과 데이터 파일의 페이지들을 모두 비교
    -> 다른 내용을 담고 있는 페이지가 있으면, Double Writer 버퍼의 내용을 데이터 파일의 페이지로 복사

데이터 무결성이 중요하면 on, 속도가 중요하면 off


# Undo log 
for transaction and isolation level
- DML(Delete, Insert, Update)로 변경되기 이전 버전의 데이터를 별도로 백업
    = 백업된 데이터를 Undo Log라고 한다.

1. for transaction
- 트랜잭션 롤백 시, 변경 전 데이터로 복구하는데 사용

2. for isolation
- 특정 커넥션에서 변경 중인 데이터를 다른 커넥션에서 조회 -> undo log에 백업한 데이터 display

up to 5.5
- 언두 로그의 사용 공간이 한 번 늘어나면 서버를 새로 구축하는 것만이 방법...
    = DML 쿼리 실행 중인 부분 조회 시, 언두로그의 이력 스캔필요;
    = 성능저하

since 5.7
- 해결. 필요한 시점에 공간을 줄일 수 있다.
    = but, 여전히 트랜잭션을 장기간 유지하면 성능에 좋지 않다.

* undo log 모니터링
`SHOW ENGINE INNODB STATUS \G`
    ...
    `History list length 31`
    
    or

    ```
    in 8.x

    SELECT count FROM information_schema.innodb_metrics
    WHERE SUBSYSTEM = 'transaction' AND NAME = 'trx_rseg_history_len'
    ```

* undo tablespace
- 언두로그가 저장되는 공간
    = from 8.0, 언두 로그는 항상 시스템 테이블스페이스 외부의 별도 로그파일에 기록!
- 하나의 언두 테이블 스페이스는 1개 이상, 128개 이하의 롤백 세그먼트를 가진다.
- 롤백 세그먼트는 1개 이상의 언두 슬롯을 가진다.
    = InnoDB 페이지 크기 / 16Byte = 언두 슬롯의 개수
- 하나의 트랜잭션은 최대 4개 까지의 언두 슬롯 사용

    in general, 최대 동시 트랜잭션 수
    = InnDB 페이지 크기 / 16 * 롤백 세그먼트 수 * 언두 테이블 스페이스 개수

- 언두 로그 슬롯이 부족하면 트랜잭션을 시작할 수 없는 심각한 문제가 발생한다.
    = since 8.0 CREATE UNDO TABLESPACE, DROP TABLESPACE 명령으로 언두 스페이스를 동적으로 추가/삭제가능

* 언두 스페이스를 필요한 만큼만 남기고 return to OS
1. 자동모드
- InnoDB purge thread가 주기적으로 불필요한 언두로그 삭제 = undo purge
    = `innodb_undo_log_truncate`: ON 시, 주기적으로 활성화
    = `innodb_purge_rseg_truncate_frequency` 변수 값을 조정해 빈도 수 조정가능

2. 수동모드
- 언두 테이블스페이스가 최소 3개 이상이 되어야 동작
    = 언두 테이블스페이스 비활성화 시 퍼지 스레드가 반납해준다.
    ```
    ALTER UNDO TABLESPACE tablespace_name SET INACTIVE;
    ALTER UNDO TABLESPACE tablespace_name SET ACTIVE;
    ```


# Change Buffer
- 레코드 INSERT, UPDATE 시 데이터 파일 변경 외에도 해당 테이블에 포함된 인덱스를 업데이트 해야...
- But, 인덱스를 업데이트 하는 작업은 랜덤IO를 발생시킨다.
    = 업데이트 할 인덱스가 많다면?!
    = 따라서, 버퍼 풀에 있으면 바로 업데이트 but if not, 임시 공간에 저장해두고 나중에 업데이트
    (결과는 바로 반환)
- 이때 사용하는 임시 메모리 공간 = Change Buffer

* Unique Key는 중복 여부를 체크해야 하므로 (결과 반환 전) 체인지 버퍼 사용불가

- 임시로 저장된 인덱스 레코드 조각은 이후 백그라운드 스레드에 의해 병합
    by change buffer merge thread
- 크기 조절도 가능하다. (p. 130)


# Redo log & log buffer
- ACID 중 D와 관련
- But, 성능도 중요하다.
    = 대부분 DB는 읽기를 위해 설계
    = 쓰기 속도가 비교적 느리다.
    = 트랜잭션이 커밋될 때 바로 리두로그가 커밋되도록 하는 것을 권장
    = 그러나 매번 이렇게 하면 부하!
- `innodb_flush_log_at_trx_commit`
    = 어느 주기로 디스크에 동기화할 것인가?
- 리두로그는 최대 1초 정도 손실이 발생할 수 있다.
- 리두로그 파일들의 전체 크기는 버퍼 풀의 효율성을 결정하므로, 신중히 결정해야 한다.
- 사용량(특히 변경작업)이 많은 DB는 리두로그 기록 작업이 문제될 수 있다.
    = ACID를 보장하는 선에서 버퍼링한다.
    = 이때 사용하는 것이 로그버퍼
- 트랜잭션이 커밋돼도 데이터 파일은 즉시 디스크로 동기화되지 않는다.
    = But, 리두 로그는 항상 디스크로 기록된다.
- since 8.0, 리두 로그 활성화/비활성화가 가능
```
SHOW GLOBAL STATUS LIKE `Innodb_redo_log_enabled`;
ALTER INSTANCE DISABLE INNODB REDO_LOG;
```
- 리두 로그가 비활성화 된 상태에서 MySQL 서버가 비정상적으로 종료된다면?
    = 마지막 체크포인트 이후 시점의 데이터는 복구불가
    = even worse, MySQL 서버의 데이터가 마지막 체크포인트 시점의 일관된 상태가 아닐 수 있다.
    = therefore, 데이터가 중요하지 않더라도, 서비스 도중에는 리두 로그를 활성화!
    (MySQL 서버가 비정상적으로 종료되어도 특정 시점의 일관된 데이터를 가질 수 있다.)


# redo log archiving (p. 135)


# adaptive hash index
- InnoDB가 자동생성한 인덱스 for frequently requested data
    = `innodb_adaptive_hash_index`: 활성화 or 비활성화 가능
- B-Tree 검색 시간을 줄여주기 위해 도입된 기능
    = 동시 다발 적으로 몇 천개의 스레드가 쿼리를 실행하면 CPU는 엄청난 프로세스 스케줄링을 해야 한다.
    = 쿼리 성능저하
- 자주 읽히는 데이터 페이지의 키 값을 이용해 해시 인덱스 생성
    -> 해시 인덱스를 통한 검색으로 레코드가 저장된 페이지를 즉시 찾아갈 수 있다.
    -> 적은 비용, 높은 성능
        ex. InnoDB 내부 잠금 저하

- B-tree 인덱스의 고유번호 to B-Tree 인덱스의 실제 키 값 조합으로 구성
    = 고유번호가 필요한 이유? InnoDB에서 adaptive hash index는 하나만 있다.
    = 모든 B-Tree 인덱스에 대한 어댑티브 해시 인덱스가 하나의 해시 인덱스에 저장됨
    = 특정 키 값이 어느 인덱스에 속해있는지 구분필요

- 데이터 페이지 주소
    = 실제 키 값이 저장된데이터 페이지의 메모리 주소
    = 버퍼 풀에 로딩된 페이지의 주소
    = 버퍼 풀에 올려진 데이터 페이지에 대해서만 어댑티브 해시 인덱스가 관리된다.
    = 버퍼 풀에서 해당 데이터 페이지가 사라지면, 어댑티브 해시 인덱스에서 해당 페이지 정보도 사라진다.

- 기존에는 어댑티브 해시 인덱스가 하나의 메모리 객체
    = 경합이 심했다.
    = 이제는 내부 잠금(세마포어) 경합을 줄이기 위해 파티션 기능이 제공된다.
    = `innodb_adaptive_hash_index_parts`

* 어댑티브 해시 인덱스가 실제로 도움이 되는 경우
1. 디스크의 데이터가 InnoDB 버퍼 풀 크기와 비슷한 경우(디스크 읽기가 많지 않은 경우)
2. 동등 조건 검색이 많은 경우
3. 쿼리가 일부 데이터에만 집중되는 경우

* 안되는 경우
1. 디스크 읽기가 많은 경우
2. 특정 패턴의 쿼리가 많은 경우 ex. JOIN or LIKE 패턴검색
3. 매우 큰 데이터를 가진 테이블의 레코드를 폭넓게 읽는 경우

어댑티브 해시 인덱스 = no Silver Bullet
- 메모리 공간 차지
    = 디스크 읽기가 많다면 NO 효용
- 일단 활성화되면 무조건 어댑티브 해시 인덱스에 찾으려는 값이 있는지 검색 필요
    = 추가비용
    = 해시인덱스의 효율이 없어도 InnoDB는 계속 해시 인덱스를 뒤진다.
- 삭제 작업에도 영향
    = 데이터 페이지의 내용을 어댑티브 해시 인덱스에서도 제거해야 함.
    = 어댑티브 해시 인덱스의 도움을 많이 받을 수록, 테이블 삭제 or 변경 작업은 더 치명적

* SHOW ENGINE INNODB STATUS
    = INSERT BUFFER AND ADAPTIVE HASH INDEX 탭을 보자

* 어댑티브 해시 인덱스의 효율은
    = 해시 인덱스 히트율, 해시 인덱스가 사용 중인 메모리 공간, 서버의 CPU 사용량을 종합해서 판단.

* 해시 인덱스의 메모리 사용량 보기
```
SELECT EVENT_NAME, CURRENT_NUMBER_OF_BYTES_USED
FROM performance_schema.memory_summary_global_by_event_name
WHERE EVENT_NAME = 'memory/innodb/adaptive hash index';
```


# MySQL log file
- 서버에 문제가 생겼을 때, 도움!

1. error log file
- MySQL 실행 중 발생하는 에러나 경고 메시지가 출력되는 로그 파일
- location: a directory defined in my.cnf `log_error`
    or with `.err` if not defined

    * 확인할 메시지
    1) 적용되지 않은 파라미터
    2) 트랜잭션 복구 메시지 - 비정상 종료 시, 트랜잭션 복구시도 but fail
    3) 쿼리 처리 도중에 발생하는 문제
    4) 비정상적으로 종료된 커넥션 메시지
        = aborted connection
        = 애플리케이션 커넥션 종료 로직 문제 or max_connect_errors ...
    5) MySQL 종료 메시지
        = 갑자기 재시작 되었을 때, 원인을 확인할 수 있는 유일한 방법...

주의
- InnoDB 엔진상태 조회명령은 큰 메시지를 에러 로그파일에 기록한다.
    = InnoDB 모니터링을 활성화 상태로 두면 에러 로그 파일이 매우 커져서 파일 시스템 공간을 다 사용해 버릴 수 있다.

2. general log
- MySQL이 쿼리 요청을 받으면 바로 기록!
`SHOW GLOBAL VARIABLES LIKE 'general_log_file'`
    = `general_log_file` 파라미터에 경로 설정
- `log_output` 파라미터를 통해 쿼리 로그를 파일 or 테이블로 저장할 지 선택가능

3. slow_query log
- `long_query_time` 변수에 설정한 시간 이상이 소요된 쿼리는 모두 기록
    = 실제 소요시간을 측정하므로, 정상적으로 실행 된 쿼리가 대상
- 마찬가지로 `log_output` 사용해서 파일 or 테이블 저장 결정
(CSV storage engine을 사용하므로 테이블에 저장해도 CSV 파일로 저장하는 것과 동일하게 작동)

* InnoDB의 경우, MySQL 엔진 레벨의 잠금 and 스토리지 엔진 자체 잠금을 둘 다 가지고 있음
    = 슬로우 쿼리 로그에 출력되는 내용이 혼란스러울 수 있다.
    
    1) time
    = 쿼리가 종료된 시점
    = time - query_time을 빼야, 쿼리가 언제 시작되었는지 알 수 있음

    2) `user@host`
    = 쿼리를 실행한 사용자의 계정

    3) query_time
    - 쿼리가 실행되는데 걸린 전체시간

    4) lock_time
    - MySQL 엔진 레벨에서 관장하는 테이블 잠금에 대한 대기시간만 표시
    - 0이 아니라고해서 무조건 잠금 대기가 있었다고 판단하기가 힘듦
        = lock_time에 표기된 시간은 실제 쿼리가 실행되는데 필요한 잠금 체크 등 코드 실행 부분까지 모두 포함
        = 매우 작은 값이면 무시해도 무방하다.

    5) rows_examined & rows_sent
    = 쿼리가 처리되기 위해 몇 건의 레코드에 접근했는가?
        & 실제로 몇 건의 처리 결과가 클라이언트에게 보내졌는가
    = 접근 건수가 보내진 건수에 비해 훨씬 높다면, 조금 더 적은 레코드에만 접근하도록 튜닝할 수 있다.
    (다만, 집합 함수가 아닌 쿼리의 경우에만 해당한다.)

NOTE)
`Percona Toolkit, pt-query-digest` p. 151

