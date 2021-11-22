# ThreadLocal
- 해당 쓰레드만 접근할 수 있는 특별한 저장소
  = 각 쓰레드마다 별도의 내부저장소 제공

* 사용법
1. 값 저장
  = ThreadLocal.set(xxx)
2. 값 조회
  = ThreadLocal.get()
3. 값 제거
  = ThreadLocal.remove()

* 주의
- 해당 쓰레드가 쓰레드 로컬을 모두 사용하고 나면, `ThreadLocal.remove()`를 호출해서 쓰레드 로컬에 저장된 값을 제거해주어야 한다.

  ## 쓰레드 풀을 사용하는 경우 심각한 문제가 발생할 수 있다.
  - 사용이 끝난 쓰레드를 풀에 반환 -> 재사용 -> 기존의 데이터가 살아있게 된다. (without .remove())


