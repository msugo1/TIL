### 스트링 치환
1. :%s/str(찾을 str)/replace(바꿀 str)
  = % -> 문서 전체
  = / -> 구분자

2. :%s/str/replace/g 
  = 다중 검색시에도 적용 (apply to multiple ones)

3. :%s/str/replace/gc
  = 치환 시 사용자에게 묻기

4. :%s/\<str\>/replace/gc
  = str을 단어 단위로 검색

### 라인 지정 스트링 치환
1. :1,10s/str/replace/gc
  = 라인 1~ 10에 대해서만 치환 적용

2. :,.s/str/replace/gc
  = 라인 1~ 현재 라인까지 치환 적용

### 라인 지정 스트링 치환
1. `.` -> 현재 라인

2. `1` -> 라인 1

3. `$` -> 문서의 마지막라인

### 라인 수를 찾기가 힘들다면?
  = visual mode

가장 중요한 것은 search를 잘하는 것

### Regular Expression
(검색 시 가장 많이 사용한다.)

주요 의미 기호
- `.`
  =  newline을 제외한 모든 문자
  ex) /a.c
- `^`
  = 문장의 시작(line의 시작)

- `$`
  = 문장의 끝(line의 끝)

- `*`
  = zero or more
  ex) .* (어떤 문자가 0번 or 여러 번)

- `\+`
  = one or more

- `\=`
  = zero or one

- `\{n}`
  = n회 반복

- `\{n, m}`
  = n~m회 반복

- `\{, m}`
  = 최대 m회 반복

- `\{n, }`
  = 최소 n회 반복

- `[0-9]`
  = 0~9 사이의 캐릭터

- `[a-z]`
  = a~z 사이의 캐릭터

- `[abc]`
  = a, b, c 중 하나와 매치되는 캐릭터

- `[^0-9]`
  = 0~9를 제외한 캐릭터

examples
1. `/sem_.*(.*)`
  = sem_으로 시작하여 함수를 호출/선언하는 경우

2. `/^#include`
  = 문장의 시작에 `#include`가 나오는 경우

3. `/\<inotify_`
  = 단어가 `inotify_`로 시작하는 경우

4. :%s/\<variable\>/var/g
  = 문서 전체에서 variable을 찾아 var로 변경

