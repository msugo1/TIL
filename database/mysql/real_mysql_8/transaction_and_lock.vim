# Transcation
- to ensure atomicity
    = no partial update
    = either all or nothing

- 꼭 필요한 최소의 코드에만 적용하자
    ex. business 로직 + DB Access 코드가 있다면, 가능한 DB Access 코드에만 넣는 것이 바람직(트랜잭션 범위의 최소화)
        = 커넥션은 한정적

        + FTP or 메일 전송 등 네트워크를 통해 원격 통신하는 작업은 어떻게든 트랜잭션에서 제거하자
        (프로그램이 실행되는 동안 원격 서버와 통신할 수 없는 상황이 발생한다면, 웹서버 뿐 아니라 DBMS 서버까지 위험해질 수 있다.)

vs Lock
    = 잠금은 for concurrency control
    = 트랜잭션은 for data consistency

# Isolation Level
- 하나의 트랜잭션 내에서 또는 여러 트랜잭션 간 작업 내용을 어떻게 차단/공유할 것인지 결정하는 레벨
    = READ UNCOMMITED, READ COMMITED, REPEATABLE_READ, SERIALIZABLE

    ## REPEATABLE_READ
    - to do with MVCC
        = 롤백에 대비해 변경되기 전 레코드를 undo 영역에 백업 후 실제 레코드 변경
    - 언두 영역에 백업된 이전 데이터를 이용해 동일 트랜잭션 내에는 동일한 결과를 보여줄 수 있게 보장
        vs READ COMMITED
        = 언두 영역에 백업된 레코드 중 몇 번째 이전 버전까지 찾아들어가는지!
        = InnoDB의 트랜잭션은 고유한 트랜잭션 번호를 가진다.
        (언두 영에 백업된 모든 레코드는 변경 발생된 트랜잭션 ID가 존재)
        = 특정 트랜잭션 구간 내 백업된 언두 데이터가 보존되어야 한다.


* dirty read in READ UNCOMMITED
    = 어떤 트랜잭션에서 처리 작업이 완료되지 않아도, 다른 트랜잭션에서 볼 수 있는 현상
    = RDBMS 표준에서는 트랜잭션 격리 수준으로 인정하지 않을 정도로 문제가 많다.
    
* non-repeatable-read in READ UNCOMMITED/COMMITED
    = 한 트랜잭션에서 작업 커밋 시, 이게 다른 트랜잭션에도 반영되어서 보여버리는 점
    = 이전 SELECT와 다음 SELECT가 다른 결과를 보일 수 있다.(다른 트랜잭션에 의해 업데이트 되어서)

* no phantom read in InnoDB for REPEATABLE_READ isolation level

# Lock
*. MySQL 엔진의 잠금
    = 모든 스토리지 엔진에 영향을 미친다.
    (vs 스토리지 엔진 잠금 = 스토리지 엔진 간에 상호영향X)

ex. 테이블 락 for 테이블 데이터 동기화, 메타데이터 락 for 테이블 구조, 네임드 락 for customisation

1. 글로벌 락

since 8.0, 백업 락: 백업 툴 들의 안정적인 실행을 위해 with 좀 더 가벼운 글로벌 락
- 특정 세션에서 백업 락 획득 시, 불가능한 작업

    1) DB 및 테이블 등 모든 객체 생성/변경/삭제
    2) REPAIR TABLE and OPTIMIZE TABLE
    3) 사용자 관리 및 비밀번호 변경
    (백업의 실패를 막기 위한 DDL 실행 차단)

- 일반적인 테이블의 데이터 변경은 허용

2. 테이블 락
- DDL 시 영향

3. 네임드 락
- GET_LOCK() 함수 이용, 임의의 문자열에 대해 잠금설정
    = 단순히 사용자가 지정한 문자열에 대해 획득/반납하는 잠금
- 여러 클라이언트가 상호 동기화를 처리해야 하는 경우
    or 많은 레코드에 대해 복잡한 요건으로 레코드를 변경하는 트랜잭션이 있는 경우
        = `동일 데이터`를 변경하거나 참조하는 프로그램끼리 `분류` 후 Named Lock

```
## 정상적으로 락을 획득/반환한 경우, 1 or NULL/0 반환

SELECT GET_LOCK('mylock', 2);
SELECT IS_FREE_LOCK('mylock');
SELECT RELEASE_LOCK('mylock');
```

4. 메타 데이터 락
- DB 객체 이름/구조 변경 시 획득(묵시적 획득만 가능)

