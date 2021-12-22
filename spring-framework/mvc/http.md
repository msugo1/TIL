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
