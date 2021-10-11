### Scope
  - 스프링 컨테이너에서 빈이 관리되는 범위
  - singleton, prototype, request, session, application
    (Default: singleton)
    * application: global

### Scope in Spring Batch?
= @JobScope, @StepScope 
  - job, step 빈 생성과 실행에 관여하는 스코프
  - `Proxy Mode`를 기본값으로 하는 스코프
    = `@Scope(value = "job", proxyMode = ScoppedProxMode.TARGET_CLASS)

  - 해당 스코프 선언시,
    빈 생성이 어플리케이션 구동 시점x -> but 빈의 `실행시점`에 이루어짐
    = lazybinding

    why? 
    @Value - 빈의 실행 시점에 값을 참조할 수 있음
    
  - @Value("#{jobParameters['parameterName']}")
  - @Value("#{jobExecutionContext['parameterName']}")
  - @Value("#{stepExecutionContext['parameterName']}")

  주의)
  - `@Value` 사용 시 빈 선언문에 @JobScope or @StepScope 선언 x 시, 예외발생
  - 프록시 모드 -> 구동시점에는 프록시, 실제 호출시점에 빈 생성
    (AOP)
  - 병렬 처리 시 각 스레드마다 생성된 스코프 빈이 할당
    = 각각 생성 후 할당
    -> 스레드에 안전하게 실행가능

### @JobScope
  - Step 선언에 정의
  - `jobParameter`, `jobExecutionContext` 사용가능

### @StepScope
  - Tasklet, ItemReader, ItemWriter, ItemProcessor 선언문에 정의
  - `jobParameters`, `jobExecutionContext`, `stepExecutionContext` 사용가능

example
```kotlin
@Bean
fun simpleJob() = jobBuilderFactory.get("simpleJob")
    .start(step1(null)) # 컴파일 오류를 내지 않기 위해서 null 값 일단 할당
    .next(step2())
    .build()

@Bean
@JobScope
fun step1(
    @Value("#{jobParameters['requestDate']}" requestDate: String
)
...

@Component
@StepScope
class MyJobParameter : Tasklet {
    
    @Value("#{jobParameters['name']}")
    lateinit var name: String
    
    ...
}
```

### Architecture
  - `@JobScope`, `@StepScope` 붙은 빈 선언 = Proxy 객체 생성
    = @Scope(value = "job(step)", ProxyMode = ScopedProxyMode.TARGET_CLASS)
  - Job 실행 시 Proxy 객체가 실제 빈 호출 
    -> 해당 메서드 실행
 
* Job, StepScope
  - Proxy 객체의 실제 대상이 되는 Bean을 등록 or 해제하는 역할
  - `실제 빈을 저장`하고 있는 JobContext, StepContext를 가지고 있다.
    = like `ApplicationContext`
      (ac.getBean으로 빈을 얻어오는 것과 유사)

* JobContext, StepContext
  - 스프링 컨테이너에서 생성된 빈을 저장하는 컨텍스트 역할
  - Job의 실행 시점에서 프록시 객체가 실제 빈을 참조할 때 사용


                                              생성할 빈 메소드 or 클래스 호출 &
                                                      @Value 바인딩 처리
     어플리케이션 구동                                           |
    ApplicationContext                                           |
            |                                      createBean --------> new Step -------
            |                                           |                               |
       createBean()                                      -- BeanFactory <-----          |
            |                                                                 |         |
            |                                                                no         |
       @JobScope? -- No --> 기본 싱글톤 빈 생성,                              |         |
            |               @Value 사용 시 예외발생                           |         |
           Yes                                                                 -- yes --
            |                                                                 |         |
            |                                                            bean exists?   |
            |                                                                 |         |
  해당 Bean의 Proxy 생성                          프록시의 실제 Bean 등록/관리|         |
            |                                    ---------> JobScope ---> JobContext    |
            |                                   |                            |          | 
            |                                   |           (새로 생성시 만)  <-- 등록--
            |                                   |                                       |
스프링 초기화 완료 및 Job실행             참조할 빈 구하기                    <- 꺼내기- 
            |                                   |                            |
             ---> JobLauncher ---> Job ---> Proxy Step -------> 실제 Step <--
                          Job은 프록시 객체 저장      Proxy가 실제 Step 호출 시 생성
                                                                    |
                                                                    |
                                                               Tasklet 실행

### in source level

1. ScopeConfiguration
``` 
static {
    jobScope = new JobScope()
    jobScope.setAutoProxy(false)
    
    # StepScope도 동일한 원리로 작동한다.
    stepScope = new StepScope()
    stepSCope.setAutoProxy(false)
}
  
  * JobScope
    - jobContext 가지고 있음 
    - 참조할 실제 빈을 여기에 저장한다.
    - get, remove, getContext ... (similar to ApplicationContext indeed)

참고)
- Job 생성 시 등록되는 스텝, 구성요소가 @~Scope를 달고 있다면 Proxy 객체가 생성/주입된다.

...

2. SimpleStepHandler.handleStep
(still proxy up to here)
then,
   JobInstance jobInstance = execution.getJobInstance()
   StepExecution lastStepExecution = jobRepository.getLastStepExecution(
      jobInstance, step.getName() ## here, a step method is invoked - 실제 Bean 생성
   )

  instead of step.getName, 
  1) onto `AopProxy`

    * call `invoke`
    - get TargetSource
    - targetSource.getTarget() ## step의 메소드를 호출하기 위해 실제 타겟 구하기

  2) onto `JobScope.get`
    - getContext (jobContext)
    with
      name: scopedTarget.step*, objectFactory (스프링 빈을 구할 수 있는 타입의 객체)
    - Object scopedObject = context.getAttribute(name)

    ```
    if (scopedObject == null) {
        synchronized(mutex) {
          scopedObject = context.getAttribute(name)
          
          if (scopedObject == null) { ## 여전히 null 이라면 생성한다.
              scopedObject = objectFactory.getObject()
                ## 빈을 생성한다.
                ### first, getContext
                ### 실제 bean 클래스 or 메소드 호출
                ### 생성 시 @Value 바인딩
              context.setAttribute(name, scopedObject) ## 생성한 빈을 등록한다.
          }
        }
    }
    ```
