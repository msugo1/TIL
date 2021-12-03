# execution
execution(modifiers-pattern? ret-type-pattern declaring-type-pattern?name-pattern(param-pattern) throws-pattern?)
    = execution(접근 제어자? 반환타입 선언타입?메소드 이름(파라미터) 예외?)

- 메소드 실행 조인포인트를 매칭한다.
- ? means 생략가능
- * 등 표현식 사용가능

ex
```
@Test
fun allMatch() {
    pointcut.expression = "execution(* *(..))"
    assertThat(pointcut.matches(helloMethod, MemberServiceImpl::class.java)).isTrue
}
```
- * 모두 일치
- (..) in params = 수, 타입 모두 상관X


```
@Test
fun packageNameMatch() {
    pointcut.expression = "execution(* hello.aop.member.annotation.MemberServiceImpl.hello(..))"
    assertThat(pointcut.matches(helloMethod, MemberServiceImpl::class.java)).isTrue
}
```

```
@Test
fun packageNameMatchFalse() {
    pointcut.expression = "execution(* hello.aop.*.*.hello(..))"
    assertThat(pointcut.matches(helloMethod, MemberServiceImpl::class.java)).isTrue
}
```
- 패키지 및 해당 패키지의 하위 패키지를 포함하기 위해서는 .. 이 되야 한다. (Not .!)
(. = 정확하게 해당 패키지만)

```
@Test
fun typeMatchSuperType() {
    pointcut.expression = "execution(* hello.aop.member.annotation.MemberService.*(..))"
    assertThat(pointcut.matches(helloMethod, MemberServiceImpl::class.java)).isTrue
}
```
- 부모 타입을 선언해도 자식 타입은 매칭!
(안되는 것도 있다고 하니 주의! = ex. 부모 타입에 있는 메소드만 매칭!)

```
@Test
fun argsMatch() {
    pointcut.expression = "execution(* *(String))"
    assertThat(pointcut.matches(helloMethod, MemberServiceImpl::class.java)).isTrue
}
- 정확한 타입의 파라미터 1개 허용

@Test
fun argsMatch() {
    pointcut.expression = "execution(* *(*))"
    assertThat(pointcut.matches(helloMethod, MemberServiceImpl::class.java)).isTrue
}
- 모든 타입의 파라미터 1개 허용

- (..): 숫자와 무관하게 모든 파라미터, 모든 타입 허용
- (String, ..): 문자열로 시작 && 그 뒤 위의 조건과 동일
```

# within
- 해당 타입이 매칭되면, 그 안의 메소드 들이 자동으로 매칭
- 타겟의 타입에 직접 적용(인터페이스를 선정하면 안됨!)

# args
(execution 은 타입이 정확히 매칭되어야 한다. = 클래스에 선언된 정보를 기반으로 판단한다.)
However, args 는 부모타입 허용 & 실제 넘어온 파라미터 객체 인스턴스를 보고 판단한다.

in codes
```
pointcut("args(String)")
pointcut("args(Object)")

execution(* *(java.io.Serializable)) - 메서드의 시그니처로 판단(정적)
    = 파라미터가 정확히 매칭되어야 한다!
args(java.io.Serializable) - 런타임에 전달된 인수로 파악
```

# @target, @within
- 타입에 있는 어노테이션으로 AOP 적용 여부를 판단한다.

@Target(hello.aop.member.annotation.ClassAop)
    = 인스턴스의 모든 메서드를 조인포인트로 적용
    (부모클래스의 메서드까지 어드바이스를 모두 적용)
@within(hello.aop.member.annotation.ClassAop)
    = 해당 타입 내에 있는 메서드만 조인포인트로 적용
    (자기 자신의 클래스에 정의된 메서드에만 어드바이스 적용)

# 주의
- args, @args, @target 은 단독으로 사용하면 안된다.
    = 실제 객체 인스턴스가 생성되고, 실행될 때 어드바이스 적용여부를 확인할 수 있다.
    = 실행시점에 일어나는 포인트컷 적용 여부도, 결국 프록시가 있어야 실행시점에 판단할 수 있다. (프록시가 없다면 판단자체가 불가!)
    
    * 스프링 컨테이너가 프록시를 생성하는 시점?
    = 스프링 컨테이너가 만들어지는, 애플리케이션 로딩시점

    = 위와 같은 지시자가 있을 경우, 스프링은 모든 스프링 빈에 AOP를 적용하려고 시도할 수 있다.
    = final로 지정된 빈들도 있으므로, 오류가 발생할 수 있다!
- 따라서, 이러한 표현식은 최대한 프록시 적용 대상을 축소하는 표현식과 함께 사용해야 한다.

# @annotation
@Aspect
class AtAnnotationAspect {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Around("@annotation(hello.aop.member.annotation.MethodAop)")
    fun doAtAnnotation(joinPoint: ProceedingJoinPoint): Any? {
        log.info("[@annotation] ${joinPoint.signature}")
        return joinPoint.proceed()
    }
}
- 가장 유용!

# @args
- 전달된 인수의 런타임 타입에 `@Check` 어노테이션이 있는 경우에 매칭

