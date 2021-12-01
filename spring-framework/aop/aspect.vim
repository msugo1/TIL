# `@Aspect` 어노테이션으로 매우 편리하게 포인트컷/어드바이스로 구성되어 있는 어드바이저 생성 기능을 지원한다.

```kotlin
@Aspect
class LogTraceAspect(private val logTrace: LogTrace) {

    @Around("execution(* hello.proxy.app..*(..))")
    fun execute(joinPoint: ProceedingJoinPoint): Any {
        val message = joinPoint.signature.toShortString()
        val status = logTrace.begin(message)
        try {
            val result = joinPoint.proceed()
            logTrace.end(status)
            return result
        } catch (e: Exception) {
            logTrace.exception(status, e)
            throw e
        }
    }
}
```
1. @Aspect
- 어노테이션 기반의 프록시 적용

2. @Around("exception ...")
- AspectJ 표현식을 사용
- `@Around, @Before` 등이 포인트 컷, 어드바이스는 해당 메서드

3. joinPoint: ProceedingJoinPoint
- `invocation: MethodInvocation`과 유사
    = 내부에 실제 호출 대상, 전달 인자, 그리고 어떤 객체가 호출되었는지 정보를 담고 있다.

# Do you remember `AnnotationAwareAspectJAutoProxyCreater`
- Advisor를 자동으로 찾아서 필요한 곳에 프록시 생성/적용
- Additionally,
    @Aspect를 찾아서 이것을 Advisor로 만들어준다. (That's why it is called AnnotationAware - as its prefix)
- 생성한 어드바이저는 @Aspect 어드바이저 빌더 내부에 저장

# @Aspect Advisor Builder
: `BeanFactoryAspectJAdvisorBuilder`

- @Aspect 정보를 바탕으로, 포인트 컷/어드바이스/어드바이저 생성 및 보관
    = 생성 based on @Aspect & 캐시 in advisor builder
    (캐시에 이미 만들어져 있는 경우, 해당 캐시를 어드바이저로 반환)

* 지금까지 배운 내용
: 횡단 관심사 (cross-cutting concern, which is 부가기능)를 해결하는 방법!