5. InnoDB 스토리지 엔진 잠금
- 레코드 기반의 잠금방식(= 뛰어난 동시성 but 어려움)
    = information_schema 내부에 INNODB_TRX, INNODB_LOCKS, INNODB_LOCK_WAITS 테이블 조회해서 현재 어떤 트랜잭션이 잠금 대기 중인지, 해당 잠금은 어떤 트랜잭션이 가지고 있는지 확인 가능
    (필요하면 장시간 잠금을 가진 클라이언트 종료가능)
    = Performance Schema를 이용해 InnoDB 내부 잠금에 대한 모니터링 방법도 추가(세마포어)

- 잠금 정보가 상당히 작은 공간으로 관리됨
    = 레코드락 -> 페이지락 or 테이블락 으로 업그레이드 되는, `Lock Escalation` 발생하지 않는다.
    
- 레코드 락 외에도 간격을 잠그는 `갭 락`, 두 개를 합친 `넥스트 키 락`이 존재

    1) 레코드 락
    - 레코드 자체가 아닌, 인덱스의 레코드를 잠근다.
    - 보조 인덱스를 사용한 변경작업은 Next Key Lock or Gap Lock을 사용하지만, PK or UK 인덱스에 의한 변경 작업에서는 레코드 자체에만 락을 건다.
    (= No Gap Lock)

    2) 갭 락
    - 레코드 자체가 아니라, 레코드와 `바로 인접한` 레코드 사이의 `간격`만을 잠근다.
    - 레코드와 레코드 사이의 간격에 새로운 레코드가 생성되는 것을 제어
    - 넥스트 키 락의 일부로 자주 사용

    3) 넥스트 키 락
    - 레코드 락 + 갭 락을 합쳐놓은 형태의 잠금
    - 주 목적 중 1
        = 갭 락 or 넥스트 키 락은 바이너리 로그에 기록된느 쿼리가 레플리카 서버에서 실행될 때, 소스 서버에서 만들어 낸 결과와 동일한 결과를 만들어내도록 보장하는 것이 주목적
        (넥스트 키 락 or 갭 락으로 인해 데드락이 발생하거나, 다른 트랜잭션을 기다리게 하는 일이 자주 발생한다.
            -> 가능하면 바이너리 로그 포맷을 ROW 형태로 바꾸면 넥스트 키 락 or 갭 락이 줄어든다.)

6. Auto increment Lock (p. 170)
- 각 레코드에 중복되지 않고, 순서대로 일련번호 값을 넣기 위함
- INSERT or REPLACE 처럼 새로운 레코드를 저장하는 쿼리에만 필요
- 트랜잭션과 관계 없이, INSERT or REPLACE 문장에서 AI 값만 가져오면 락 바로 해제
- `innodb_autoinc_lock_mode`
   = 0: AI락
   = 1: 증가 건수를 예측 가능한 경우, 경량화 된 래치(뮤텍스) 사용 = 아주 짧은시간 잠금, 필요한 자동증가 값 가져오면 바로 해제
   = 2: NO AI락, 무조건 경량화된 래치 = STATEMENT 포맷의 바이너리 로그 복제 시, 마스터 <-> 슬레이브 간 AI값이 달라질 수 있음

* AI 값이 증가하면 줄어들지 않는 이유?
    = AI 잠금 최소화를 위해


# index and Lock in InnoDB
- 변경할 레코드를 찾기 위해, 검색한 인덱스의 레코드를 모두 Lock
    = 업데이트를 위한 테이블 풀 스캔 시 ... 모든 레코드가 잠긴다.
    = 인덱스 설계가 매우 중요하다.


# 레코드 수준의 잠금 확인 및 해제(p. 172)
until 8.0
- information_schema, INNODB_TRX, INNODB_LOCKS, INNODB_LOCK_WAITS

since 8.0
- performance_schema: data_locks, data_lock_waits 테이블

```
SELECT
    r.trx_id as waiting_trx_id,
    r.trx_mysql_thread_id as waiting_thread
    r.trx_query as waiting_query
    b.trx_id as blocking_trx_id,
    b.trx_mysql_thread_id as blocking_thread,
    b.trx_query as blocking_query
FROM performance_schema.data_lock_waits as w
    INNER JOIN information_schema.innodb_trx as b on b.trx_id = w.blocking_engine_transaction_id
    INNER JOIN information_schema.innodb_trx as r on r.trx_id = w.requesting_engine_transaction_id;

OR

SELECT * FROM performance_schema.data_locks\G;
```