# bean
- 스프링 전용 포인트컷 지시자 = 빈의 이름으로 지정
(스프링에만 사용가능)

```
@Aspect
class BeanAspect {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Around("bean(orderService) || bean(*Repository)")
    fun doLog(joinPoint ProceedingJoinPoint): Any? {
        log.info("[bean] ${joinPoint.signature}")
        return joinPoint.proceed()
    }
}
```
= 빈의 이름이 확정적일 때 사용하나, 많이 사용되지는 않는다!

# 매개변수 전달 to `advice`
this, target, args, @target, @within, @annotation, @args

ex.
@Before("allMember() && args(arg, ..)")
fun logArgs3(arg: String) {
    log.info("[logArgs3] arg=$arg")
}
- 포인트 컷의 이름과, 매개변수의 이름을 맞추어야 한다. (here arg)
- 타입이 메서드에 지정한 타입으로 제한됨! (here String)

```
@Aspect
class ParameterAspect {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Pointcut("execution(* hello.aop.member..*.*(..))")
    fun allMember() {}

    @Around("allMember()")
    fun logArgs1(joinPoint: ProceedingJoinPoint): Any? {
        val arg1 = joinPoint.args[0]
        log.info("[logArgs1]${joinPoint.signature}, arg=$arg1")
        return joinPoint.proceed()
    }

    @Around("allMember() && args(arg, ..)")
    fun logArgs2(joinPoint: ProceedingJoinPoint, arg: Any): Any? {
        log.info("[logArgs2]${joinPoint.signature}, arg=$arg")
        return joinPoint.proceed()
    }

    @Before("allMember() && args(arg, ..)")
    fun logArgs3(arg: String) {
        log.info("[logArgs3] arg=$arg")
    }

    @Before("allMember() && this(obj)")
    fun thisArgs(joinPoint: JoinPoint, obj: MemberService) {
        log.info("[this]${joinPoint.signature}, obj=${obj.javaClass}")
    }

    @Before("allMember() && target(obj)")
    fun targetArgs(joinPoint: JoinPoint, obj: MemberService) {
        log.info("[target]${joinPoint.signature}, obj=${obj.javaClass}")
    }
    // this: 컨테이너에 올라간 객체(= 프록시), target: 실제 객체

    @Before("allMember() && @target(annotation)")
    fun atTarget(joinPoint: JoinPoint, annotation: ClassAop) {
        log.info("[@target]${joinPoint.signature}, obj=$annotation")
    }

    @Before("allMember() && @within(annotation)")
    fun atWithin(joinPoint: JoinPoint, annotation: ClassAop) {
        log.info("[@within]${joinPoint.signature}, obj=$annotation")
    }

    @Before("allMember() && @annotation(annotation)")
    fun atAnnotation(joinPoint: JoinPoint, annotation: MethodAop) {
        log.info("[@annotation]${joinPoint.signature}, annotationValue=${annotation.value}")
    }
}
```

# more about this & target
- 적용타입 하나를 정확히! 지정해야 한다. (* 사용불가, but 부모타입 허용!)

* Proxy 생성 방식에 따라 차이가 발생한다.(JDK vs CGLIB)
    = interface vs concrete class

this(hello.aop.member.MemberService)
target(hello.aop.member.MemberService)
1. with JDK (interface-based)
MemberService
this(hello.aop.member.MemberService)
target(hello.aop.member.MemberService)

- this: proxy 객체를 보고 판단 
    = 부모타입을 허용하므로, AOP 적용!
- target: target 객체를 보고 판단
    = 부모타입을 허용하므로, AOP 적용!

MemberServiceImpl
this(hello.aop.member.MemberServiceImpl)
target(hello.aop.member.MemberServiceImpl)

- this: proxy 객체를 보고 판단
    = JDK 기반 프록시 객체는 MemberService 인터페이스 기반으로 구현된 새로운 클래스
    = MemberServiceImpl를 알지 못하므로... AOP 대상X
- target: target == MemberServiceImpl. 따라서 AOP 대상O

2. with CGLIB (concrete class & inheritance based)
MemberService (interface)
this(hello.aop.member.MemberService)
target(hello.aop.member.MemberService)

- this: proxy 객체를 보고 판단 
    = 부모타입을 허용하므로, AOP 적용!
- target: target 객체를 보고 판단
    = 부모타입을 허용하므로, AOP 적용!

MemberServiceImpl
this(hello.aop.member.MemberServiceImpl)
target(hello.aop.member.MemberServiceImpl)

- this: proxy 객체를 보고 판단
    = CGLIB은 상속을 이용해 프록시 생성
    = 따라서, AOP 적용
- target: target == MemberServiceImpl. 따라서 AOP 대상O

참고
* 테스트 시, `@SpringBootTest(properties = "spring.aop.proxy.target-class=false")` 지정을 통해 `application.properties` 파일에 설정 값을 지정하는 것을 대체가능!
(by the way, false means `use JDK!`)

* this, target 지시자는 단독으로 보다는, `파라미터 바인딩`에 주로 사용된다.

