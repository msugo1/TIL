# AOP 적용시점
1. compile time
2. class loading time
3. runtime (proxy)

1, 2 = weaving
- AspectJ가 제공하는 특별한 컴파일러가 필요하다.
- 실제 대상코드에 애스펙트를 통한 부가기능 호출코드 포함


* 컴파일 시점 AOP 단점
- 별도의 컴파일러 필요
- rather complicated


* class 로딩 시점
: 자바 실행 시 .class 파일이 JVM 내부의 클래스로더에 보관된다.

이때, .class 파일을 조작하는 것
= loadtime weaving
(java instrumentation)

단점?
- 클래스 로더 조작기 지정필요 (자바 실행할 때, java -javaagent)
    = 번거롭고, 운영하기가 어렵다.


* runtime 시점
- 이미 자바가 실행되고 난 이후
    = 자바 언어가 제공하는 범위 안에서 부가기능을 적용해야 한다.
    (in spring, helps from spring container, proxy, DI, bean post processor etc - everything necessary)
    = 최종적으로 프로시를 통해 스프링 빈에 부가기능 적용가능

- 프록시 기반만 가능하므로 이에 따른 제약이 있다.
    but, 장점은 no additional hassles unlike compile or class loading time weaving

then, 단점?
- 무조건 메서드 호출시만 적용가능 (생성자 호출 시 등 적용 불가)
    = therefore, spring aop is only applied to methods basically

NOTE)
AOP 적용가능 위치?
- joinpoint = 생성자, 필드 값 접근, static 메서드 접근, 메서드 실행
(메서드 실행 외에는 프록시 개념 적용 불가!)


* spring aop는 별도의 추가 설정 필요X (what we only need is the framework itself, spring!!)
    in addition, 실무에서는 스프링이 제공하는 AOP만 사용해도 대부분의 문제를 해결할 수 있다.


# AOP 용어 정리
1. Joinpoint
- advice가 적용될 수 있는 위치
ex. 메소드, 생성자 호출, 필드 값, static 메서드 접근 등
- 추상적인 개념
- AOP를 적용할 수 있는 모든 지점!
    = 스프링에서는 of course, only 메소드 호출지점 (because it is based on proxy)

2. Pointcut
- 조인포인트 중에서 어드바이스가 적용될 위치 선별
- 주로 AspectJ 표현식을 사용해서 지정
- 스프링 AOP는 only 메소드 실행지점!

3. Target
- 어드바이스를 받는 객체. 포인트 컷으로 결정

4. Advice
- 부가기능
    = 특정 joinpoint에서 Aspect에 의해 취해지는 조치
- Around, Before, After ... 

5. Aspect
- Advice + Pointcut 모듈화 (= @Aspect)
- 여러 어드바이스와 포인트 컷이 함께 존재

6. Advisor
- 하나의 어드바이스 + 하나의 포인트 컷
- 스프링 AOP에서만 사용되는 특별한 용어

7. Weaving
- 포인트 컷으로 결정한 타겟의 조인 포인트에 어드바이스를 적용하는 것
- 위빙을 통해 핵심 기능에 영향을 주지 않고, 부가기능을 추가할 수 있다.
- AOP 적용을 위해 Aspect를 객체에 연결한 상태

# 적용
주의)
`@Aspect` doesn't mean it's subjected to component scan
- actually, it should be registered as a bean on top of that

* How to register components as a spring bean?
1. @Bean in a method
2. @Component for component scan
3. @Import - normally goes with configuraiton files

example
```
@Aspect
class AspectV1 {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Around("execution(* hello.aop.order..*(..))")
    fun doLog(joinPoint: ProceedingJoinPoint): Any? {
        log.info("[log] ${joinPoint.signature}")
        return joinPoint.proceed()
    }
}
```
- `@Around`에 포인트컷 표현식을 직접 넣을 수 있지만, `@Pointcut`을 사용해 별도로 분리할 수도 있다.

```
@Aspect
class AspectV2 {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Pointcut("execution(* hello.aop.order..*(..))")
    private fun allOrder() {
        // pointcutSignature - 파라미터가 들어가는 것도 모두 맞춰주어야 한다.
    }

    @Around("allOrder()")
    fun doLog(joinPoint: ProceedingJoinPoint): Any? {
        log.info("[log] ${joinPoint.signature}")
        return joinPoint.proceed()
    }
}
```
- `@Pointcut`에 표현식을 사용
    = 메소드 이름을 통해 포인트컷에 의미를 부여할 수 있다.
    = public으로 설정 시 다른 애스펙트에서도 사용가능

```
@Aspect
class AspectV3 {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Pointcut("execution(* hello.aop.order..*(..))")
    private fun allOrder() {
        // pointcutSignature - 파라미터가 들어가는 것도 모두 맞춰주어야 한다.
    }

    // 클래스 이름 패턴이 *Service
    @Pointcut("execution(* *..*Service.*(..))")
    private fun allService() {

    }

    @Around("allOrder()")
    fun doLog(joinPoint: ProceedingJoinPoint): Any? {
        log.info("[log] ${joinPoint.signature}")
        return joinPoint.proceed()
    }

    // hello.aop.order 의 하위 패키지 && 클래스 이름 패턴이 *Service 인 경우
    @Around("allOrder() && allService()")
    fun doTransaction(joinPoint: ProceedingJoinPoint) = try {
        log.info("[트랜잭션 시작] ${joinPoint.signature}")
        val result = joinPoint.proceed()
        log.info("[트랜잭션 커밋] ${joinPoint.signature}")
        result
    } catch (e: Exception) {
        log.info("[트랜잭션 롤백] ${joinPoint.signature}")
        throw e
    } finally {
        log.info("[resource release] ${joinPoint.signature}")
    }
}
```
- 현재, `doLog - doTransaction - Service - doLog - Repository` 순으로 실행
    = but then, how to change the orders?

