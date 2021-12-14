# OSIV - Open Session In View (in hibernate)
(in JPA, Open EntityManager In View)

* Persistent Context
- 일반적으로 트랜잭션을 시작한 시점에 JPA가 가져온다.

반환시점은?
- with OSIV: 가져온 영속성 컨텍스트를, 트랜잭션이 끝나고(in a service layer), 컨트롤러 계층으로 넘어가도 반환X
    = Persistent Context & Database Connection alive till the response is fully done

* OSIV 시작시점? (찾아보자)

* 단점(trade-off)
- 커넥션을 너무 오래 유지한다.
    = 실시간 트래픽이 중요한 애플리케이션에서, 커넥션이 모자랄 수 있다.
    = 장애로 이어진다.
    ex. Controller -> 외부 API 호출 시, API 호출이 끝나는 동안 리소스 반환불가

# without OSIV? (OSIV = off)
- 모든 지연로딩은 트랜잭션 안에서 처리되어야 한다.
- 컨트롤러 or interceptor/filter 단에서 지연로딩 된 부분을 사용하려면, 트랜잭션이 끝나기 전에 강제호출되어야 한다.
(대신 커넥션 리소스는 낭비 X)

* 커맨드와 쿼리 분리?
- 쿼리용 서비스를 별도로 만든다.
with OSIV off
    = 일반적으로 성능이슈가 발생하는 부분 = 조회
    = 복잡한 화면을 출력하기 위한 쿼리는, 화면에 맞추어 성능 최적화가 필요하다

* osiv를 키면 간단명료한 코드를 작성할 수 있다는 장점이 있다.
    but 커넥션 등 문제가 생길 수 있다.

따라서,
* 실시간 성능이 중요한 부분 with so much traffic 
- normally no osiv
but admin that doesn't require as many connections - with osiv

