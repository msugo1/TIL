문자 데이터 - 여러 개가 모여서 문자열을 이룬다.
    = 가변

**길이**를 표현하는 방법?
1. 문자열 맨 앞에 길이를 표시 (in Java ..)
2. 같이 사용되는 변수에 그 길이를 표시
3. 마지막에 문자열의 끝을 표시하는 특수문자를 두기 (in C)

### String in Java
- Unicode
- lh: halfword 
    = 16비트 데이터에 대한 적재와 저장 명령어 포함
    = 메모리에서 16비트를 읽어서 레지스터의 우측 16비트에 할당
- lhu: load halfword unsigned
    = 부호없는 수 적재
- sh: store half
    = 우측 16비트를 메모리에 쓰기
```
lhu $t0, 0($sp)
sh  $t0, 0($gp)
```

