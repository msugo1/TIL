# MySQL엔진 ---- Handler API ----  스토리지 엔진 
1. MySQL 엔진
  - Connection Handler, SQL Interface, SQL Parser, SQL Optimiser, Cache & Buffer
  - SQL 문장 분석 & 최적

2. Storage 엔진
  - 실제 데이터 저장/불러오기

3. Handler API
  - Handler 요청? 
    = MySQL 엔진의 쿼리 실행기 --- 데이터 읽기/쓰기 요청 ---> 스토리지 엔진
    = 요청 자체가 핸들러 요청
    = 이때 사용되는 API는 핸들러 API


  - `SHOW GLOBAL STATUS LIIKE 'Handler%'
    = 얼마나 많은 데이터(레코드) 작업이 있었는지 through Handler API

# 스레드 기반 = Foreground Thread (FT) + Background Thread (BT)
1. FT
  - 각 클라이언트 사용자가 요청하는 쿼리문장 처리
  - as many as users connected to the MySQL Server
  - `thread_cache_size` = Thread pool size

  in InnoDB
  - 버퍼나 캐시까지만 FT가 처리
  (버퍼를 실제 디스크에 기록하는 작업은 by BT)
    
2. BT
  (InnoDB 기준)
  1) Main Thread
    = 모든 쓰레드를 총괄

  2) Insert Buffer 병합 Thread

  3) 로그를 디스크로 기록하는 Thread

  4) InnoDB 버퍼 풀의 데이터를 디스크에 기록하는 Thread

  5) 데이터를 버퍼로 읽어들이는 Thread

  6) 기타 여러 잠금 or 데드락을 모니터링하는 Thread


  - 가장 중요한 것은 Log Thread, Write Thread(버퍼의 데이터를 디스크로 쓴다.)
  - `innodb_write_io_threads`
    = 쓰기 쓰레드의 개수 지정
  - `innodb_read_io_threads`
    = 읽기 쓰레드의 개수 지정
  
  - 데이터 read 작업은 FT에서 주로 처리, but write 작업은 BT가 주로 담당
    = 2~4 혹은 4개 이상으로 충분히 설정할 필요가 있다.

* 읽기 작업은 버퍼링 처리가 불가능하다

# 메모리 할당 및 사용구조 = GLOBAL + SESSION(= LOCAL) 영역

in global
: key cache, buffer pool(InnoDB), query cache, binary log buffer, log buffer, table cache

in session
: connection buffer, result buffer, read buffer, join buffer, random read buffer, sort buffer

* 글로벌 메모리 영역
  - assigned by OS
  - 하나의 메모리 공간만 할당
  - 모든 스레드에 의해서 공유

* 로컬 메모리 영역
  - 클라이언트 스레드가 쿼리를 처리하는데 사용하는 메모리 영역
    = 각 클라이언트 스레드 별 독립 할당
  - 각 쿼리의 용도별로 `필요할 때만` 공간 할당

  ex. connection buffer & result buffer
    = 커넥션이 열려 있는 동안 계속 할당

      sort buffer & join buffer
    = 쿼리를 실행하는 순간에만 할당, 이후 바로 해제

# SQL Parser -> SQL Optimiser -> SQL 실행기 -> 데이터 읽기/쓰기 (by storage engine) -> 디스크
= (Query Parser, 전처리기) -> 옵티마이저 -> 쿼리 실행기(실행 엔진) -> 스토리지 엔진(핸들러) -> HW

  - Optimiser가 계획 최적화/생성 -> 실행 엔진이 이를 처리하기 위해, 핸들러에게 계속 요청 (한 핸들러에게 요청 후 결과 수집, 이후 해당 결과를 다른 핸들러에게 요청시 활용)

# MySQL 엔진이 각 스토리지 엔진에게 데이터를 읽어오거나 저장하도록 명령하기 위해서는, 핸들러를 꼭 통해야 한다.

# Master - Slave

* I/O Thread, SQL Thread in Slave
  - I/O Thread 
    = 마스터 서버에 접속해 변경 내역 요청, 받아온 내역은 릴레이 로그에 기록

  - SQL Thread
    = 릴레이 로그에 기록된 변경 내역 재실행 
    = 슬레이브의 데이터를 마스터와 동일한 상태로 유지

# query cache
  - 동일한 쿼리 문이 들어왔을 때, 미리 메모리에 캐시된 결과를 반환

* 반드시 캐시를 사용하는 것은 아니며, 아래의 절차를 모두 통과해야 한다.

1. 요청된 쿼리 문장이 쿼리 캐시에 존재하는가?
  - 쿼리 캐시는 MySQL의 최 앞단에 위치한다.
  - 쿼리 문장 자체가 동일한지 비교(공백, 탭 등의 문자, 대소문자까지 완벽히 같아야 한다.)
    = prepared statment 가 캐시를 사용할 확률이 높은 이유

2. 해당 사용자가 그 결과를 볼 수 있는 권한을 가지고 있는가?
  - 권한이 없다면, 당연히 보여줘서는 안된다.

3. 트랜잭션 내에서 실행된 쿼리의 경우, 가시 범위 내에 있는 결과인가?
  - 트랜잭션 가시 범위
    = InnoDB 트랜잭션은 각각의 고유한 id를 갖는다.
    = 자신보다 나중에 실행된 트랜잭션(자신의 id < 대상 트랜잭션 id>)인 경우는 참조가 불가능해야 한다.
   
4. 호출 시점에 따라 결과가 달라지는 요소가 있는가?
  ex. CURRENT_DATE(), SYSDATE(), RAND() 등
  - 이런 요소는 최대한 사용하지 않는 편이 쿼리 캐시 활용에 도움이 된다.

5. for prepared statement, 변수가 결과에 영향을 미치지 않는가?

6. 캐시가 만들어지고 나서, 해당 데이터가 다른 사용자에 의해 변경되지 않았는가?
  - 캐시된 데이터가 변경되면 invalidation이 필요하다. (무효화)
    = 테이블 단위의 작업
    = 쿼리 캐시의 크기가 커지면, 무효화 작업시간이 매우 늘어난다.
    (메모리 작업이라고 해도, 상당한 시간이 필요하다.)
    = 따라서, 32M ~ 64M 정도의 캐시가 적당하다.

7. 쿼리에 의해 만들어진 결과가 캐시하기에 너무 크지 않은가?
  - `쿼리 결과 크기 > 캐시 크기` 인 경우 당연히 담길 수 없다.
  - `쿼리 결과 크기 is similar to 캐시 크기` 인 경우 비효율 적인 캐시 사용
    = `query_cache_limit` 옵션을 지정해, 특정 크기 미만의 쿼리만 캐시하도록 지정가능

8. 그 밖에 쿼리 캐시를 사용하지 못하게 하는 요소가 있는가?
  1) 임시 테이블에 의한 쿼리
  2) 사용자 변수의 사용
  3) 칼럼 기반의 권한 설정
  4) LOCK IN SHARE MODE 힌트
    = SELECT 문장에 끝에 붙여서, 조회하는 레코드에 공유잠금을 설정하는 쿼리(S Lock)
  5) FOR UPDATE 힌트
    = SELECT 문장의 끝에 붙여서, 조회하는 레코드에 배타적 잠금을 설정하는 쿼리(X Lock)
  6) UDF(User Defined Function)의 사용
  7) 일부분의 서브 쿼리 (상관쿼리)
  8) 스토어드 루틴에 사용된 쿼리
  9) SQL_NO_CACHE 힌트

# InnoDB 스토리지 엔진의 특성
1. PK에 의한 클러스터링
  - PK 순서대로 디스크에 저장

2. 잠금이 필요 없는 일관된 읽기(Non-locking consistent read)
  - MVCC(Multi Version Concurrency Contrl) 기술을 이용해 락을 걸지 않고 읽기 작업을 수행
  (except for SERIALIZABLE)

3. FK(Foreign Key) 지원 (Not available in MyISAM or MEMORY)

4. 자동 데드락 감지
  - InnoDB는 그래프 기반의 데드락 체크방식을 사용한다.
    = 데드락이 발생함과 동시에 바로 감지
  - 데드락이 감지되면, 관련 트랜잭션 중에서 ROLLBACK이 가장 용이한 트랜잭션을 자동적으로 강제종료

5. 자동화된 장애 복구
  - InnoDB에는 손실이나 장애로부터 데이터를 보호하기 위한 여러 메커니즘이 탑재되어 있다.
    = MySQL 서버가 시작될 때, 완료되지 못한 트랜잭션이나 디스크에 일부만 기록된 데이터 페이지(Partial write) 등에 대한 일련의 복구 작업이 자동으로 진행된다.

# InnoDB Buffer Pool
: 디스크의 데이터 파일이나 인덱스 정보를 메모리에 캐시해 두는 공간 / 쓰기 작업 지연을 위한 버퍼 역할
(InnoDB의 핵심!)
  + 많은 백그라운드 작업의 기반이 되는 메모리공간

  - InnoDB 버퍼 풀은 아직 디스크에 기록되지 않은 변경된 데이터를 가지고 있음 (= Dirty Page)
  - 주기적 or 어떤 조건이 되면 디스크에 flush (write 쓰레드가 필요한 만큼만 though = 전체를 디스크에 쓰는 것이 아님!)

# Undo Log
  - 데이터 변경 시, 변경되기 전의 데이터를 보관하는 곳
  - 롤백 시, 언두 로그의 값을 가져다 복원
      + 동시성 제공에 활용(ex. 현재 트랜잭션에서 데이터 변경 but 커밋 전. 다른 트랜잭션에서는 언두 로그의 값이 보임)

# Insert Buffer
  - Insert, Update 시 데이터 파일 변경 외에도 테이블에 포함된 인덱스를 업데이트하는 작업이 필요하다.
  - But, 인덱스를 업데이트하는 작업은 랜덤한 디스크 읽기 작업을 포함한다.
    = 테이블에 인덱스가 많다면? 상당히 많은 자원을 소모한다.
    = 따라서, 버퍼 풀에 변경해야 할 인덱스가 있으면 바로 업데이트 하되, 없는 경우 (디스크로 부터 읽어와야 할 경우) 임시 공간에 저장해둔다. (결과는 여전히 사용자에게 바로 반환)
    = 이때 사용하는 임시 공간이 Insert Buffer

  - unique index는 인서트 버퍼 사용 불가 (why? 결과 반환 전 중복체크가 필요하므로)
  - 인서트 버퍼에 저장된 인덱스 레코드 조각은 이후 BT에 의해 병합(= Insert Buffer Merge Thread)
    = DELETE 버퍼링 도 가능 since 5.5


