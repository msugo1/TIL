# Table <-> Object, 패러다임의 불일치
- 테이블은 `외래키`로 Join to find a related table
    = 방향이라는 개념 X
- 객체는 `참조`!
    = 참조 필드가 있는 쪽으로만 참조가능

```
ex. Member(n) : Team(1)

(단방향)
class member {

    @manytoone # fetch: lazy or eager
    @joincolumn("team_id")
    team: team
}

class team {


}

(양방향)
class member {

    @manytoone # fetch: lazy or eager
    @joincolumn("team_id")
    team: team
}

class team {

    @OneToMany(mappedBy = "member_id")
    member: MutableList<Member> = ArrayList()
}
```
* mappedBy
- 나는 여기에 매핑에 되어 있다!

양방향 in 객체
- actually, 단방향 2(Member to Team, and Team to Member)
- Then, in a table, where should FK be managed? dilema
    = Member의 Team 값을 바꿔야 할까? 혹은 Team의 값을 직접 바꿔야할까?

* Rule
- 둘 중에 하나를 `주인`으로(연관관계의 주인)
- 주인 만이 외래키를 관리(등록, 수정)
    = 주인이 아닌 쪽은 읽기만 가능
- `mappedBy` means it is not an owner!
    = 주인이 아닌 경우 mappedBy 속성을 통해 주인 지정

Who to be an owner? where FKs lie!
    = normally N쪽이 주인!
    = 외래키의 위치를 기준으로 결정(외래키가 있는 곳이 주인)

* 항상 연관관계 주인에서 값을 수정하자!
    + 양방향 매핑 시에는 모두 값을 넣어주자. (실수를 예방하는 지름길)
    = 순수 객체 상태를 고려해서 양쪽 모두에 값을 넣자!
    = 연관 관계 편의 메소드를 작성하자
    ```
    ex.
    fun changeTeam(team: Team) {
        this.team = team
        team.members.add(this)
    }
    ```

* 양방향 매핑 시에 무한루프를 조심
    ex. toString(), lombok, JSON 생성 라이브러리
    - lombok's toString 은 사용하지 말자
    - 엔티티를 직접 반환하지 말고 DTO를 쓰자!
        = 엔티티는 언제나 가변 (엔티티가 바뀐다? = API의 스펙이 바뀌어버린다.)

* 처음에는 단 방향 매핑을 잘하자!
    - 이후 양방향 매핑이 필요해지면 추가
    - 객체 입장에서 양방향으로 설계해두면 고민의 포인트만 증가한다.
    (사실 단 방향 만으로도 이미 연관관계 매핑은 완료되어 있다.)


# details
* 실전에서 써서는 안되는 매핑 = M:N(다대 다)

* 다대 일
- 다쪽에 외래키가 위치

    vs * 일대 다 단방향
        - `@JoinColumn` 을 반드시 써야 한다. (아니면 조인 테이블 하나를 추가해버린다;)
        - 일쪽에 외래키가 위치 (권장X)
        = but 테이블 입장에서는 무조건 다 쪽에 외래키가 위치한다. (설계 상!)
        - 업데이트 쿼리가 한 번 더 나간다는 문제1
        - 일쪽 엔티티를 수정했는데, 쿼리가 다 쪽에 나가게 된다는 문제 2(perplexing!)
    (설계 상 손해를 보더라도, 왠만하면 다대 일을 사용하자!)

    참고: 일대 다 양방향
        - 공식적 지원X
        - 반대 쪽에서도 `@JoinColumn` 을 사용하되, `insertable = false, updatable = false` 를 추가한다.
            = 읽기 전용 필드를 사용해서 양방향 처럼 사용하기

## 일대 다 단방향/양방향 <<<<<<<<<<<<<<<<<<<<<<<<<<<<< 다대일 양방향 
## 거의 무조건 다대 일 사용하자!
