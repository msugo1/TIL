# MVC Pattern

1. C: Controller
- HTTP 요청을 받아서 파라미터 검증 & 비즈니스 로직 실행
- 뷰에 전달할 결과 데이터를 조회해서 모델에 담음

2. M: Model
- 뷰에 출력할 데이터를 모델에 담아둔다.
    = 뷰가 필요한 데이터를 모두 모델에 담아서 전달해주는 덕분에, 뷰는 비즈니스 로직 or 데이터 접근을 몰라도 된다.
    = 화면에 렌더링하는 일에 집중

3. V: View
- 모델에 담겨있는 데이터를 사용해서, 화면을 그리는 일에 집중


                                        invoke 
    Client --- request ---> Controller <------> (business logic) 
                                |       result 
                                |
                                 -------------> model <------------- view
                                                                      |
           <----------------------------------------------------------
               response


* dispatcher.forward
- 다른 서블릿 or JSP로 이동할 수 있는 기능(서버 내부 호출)

    ## redirect vs forward
    1) redirect: 실제 클라이언트에 응답 나간 이후, 클라이언트가 redirect 경로로 재요청 (클라이언트가 인지 가능 & URL도 변경)
    2) forward: 서버 내부에서 일어나는 호출 = 클라이언트 인지 X, 경로 변경X

* WEB-INF
- 외부에서 부를 수 없는 경로
    = 항상 컨트롤러를 거쳐서 내부에서 `forward` 되어야 함


# servlet-jsp only mvc pattern 한계
1. forward 중복
- request.getRequestDispatcher & dispatcher.forward 중복

2. viewPath 중복
- prefix, suffix
    ex. /WEB-INF/views/ & .jsp
    = 다른 뷰로 변경 시 전체 코드 다 변경해야 함...

3. 사용하지 않는 코드
- response 사용X
- HttpServletRequest, HttpServletResponse
    = HTTP에 종속적 & 해당 클래스를 사용하는 코드는 테스트를 작성하기도 어렵다.

4. 공통처리가 어렵다.
- 기능이 복잡해질수록 공통으로 처리해야 하는 부분이 증가함.
    = 해당 메서드를 항상 호출해야 한다.
    = 실수로 호출하지 않으면 문제발생...
    = 호출 자체가 중복

In short,
    공통처리가 어렵다는 문제가 있다.

This is why spring uses the front-controller pattern
- 수문장이 앞단에서 공통처리!

# front-controller pattern
1. 프론트 컨트롤러 서블릿 1개로 요청 받음
2. 프론트 컨트롤러가 요청에 맞는 컨트롤러 찾아서 호출

= 입구는 하나
= 공통처리
= 프론트 컨트롤러 외 나머지 컨트롤러는 서블릿 사용할 필요x

(Dispatcher Servlet in Spring)


