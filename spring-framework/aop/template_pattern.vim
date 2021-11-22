# 템플릿 메서드 패턴
- 변하는 것과, 변하지 않는 것을 분리하기 위함
  = especially 단순하게 메서드로 추출하기가 힘들 때

ex. try, catch & 중간에 핵심로직


                      AbstractTemplate
                      ----------------
                          execute()
                        ------------
                           call()  
                             |
                             |
                      ------------------
                     |                  |
                     |                  |
                   call()             call()
        
                SubClassLogic1      SubClassLogic2


```
abstract class AbstractTemplate {

    private val log = LoggerFactory.getLogger(this::class.java)

    fun execute() {
        val startTime = System.currentTimeMillis()
        call()
        val endTime = System.currentTimeMillis()
        val resultTime = endTime - startTime
        log.info("resultTime = $resultTime")
    }

    abstract fun call()
}

class SubClassLogic1 : AbstractTemplate() {

    private val log = LoggerFactory.getLogger(this::class.java)

    override fun call() {
        log.info("비즈니스 로직 1 실행")
    }
}

class SubClassLogic2 : AbstractTemplate() {

    private val log = LoggerFactory.getLogger(this::class.java)

    override fun call() {
        log.info("비즈니스 로직 2 실행")
    }
}

```
                         
틀을 두고(변하지 않는 부분) in a parent class
상속으로 변하는 부분 구현 - 호출 in a child class
= 다형성

* with 익명 내부 클래스
@Test
fun templateMethod2() {
  val template1 = object : AbstractTemplate() {
    override fun call() {
      log.info("비즈니스 로직1 실행")
    }
  }
  template1.execute()

    val template2 = object : AbstractTemplate() {
      override fun call() {
        log.info("비즈니스 로직2 실행")
      }
    }
  template2.execute()
}

* 템플릿 메서드 패턴은 상속을 사용한다.
  = 상속에서 오는 단점을 그대로 안고 간다.
  ex. 부모 - 자식 클래스의 strong coupling in compile time
      what if 자식 클래스 doesn't make use of anything from 부모 클래스 but still had to inherit?
    
      좋은 설계 x
      - 부모에서 수정이 일어날 경우 자식이 영향을 받는다. 
      - 쓰지도 않는데 영향을 받는다?!

* 템플릿 메서드 패턴과 비슷하면서, 상속의 단점을 제거할 수 있는 것?
  = Strategy Pattern (전략패턴)

# 전략 패턴

