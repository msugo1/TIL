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

### 멀티 윈도우
가로 분할, 세로 분할이 존재

1. 가로 분할
  - `:split`, `ctrl+w s`, `ctrl+w n
  
  or when open

  - vim `-o` file1 file2 ..
  
  # 새 창
  - `:new` or `ctrl+w n`

2. 세로 분할
  - `:vsplit`, `ctrl+w v`
  
  or when open

  - vim `-o` file1 file2 ..

 # 새 창
  - `:vnew` or `ctrl+w N`

3. 창 닫기
  1) 현재 창
  - `:quit`, or `ctrl + w q`
  
  2) 현재 창만 남기기
  - `:only` or `ctrl + w o`

4. 창간 이동
  - ctrl + w w: 다음 창으로 이동
  - ctrl + w k: 윗 창으로 이동
  - ctrl + w j: 아래 창으로 이동
  - ctrl + w h: 왼쪽 창으로 이동
  - ctrl + w l: 오른쪽 창으로 이동
  - ctrl + w t: 최상단 창으로 이동
  - ctrl + w b: 최하단으로 이동

5. 창 이동
  - ctrl + w K: 윗 창으로 이동
  - ctrl + w J: 아래 창으로 이동
  - ctrl + w H: 왼쪽 창으로 이동
  - ctrl + w L: 오른쪽 창으로 이동

6. 창 크기 조절
  - ctrl + w // ctrl + w -: 높이 증가/감소
  - ctrl + w _ or /: 높이 최대화
  - ctrl + w > // ctrl + w <: 폭 증가/감소
  - ctrl + w |: 폭 최대화
  - ctrl + w: 높이/폭 모두 같게

7. 기타 기능
  - 새 창에서 tag jump
  : ctrl + w ]
  - 커서 위치의 파일 이름을 새창에서 열기
  : ctrl + w f

### 단축키 지정
- 어떤 모드에서 어떤 키에 어떤 액션을 지정하겠다.

map - normal, visual, select, oppend
nmap  - normal
vmap - visual, select
smap - select
xmap - visual
omap - oppend
map! - insert cmdline
imap - insert
lmap - insert, cmdline, lang-arg
cmap - cmdline
tmap - terminal

1. 기본 문법
:CMD LHS RHS
- CMD: map, nmap, imap
- LHS: 입력할 키
- RHS: 입력 시 동작

* 키 표현
- <C-key>: CTRL + key
- <S-key>: SHIFT + key
- <A-key>: ALT + key
- <C-S-key>: CTRL + SHIFT + key

* 특수 키 표현
- <BS>
- <Tab>
- <CR>, <Enter>, <Return>
- <ESC>
- <Space>
- <Up> / <Down> / <Left> / <Right>
- <F1> - <F12>
- <Insert>
- <Del>
- <Home>
- <End>
- <PageUP>
- <PageDown>

ex.
* normal mode, F8 = printf()
  = `:nmap <F8> oprintf("%s %d line: \n", __func__, __LINE__); <ESC>

* insert mode, F8 = print()
  = `:imap <F8> printf("%s %d line: \n", __func___, __line__); <CR> (Enter)

* F2 누르면 커서 위의 단어를 cscope find symbo로 매핑해서 실행
  = `:nmap <F2> :cs find s <C-R>=expand("<cword>")<CR><CR>

  cs - cscope
  find s - cscope command
  <C-R=expand("<cword>") - 커서 위의 단어 가져오기

  = `:nmap <F7> :man <C-R>=expand("<cword>")<CR>
