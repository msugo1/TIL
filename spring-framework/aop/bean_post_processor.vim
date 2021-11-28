# 빈 등록 with `@Bean` or via component scan
- 스프링이 대상 객체 생성 &  컨테이너 내부의 빈 저장소에 등록
- 이후, 컨테이너에서 빈을 조회해서 사용

# bean post processor
- 저장소에 등록하기 직전에 빈 조작
- 객체를 조작할 수도, 완전히 다른 객체로 바꿔치기 할 수도 있다.

```kotlin
interface BeanPostProcessor {
	fun postProcessBeforeInitialization(bean: Any, beanName: String): Any
	fun postProcessAfterInitialization ...
}
```

1. 빈 생성 후 @PostConstruct 등의 이벤트가 발생하기 전 호출
2. 										   발생한 후 호출



	Spring ----> 1. A 객체 생성
	  |									      BeanPostProcessor
 	  |								  --------------------------------
	   --------> 2. A 객체 전달 -----> A 객체 ----> B 객체 (바꿔치기) -----> 등록: B 객체

* Summary
- 빈 후처리기: 빈을 조작/변경할 수 있는 후킹 포인트
	= 빈을 프록시로 교체할 수도 있다!

 - Spring
	= `CommonAnnotationBeanPostProcessor` 빈 후처리기 자동등록
	= `@PostConstruct` 가 붙은 메소드 호출

```kotlin
@Configuration
class BeanPostProcessorConfig {

    @Bean
    fun logTracePostProcessor(logTrace: LogTrace) = PackageLogTracePostProcessor(
        basePackage = "hello.proxy.app",
        advisor = getAdvisor(logTrace)
    )

    private fun getAdvisor(logTrace: LogTrace): Advisor {
        val pointcut = NameMatchMethodPointcut().apply {
            this.setMappedNames("request*", "order*", "save*")
        }

        val advice = LogTractAdvice(logTrace)
        return DefaultPointcutAdvisor(pointcut, advice)
    }
}
```
= 더 이상 proxy configuration이 별도로 필요 없다.
= 스프링이 이미, 프록시를 생성하기 위한 빈 후처리기를 만들어서 제공한다!

* 포인트 컷!
- 위에서 package 이름을 가지고, 프록시 적용대상을 판별
- 포인트 컷을 사용하면 더 깔끔하지 않을까?!
	= 포인트 컷은 이미 클래스. 메서드 단위의 필터 기능을 가지고 있다.
	= 더 정밀한 설정이 가능

Threfore,
	1. 프록시 적용 대상 여부 체크기능(빈 후처리기 - 자동 프록시 생성)
	2. 어드바이스 적용여부 판단 when a method is invoked (프록시 내부)

* - 위에서 package 이름을 가지고, 프록시 적용대상을 판별
- 포인트 컷을 사용하면 더 깔끔하지 않을까?!
	= 포인트 컷은 이미 클래스. 메서드 단위의 필터 기능을 가지고 있다.
	= 더 정밀한 설정이 가능

! 사실 AOP는 프록시 적용여부를 포인트컷으로 이미 판별!

# Spring이 제공하는 빈 후처리기
1. 자동 프록시 생성기
: `AnnotationAwareAspectJAutoProxyCreater` 자동등록
- 스프링 빈으로 등록된 `Advisor` 들을 자동으로 찾아서 프록시가 필요한 곳에 자동으로 프록시 적용
	(Advisor = Advice + Pointcut --> Advisor만 알고 있으면 어떤 스프링 빈에 프록시를 적용해야 할지, 어떤 부가기능을 적용할 지 알 수 있다.)

* 작동과정
1. 생성
	- 스프링 빈 대상이 되는 객체 생성(@Bean, Component Scan...)
2. 전달
	- 생성된 객체를 빈 저장소에 등록하기 직전에 빈 후처리기에 전달
3. 모든 Advisor 빈 조회
	- 자동 프록시 생성기 - 빈 후처리기는 스프링 컨테이너에서 모든 `Advisor` 조회
4. 프록시 적용대상 체크
	- 조회한 Advisor에 포함되어 있는 포인트컷을 사용해서 해당 객체가 프록시를 적용할 대상인지 아닌지 판단
	- 객체의 클래스 정보 & 모든 메서드를 포인트컷 하나하나 모두 매칭
	(조건이 하나라도 만족하면 프록시 적용대상 - ex. 10개 메소드 중 하나만 포인트컷 조건에 만족해도 프록시 적용대상!)
5. 프록시 생성
	- 프록시 객체 반환 + 스프링 빈으로 등록(적용대상) or 원본(적용대상이 아닌경우)
6. 빈 등록
	- 반환된 객체는 스프링 빈으로 등록	 

* 프록시를 모든 곳에 생성하는 곳은 비용낭비!
- 꼭 필요한 곳에 최소한의 프록시 적용
	= 자동 프록시 생성기는 모든 스프링 빈에 프록시를 적용하지 않는다.
	= 대신, 포인트 컷으로 한 번 필터링해서 어드바이스가 사용될 가능성이 있는 곳에만 프록시를 적용한다.

```kotlin
	@Bean
    fun advisor2(logTrace: LogTrace): Advisor {
        // pointcut
        val pointcut = AspectJExpressionPointcut()
        pointcut.expression = "execution(* hello.proxy.app..*(..)) && !execution(* hello.proxy.app..noLog(..))"
        val advice = LogTraceAdvice(logTrace)
        return DefaultPointcutAdvisor(pointcut, advice)
    }
```
= 실무에서는 주로 aspectJ expression 을 사용한다. 
	(단순히 이름 매칭으로 판단한다면, 모든 패키지 내부의 `request..` 등이 들어가는 어떤 메소드라도 포인트컷에 걸린다...
	- 문법을 알아둬야 한다.


