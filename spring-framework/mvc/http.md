## @ModelAttribute
- 파라미터 객체 자동매핑 with setter
(can be left out)

## @RequestBody
```
1. HttpServletRequest.inputStream / HttpServletResponse.outputWriter
2. inputStream / outputWriter
3. HttpEntity
4. RequestEntity / ResponseEntity
5. @RequestBody / @ResponseBody
```
- converted by `HttpMessageConverter`
- nothing to do with @RequestParam, @ModelAttribute
- `@RequestBody`는 생략 불가능
    = 생략하면 `@ModelAttribute`가 붙어 버린다.

## HttpMessageConverter
    JsonConverter or StringConverter

- 여러 HttpMessageConverter가 이미 등록되어 있음
    = 클라이언트의 HTTP `Accept`헤더와, 서버의 `컨트롤러 반환 타입정보`를 조합해서 선택

요청: `@RequestBody`
    = 요청 데이터 타입 + Media Content-Type
응답: `@ResponseBody`
    = 응답 데이터 타입 + Accept Header(produces)

* canRead, canWrite
- 해당 클래스, 미디어타입을 지원하는지

* read, write
- 메시지 컨버터를 통해 읽고 쓰는 기능

### 0: ByteArrayHttpMessageConverter
- `byte[]`처리

### 1: StringHttpMessageConverter
- `String`

### 2: MappingJackson2HttpMessageConverter
- `객체` or `HashMap` & `application/json`

0순위 부터 순서대로 canRead/canWrite 호출, false 시 다음 순위로
 

## HttpMessageConverter가 사용되는 곳?
### 비밀은 handlerAdapter 
(especially, `RequestMappingHandlerAdapter`)
- 여기서 처리한 후 Controller(Handler)로 넘긴다.

### with ArgumentResolver
- 필요한 파라미터 생성 후, 값을 컨트롤러를 호출하면서 넘겨준다!
- 30개가 넘는 AR 존재;

### and ReturnValueHandler
- 컨트롤러의 반환 값 변환
    ex. ModelAndView, @ResponseBody, HttpEntity...

!()[./http/http_message_converter.png]


