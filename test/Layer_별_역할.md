# Layer 별 역할

= Layer 별 테스트가 필요한 사항들

## 어댑터

---

### Input

- 입력 변환
  - from **inbound request message**  to **inbound request object**
  - from **inbound request object** to **usecase command/query**

- 권한검사

- 입력 유효성 검증

- 유즈케이스 호출

- 출력변환
  
  - from **usecase return** to **inbound response**

- 응답반환
  
  - send inbound response to the client 



**스프링이 처리해주는 것**

- 입력 변환, 출력변환, 유효성검증



**스프링 시큐리티가 처리해주는 것**

- 권한검사





### Output

- 입력변환
  
  - infrastructure 전송될 포맷에 맞는 형태로 변환

- 변환된 입력 전송

- 출력변환
  
  - infrastructure 에서 받은 응답을 애플리케이션에 맞는 형태로 변환

- 변환된 출력 반환


