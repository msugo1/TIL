# Stream File
  - 프로그램 < ---- 스트림 파일 ---- > 입/출력 장치
  - works like a bridge

  - 문자 배열 형태의 버퍼를 가지고 있음
    + 위치를 알아야 하므로, 버퍼의 메모리 위치 및 크기도 알아야한다.
  (위 정보로 버퍼의 상태 파악 -> 데이터 입출력)
  - `FILE` 구조체
    = 필요한 정보들을 묶어서 가지고 있다.

* 장점
  - 입출력 효율 improvement
    = 디스크 속도 <<<<<<<< 프로그램의 데이터처리 속도
    = 버퍼에 모아서 한 번에 보내면 속도 차이를 줄일 수 있다. (디스크가 버퍼 내용을 기록하는 동안, 프로그램은 다시 버퍼를 채운다)
  - 장치로부터 independent (입출력 함수가 장치에 직접 접근x -> 입출력 장치가 바뀌어도 함수를 수정할 필요가 없다.)
    = stream file <-> 입출력장치 연결은 운영체제가 담당

* fopen
  - 메모리에 스트림파일 생성
    + FILE 구조체 변수의 주소 반
  - fopen(filename, mode)
    MODE:  r - read, w - write, a - append

* fclose
  - fopen으로 연 파일 닫기
    = 닫을 파일의 파일포인터를 준다.
  - 성공적으로 파일을 닫으면 0, 오류가 발생하면 EOF 반환
  - fopen으로 만들어진 스트림 파일은 메모리를 사용한다.
    = 따라서, 파일 입출력을 끝나면 반드시 닫아줘야 한다.

* fgetc
  - 문자입력 함수
    = 파일에서 하나의 문자 입력, 반환
 
  how fgetc works
  1. 하드디스크에서 데이터를 가져와 버퍼를 채운다. (처음에는 버퍼가 비어있으므로)
    = 버퍼 크기만큼 데이터를 가져온다.
  2. 파일 포인터와 연결된 스트림 파일의 버퍼에서 데이터를 가져온다.
  3. 한 문자씩 반환
    = 위치 지시자를 활용해서 1, 2, 3 ... n 번째 문자 반환
    (지시자는 파일 open 시 0으로 초기화, 데이터를 읽을 때 해당 크기만큼 증가)
  4. EOF가 반환될 때까지 반복
    = `fgetc` 자체가 하드디스크에 있는 파일의 입력이 끝났음을 확인하는 방법?
      파일의 크기와 현재까지 읽어 들인 데이터의 크기 비교

* fputc
  - 문자 to a file!
  - fputc(char, file pointer)

  fputc ---> stream file's buffer ---> a file in the disk
        (개행 문자 출력 전까지 버퍼링)

  - `fflush` 함수를 사용하면 버퍼의 데이터를 즉시 장치로 
    = perhaps, in some situations where data consistency has to be secured
  (버퍼에 담겨있는 도중에 전원이 나가면 얘네는 소실되기 때문 ㅜ)

# 표준 입출력 스트림
- 운영체제가 프로그램 실행 시 만드는 스트림 파일
  = stdin, stdout, stderr

# text vs binary
- 데이터를 ASCII 코드 값에 따라 저장한 것 = text
- 나머지 binary
- 'b' or 't' 를 추가해서 파일의 형태 표시
  = rb, wb, ab, rt, wt, at
  = 파일의 형태를 별도로 표시하지 않으면 자동으로 텍스트 파일로 개방
    but, 파일의 형태 != MODE 인 경우 문제가 심각...
  = However, UNIX System isn't the same (텍스트 or 바이너리 모두 바이너리로 취급) - 어쩐지 출력 잘되더라;;

# + mode
- 읽고 쓰는 작업을 함께할 수 있다.

