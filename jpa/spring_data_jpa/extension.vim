# custom repository
1. create an interface
2.  ..       class for implementation

example
```kotlin
interface MemberRepositoryCustom {
    fun findMemberCustom(): List<Member>
}

class MemberRepositoryImpl : MemberRepositoryCustom {
    override fun ... 구현
}

    + 기존 Repository에 구현 추가

interface MemberRepository : JpaRepository<Member, Long>, MemberRepositoryCustom
...
```

주의: 실제 인터페이스 Repository (위에서는 MemberRepository) + Impl 으로 이름을 맞춰야 한다.
    = spring data jpa가 인식해서 알아서 처리해줌


# Auditing
- 엔티티를 생성, 변경할 때 변경한 사람과 시간 추적
    = 등록일, 수정일, 등록자, 수정자

1. with Pure JPA
```kotlin
@MappedSuperClass
class JpaBaseEntity {
    @Column(updatable = false)
    var createdDate: LocalDateTime = LocalDateTime.now()

    var updatedDate: LocalDateTime = LocalDateTime.now()

    @PrePersist
    fun prePersist() {
        val now = LocalDateTime.now()
        createdDate = now
        updatedDate = now
    }

    @PreUpdate
    fun preUpdate() {
        updatedDate = LocalDateTime.now()
    }
}

class Member : JpaBaseEntity()
```

2. with spring data jpa
    1) @EnableJpaAuditing
        then

    2) @CreatedDate, @LastModifiedDate
    ```
    @EntityListener(AuditingEntityListener::class.java)
    @MappedSuperClass
    class BaseEntity
    ...
    @CreatedDate
    @Column(updatable = false)
    var createdDate: LocalDateTime

    @LastModifiedDate
    var LastModifiedDate: LocalDateTime
    ```

    or even more (등록자, 수정자)
    ```
    @CreatedBy
    @Column(updatable = false)
    var createdBy: String
    
    @LastModifiedBy
    var LastModifiedBy: String

        + 추가 설정
        @Bean
        fun auditorProvider(): AuditorAware<String> = {
            UUID.randomUUID.toString()
        }
        
    ```

# Domain Class Converter
    ```
    @GetMapping("/members/{id}")
    fun findMember(@PathVariable member: Member): String {
        return member.name
    }
    ```
    = 스프링 부트가 PK를 사용해 자동 바인딩해준다.
    = 권장X

    * 단순 조회용으로만 사용해야 한다.
    - 트랜잭션 X = 변경이 DB에 반영되지 않음(OSIV가 있긴 한데... 굳이 이렇게 복잡하게 여기서 수정할 필요가 있나)


# 페이징과 정렬
- web에서 자동바인딩 제공
    ```
    @GetMapping("/members")
    fun list(pageable: Pageable): Page<Member> {
        return memberRepository.findAll(pageable)
    }
    ```
    http:// ~ ?page= &size= &sort= 

- page default: 20

  * how to change?
    in yml
    spring.data.web.pageable.default-page-size: 10  
    spring.data.web.pageable.max-page-size: 2000

    or with annotation
    @PaeableDefault(size = 5, sort = "username") pageable: Pageable

- 페이징 정보가 둘 이상이면 `접두사`로 구분
- Page를 1부터 시작하기
    1) Pageable, Page를 파라미터와 응답값으로 사용하지 않고 직접 클래스 만들어서 처리
        ex. PageRequest.of(page = 1, size = )
                then, process it with another custom class
    2) spring.data.web.pageable.one-indexed-parameters: true
        = 한계: 나머지 데이터들은 page = 0임을 가정하고 동작. 따라서, pagenumber, number 데이터가 맞지 않는다.