* Advice는 기본적으로 순서를 보장하지 않는다.
- 순서 지정을 위해서는 `@Aspect` 적용 단위로 `org.springframework.core.annotation.@Order` 어노테이션 적용이 필요하다.
    = 요 어노테이션은 클래스 단위로 적용 가능(어드바이스 단위로는 불가!)
    = therefore, a number of advice bound wtih one aspect doesn't gurantee you the desired order.
- 애스팩트를 별도의 클래스로 분리하는 작업이 필요하다!
```
@Aspect
class AspectV5Order {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Order(2)
    @Aspect
    class LogAspect {

        private val log = LoggerFactory.getLogger(this::class.java)

        @Around("hello.aop.order.aop.Pointcuts.allOrder()")
        fun doLog(joinPoint: ProceedingJoinPoint): Any? {
            log.info("[log] ${joinPoint.signature}")
            return joinPoint.proceed()
        }
    }

    @Order(1)
    @Aspect
    class TxAspect {

        private val log = LoggerFactory.getLogger(this::class.java)

        @Around("hello.aop.order.aop.Pointcuts.orderAndService()")
        fun doTransaction(joinPoint: ProceedingJoinPoint) = try {
            log.info("[트랜잭션 시작] ${joinPoint.signature}")
            val result = joinPoint.proceed()
            log.info("[트랜잭션 커밋] ${joinPoint.signature}")
            result
        } catch (e: Exception) {
            log.info("[트랜잭션 롤백] ${joinPoint.signature}")
            throw e
        } finally {
            log.info("[resource release] ${joinPoint.signature}")
        }
    }
}
```

# Advice 종류
1. `@Around` - the most powerful
- 메소드 호출 전후에 수행!
- 조인포인트 실행 여부, 반환 값 변환, 예외 변환 등 가능

2. `@Before`
- 조인포인트 실행 이전

3. `@After`
- like finally, 정상 반환 or 예외에 상관X

4. `@AfterReturning`
- joinpoint 실행이 정상적으로 완료된 후

5. `@AfterThrowing`
- joinpoint 실행 중 예외가 발생한 경우


in short,

   # @Around("hello.aop.order.aop.Pointcuts.orderAndService()")
   fun doTransaction(joinPoint: ProceedingJoinPoint) = try {
        # @Before
        log.info("[트랜잭션 시작] ${joinPoint.signature}")
        val result = joinPoint.proceed()
        # @AfterReturning
        log.info("[트랜잭션 커밋] ${joinPoint.signature}")
        result
   } catch (e: Exception) {
        # @AfterThrowing
        log.info("[트랜잭션 롤백] ${joinPoint.signature}")
        throw e
   } finally {
        # @After
        log.info("[resource release] ${joinPoint.signature}")
   }

- ProceedingJoinPoint 는 @Around 에만 사용이 가능하다.

```
@Before("hello.aop.order.Pointcuts.orderAndService()")
fun doBefore(joinPoint: JoinPoint) {
    log.info("[before] ${joinPoint.signature}")
}
```
- @Before 는 별도의 target 메소드 호출을 필요로 하지 않는다.
    = `joinpoint` 가 필요하지 않다면, 굳이 파라미터로 줄 필요도 없다!

```
@AfterReturning(value = "hello.aop.order.Pointcuts.orderAndService()", returning = "result")
fun doReturn(joinPoint: JoinPoint, result: Any?) {
    log.info("[return] ${joinPoint.signature} result = $result")
}
```
- @AfterReturning 어노테이션 값으로 `returning`을 지정해주어야 한다.
    = 요거는 메소드 파라미터에 결과 값과 매칭
- 결과 값을 조작할 수는 없다.

```
@AfterThrowing(value = "hello.aop.order.Pointcuts.orderAndService()", throwing = "ex")
fun doThrow(joinPoint: JoinPoint, ex: Exception) {
    log.info("[ex] ${joinPoint.signature} message = $ex")
}
```
- @AfterThrowing 은 @AfterReturning 과 유사하다.

```
@AfterThrowing(value = "hello.aop.order.Pointcuts.orderAndService()", throwing = "ex")
fun doThrow(joinPoint: JoinPoint, ex: Exception) {
    log.info("[ex] ${joinPoint.signature} message = $ex")
}
```
- like finally (regardless of what happens in a target method, either returing successfully or throwing exceptions)

# @Around 만 있어도 필요한 기능은 모두 수행 가능
    = 나머지는 사실 @Around의 일부 기능만 수행하는 역할

- @Around 는 ProceedingJoinPoint, 나머지는 Joinpoint (생략 가능)
    why? ProceedingJoinPoint 는 `proceed()` 메소드를 가지고 있다. (다음 어드바이스 or 타겟 호출)
    = @Around 는 직접 타겟 메소드의 호출이 필요하다.

* `proceed()` 여러번 호출할 수 있다. for retry especially

- `@AfterReturning` 은
    = returning's type == param type 인 경우에만 호출된다! (다르면 호출되지 않는다, @AfterThrowing 도 마찬가지!)
    = `@Around` 와 다르게, 반환되는 객체를 변경할 수 없다. (따라서, 객체의 변환이 필요하면 @Around)

- `@After`
    = 일반적으로 리소스를 해제하는데 사용!

# 왜 @Around 외에 다른 옵션들이 있을까?
* `@Around` 는 다음 호출을 위해 반드시 `proceed()` 호출을 필요로 한다.
- 호출하지 않으면 다음 chain 의 것들이 호출되지 않는다. (a point of serious failure)

