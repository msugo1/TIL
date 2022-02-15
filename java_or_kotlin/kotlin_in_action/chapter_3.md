(up to chapter 2)
- backing field: 프로퍼티에는 그 프로퍼티 값을 저장하기 위한 필드가 있다.
    = 커스텀 게터를 작성하면 프로퍼티 값을 그때그때 계산할 수도 있다.
    ```
    ex.
    class Rectangle(val height: Int, val width: Int) {
        val isSquare: Boolean
            get() {
                return height == width
            }
    }
    
    1 매번 계산해준다.
    2 파라미터가 없는 함수를 정의하는 방식 및 커스텀 게터를 정의한느 방식 모두 비슷하다. performance-wise
    3 일반적으로 클래스의 `특성`을 정의하고 싶다면, `프로퍼티`로 그 특성을 정의하자.
    ```

- smart casting
    = only works with `val`
    1) val이 아닌 경우, 혹은 커므섬 프로퍼티를 사용할 경우 항상 고정된 값을 사용하는지에 대한 확신이 없어 smart casting이 안된다고 한다.

---

### subjects to talk about
- `@JvmOverloads` and default params
- custom getter/setter
- difference between 확장함수 vs 멤버함수
    = and the best practice
- also between 확장 함수 vs 확장 프로퍼티
- the effectiveness of 로컬 함수

```
- 언제 정적함수 vs 언제 인스턴스 함수
```

---

~ Util
- can be removed by top level classes and properties

### Top-Level classess and properties in Kotlin
- 컴파일러가 바깥의 새로운 클래스를 정의해준다.
    = 코틀린에서 최상위 함수/프로퍼티를 사용할 수 있는 이유
    = 일반적으론 파일 이름 but `@JvmName`을 사용해서 이름을 지정해줄 수 있다.
- 이후 정적함수, 변수로 컴파일 된다.

### 확장함수 (and 확장 프로퍼티?)
1. 확장함수
- 어떤 클래스의 멤버 메소드인 것처럼 호출
- But, 그 클래스 밖에서 선언
```
fun String.lastChar(): Char = this.get(this.length - 1)
```
- 함수 이름 앞 클래스: 수신 객체 타입
- 타입을 받아서 `this`로 활용할 수 있다.
    = this는 생략이 가능하다.
- 자바 클래스로 컴파일한 클래스 파일이 있는 한 그 클래스에 원하는대로 확장이 가능하다.
- 확장함수가 캡슐화를 깨지는 않는다.
    = 클래스 내부에서만 사용할 수 있는 private, protected 멤버는 사용이 불가

NOTE
1) 내부적으로 확장함수는 수신객체를 첫번째 인자로 받는 `정적 메소드`
    = 다른 어댑터 객체 or 실행시점 부가비용 X
    = 자바에서도 `클래스이름.함수명(parameters...)` 로 사용가능

2) 확장함수는 오버라이드 할 수 없다.
    = 수신 객체로 지정한 변수의 `정적` 타입에 의해 호출함수 결정
    = 정적: 컴파일 시점에 타입결정
    (vs 동적: 실행시점에 결정)

### infix
- 파라미터는 유일해야 한다.
    = 확장 함수, 일반 함수 모두 중위호출이 가능하도록 만들 수 있다.

just add `infix`
```
infix fun Any.to(other: Any) = Pair(this, other)
```
