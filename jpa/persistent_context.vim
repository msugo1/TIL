# JPA에서 가장 중요한 개념 중 하나
- EntityManager <-> PersistentContext
    in Spring it is N : 1 (access to PersistentContext via EntityManagers)

# Entity Lifecycle
1. 비영속(new/transient)  
- 영속성 컨텍스트와 관련 없음
- 새로운 상태

2. 영속(managed)
- 영속성 컨텍스트에 의해 관리되는 상태

3. 준영속(detached)
- 영속성 컨텍스트에 저장되었다가 분리된 상태
- detach(), clear(), close()

4. 삭제 (removed)
- 삭제된 상태

# 영속성 컨텍스트의 이점
1. 1차 캐시 
(큰 효용은 없다. 
- em normally comes with Trnasaction, which is closed after transaction shuts down
- it just flashes within one business normally in general)

2. 동일성 보장
- application level의 `repeatable read`지원
- 1차 캐시에 있다면, 같은 영속성 컨텍스트 내에서는 언제나 same entity! (only if the id is identical)

3. 트랜잭션을 지원하는 쓰기지연 (transactional write-behind)
- 쓰기 지연 SQL 저장소에 쿼리 저장 후, 트랜잭션 커밋 시에 DB로! (buffering!)
    = `hibernate.jdbc.batch_size` - 지정한 사이즈만큼 모아서 DB에 보내기

4. 변경 감지(dirty checking)
- 트랜잭션이 열려있는 경우, 영속 메소드(ex. em.persist)를 임의로 호출할 필요가 없다.
    1) 트랜잭션 커밋 시점에, 영속성 컨텍스트 내 엔티티와의 `스냅샷 비교` (최초 시점의 상태)
    2) UPDATE SQL 생성 & DB에 쿼리(flush)
    
    * flush: 영속성 컨텍스트의 변경내용을 DB에 반영

5. 지연 로딩(lazy loading)

# flush
* How to invoke flush?
1. em.flush() - 직접 호출
2. 트랜잭션 커밋 - 자동 호출
3. JPQL 쿼리 실행 - 자동 호출
 
NOTE!!!
- flush를 호출하더라도 영속성 컨텍스트는 비워지지 않는다.
    = 여기서 flush는 DB와의 동기화 의미
    (트랜잭션 이라는 작업 단위가 중요 - 커밋 직전에만 동기화)

# 준영속
- 영속 -> 준영속 (영속 상태의 엔티티가 영속성 컨텍스트에서 분리)
- 영속성 컨텍스트가 제공하는 기능 못함
    = 변경감지 동작X


