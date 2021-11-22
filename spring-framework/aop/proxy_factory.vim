# Proxy Factory
  - JDK & CGLIB 문제점?
  = 둘의 동작방식 및 필요한 callback 구현체가 다르다.
  (둘 다 중복으로 만들어서 관리해야 할까?)

  - Spring이 제공하는 다양한 기능을 사용할 수 있다. with Proxy Factory
    ex. AopUtils.isAopProxy(proxy) 
      this can be only used when a proxy is created by ProxyFactory 
 
* 스프링
- 유사한 구체기술이 있을 때, 통합해서 일관성 있게 접근할 수 있도록 추상화된 기술을 제공한다.
- for Proxy, ProxyFactory
  = 요거 하나로 편하게 동적 프록시 생성가능
  = interface - JDK, concrete - CGLIB or 설정 변경 가능



    Client ------> ProxyFactory -------> JDK or CGLIB
     /|\                                       |
      |                                        |
       ---------------------------- 반환 ------

- 다른 callback을 위해서 등장한 개념 = Advice

 client --> (jdk proxy) handler.invoke() --> adviceInvocationHandler (JDK) ---------
                                                                                    |
                                                                                (Advice 호출)  ----------> Advice ---------> Target
                                                                                    |
 client --> (cglib proxy) intercept()    -->  adviceMethodInterceptor (CGLIB) ------


- 특정 조건에 맞을 때 프록시 로직을 적용하는 기능도 공통으로 제공되었으면?
  = Pointcut

# Advice
- 어드바이스를 만드는 방식 varies
  = but basic - implement the interface `MethodInterceptor` by Spring
  (org.aopalliance.intercept)

```Kotlin
import org.aopalliance.intercept.MethodInterceptor
import org.aopalliance.intercept.MethodInvocation
import org.slf4j.LoggerFactory

class TimeAdvice : MethodInterceptor {

    private val log = LoggerFactory.getLogger(this::class.java)

    override fun invoke(invocation: MethodInvocation): Any? {
        log.info("TimeProxy 실행")
        val start = System.currentTimeMillis()

        val result = invocation.proceed()

        val end = System.currentTimeMillis()
        log.info("TimeProxy 종료, time spent = ${end - start}")
        return result!!
    }
}
```
- invocation.proceed() 호출 시, target을 찾아서 알아서 실행해준다.
  = target 설정 필요 X
- 프록시 팩토리로 프록시 생성 시, target 정보를 파라미터로 전달

# Pointcut, Advice, Advisor
1. Pointcut
- where to apply additional functions (filtering)
- which point

2. Advice
- additional functions called by proxies

3. Advisor
- a combination of one pointcut and one advice (one advisor + one pointcut)
- where to and what 

* 조언(advice)을 어디(pointcut)에 할 것인가?
* 조언자(advisor)는 어디(pointcut)에 조언(advice)을 해야할 지 알고 있다.

= 역할과 책임 분리

ex.
```kotlin

@Test
fun advisorTest1() {
  val target: ServiceInterface = ServiceImpl()
    val pf = ProxyFactory(target)
    val advisor = DefaultPointcutAdvisor(Pointcut.TRUE, TimeAdvice())
    pf.addAdvisor(advisor)
    val proxy = pf.proxy as ServiceInterface
    proxy.save()
    proxy.find()
}
```

* Pointcut
- ClassFilter + MethodFilter
  = 클래스가 맞는지? 메서드가 맞는지?
  = 둘 다 true인 경우만 어드바이스 적용

- 직접 구현할 수도 있지만, 스프링이 필요한 대부분을 제공한다
  ex. 
  1. NameMatchedMethodPointcut
  = 내부적으로 PatternMatchUtils 사용 (*xxx* 허용)

  2. JdkRegexMethodPointcut
  = JDK 정규표현식을 기반으로 포인트컷 매칭

  3. TruePointcut
  = 항상 참을 반환한다.

  4. AnnotationMatchingPointcut
  = 어노테이션으로 매칭

  5. AspectJExpressionPointcut
  = aspectJ 표현식으로 매칭
  = 요것이 가장 중요(편리, 기능 many) 

* 1 proxy : N advisor
ex.
```kotlin
    @Test
    @DisplayName("하나의 프록시, 여러 어드바이저")
    fun multiAdvisorTest2() {
        // client -> proxy ->  advisor2 -> advisor1  -> target
        val advisor1 = DefaultPointcutAdvisor(Pointcut.TRUE, Advice1())
        val advisor2 = DefaultPointcutAdvisor(Pointcut.TRUE, Advice2())

        // create proxy1
        val target: ServiceInterface = ServiceImpl()
        val pf1 = ProxyFactory(target)

        pf1.addAdvisor(advisor1)
        pf1.addAdvisor(advisor2)
        val proxy = pf1.proxy as ServiceInterface
        proxy.save()
    }
```
- 등록한 순서대로 호출

* NOTE
- AOP 적용 수 만큼 프록시가 생성되는 것이 아니다.
  = 성능 최적화를 위해 프록시는 하나만 + 하나의 프록시에 여러 어드바이저 적용
  = 여러 AOP 적용해도 타겟에 대한 프록시는 하나만!!

## Result in ProxyFactory
* 장점
- 매우 편리하게 프록시 생성 가능
- advice, pointcut, advisor 덕분에, 어떤 부가기능을 어디에 적용할 지 명확하게 설정가능 (even 재사용)

* 단점
- still 지나치게 많은 설정파일  
  = 100개의 스프링 빈이 있다면 100개 동적프록시 생성코드 필요
- 컴포넌트 스캔 사용 시 지금까지 적용한 방법으로 프록시 적용 불가
  = 이미 실제 객체를 컴포넌트 스캔으로 빈으로 등록 다 해버림
  = 프록시를 실제 객체 대신 넣어야 한다...

위의 두 문제를 해결해 줄 것이 바로 `빈 후처리기`
