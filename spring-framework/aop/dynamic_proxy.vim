# works with Reflection
  1. Class.forName
  - 클래스에 대한 메타정보
  2. Class.forName.getMethod()
  - 메소드에 대한 메타정보

  실행은 `method.invoke(target)`
  - 공통 로직을 빼내고 다른 메타정보를 제공해 동적으로 실행할 메소드를 변경할 수 있다.

* 주의
  - 당연하게도, 호출할 클래스와 메소드 정보가 다르면 예외가 발생
    = 이 오류는 컴파일 시점에 잡지 못한다..  런타임이 되어야 발생;;
    ex. 문자를 잘못 넘긴다면?
        Class.forName("Hello").getMethod("callllll")
        - 컴파일러가 잡을 수 없다 -> 애플리케이션 구동 후에 오류 발생;;

  - 필요할 때만 주의해서 사용해야 한다.

# JDK 동적 프록시?
  - 프록시 객체를 동적으로 런타임에 대신 만들어줌
  - 인터페이스 기반!

```
@Test
fun dynamicA() {
    val target = AImpl()
    val handler = TimeInvocationHandler(target)
    Proxy.newProxyInstance(A::class.java.classLoader, arrayOf(A::class.java), handler)
}
```

client: proxy.(method) -> proxy1: handler.invoke() -> invocationHandler: method.invoke

* 적용 대상만큼 프록시 객체를 만들 필요가 없다.
* 같은 부가기능 로직을 한 번만 개발해서 공통으로 넣어주면 된다.

한계
- JDK 동적 프록시는 인터페이스가 필수
- 인터페이스가 없다면? CGLIB 필요

# CGLIB
  - 바이트코드를 조작해서 동적으로 클래스를 생성하는 기술제공
  - 인터페이스 없이 구체 클래스만 가지고 동적 프록시 생성
  - 스프링 내부 소스에 포함되어 별도의 외부 라이브러리를 추가하지 않아도 된다.
  - 직접적으로 사용할 일은 거의 없다.
    = ProxyFactory in Spring facilitates to use CGLIB

* JDK - InvocationHandler
CGLIB?
  - MethodInterceptor

```kotlin
interface MethodInterceptor : Callback {
    fun intercept(obj: Any, method: Method, args: Array<out Any>, proxy: MethodProxy): Any
}
```
obj: CGLIB가 적용된 객체
method: 호출된 메소드
args: 메소드를 호출하면서 전달된 인수
proxy: 메소드 호출에 사용

* JDK 처럼 method 를 사용해도 되지만, CGLIB는 성능상 proxy: MethodProxy 를 사용하는 것을 권장!

name
`대상클래스$$EnhancerByCGLIB$$임의코드`

* CGLIB 제약
  (due to 상속)

  - 부모 클래스의 생성자 체크 필요 (CGLIB은 자식 클래스를 동적으로 생성 = 기본 생성자 필요)
  - final 키워드가 있으면 상속 불가
    in class
    = CGLIB에서는 예외 발
    in method
    = 메서드 오버라이딩 불가능(CGLIB에서 프록시 로직이 동작하지 않음)
