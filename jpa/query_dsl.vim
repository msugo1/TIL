# Q클래스 사용하기

ex. Member -> QMember

1. val qMember = QMember("m")
  = 별칭 직접 지정하기

2. val qMember = QMember.member
  = 기본 인스턴스 사용하기

3. static import
  -> 코틀린에서도 되려나?

# JPQL이 제공하는 모든 검색조건 제공 as codes!!! (can be checked in a compile time)
```
member.username.eq("member1") ## username == member1
member.username.ne("member1") ## username != member1

member.username.isNotNull() ## username IS NOT NULL

member.age.in(10, 20) ## age IN (10, 20)
member.age.notIn(10, 20) ## age NOT IN (10, 20)
member.age.between(10, 30) ## age BETWEEN 10 AND 30

member.age.goe(30) ## age >= 30
member.age.gt(30) ## age > 30
member.age.loe(30) ## age <= 30
member.age.lt(30) ## age < 30

member.username.like("member%") ## LIKE `member%`
member.username.contains("member") ## LIKE `%member%`
member.username.startWith("member") ## LIKE `member%`
```

# in where
1.

.where(member.username.eq("member1")
  .and(member.age.eq(10)))

2.

.where(
    member.username.eq("member1"),
    member.age.eq(10)
)

1, 2 모두 똑같이 동작
(2의 경우 중간에 null이 들어가면 무시)


# 서브쿼리 in QueryDSL
  = `com.querydsl.jpa.JPAExpressions`

example
```
    @Test
    fun subQueryIn() {

        val subMember = QMember("subMember")

        val result = jpaQueryFactory
            .selectFrom(member)
            .where(
                member.age.`in`(
                    JPAExpressions
                        .select(subMember.age)
                        .from(subMember)
                        .where(subMember.age.gt(10))
                )
            )
            .fetch()

        assertThat(result).extracting("age")
            .containsExactly(20, 30, 40)
    }

    @Test
    fun selectSubQuery() {
        val subMember = QMember("subMember")

        val result = jpaQueryFactory
            .select(
                member.username,
                JPAExpressions
                    .select(subMember.age.avg())
                    .from(subMember)
            )
            .from(member)
            .fetch()

        result.forEach { println(it) }
    }
```

* from 절의 서브쿼리 한계
- JPQL과 마찬가지로, from 절의 서브쿼리는 지원하지 않는다.
- Hibernate 구현체를 직접 사용해야 한다.
  or Native Query = JPA의 한계
  or Join으로 변경 (불가능한 경우도 있지만 일반적으로는 가능)
  or 쿼리를 2번 분리해서 실행

# 모든 로직을 DB SQL문에 맞추려다 보면 문제가 발생한다.
  - 쪼개서 가져와가지고 애플리케이션 단에서 짜맞추는 것은 어떨까?
  - in 안의 서브쿼리 등 성능에 문제가 생길 수 있는 경우도 많다.

SQL AntiPatterns

# Case
```
    @Test
    fun basicCase() {
        val result = qf
            .select(
                member.age
                    .`when`(10).then("열살")
                    .`when`(20).then("스무살")
                    .otherwise("기타")
            )
            .from(member)
            .fetch()

        result.forEach { println("s = $it") }
    }

    @Test
    fun complexCase() {
        val result = qf
            .select(CaseBuilder()
                .`when`(member.age.between(0, 20)).then("0 ~ 20살")
                .`when`(member.age.between(21, 30)).then("21살 ~ 30살")
                .otherwise("기타")
                )
            .from(member)
            .fetch()

        result.forEach { println("s = $it") }
    }
```

* 꼭 필요한지, 혹은 어플리케이션 단에서 처리하는 것이 더 적합한지 비교하고 결정하기

# 상수 or 문자더하기
```
    @Test
    fun constant() {
        val result = qf.select(member.username, Expressions.constant("A"))
            .from(member)
            .fetch()

        result.forEach { println(it) }
    }

    @Test
    fun concat() {
        val result = qf
            .select(member.username.concat("_").concat(member.age.stringValue()))
            .from(member)
            .where(member.username.eq("member1"))
            .fetch()

        result.forEach { println(it) }
    }
```

* `.stringValue()`
  - 문자가 아닌 다른 타입들을 문자로 변환
  - ENUM 처리할 때 자주 사용

# 프로젝션 결과반환
1. 대상이 하나인 경우
  = 해당 타입으로 반환

2. 대상이 둘 이상이면?
  = 튜플 or DTO로 조회

* 튜플은 query dsl의 타입이다.
  = 다른 계층이 요 객체타입을 알게하는 것은 좋은 설계가 아니다.
  = DTO에 필요한 값을 담아서 쓰는 것이 기본적인 설계

 
