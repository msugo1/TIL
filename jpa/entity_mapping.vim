# object <-> table
`@Entity`
- JPA가 관리
- 기본 생성자 필수(코틀린은 자체적으로 if-else 를 통해 해결)
- final, enum, interface, inner 클래스에는 사용X
(kotlin needs all open! (spring jpa does the job though automatically)

NOTE
1. add a unique constraint
ex.
```
@Table(uniqueConstraints = {@UniqueConstraint
    name = "NAME_AGE_UNIQUE",
    columnNames = {"NAME", "AGE"}
})
```

2. add column properties
ex.
```
@Column(unique = true, length = 10)
```
- but, @Column(unique = ) 는 자주 사용하지 않는다.
    why? 이름이 랜덤하게 나오므로... 효율성이 떨어진다. (별도 이름을 두는게 맞다 for maintanence in production)
    = 1 방식으로 두면 이름 매핑도 가능!

3. even precision, and scale for BigDecimal
    - precision: 전체 자릿수
    - scale: 소수점 수
    (Converter와 차이가 뭘까?)

`@Temporal`
- LocalDate, LocalDateTime은 `@Temporal` 생략가능

# PK 매핑
NOTE
1. IDENTITY
- DB에 들어가야 PK 값을 알 수 있다.
    = JPA 입장에서 자체적으로 PK를 알 수 있는 방법 없음 
- 따라서, 영속 상태가 되자마자 DB에 쿼리날림 (PK 찾으려고)
    = 이렇게 ID를 가져온다...
- 지연 쓰기가 불가능하다.
- 일반적으로는 성능에 큰 영향이 있지는 않지만, 배치 INSERT 시 성능 문제가 발생하더라;
    = SEQ로 대체하는 방법 등이 있다. (only if it is possible)
    (SEQ는 채번 사이즈를 미리 증가시킬 수 있으므로)