```c
#include <stdio.h>
#include "string.h"
 
int main() {
    FILE *fp;
    char str[20];

    fp = fopen("/Users/soo/CLionProjects/c-practice/a.txt", "a+");
    if (fp == NULL)
    {
        printf("파일을 만들지 못했습니다. \n");
        return 1;
    }

    while (1)
    {
        printf("과일 이름: ");
        scanf("%s", str);
        if (strcmp(str, "end") == 0)
        {
            break;
        }
        else if (strcmp(str, "list") == 0)
        {
            fseek(fp, 0, SEEK_SET);
            while (1)
            {
                fgets(str, sizeof(str), fp);
                if (feof(fp))
                {
                    break;
                }
                printf("%s", str);
            }
        }
        else
        {
            fprintf(fp, "%s\n", str);
        }
    }

    fclose(fp);
    return 0;
}
```
- 파일의 입력과 출력을 서로 전환할 때, `fseek` 함수 호출이 필요하다.
  = 버퍼의 데이터를 하드로 옮긴 후, 버퍼를 다른 작업을 위한 공간으로 설정
    or else 입출력 순서가 꼬인다.

* fseek
  = `int fseek(FILE *stream, long offset, int whence)`
  = whence를 기준으로 offset만큼 위치 지시자를 옮긴다.
  = 실패 시 0 반환

  for whence with possible offsets
  - SEEK_SET = 파일의 처음(양수만 가능)
  - SEEK_CUR = 파일의 현재위치 (음수, 양수 모두가능)
  - SEEK_END = 파일의 끝 (음수만 가능)

* feof
- 스트림 파일의 데이터를 모두 읽었는가?
- 파일의 끝이면 0 = true 를 반환한다.

# 다양한 파일 입출력 함수
* fgets, fputs
  - 문자열을 파일에 출력 or 파일로부터 데이터를 입력받을 때, line by line
  - `fgets`는 읽을 데이터의 크기가 크다면, 저장공간의 크기까지만 입력이 가능하다. (메모리 침범 가능성 제거)

compared to gets, puts
- gets: 문자열을 입력할 때 개행문자를 제거할 필요가 없다.
- puts: 출력 시 자동으로 줄을 바꿔준다.

BUT! 저장공간의 크기를 인자로 넘기지 않으므로... 메모리 침범가능성

* fscanf, fprintf
1. fscanf
- 파일에 저장된 문자열을 숫자로 변환해서 입력

2. fprintf
- 정수나 실수를 쉽게 파일에 write

둘 다, scanf, printf와 유사하지만 파일을 지정하는 것이 차이점

* fflush
- 스트림 파일을 사용하는 입출력 함수들이 버퍼를 공유하면, 예상과 다른 결과가 나올 수 있다.

ex.
```c
int main() {
    FILE *fp;
    int age;
    char name[20];

    fp = fopen("/Users/soo/CLionProjects/c-practice/a.txt", "r");

    fscanf(fp, "%d", &age);
    fgets(name, sizeof name, fp);

    printf("나이 : %d, 이름 : %s", age, name);
    fclose(fp);
  
    return 0;
}
```
- fscanf, fgets 함수가 개행문자를 처리하는 방식이 다르기 때문에, 실행결과가 예상과 다르게 나온다...
  = fgets: 개행문자가 나올때까지 문자열 입력 (up to '\n')
  = fscanf: 공백 - 입력데이터 구분용... 등

- 이때, `fflush` comes to the rescue
  `int fflush(FILE *)`
  = but 잘 사용해야 한다...
  = 잘못하면 버퍼에 있는 모든 것들이 비워질 수 있기 때문

- 따라서, fflush는 주로 write 시 유용
  = 버퍼를 비우면서 남은 데이터를 연결된 장치로 바로 write

* fread, fwrite
- 입출력할 데이터의 크기와 개수를 인수로 줄 수 있다.
  = 구조체, 배열 등 데이터 양이 많은 경우에도 파일에 쉽게 입출력이 가능하다.

- 숫자 <-> 문자 사이의 변환과정을 수행하지 않는다.
  = 입출력 효율을 높일 수 있다.
  = 그러나, 파일의 내용을 메모장 같은 편집기로 직접 확인이 불가능하다고 한다.


