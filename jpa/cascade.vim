# 영속성 전이
- 특정 엔티티를 영속 상태로 만들 때, 연관된 엔티티도 함께 영속상태로 만들고 싶은 경우
    ex. 부모 1 저장시 자식 N도 함께

ex.
```
@Entity
class Parent {
    ...
    @OneToMany(mappedBy = "parent")
    var children: List<Child>
}

@Entity
class Child {
    ...
    @ManyToOne
    @JoinColumn(name = "parent_id")
    val parent: Parent
}

...
val child1 = Child()
val child2 = Child()

val parent = Parent()
parent.addChild(child1)
parent.addChild(child2) # done by 연관관계 편의 메소드
```
- 원래라면 em.persist 세번 호출 필요
- parent가 중점이라면 Cascade 를 통해 영속성 관리
    = @OneToMany(mappedBy = "parent", cascade = CascadeType.ALL)
    = 한 번에 모두 영속화

# 주의
- 영속성 전이는 연관관계 매핑과 아무런 관련이 없음
    = 단순히 영속화를 함께하는 편의 제공

# 속성
1. ALL: 모두 적용
2. PERSIST: 영속 시만 Cascade 적용
3. REMOVE: 삭제 시만
4. MERGE: 병합 시만
5. REFRESH
6. DETACH 
(1, 2만 주로... 실무에서는 자주 사용하지 않는다 함)
= 특히 여러 엔티티와 연관되어 있는경우 사용하면 안된다!!!
(단일 엔티티에 종속적인 경우만 사용하자)

# 고아 객체
- 고아객체 제거: 부모 엔티티와 연관관계까 끊어진 자식 엔티티 자동삭제
`orphanRemoval`
= @OneToMany(mappedBy = "parent", cascade = CascadeType.ALL, orphanRemoval = true)
= 참조가 제거된 엔티티는 다른 곳에서 참조하지 않는 고아객체로 보고 삭제하는 기능
(참조하는 곳이 하나일 때만 사용해야 한다!!!) = 개인소유

- @OneToOne, @OneToMany 만 사용가능
(개념적으로 부모를 제거하면 자식은 모두 고아가 된다. 따라서, orphanRemoval=true 로 지정한 경우, 해당 부모의 자식객체들이 모두삭제된다.)
    like CascadeType.REMOVE


