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