vs JPQL
```kotlin
    @Test
    fun findDTOByJPQL() {
        val result = em.createQuery(
            "select new study.querydsl.entity.MemberDTO(m.username, m.age) from Member m",
            MemberDTO::class.java
        )
            .resultList

        result.forEach { println(it) }
    }
```
- `select m.username, m.age FROM Member m` 등의 구문은 사용이 불가능하다. (타입이 다르기 때문에)
- 위 처럼 new study ~ 를 모두 붙여줘야 한다...
  = 패키지까지 다 적어야 하고, 생성자 방식만 지원한다.

in QueryDSL?
1. property 접근(Setter)
2. 필드 직접 접근
3. 생성자 사용

example
```kotlin
    @Test
    fun findDTOByJPQL() {
        val result = em.createQuery(
            "select new study.querydsl.entity.MemberDTO(m.username, m.age) from Member m",
            MemberDTO::class.java
        )
            .resultList

        result.forEach { println(it) }
    }

    @Test
    fun findDtoBySetter() {
        val result = qf
            .select(Projections.bean(MemberDTO::class.java, member.username, member.age))
            .from(member)
            .fetch()

        result.forEach { println(it) }
    }

    @Test
    fun findDtoByField() {
        val result = qf
            .select(Projections.fields(MemberDTO::class.java, member.username, member.age))
            .from(member)
            .fetch()

        result.forEach { println(it) }
    }

    @Test
    fun findDtoByConstructor() {
        val result = qf
            .select(Projections.constructor(MemberDTO::class.java, member.username, member.age))
            .from(member)
            .fetch()

        result.forEach { println(it) }
    }

    @Test
    fun findUserDto() {
        val result = qf
            .select(Projections.fields(UserDTO::class.java, member.username.`as`("name"), member.age))
            .from(member)
            .fetch()

        result.forEach { println(it) }

        // with subQuery
        val subMember = QMember("subMember")
        val anotherResult = qf
            .select(
                Projections.fields(UserDTO::class.java,
                member.username.`as`("name"),
                ExpressionUtils.`as`(JPAExpressions
                    .select(subMember.age.max())
                    .from(subMember),
                    "age")
                )
            )
            .from(member)
            .fetch()

        anotherResult.forEach { println(it) }
    }
```

* 주의
- 생성자 주입 시 position & type matching에 주의한다.

# @QueryProjection
- DTO에 대한 Qclass를 생성 -> 컴파일 시점에 오류를 잡아줄 수 있다.
```kotlin
    @Test
    fun findDtoByQueryProjection() {
        val res = qf
            .select(QMemberDTO(member.username, member.age))
            .from(member)
            .fetch()

        res.forEach { println(it) }
    }
```

- However...
  1. Q파일을 먼저 생성해야 한다.
  2. DTO자체가 POJO -> QueryDSL에 의존적인 클래스로 변경
    = 특히나 여러 곳에서 사용되는 DTO라면?
    = DTO가 깔끔하길 원하면 field 방식이 괜찮다. (실용적인 경우는 QueryProjection)

# 동적쿼리
1. BooleanBuilder
```
    @Test
    fun dynamicQuery_BooleanBuilder() {
        val usernameParam = "member1"
        val ageParam = null

        val result = searchMember1(usernameParam, ageParam)
        assertThat(result.size).isEqualTo(1)
    }

    private fun searchMember1(usernameCond: String?, ageCond: Int?): List<Member> {
        val builder = BooleanBuilder()
        /*
            초기 값도 지정이 가능하다.
            BooleanBuilder(member.username.eq(usernameCond))

            builder 또한 and/or 로 조립이 가능하다.
         */
        usernameCond?.let {
            builder.and(member.username.eq(it))
        }

        ageCond?.let {
            builder.and(member.age.eq(it))
        }

        return qf.selectFrom(member)
            .where(builder)
            .fetch()
    }
```
  - 값이 있는 변수만 동적으로 조건 생성
  - 초기 값도 지정이 가능하다.
    = BooleanBuilder(member.username.eq(usernameCond))
  - builder 또한 and/or 로 조립이 가능하다.

2. Where with multiple parameters
```
    @Test
    fun dynamicQuery_WhereParam() {
        val usernameParam = "member1"
        val ageParam: Int? = 10
        
        val result = searchMember2(usernameParam, ageParam)
        assertThat(result.size).isEqualTo(1)
    }

    private fun searchMember2(usernameCond: String?, ageCond: Int?): List<Member> {
        return qf
            .selectFrom(member)
            .where(usernameEq(usernameCond), ageEq(ageCond))
            .fetch()
    }

    private fun ageEq(ageCond: Int?) = ageCond?.let {
        member.age.eq(it)
    }

    private fun usernameEq(usernameCond: String?) = usernameCond?.let {
        member.username.eq(it)
    }

    private fun allEq(usernameCond: String?, ageCond: Int?) = usernameEq(usernameCond)?.and(ageEq(ageCond))
```
  - 조합해서 사용이 가능하다.
  - 다른 쿼리에서 해당 메소드 재사용 가능
  - 쿼리 자체의 가독성이 높아진다.

