# Problems
1. 프록시 & 내부 호출
- 대상 객체의 내부에서 메서드 호출할 시, 프록시를 거치지 않고 대상 객체를 바로 호출...
   
ex
```
@Component
class CallServiceV0 {

    private val log = LoggerFactory.getLogger(this::class.java)

    fun external() {
        log.info("call external")
        internal()
    }

    fun internal() {
        log.info("call internal")
    }
}

@Aspect
class CallLogAspect {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Before("execution(* hello.aop.internalcall..*.*(..))")
    fun doLog(joinPoint: JoinPoint) {
        log.info("aop=${joinPoint.signature}")
    }
}

@SpringBootTest
@Import(CallLogAspect::class)
internal class CallServiceV0Test {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Autowired
    lateinit var callServiceV0: CallServiceV0

    @Test
    fun external() {
        log.info("target=${callServiceV0.javaClass}")
        callServiceV0.external()
    }

    @Test
    fun internal() {
        log.info("target=${callServiceV0.javaClass}")
    }
}
```
- external 호출 시, callServiceV0.external 에만 aop 적용, 이후 이어지는 internal 에는 aop 적용X
(why? 별다른 참조가 메소드 앞에 없으면, this를 자동으로 붙임... here this is a real target instance)
= 스프링 AOP의 한계점(AspectJ AOP는 이런 문제가 발생하지 않음 = 바이트 코드를 직접 weaving 하기 때문)

* 내부호출 문제를 어떻게 해결할 수 있을까?
1) self injection
- 주입받는 자기 자신도 Proxy
- 결국 해당 메소드를 호출할 때, 프록시 메소드 호출!

```
@Component
class CallServiceV1 {

    private val log = LoggerFactory.getLogger(this::class.java)

    @Autowired
    lateinit var callServiceV1: CallServiceV1

    fun external() {
        log.info("call external")
        callServiceV1.internal()
    }

    fun internal() {
        log.info("call internal")
    }
}
```
- 생성자 주입을 사용할 수 없다. (순환참조문제 발생)
    = 생성도 안된 자기 자신을 어떻게 주입할수 있을까!
    = setter 주입도 가능

2) 지연조회
done with `ObjectProvider(Provider)` or ApplicationContext
- `ApplicationContext`는 주입 받을 수 있다.
    But, 지나치게 거대하다..

Then?
```
@Component
class CallServiceV2(private val callServiceProvider: ObjectProvider<CallServiceV2>) {

    private val log = LoggerFactory.getLogger(this::class.java)

    fun external() {
        log.info("call external")
        val callServiceV2 = callServiceProvider.`object`
        callServiceV2.internal()
    }

    fun internal() {
        log.info("call internal")
    }
}
```
- ObjectProvider 로 LazyLoading

3) 구조 변경 - most recommended 
* create a new separate class, then call it from outside
```
@Component
class InternalService {

    private val log = LoggerFactory.getLogger(this::class.java)

    fun internal() {
        log.info("call internal")
    }
}

@Component
class CallServiceV3(
    private val internalService: InternalService
) {

    private val log = LoggerFactory.getLogger(this::class.java)

    fun external() {
        log.info("call external")
        internalService.internal()
    }
}
```
- or client에서 둘다 호출하는 구조도 가능
(ex. client -> external then client -> internal)

# 참고
- 인터페이스 메서드가 나올 정도의 규모에 AOP를 적용하는 것이 바람직
    = AOP는 public 메서드에만 적용
- public -> public 호출 시 AOP 적용이 잘 되지 않는 경우, 내부호출 문제를 의심해보자!`:wq


