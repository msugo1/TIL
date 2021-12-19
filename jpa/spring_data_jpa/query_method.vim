1. 메소드 이름으로 쿼리 생성!
ex. findByUsername, findByEmail, findByUsernameAndAgeGreaterThan...
- 원래는 JPQL로 메소드를 구현해야 하지만 - spring data jpa magic!
- 여러 종류가 있으며 공식문서를 참고하자

NOTE
- 엔티티 필드명 변경 시 메소드 이름도 필수로 교체해줘야 한다.

2. `@NamedQuery`
- 실무에서 쓸일은 크게 많지 않다고 한다.

ex.
@Entity
@NamedQuery(
    name = "Member.findByUsername",
    query = "SELECT m FROM Member m WHERE m.username = :username"
        )

... to repository

fun findByUsername(username: String) {
    return em.createNamedQuery("Member.findByUsername", Member::class.java)
        .setParameter("username", username)
        .resultList
}
- 관례가 있어서 @Query or even 구현 없이도, 이름만 같다면 바로 동작한다.
- 자주 쓰진 않지만, 애플리케이션 로딩 시점에 쿼리를 실행해서, 잘못된 부분을 잡아줄 수 있다는 장점

3. `@Query`
- 리포지토리에 바로 쿼리 정의가능
- 얘도 로딩시점에 쿼리 파싱해서 오류 잡아준다.
(이름 없는 네임드 쿼리)

* 컬렉션도 파라미터 바인딩이 가능하다.
ex.
@Query("SELECT m FROM Member m where m.username in :names")
List<Member> findByNames(@Param("names") names: List<String>)

# flexible return types
memberRepository.findMemberByUsername
    = it can return one member, members, optional ...
    = or even more
    = refer to the official document please

# Paging with JPA
1. pure JPA
ex.
```
fun findByPage(age: Int, offset: Int, limit: Int): List<Member> {
    return em.createQuery("SELECT m FROM Member m WHERE m.age = :age order by m.username desc", Member::class.java)
        .setParameter("age", age)
        .setFirstResult(offset)
        .setMaxResults(limit)
        .resultList
}

fun totalCount(int age): Long {
    return em.createQuery("SELECT count(m) FROM Member m WHERE m.age := age", Long::class.java)   
        .setParameter("age", age)
        .singleResult
}
```

2. with Spring Data Jpa
    + Sort, Pagable: 정렬 & 페이징

* Page: limit & offset
    vs Slice: cursor (내부적으로 limit + 1 조회)

```
fun findByAge(age: Int, pageable: Pageable): Page<Member>   

    + PageRequest.of(0, 3, Sort.by(Sort.Direction.DESC, "username")) # 0부터 페이지 시작
        = totalCount 쿼리 별도필요X -> 얘가 직접보냄!
```

Paging 시 count query를 별도로 지정할 수 있다.
    = could be useful when count query does not have to be as complicated

* entity to dto with Page
    = page.map(member -> MemberDto(member.id, member.username, ... ))


# 벌크성 수정쿼리
    fun bulkAgePlus(age: Int): Int {
        return em.createQuery("update Member m set m.age = m.age + 1 where m.age >= :age")
            .setParameter("age", age)
            .executeUpdate()
    }
    
       @Modifying # update 시 modifying 필요
       @Query("update Member m set m.age = m.age + 1 where m.age >= :age") 
    => fun bulkAgePlus(@Param("age") age: Int): Int

- 벌크 연산은 DB에 direct로 쿼리 날림
    = 영속성 컨텍스트의 것들은 수정사항이 반영 안된 상태
    = 부정합!
    = therefore, em.flush, em.clear 호출해서 영속성 컨텍스트 초기화 필요(혹시 그 다음에 로직이 있다면)

    or @Modifying(clearAutomatically = true) 설정으로 똑같은 동작가능


@EntityGraph
- 연관된 엔티티들을 한번에 조회하는 방법

ex.
@EntityGraph(attributePath = {"team"})
override fun findAll(): List<T>

- JPQL에 덧붙여 사용가능!
    or @NamedEntityGraph도 존재 (자주 쓰이지는 않는다.)
    = 쿼리가 복잡해지면 결국 JPQL을 직접 사용해야 한다...


# JPA Hint & Lock
- SQL Hint X, JPA 구현체에게 제공하는 힌트

ex. readOnly hint
    = 조회용으로만 사용할거다. 변경감지 동작하지 말아라!

    @QueryHints(value = @QueryHint(name = "org.hibernate.readOnly", value = "true"))
    fun findByUsernameReadOnly(username: String)
    = 내부적으로 스냅샷 만들지 않는다. (자체 성능 최적화)
    = 얻을 수 있는 이점은 많지 않을 수 있다; (성능 테스트를 해보고 사용)
 
# Lock

@Lock(LockModeType.PESSIMISTIC_WRITE or READ) # or OPTIMISTIC_..
 fun findByUsernameWithLock(username: String)


