`override` 된 함수는 기본적으로 open
- 다른 클래스에서 상속받아서 오버라이딩 못하게 하려면 `final`을 명시적으로 붙여줘야 한다.

`final`이 아닌 경우 스마트캐스팅 적용 불가
- 언제 어디서 타입이 바뀔지 알 수 없다.

내부 클래스 -> 외부 클래스로의 참조가 직렬화를 막는다?

---

### subjects to talk about
1. 인터페이스 vs 추상클래스 차이점
2. sealed interface vs sealed class
    = 참고: 코틀린 인 액션에는 sealed 인터페이스 없다고 나와있었음
    = 1.5 버전부터 있다.
3. 데이터 클래스 and 불변성 in p.177
4. J2EE vs Jarkrta

---

### visibility modifier
- public, private, protected, internal
- `package-private`은 코틀린에서는 존재하지 않는다.
    = 취약점: 다른 jar 파일에서도 패키지 명만 일치시키면 접근가능
- internal
    = 같은 모듈 내부에서만 접근가능 
    = same jar
- protected는 `최상위 선언`에는 적용불가
- 어떤 클래스의 기반 타입 목록에 들어있는 타입이나, 제네릭 클래스의 타입 파라미터에 들어있는 타입의 가시성 >= 그 클래스 자신의 가시성

### sealed class
- 상위 클래스에 sealed
- 상속받으면, 하위 클래스들은 상위클래스 안에 중첩되어야 한다.
- when에서 default 분기가 필요없어진다.

### 초기화 블록
- 주 생성자와 함께 사용된다.
    = 주 생성자는 별도의 코드를 포함할 수 없다.
    = 부가로직이 필요하면 초기화 블록
    = 여러 초기화 블록도 선언할 수 있다.

### == vs ===
== calls 동등성 비교
=== 동일성 비교

### copy with data class
- copy 메소드를 자동으로 제공
- 원하는 프로퍼티만 변경해서 copy 가능
```
data class(val name: String, val postalCode: Int)

val lee = Client("Lee", 4122)
val newLee = lee.copy(poastalCode = 4000)
```