* 다만 null 체크는 주의해서 처리하자

# 수정, 삭제 벌크 연산
```
    @Test
    fun bulkUpdate() {
        val count = qf
            .update(member)
            .set(member.username, "비회원")
            .where(member.age.lt(28))
            .execute()
    }
```
  - 영속성 컨텍스트와 DB 의 값이 달라진다.
    why? 벌크 연산은 DB에 바로 쿼리를 날려버리기 때문

  - 조회 시
  ex. queryFactory.selectFrom(member).fetch()

    DB에서 값을 가져와도, 영속성 컨텍스트에 이미 값이 있는 경우에는 DB에서 조회된 값을 버린다.

   - 벌크 연산 실행 후에는 `em.flush(), em.clear()`를 호출하자
    = spring data jpa는 자동적으로 날리는 옵션 제공

# SQL function 호출
  - JPA와 같이 Dialect에 등록된 내용만 호출할 수 있다.
  - 자주 호출하는 function은 내장되어 있다.

# QueryDSL + Spring Data JPA
  
* 사용자 정의 리포지토리
  - Spring Data JPA works based on interface
  - QueryDSL requires implemented codes

  Then,

1. 사용자 정의 인터페이스 작성
2. 사용자 정의 인터페이스 구현
3. 스프링 데이터 리포지토리에 사용자정의 인터페이스 상속
 

* 페이징
- Pageable pageable 사용 (with PageRequest.of)
- count 쿼리를 함께 날리거나, count만 따로 날리거나(최적화가 필요한 경우)
  = count 쿼리가 생략가능하면 생략해서 처리
  ex. 페이지 시작 & 컨텐츠 사이즈 < 페이지 사이즈
      마지막 페이지일 때 (offset + 컨텐츠 사이즈)

```kotlin
override fun searchPageComplex(condition: MemberSearchCondition, pageable: Pageable): Page<MemberTeamDTO> {
  val content = queryFactory
    .select(
        QMemberTeamDTO(
          member.id.`as`("memberId"),
          member.username,
          member.age,
          team.id.`as`("teamId"),
          team.name.`as`("teamName")
          )
        )
    .from(member)
    .leftJoin(member.team, team)
    .where(
        usernameEq(condition.username),
        teamNameEq(condition.teamName),
        ageBetween(condition.ageGoe, condition.ageLoe)
        )
    .offset(pageable.offset)
    .limit(pageable.pageSize.toLong())
    .fetch()

    val countQuery = queryFactory
    .select(member)
    .from(member)
    .leftJoin(member.team, team)
    .where(
        usernameEq(condition.username),
        teamNameEq(condition.teamName),
        ageBetween(ageGoe = condition.ageGoe, ageLoe = condition.ageLoe)
        )

    return PageableExecutionUtils.getPage(content, pageable) {
      countQuery.fetchCount()
    }
}
```
= `PageableExecutionUtils` 사용 시, 카운트 쿼리가 불필요하면 날아가지 않음

# 스프링 데이터 정렬
  - 스프링 데이터 JPA는 자신의 정렬(Sort)를 QueryDsl의 정렬(OrderSpecifier)로 편리하게 변경하는 기능제공
    = join 들어가고 복잡해지면 사용하기 힘듦

# 스프링 데이터가 제공하는 QueryDsl 기능
  - 제약이 커서 복잡한 실무 환경에서는 사용하기 많이 부족

  1. QueryDslPredicateExecutor
  - 조인 불가능(묵시적 조인 외 left join은 불가능)
  - 클라이언트 코드가 QueryDsl에 의존해야 한다.
    = 변경 시 DAO 코드를 직접 고쳐야 한다.

  2. QueryDsl Webl
  - 지나치게 복잡함(단순한 조건만 처리가능)
  - 컨트롤러가 QueryDsl에 의존
  : 복잡한 실무환경에 부적합하므로 권장X

  3. QuerydslRepositorySupport

  장점
  - getQueryDsl().applyPagination() 
    = 스프링 데이터가 제공하는 페이징을 Querydsl로 편리하게 변환가능
    (sort는 오류발생 주의!)

  - from()으로 시작가능
    (최근에는 queryFactory를 사용해서 `select`로 시작하는 것이 더 명시적)

  - entityManager 기본제공

  단점
  - querydsl 3.x 버전 대상 (4.x에 나온 jpaQueryFactory로 시작할 수 없음)
    = from으로 시작
  - queryFactory를 제공하지 않음
  - 스프링데이터 sort 기능이 정상동작하지 않음

# QueryDsl 지원 클래스 Customization

* 장점
- 스프링 데이터가 제공하는 페이징을 편리하게 변환
- 페이징과 카운트 쿼리 분기가능
- 스프링 데이터 Sort 지원
- `select()`, `selectFrom()`으로 시작가능
- `EntityManager`, `QueryFactory` 제공


