# 전략 패턴
  - 변하지 않는 부분을 두는 곳: Context
  - 변하는 부분을 두는 곳: Strategy
  - 그리고 이 둘을 사용하는 Client

                             <interface>
    Context --------------->  Strategy
    execute()                  call()
                                 |
                              ------
                             |      |
                          call()  call()
                        strategy1 strategy2


* example
```
class ContextV1(val strategy: Strategy) {
    
    private val log = LoggerFactory.getLogger(this::class.java)

    fun execute() {
        val startTime = System.currentTimeMillis()
        strategy.call()
        val endTime = System.currentTimeMillis()
        val resultTime = endTime - startTime
        log.info("resultTime = $resultTime")
    }
}

interface Strategy {
    fun call()
}

@Test
fun strategyV3() {
  val context1 = ContextV1(object : Strategy {
      override fun call() {
      log.info("비즈니스 로직1 실행")
      }
      })
  context1.execute()
}
```

* 선조립 후 실행
  = 조립 후 Context를 실행만 하면 된다.
    -> 스프링 로딩 시 의존관계 주입 후 요청 처리와 비슷
  = Context + Strategy 한 번 조립 후에는 변경이 어렵다.
    -> Setter를 제공할 수 있으나, 컨텍스트를 싱글턴으로 사용하면 동시성 이슈 발생가능 -> 고려할 점이 많다.

# 컨텍스트 실행 시점에 직접 파라미터로 전략을 전달하기 (like DI!)
```
class ContextV2 {

    private val log = LoggerFactory.getLogger(this::class.java)

    fun execute(strategy: Strategy) {
        val startTime = System.currentTimeMillis()
        strategy.call()
        val endTime = System.currentTimeMillis()
        val resultTime = endTime - startTime
        log.info("resultTime = $resultTime")
    }
}

@Test
fun strategyV1() {
    val context = ContextV2()
    context.execute(object : Strategy {
        override fun call() {
            log.info("비즈니스 로직1 실행!")
        }
    })
}
```

- Context를 실행할 때마다 전략을 전달
- 실행시점에 원하는 전략을 유연하게 전달할 수 있음
- 하나의 컨텍스트만 필요!

* startegy pattern with a parameter

    Client ---------->  Context  
                        execute() ----- strategy.call() --------> Strategy
           <----------            <----                 <--------  call()

- 단점: 실행할 때마다 전략을 계속 지정해줘야..
= 상황에 맞게 쓰자!

# 템플릿 - 콜백 패턴
* 콜백: Callback
- 다른 코드의 인수로서 넘겨주는 실행가능한 코드
- Context - Strategy 중 `Strategy`

= 스프링에서 자주 사용하는 방식 (정식적인 GOF 디자인패턴은 아님)
  - 전략 패턴에서 템플릿, 콜백 부분이 강조된 패턴
  - xxxTemplate으로 되어 있는 경우!


# In Short
- 템플릿 - 콜백 패턴을 적용해 코드 최적화
- but, still 원본코드를 수정해야 한다. 이전과 비교해서 더 힘들게 or 덜 힘들게 수정하냐의 차이
 
