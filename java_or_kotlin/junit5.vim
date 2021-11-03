@DisplayNameGeneration(DisplayNameGenerator.ReplaceUnderscores::class.java)
  - 테스트 메소드 이름 대체 based on the strategy specified here (or probably @DisplayName)

# Assertion

* assertAll(
  () -> assertNotNull( ... ),
  () -> assertEquals( ... ),
  () -> assertTrue( ... )
)


- assert 구문 실패 시, 기본적으로 다음 구문은 실행하지 않음
- 위처럼 all로 묶으면 모두 실행한다. (성공, 실패 상관없이)
  = lambda를 사용해서 호출


* asssertTimeout
  = 테스트 메소드가 특정 시간 안에 끝나는지 검증

ex. assertTimeout(Duration.ofSeconds(10), () -> {
  Thread.sleep(1100)
})

  
  assertTimeoutPreemtively
  - 위의 타임아웃은 정해진 시간을 넘어도 끝날 때까지 대기 후 결과리턴
  - 이 타임아웃은 시간 넘으면 무조건 바로 실패처리

  ## ThreadLocal을 사용하는 경우 제대로 테스트가 안될 수 있음에 주의한다.

* assumTrue
- 값이 참인 경우만 다음의 테스트를 실행한다.

similar to `assumingThat`

- how to use?
  1. assumeTrue("LOCAL".equals(System.getenv("TEST_ENV"), true))
    + test code from the next line

  2. assumingThat("LOCAL".equals(System.getenv("TEST_ENV"), true)) {
          // 실행할 로직
  }


- or with annotations

`@Enabled`, `@Disabled`

ex. @DisabledOnOs(OS.MAC)
    @EnabledOnOs(OS.LINUX)

    @EnabledOnJre(JRE.JAVA_8)

    @EnabledIfEnvironmentVariable(named = "TEST_ENV", matches = "LOCAL")


# 테스트 태깅과 필터링

@Test
@DisplayName
@Tag("fast_test")
@Tag("slow_test")

in intellij
  =  Edit Configuration -> Test Kind: Tags -> Tag Expression 등록

- maven or gradle 설정을 통해, 빌드 시 실행할 테스트를 결정할 수도 있음

# 테스트 반복
@RepeatTest(n)

@RepeatTest(value = n, name = ?)

in name
- {displayName}
- {currentRepetition}
- {totalRepetition}

@ParameterizedTest
= 다른 값들 가지고 테스트하기

@ValueSource
= 값 부여

ex.
```kotlin
@ParameterizedTest
@ValueSource(strings = {"날씨가", "많이", "추워지고", "있어요"})
fun parameterizedTest(String message) {
    println(message)
}
```
= value 개수 만큼 테스트 반복, 각 value 값이 message에 전달
= 암묵적인 타입 변환이 가능
= 명시적인 매핑을 위해서는 컨버터가 있어야 한다.
(ex. SimpleArgumentConverter & @ConvertWith)
```
@ParameterizedTest
@ValueSource(@ConvertWith(StudyConverter.class) study: Study) {
    ...
}

class StudyConverter : SimpleArgumentConverter {

    override fun covert ... = Study( ... )
}
```

주의)
  - argumentConverter는 한 파라미터 타입에만 적용가능하다.
  - 타입이 여러 개인 경우 각 파라미터를 매핑 한 후 전달 or `aggregator` or Argument Accessor

```
class StudyAggregator : ArgumentsAggregator {
    
    override fun aggregateArguments(argumentAccessor, parameterContext) = Study(accessor.getInteger(0), accessor.getString(1))
}

fun parameterizedTest(@AggregateWith(StudyAggregator::class) study: Study) ...  

```

@ParameterizedTest(name = {index} {displayName} message = {0})

{index} - 현재 파라미터의 인덱스
{0} - 현재 인덱스에 있는 파라미터 출력
{displayName} - @DisplayName description 출력

@NullSource
@EmptySource
= @NullAndEmptySource

@CsvSource({""}) 
= 여러 타입의 값들을 한 번에 넘겨줄 수 있다.

# 테스트 인스턴스
- 기본적으로 메소드 당 새 인스턴스
  = 순서에 의한 의존성을 제거하기 위해
- JUnit5에서는 인스턴스 전략을 변경할 수 있다. (클래스 당 1개만 생성되도록)
  = `@TestInstance(TestInstance.LifeCycle.PER_CLASS)
  = 이 경우 BeforeAll, AfterAll이 static할 필요가 없다.


& @TestMethodOrder(MethodOrderer.OrderAnnotation.class)
  - Junit's @Order

  @Order(1), @Order(2), @Order(3) ... = the lower, the higher priority

# junit-platform.properties
= test.resources.junit-platform.properties
(resources - test directory로 설정필요)

in properties
junit.jupiter.testinstance.lifecycle.default = per_class
junit.jupiter.conditions.deactivate = org.junit.*DisabledCondition
junit.jupiter.displayname.generator.default = \ 
    org.junit.jupiter.api.DisplayNameGenerator$ReplaceUnderscores


# Junit5 확장모델
= Extension only

