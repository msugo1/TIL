### Code Coverage
* How many of my source codes are covered by test codes?

Then, how are code coverage solutions made?
- read byte codes, and mark where to count, then count where marks are while running the source codes and then compare
- then display where the programme has passed or where not
- 바이트 코드 조작으로 이러한 기능을 수행할 수 있게된다.

* Bytecode 조작 library
1. ASM
2. Javassist
3. Byte Buddy

```kotlin
(example with ByteBuddy)
class Moja {
    fun pullout() = ""
}

fun main() {
    ByteBuddy().redefine(Moja::class.java)
        .method(named("pullout")).intercept(FixedValue.value("Rabbit!"))
        .make().saveIn(File("/Users/soo/Desktop/toyproject/hello-spring/out/production/classes/"))

    println(Moja().pullout())
}

(위에 pullout 메소드에는 아무것도 없지만, 출력시 Rabbit이 나온다.)
```

### JavaAgent
- byte 관련 스펙?

```java
public static void premain(String agentArgs, Instrumentation inst) {
    new AgentBuilder.Default()
            .type(ElementMatchers.any())
            .transform((builder, typeDescription, classLoader, module)
                    -> builder.method(named("pullout"))
                    .intercept(FixedValue.value("Rabbit")))
            .installOn(inst);
}
```
- maven 문제로 아쉽게 실습은 못따라서 해봤음
  = 나중에 해결해서 다시 해볼 예정(일단 지금은 시간을 너무 많이 썼음)
  = jar 파일 gradle로 생성하는 법 including javaagent results 또한 찾아야 한다.

- jar 파일을 VM options -javaagent=`path`에 설정해주면, 조작한 클래스를 가져다 쓸 수 있다.
  = 클래스 로딩할 때 javaagent를 거쳐서 변경된 바이트코드를 읽어 사용한다.
  (메모리 내부엔 이미 박혀있다. - 좀 더 transparent(비 침투적)인 방법)

### 바이트 코드 조작은 다양한 곳에 활용된다.
- 프로그램 분석, 코드 복잡도 계산
- 클래스 생성
  = 프록시, 특정 API 호출 접근제한, 컴파일러
- etc
  = 프로파일러, 최적화, 로깅 ... (without contaminating original classes)

even component scan in Spring!
