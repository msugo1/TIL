JPQL, Criteria, QueryDSL
- JPQL: 엔티티를 중심으로 검색 쿼리를 작성할 수 있게 도와준다.
(JPQL -> SQL로 JPA가 자동번역)
    = but, String으로 쿼리를 넣기 때문에, 실수위험 증가
    = and 동적쿼리 작성이 힘들다.

- Criteria: 자바코드로 쿼리작성가능
    = but, 가독성이 떨어진다..... (유지보수가 힘들어진다. 실용성X)
    = QueryDSL 사용하자 그냥;

- QueryDSL: JPQL, Criteria의 단점 상쇄
    = 코드로 작성하기 때문에, 오타가 있으면 컴파일 시점에 잡아줄 수 있다.
    = 동적쿼리를 만들기 쉽다.
    = 분리를 통해 재사용도 가능하다.
    = 실제 쿼리와 비슷해서, 가독성이 좋다.
    (설정이 빡세지만, 요거를 제일 추천!)
    * JPQL 바탕이기 때문에, 일단 JPQL을 잘 알아야 한다.

- Native SQL: JPA가 제공하는 SQL을 직접 사
    = 특정 DB에 의존
    = JPA로는 해결이 불가능한 쿼리에 사용가능
    = em.createNativeQuery()

- 외에도 JDBC or MyBatis 등 조합해서 사용가능
    = 영속성 컨텍스트를 적절한 시점에 강제 플러쉬 해줘야 한다.
    (JPA와 관련없는 기술이기 때문에 JPA가 auto flush 해주지 않는다.)
    
# JPQL 
: Java Persistence Query Language

* Basic
- JPQL = 객체지향 쿼리 언어
    means, 테이블 대상 쿼리X but 엔티티 객체 대상 쿼리O
- SQL 추상화로, 특정 DB에 종속X
- JPQL은 결국 SQL로 변환된다

# JPQL 문법
    select_문 :: =
        select_절
        from_절
        [where_절]
        [groupby_절]
        [having_절]
        [orderby_절]

    update_문 :: = update_절[where_절]
    delete_문 :: = delete_절[where_절]

ex. select m from Member as m where m.age > 18
- 엔티티와 속성은 대소문자 구분O (Member, age)
- JPQL 키워드는 대소문자 구분X(SELECT, FROM, where)
- 엔티티 이름 사용(테이블 이름X)
- 별칭 필수(as 생략가능)

# 집합과 정렬
select 
    COUNT(m),
    SUM(m.age),
    AVG(m.age),
    MAX(m.age),
    MIN(m.age)
from Member m

# TypeQuery vs Query
- TypeQuery: 반환 타입이 명확할 때
- Query: 명확하지 않을 때

# 결과 조회 API
- query.getResultList()
    = 결과가 하나 이상일 때, 리스트 반환
    (없으면 emptyList)

- query.getSingleResult()
    = 결과가 정확히 하나, 단일 객체 반환
    (없으면 NoResultException, 둘 이상이면 NonUniqueResultException)

# 파라미터 바인딩
- 이름 기준으로 사용하자 (위치 기준보다 명확)

# Projection
: SELECT 절에 조회할 대상 지정
(대상 - 엔티티, 임베디드 타입, 스칼라 타입(숫자, 문자 등 기본 데이터 타입))

- 엔티티 프로젝션 시, 모두 영속성 컨텍스트에서 관리된다.
- 임베디드 타입은 `속해 있음`
    = 자체적 쿼리 불가 (ex. select a from Address as a, Address::class.java 불가능!!!)
    = 대신, select o.address from Order o, Address:class.java 는 가능!
- Distinct로 중복제거 가능

* 여러 값 조회 시, 
    1. Query 타입으로
    2. Object[] 타입으로
    3. new 명령어 with DTO 타입으로
조회가 가능하다.
    = 3번이 제일 낫다.
    (But, with pure JPQL, 패키지 포함한 전체 클래스 명이 들어가야 한다. && 순서와 타입이 일치하는 생성자가 필요하다...)
    = QueryDSL로 커버가 가능

# Paging
- setFirstResult(int startPosition): 시작 위치, setMaxResult(int maxResult): 조회할 데이터 수
    로 추상화가 되어있다.
ex. em.createQuery("select m from Member m order by m.age desc", Member::class.java)
        .setFirstResult(0)
        .setMaxResult(10)
        .getResultList()

# Join
: 객체를 중심으로 조인

1. innerJoin
ex. select m from Member m [inner] join m.team t

2. outerJoin
ex. select m from Member m left [outer] join m.team t

3. theta join
ex. select count(m) from Member m, Team t where m.username = t.name

* Join with On(since JPA 2.1)
1. 조인대상 필터링
2. 연관관계 없는 엔티티 외부조인(since Hibernate 5.1)

ex.
1.
JPQL - select m, t from Member m left join m.team t on t.name = "A"
SQL - select m.*, t.* from member m left join team t on m.team_id = team.id and t.name = "A"

2.
JPQL - select m, t from Member m left join Team t on m.username = t.name
SQL - select m.*, t.* from member m left join team t on m.username = t.name

# Subquery
ex. select m from Member m where m.age > (select avg(m2.age) from Member m2)
select m from Member m where (select count(o) from Order o where m = o.member) > 0

* JPA 서브쿼리의 한계
- 표준: Where, Having 절에서만 서브쿼리 사용가능
(Hibernate: Select 절도 지원)
- From 절의 서브쿼리는 현재 JPQL에서 불가능
    = 조인으로 풀 수 있으면, 풀어서 해결하자!
    = 아니면 Native Query
    = or even just resolve them on an application level 
    (from 절의 서브쿼리는 사실, SQL 자체에 로직이 있는 경우가 많다. = 요거를 애플리케이션 단에서 처리하자)

# JPQL 타입표현
- ENUM: ex. jpabook.MemberType.Admin(패키지 명 포함)
    in JPQL = select m.username from Member m where m.type = jpql.MemberType.Admin
    (파라미터 바인딩으로 해결가능)      
    m.type =: userType
    JPQL
        .setParameter(userType, MemberType.Admin)


- 엔티티 타입: ex. TYPE(m) = Member(상속 관계에서 사용)
    in JPQL = select i from Item i where type(i) = Book, Item::class.java
    (Book에 지정된 @DiscriminatorValue를 자동으로 검색조건에 활용)

# CASE 식
1. 단순 case
2. 기본 case
3. coalesce
- 하나씩 조회해서 null이 아니면 반환
ex. select coalesce(m.username, "no name member") from Member m

4. nullif
- 두 값이 같으면 null, 다르면 첫 번째 값 반환
ex. select NULLIF(m.username, "관리자") from Member m

# JPQL 함수
- 기본적으로 제공하는 함수들 (ex. concat, substring ...)
- 사용자 정의 함수
    Hibernate는 사용전 방언에 추가 필요

    ex.
    clas MyDialect : MySQLDialect() {
        select function('group_concat', i.name) from Item i
    }
    
