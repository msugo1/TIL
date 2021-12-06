* 사용하지도 않는 객체를 연관관계가 있다고 해서, 무조건 가져와야 할까?
- NOPE. 조회를 뒤로 미룰 수 있다.
- core: `em.getReference()` = 조회를 미루는 가짜 객체(프록시) 반환

# Proxy in JPA
- 실제 클래스를 상속받아서 만들어짐
- 실제 클래스와 겉 모양이 같다.
    = 사용하는 입장에서는 (이론상) 진짜/프록시 구분없이 사용

* proxy -> proxy.property -> request init to Persistent Context -> DB query -> create a real entity -> return the property now

- 처음 사용 시 한번만 초기화
- 프록시 객체 초기화 시, 프록시 객체가 실제 엔티티로 바뀌지 않는다!
    = 참조로 접근 가능할 뿐
(매우 중요!)
- 프록시 = 원본객체 상속 = `==` 비교하면 당연히 false
    = `instanceOf` 사용해야 한다.
- 영속성 컨텍스트에 있다면, 프록시 호출해도 원본이 나간다.
    = 심화: 사실 jpa가 신경쓰는 것은, 한 영속성 컨텍스트에서 m1(id = 1), m2(id = 1)로 아이디가 같다면 m1 == m2 만족해야 한다.
    = 따라서... `em.getReference(Member::class.java, member1.id)`로 프록시 조회 후, em.find(Member::class.java, member1.id) 로 실제 엔티티 조회하면 뒤에꺼는 버려진다.

**** 준영속 상태일 때, 초기화 불가 (영속성 컨텍스트 관리대상이 아니므로)
(LazyInitializationException)

# 프록시 확인
1. 프록시 인스턴스의 초기화 여부 확인
`PersistenceUnitUtil.isLoaded(entity: Any)`
= from EntityManagerFactory

2. 프록시 클래스 확인
`entity.javaClass.name`

3. 프록시 강제 초기화
`org.hibernate.Hibernate.initialize(entity)`
(JPA 표준은 강제 초기화 없음)


# 즉시로딩 vs 지연로딩
```
@Entity
class Member {

    ...
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn
    team: Team
}
```
위 지연로딩(vs 즉시로딩: FetchType.EAGER)

*** 실무에서는 즉시로딩을 쓰면 안된다. ***
- 예상치 못한 SQL이 발생할 수 있다.
- 즉시 로딩은 JPQL에서 N+1 문제를 일으킨다.
    = JPQL은 SQL로 번역된다.
    ex. em.createQuery("SELECT m FROM Member m", Member.class)
    = 멤버만 가져오는 쿼리, but Team이 즉시로딩으로 설정되어 있으면 Team도 가져와야 하므로 Member 먼저 조회 후, Team을 셀렉트하는 쿼리가 나가게 된다. (EAGER은 일단 무조건 값을 채워줘야 하므로..., LAZY 였으면 프록시를 넣어도 됬다.)

NOTE: @ManyToOne, @OneToOne 기본이 즉시로딩
    = LAZY 로 설정하자
(일단 LAZY 로딩을 기본으로 깔고가자)



