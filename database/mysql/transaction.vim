* transaction - for atomicity, consistency
* lock - for concurrency, isolation

# 트랜잭션의 범위는 가능한 작게!
  - 특히 커넥션 풀을 사용하는 경우, 불필요한 트랜잭션은 대기 시간을 발생시킬 수 있다.
  - 네트워크 작업이 있는 경우, 트랜잭션에서 배제하는게 좋다고 한다.
  (ex. ftp)

# Lock in MySQL
1. Global Lock
  - `FLUSH TABLES WITH READ LOCK`으로 명시적 획득만 가능
  - MySQL 전체 Lock 중 가장 범위가 큼
    = 모든 테이블에 잠금을 건다.
    = 해당 Lock을 획득하기 위해서는 먼저 실행된 쿼리가 종료되어야 한다.
    (MySQL 서버 전체 ex. 한 세션에서 글로벌락 획득시 SELECT를 제외한 나머지 op는 대기 till the gl is released)
    
    ex. for 일관된 덤프
      but, 가급적이면 사용하지 않는 것이..

2. Table Lock
  - 명시적 획득 with `LOCK TABLES (table_name) [READ | WRITE]`
    = 글로벌 락과 마찬가지로 상당한 영향
  - 묵시적 획득
    = 쿼리 실행 시
    = InnoDB는 DDL(스키마 변경쿼리) 시 테이블 잠금
     * & insert into ... (select ... from ...) 더 알아보기

3. User Lock
  - GET_LOCK() 함수를 이용해 임의로 잠금 설정가능
  - 이 Lock의 대상?
    = 단순히 사용자가 지정한 문자열에 대해 획득하고 반납

  - or 많은 레코드를 한 번에 변경하는 트랜잭션의 경우에 유용하게 사용가능
  (how it is described in Real MySQL)
    = 한꺼번에 많은 레코드 변경 시 자주 데드락의 원인이 되곤 한다.
    = 동일 데이터를 변경하거나 참조하는 프로그램끼리 분류해서 유저 락을 걸고 쿼리를 실행하면 해결가능

4. Name Lock
  - 데이터베이스 객체이름 변경 시 획득하는 잠금
    = 이름 변경 시 자동획득
    = 원본이름, 변경될 이름 두 개 모두 한꺼번에 잠금설정

# Lock in especially in InnoDB
(record lock based)

INFORMATION_SCHEMA(DB)
  -> INNODB_TRX, INNODB_LOCKS, INNODB_LOCK_WAITS
  = 세 테이블을 조인해서 조회하면 현재 어떤 트랜잭션이, 어떤 잠금을 대기하고 있고 
    해당 잠금을 어느 트랜잭션이 가지고 있는지 확인할 수 있음

* 비관적 잠금(Pessimistic Locking)
  - `잠금 획득 first`, then `변경 작업`

* 낙관적 잠금(Optimistic Locking)
  - `변경 작업 first`, then `잠금 충돌 확인`

* InnoDB에서 기본적으로 lock escalation은 일어나지 않는다고 한다.
  lock escalation? record lock -> page lock -> table lock.

1. record lock
  - 레코드 자체만 잠금
  - InnoDB는 레코드 자체가 아닌, 인덱스의 레코드를 잠근다.
  = 보조 인덱스를 사용한 변경 시 Next Key Lock or Gap Lock 사용
  = PK or UK 변경 시, 레코드 자체에만 Lock

2. gap lock
  - 레코드 그 자체가 아닌, 레코드와 바로 인접한 레코드 사이의 간격만을 잠근다.
    = 레코드와 레코드 사이의 간격에 새로운 레코드가 생성되는 것을 제어
    = Next key lock의 일부로 사용

3. next key lock
  - like record lock + gap lock
  
4. 
