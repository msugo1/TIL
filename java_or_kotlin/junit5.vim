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
