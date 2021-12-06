# 한계
1. JDK with interface-based proxy
- 구체 클래스로 타입 캐스팅이 불가능하다.
(JDK proxy는 인터페이스를 구현했지, 그 구체클래스가 무엇인지는 전혀 idea가 없다...)
    = ClassCastException

vs CGLIB
    = 구체클래스를 기반으로 프록시 생성
    = 따라서, 구현 클래스로 당연히 캐스팅 가능하다.

MemberService <-- MemberServiceImpl <-- CGLIB Proxy
* 진짜 문제는 의존관계 주입에서 발생한다.

2. CGLIB with inheritance-based proxy
- 상속 기반이기 때문에, 한계점이 있다.

* 대상 클래스에 기본생성자 필수
    = 상속해서 호출 시 부모의 기본생성자가 먼저 불리므로
* 생성자 2번 호출문제
    = 실제 target 객체 생성시 호출
    = 프록시 객체 생성시 부모생성자 호출
    (스프링은 objenesis 라이브러리로 1, 2 문제 해결)
* final 키워드와의 궁합문제
