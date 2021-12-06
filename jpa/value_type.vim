# JPA 데이터 타입 분류
1. 엔티티 타입
- 객체 defined with `@Entity`
- 데이터가 변해도 식별자로 지속해서 추적가능

2. 값 타입
- int, Integer, String 등 단순히 값으로 사용하는 자바 기본타입이나 객체
- 식별자 X, 값만 존재하므로 변경 시 추적불가

    2 - 1. 기본값 타입(primitive, wrapper for primitive, String)
        = 생명주기를 엔티티에 의존
        = 값 타입은 공유하면 안됨! (회원 이름 변경 시, 다른 회원들의 이름까지 변경되어 버린다면??) 
        = 기본 타입은 애초에 공유되지 않는다.
        = 래퍼 클래스 or String 클래스는 공유 가능한 객체이지만, immutable

    2 - 2. 임베디드 타입(복합 값 타입)
        = 새로운 값 타입을 직접 정의할 수 있음
        = 복합 값 타입 (기본 값 타입들을 모아서 만드므로)
        = 값 타입이므로 변경 시 추적불가
            
        `@Embedded` - 사용하는 곳
        `@Embeddable` - 정의하는 곳
        (기본생성자 필수)

        * 장점
        1) 재사용
        2) 높은 응집도
        3) `Period.isWork()` 처럼 해당 값 타입만 사용하는 의미있는 메소드를 만들 수 있음

        = 임베디드 타입을 사용하기 전/후로 매핑하는 테이블은 같다.
        = 객체와 테이블을 아주 세밀하게 매핑하는 것이 가능하다. 
        = Embedded 타입 값 자체가 null이면 매핑된 모든 값은 null!
    2 - 3. 컬렉션 값 타입

NOTE
`@AttributeOverride`
- 한 엔티티에서 같은 값 타입을 사용한다면?
    = 칼럼명이 중복됨
- here, `@AttributeOverride, @AttributeOverrides` comes to the rescue

```
@Embeddable
class Address {
    val zipCode: String? = null,
    val street: String? = null,
    val city: String? = null
}

@Embedded
val homeAddress: Address

@Embedded
@AttributeOverrides({
    @AttributeOverride(name="city", column=@Column(name = "work_city"))
    @AttributeOverride(name="street", column=@Column(name = "work_street"))
    @AttributeOverride(name="zipcode", column=@Column(name = "work_zipcode"))
})
val workAddress: Address
```

# 값 타입은 단순하고 안전하게 다룰 수 있어야 한다.
- `Embedded` 같은 값 타입을 여러 곳에서 공유하면 위험 (참조가 전달되는 객체이므로...)
    = 연쇄적으로 공유한 객체의 값이 다 바뀌어 버린다.
    = 공유해서 사용하고 싶으면 값 타입이 아닌, 엔티티 타입이 필요하다.
    = 아니면 값을 복사해서 사용
    (
        ex. val address = Address("city", "street", "zipcode")
            val copyAddress = Address(address.city, address.street, address.zipCode)
    )

- 객체의 공유참조는 피할 수 없다...
    = 객체 타입을 수정할 수 없게 만들어야, 부작용을 원천 차단할 수 있다.
    ex. 값 타입을 immutable object로 설계하기
    (no setter = val in Kotlin)
    = 값을 수정하려면 해당 타입의 객체를 통으로 변경해야 한다.

# 값 타입의 비교
- 인스턴스가 달라도 그 안에 값이 같으면 같다고 봐야한다.

객체 타입은?
    val a = Address("서울")
    val b = Address("서울")

    a == b - false basically (with different references)

- but for Embedded types (값 타입) cases like above should be true
    = equals 메소드를 적절하게 재정의할 필요가 있다.

# 값 타입 컬렉션
- RDB는 기본적으로 컬렉션 표현 불가
    = 별도의 테이블로 추출해야 함

Member
id (PK) - FAVOURITE_FOOD (member_id(pk, fk), food_name(pk))
        - ADDRESS (member_id(pk, fk), city(pk), street(pk), zipcode(pk))

ex
```
@Entity
class Member {

    ...

    @ElementCollection
    @CollectionTable(
        name = "FAVOURITE_FOOD"
        joinColumns = @JoinColumn(name = "member_id")
    )
    @Column(name = "FOOD_NAME")
    favouriteFoods: Set<String> = HashSet()

    ...
}
```
- 값 타입 컬렉션은 라이프 사이클이 의존적
    = 영속성 전이 + 고아객체 제거 기능을 필수로 가진다.
- 값 타입 컬렉션도 지연로딩 전략 사용

* 수정 example with Set<Address>
val address1 = Address("old1", "street", "10000")
- 요 객체를 먼저 지워야 한다. from the Set
- equals, hashCode가 제대로 override 되어 있어야 remove(address1)이 가능하다.
(제대로 안되어있으면 x망)
- 이후 새로운 Address 객체를 만들어 넣는다.

*** in query
- 컬렉션을 모아둔 테이블의 관련 데이터를 모두 삭제 후 다시 삽입
(통째로 갈아끼는 느낌)

WHY??

# 값 타입 컬렉션 제약사항
- 값 타입은 엔티티와 다르게 식별자가 없다.
    = 값을 변경하면 추적이 어려움
    = 따라서, 변경발생 시, 주인 엔티티와 연관된 모든 데이터 삭제 후 새롭게 현재 컬렉션에 있는 값을 모두 다시 저장
- @OrderColumn(name = "address_history_order")을 넣어서 위 현상을 방지할 수 있으나...
    = 매우 위험하다. (일단 동작 자체가 예측이 안된다.)
    = 중간 order가 비어있으면 또 문제가 된다. (ex. 0, 1, 2, 3에서 2가 사라지면 0, 1, null, 3 == possible NPE)

(
    why don't you consider 1:N relations instead
    - promote the value type object to an entity
    ex
    class AddressEntity {
        @Id
        @GeneratedValue
        var id: Long = 0,

        var address: Address
    }
    
    then in Member
    class Member {
        ...              @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
                         @JoinColumn("member_id")
        List<Address> -> List<AddressEntity>
    }
)

- 값 타입 컬렉션을 매핑하는 테이블은 모든 컬럼을 묶어서 PK 구성필요
(NOT NULL & UNIQUE as well)

* 값 타입 컬렉션은 진짜 단순할때만 사용하자!
    = 왠만하면 엔티티로!!!!
    (식별자가 필요하고, 지속적으로 값을 추적/변경해야 한다면 그것은 값 타입이 아니라 엔티티다.)

* hashcode, equals override 시 주의점
- getter를 사용해서 값을 가져와야 한다.
    = 프로퍼티를 직접 사용하면, proxy 사용 시 값 계산이 안된다고 한다.
    (getter 호출 시에는 getter 를 통해 실제 객체로 접근? 한다고 한다.)
