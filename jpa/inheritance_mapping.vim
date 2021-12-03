# 상속관계 매핑
- RDBMS는 상속관계가 없다!
    = 슈퍼타입 & 서브타입 모델링 기법이 그나마 유사
- 객체의 상속 구조와 DB의 슈퍼타입-서브타입 관계를 매핑하는 것

# 구현 방식
1. 조인 전략
Item - Album, Movie, Book

Item: id, name, price, d_type
Album: item_id, artist
Movie: item_id, director, actor
Book:  item_id, author, isbn

= insert 2번
= 조인으로 데이터 가져오기!
= d_type 과 같은 구분에 필요한 타입 값을 두어 각 타입 구분!

2. 단일테이블 전략
- 모든 것은 하나로!

3. 구현 클래스마다 별도의 테이블
- 각 클래스별로 테이블 하나씩 만들기

* 어떤 방식을 사용하더라도 매핑이 가능하다.
= 기본 전략은 Single Table!

# 사용법
```
1.
@Entity
@Inheritance(strategy = Inheritance.JOINED)
(@DiscriminatedColumn - 엔티티 명이 들어간다! by default = DType, 왠만하면 넣어주자 - DB 상으론 source가 구분이 안된다.)
class SuperClass {
    ...
}
```
= 자식 클래스에서 `@DiscriminatorValue( ...  )` 을 통해 저장되는 값을 바꿀 수 있다. (by DiscriminatedColumn)

2.
@Inheritance(strategy = Inheritance.SINGLE_TABLE)
= `DType`이 무조건 생긴다 (even without @DiscriminatedColumn)

3. 
@Inheritance(strategy = Inheritance.TABLE_PER_CLASS)
abstract class Item  

얘에 대한 클래스는 안만들어짐
- 하위 클래스 테이블만 만들어짐
- @DiscriminatedColumn 이 필요가 없다!

# 각각의 장단점?
1.
+: 가장 정규화됨!, 외래키 참조 무결성 제약조건 활용가능, 저장공간 효율화
-: 조인!(성능 저하), 조회 쿼리가 복잡, 저장 시 Insert 2번 호출... (다른 건 사실 다 괜찮은데, 조회 쿼리가 복잡한게 문재라고 한다)
(정석)

2. 
+: 성능(조인 필요없음), 단순한 쿼리
-: 자식 엔티티가 매핑한 컬럼은 모두 NULL을 허용해야 한다. (다른 타입의 자식인 경우 해당 값을 채우지 못하므로)
    테이블이 매우 커질 수 있다.(단일 테이블에 모든 것을 넣으므로), 상황에 따라서 오히려 조회 성능이 나빠질 수 있다.(임계점을 넘은 경우만 - 거의 없다고 한다.)

3.
+: 서브 타입을 명확하게 구분해서 처리 가능, not null 제약조건 사용가능
-: 가져올 때 망한다.... UNION ALLLLL (아이디가 명확하지 않으므로;;), 변경이라는 관점에서 매우 좋지 않음
    = 쓰지 말자!

# @MappedSuperclass
- 매핑정보 상속
    = 공통 매핑정보가 필요할 때(Base Entity)
    (중복된 매핑의 효율적인 제거)
- 해당 어노테이션이 붙어있으면 테이블 생성하지 않음!
    = but still @Column 사용해서 컬럼이름 변경가능!
- 조회, 검색 불가
- 직접 생성할 일이 없으므로 abstract!
