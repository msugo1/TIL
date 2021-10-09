### JVM
- 자바 가상머신
- 자바 바이트 코드(.class)를 OS에 특화된 코드로 변환
- 이후 실행 (with the Interpreter & JIT Compiler)
- 바이트 코드를 실행하는 표준 & 구현체
  (JVM 자체는 표준 -> 이것을 벤더들이 구현)
- 특정 플랫폼에 종속적

* JVM만 홀로 제공되지 않는다.
  = at least as JRE

### JRE(Java Runtime Environment)
= JVM + Library
- 자바 애플리케이션을 실행할 수 있도록 구성된 배포판
  = 자바 애플리케이션을 실행하는 것이 목적(실행에 필요한 최소한의 것들)
  = JVM & 핵심 라이브러리 및 자바 런타임 환경에서 사용하는 프로퍼티 세팅, 리소스 파일 등
- 개발 관련도구는 포함하지 않음
  -> JDK
  ex. Javac not in JRE


### JDK(Java Development Kit)
- JRE + 개발에 필요한 툴
- from Java11, only JDK is provided (not JRE alone)   

### JAVA
- Programming Language
- compiled by Javac(Java Compiler)

* Java 외에도 여러 JVM 기반 언어가 존재한다. ex) Kotlin, Groovy
ex. `.kt`
- kotlinc로 컴파일
- java 명령어로 바로 실행할 수는 없다.
- kotlinc `.kt` -include-runtime -d `.jar`
  = jar 파일로 만든 후 java -jar `.jar`
  (물론 이렇게 실행하지는 않는다. thanks to IDE!)

### JVM의 구조
1. Class Loader System
: loding, linking, initialization
  (컴파일 된 바이트 코드를 읽어 들여서 메모리에 배치)

- link
  = reference를 연결하는 과
- initialization
  = static 값들을 초기화 및 변수에 할당

               |
               |

2. Memory
: stack, PC(PC registers), native method stack, heap, method

- 메소드 영역
  = 클래스 수준의 정보(클래스 이름, 부모 클래스 이름, 메소드, 변수) 저장
  = 공유자원
  (다른 영역에서도 참조할 수 있는 정보)

- 힙 영역
  = 객체를 저장
  = 공유자원
  (실제 인스턴스 들 + 묵시적으로 만들어진 객체들 = ex. 클래스 타입의 객체들) 

** 이하 영역의 것들은 각 스레드마다 별도의 저장 공간을 가진다. **
- 스택 영역
  = 각 쓰레드 마다 런타임 스택 만듦
  (이 안의 메소드 호출을 스택 프레임으로 쌓인다.)
  = 쓰레드가 종료되면 런타임 스택도 사라진다.

- PC(Program Counter) 레지스터
  = 쓰레드마다 쓰레드 내 현재 실행할 스택 프레임을 가리키는 포인터가 생성된다.

- 네이티브 메소드 스택
  = 네이티브 메소드를 호출할 때마다 생기는 별도의 메소드 스택

          native method stack
                  |
                  |
    ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ  
   |                                  |
   |                         native method interface
   |                                  |
   |                                   ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ native method library
   |                                  (네이티브 메소드를 사용하기 위해서 native method interface를 거처야 한다.)
   |
   |                        * native method
   |                          = native 키워드 at first, java가 아닌 c or c++로 구현
   |                                 
   |
   |
실행 엔진
- 인터프리터
- JIT Compiler
- GC

  = 컴파일 된 바이트 코드를 `한 줄씩` 호출하면서 native code로 바꿔서 기계가 이해할 수 있도록 한다.
    by interpreter
  = 효율을 높이기 위해 반복되는 코드는 미리 native code로 변환해둔다. 
      or 여러 번 실행되거나 기준을 충족하는 코드가 있다면 native code로 통채로 컴파일 해버린다.
    (interpreter가 컴파일 된 코드를 만나면 해석 없이 바로 사용한다.)
    (why programs tend to be slow at first then faster and faster as time goes by)
    by JIT Compiler

* GC
- 더이상 참조되지 않는 객체를 모아서 정리한다.

### 클래스 로더 시스템

1. 로딩

BootStrap

    |

Extension

    |

Application
(or BootStrap - Platform - Application)
- 최상위 BootStrap ClassLoader는 네이티브 코드로 구현되어 있어서 자바에서 참조해서 출력할 수 없다.
- 99%는 애플리케이션 클래스 로더에서 정보를 불러온다.
- 클래스 로딩 요청을 받으면 제일 부모 = BootStrap 로더 부터 읽기 시작한다.
  (없으면 아래로 타고 내려간다.)
- 셋 다 해당 클래스를 찾을 수 없으면 `ClassNotFoundException`이 발생한다. 

  = 클래스 로더가 .class 파일을 읽고, 그 내용에 따라 적절한 바이너리 데이터를 만든다.
  = 이후 메소드 영역에 해당 데이터를 저장한다.
  * what is stored?
  1) FQCN (Fully Qualified Class Name) 
    -> 패키지 경로까지 포함한 Full Name
    PackageName + ClassName + ClassLoader
  2) whether it is a class, interface or enum?
  3) 메소드 & 변수
  
  = 로딩이 끝나면 해당 클래스 타입의 클래스 객체를 생성하여 힙 영역에 저장

2. 링크

Verify

  |

Prepare

  |

Resolve

  * Verify
    = 검증
    = .class 파일이 유효한지 체크
 
  * Preparation
    = 메모리 준비과정
    (클래스에 있는 static 변수 및 기본 값에 필요한 메모리 준비)

  * Resolve
    = 심볼릭 메모리 레퍼런스를 메소드 영역에 있는 실제 레퍼런스로 교체
    (Optional - 이때 혹은 나중에 객체를 사용할 때 발생할 수 있음)
    = Symbolic Reference: 논리적 연결
    = 실제 레퍼런스: 힙영역에 있는 실제 인스턴스 참조

3. 초기화
- 준비한 값을 할당
  = 스태틱 변수는 이때 모두 할당
  = 스태틱 블록도 이때 실행

### 가장 중요한 것은 바이트 코드 ###
### 실행을 위해서는 바이트 코드가 필요하다 ###
### 바이트 코드를 직접 조작이 가능하다. ###
