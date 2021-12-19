# SimpleJpaRepository 
- 구현 확인

* 새로운 엔티티 판별밥?
1. 식별자가 객체
- id가 null이면 새것

2. 식별자가 primitive type
- id가 0이면 새것

* GeneratedValue를 사용할 수 없다면?
- implement Persistable
    = isNew 구현해서 새 엔티티인지 판단

# Projections
- 인터페이스 정의 후, 필요한 속성을 반환하게 하면...
    = 스프링 data jpa가 프록시 구현체를 만들어서 넣어준다!
    = 필요한 값도 반환해준다!

- SpEL도 사용가능
    = open projections
    why? 엔티티를 다 가져와서 그 후 필요한 연산

- 클래스 기반도 가능
    = 생성자의 파라미터 `이름`이 중요

- 제네릭 프로젝션도 가능
    = 두번째 파라미터로 타입만 넘기면 됨.

- 중첩구조도 가능하지만, 루트 빼고는 최적화 불가

# Native Query
@Query( ... nativeQuery = true)

제약
- Sort 이용한 정렬이 제대로 동작하지 않을 수 있다.
- JPQL처럼 어플리케이션 로딩 시점에 문법확인 불가
- 동적쿼리 불가

* Native SQL로 단순 DTO 조회 시 JdbcTemplate or MyBatis가 더 나을 수 있음...

with Projections?

@Query(
    value = "SELECT m.member_id as id, m.username, t.name as teamName FROM member m LEFT JOIN team t"
      ),
    countQuery = "SELECT count(*) FROM member",
    nativeQuery = true
Page<MemberProjection> findByNativeProjection(pageable: Pageable)

    interface MemberProjection {
        fun getId(): Long
        fun getUsername(): String
        fun getTeamName(): String
    }
