# 경로표현식
. 으로 객체 그래프 탐색

```
select m.username -> 상태 필드(요기서 딱 끝!)
from Member m
    join m.team t -> 단일 값 연관 필드 (여기 부턴 다른 엔티티로!)
    join m.orders o -> 컬렉션 값 연관 필드
where t.name
```
= 어떤 필드에 접근하는지에 따라 내부적으로 동작방식이 달라지므로, 꼭 구분해서 이해해야 한다.

1. 상태 필드
- 단순히 값을 저장하는 필드(ex. username, age ...)
- 경로 탐색의 끝(탐색 X)

2. 연관 필드
- for relations, associations (연관관계를 위한 필드)
    
    2 - 1 single (@ManyToOne, @OneToOne) - 대상이 엔티티 ex. m.team
        = 묵시적 내부조인 발생(inner join), 탐색 O 

    2 - 2 collection (@ManyToMany, @OneToMany) - 대상이 컬렉션 ex. m.orders
        = 묵시적 내부조인 발생, but 탐색 불가
        = From 절에 명시적 조인을 통해 별칭을 얻어야 추가 탐색이 가능해진다.
        
        ex. select t.members(. 불가능) from Team t
        
            instead - select m.username from Team t join t.members `m`

*** 묵시적 조인을 쓰지 말자!!!!!!
(쿼리 튜닝 등이 정말 어렵다.)
= 항상 명시적 조인을 사용하자

# Fetch Join
*** 매우 중요하다 ***
left join | inner join fetch 조인 경로

- 성능 최적화를 위해 JPQL에서 제공(N + 1 문제 해결)
- 연관된 엔티티/컬렉션을 SQL 한 번에 함께 조회

ex. JPQL - select m from Member m join fetch m.team
    SQL - select m.* t.* from Member m inner join Team t on m.team_id = t.id

* 컬렉션 fetch join
ex. select t from Team t join fetch t.members where t.name = "팀A"

주의) 1:N 쿼리의 경우, 데이터가 뻥튀기 될 수 있다.

ex.
    Team            Member
  id  name      id team_id name
  1  teamA       1   1
  2  teamB       2   1
  
  teamA join query result
   
   id name(team) id team_id name(member)
   1    teamA    1    1
   1    teamA    2    1

* 객체 입장에선 안에 몇 건이 담겨있는지, 중복인지 알 방법이 없음
    = 일단 가져온다.
    (위 처럼 teamA 결과가 2건이면 2건 다 가져와서 매핑)

# How to remove the duplicate?
`DISTINCT`
JPQL's DISTINCT 
1. SQL에 DISTINCT 추가
2. 애플리케이션에서 엔티티 중복제거

ex. select distinct t from Team t join fetch t.members 
    where t.name = "팀A"

   id name(team) id team_id name(member)
   1    teamA    1    1
   1    teamA    2    1

- 결과가 완전히 같지 않으므로, SQL 만으로는 DISTINCT 실패!
- 애플리케이션에서 distinct 추가로 같은 식별자를 가진 엔티티 제거작업
    = now 중복제거 완료

NOTE
- N:1 은 뻥튀기 현상 없음

# Fetch Join vs (Normal) Join
- 일반조인은 실행 시 연관된 엔티티를 함께 조회하지 않는다.
- 페치조인을 사용할 때만, 연관된 엔티티 즉시로딩
    = 객체 그래프를 SQL 한 번에 조회하는 개념

* 대부분 N + 1 문제는 fetch join으로 해결할 수 있다.

# fetch join의 특징 & 한계
1. fetch join 대상에는 별칭을 줄 수 없다.
- Hibernate 는 가능하나, 표준이 아니므로 가급적 사용하지 말자.

ex. 몇개 걸러서 탐색 불가능 - 위험(의도치 않은 동작이 발생할 수 있음)
    = JPA의 의도: 일단 모든 객체 그래프에 접근가능해야 한다.
    (접근할 때마다 가져오는 개수가 다르다면..?? = 어디에 뭘 맞춰야 돼!!!!!)
    
    일부를 거르고 싶다면? ex. Team 내 멤버가 10000000000 명
    = 한 번에 조회하면 문제!
    = 이럴 때는, 그냥 필요한 멤버 자체를 조회해야 한다. (Team -> Member 찾아가면 안된다.)


2. 둘 이상의 컬렉션은 fetch join 불가
(혹시나 된다고 하더라도 하면 안된다.)

ex. 
class Team {

    @OneToMany
    var members: List<Member>

    @OneToMany
    var orders: List<Order>
}
- members, orders 둘 다 fetch join 하면 안된다!!!!
    ex. 데이터가 뻥튀기 * 뻥튀기 되는 등 예측 불가!!!


3. 컬렉션을 페치조인하면 페이징 사용불가 ㅜㅜ
    = fetch join + @BatchSize

# treat
- 자바의 타입 캐스팅과 유사
- 부모 타입을 특정 자식 타입으로 다룰 때 사용
    in from, where, and select (only in Hibernate)

# 엔티티 직접 사용
- JPQL에서 엔티티를 직접 사용하면, SQL에서 해당 엔티티의 기본 값 사용

# Named Query
- 애플리케이션 로딩 시점에 쿼리 검증 -> 캐시 (재사용성 증가)

@Entity
@NamedQuery(
    name = "Member.findByUsername",
    query = "select m from Member where m.username = :username"
)
class Member

em.createQuery("Member.findByUsername", Member::class.java)
...

- spring data jpa 사용 시, @Query() 사용가능

# Bulk 연산
- em.createQuery .executeUpdate()
- 영속성 컨텍스트 무시 = DB 직접 쿼
    = 벌크 연산 실행 후, 영속성 컨텍스트 초기화필요
    (JPQL 호출 전 flush 자동 호출되긴 한다. but 영속성 컨텍스트 clear가 이루어지지 않으므로 데이터가 남아있다. = JPQL 결과를 버린다...)
    = later, @Modifying above spring data jpa (= em.clear 자동호출)

     

