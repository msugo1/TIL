## Interprocess Communication (IPC, 프로세스간 통신)

### 공유 메모리 vs 메시지 전달
1. 메시지 전달
- 협력 프로세스들 사이에 교환되는 메시지를 통해 협력
- 충돌을 회피할 필요가 없다.
    = 적은 양의 데이터를 교환하는데 유용
    = 공유메모리봐 구현하기 편하다.

2. 공유 메모리
- 공유 메모리를 구축할 때만 시스템 콜 필요(vs 메시지 시스템: 시스템 콜을 사용하여 구현 = 커널 간섭 등 부가적인 시간소비 작업)
    = 이후에는 공유 메모리 접근 시에 일반적인 메모리 접근으로 취급(= 커널의 도움이 필요 없다.)

### IPC example
1. POSIX Shared Memory
- `메모리 - 사상` 파일을 사용하여 구현
    = 메모리의 특정 영역을 파일과 연관시킨다.
    = 공유 메모리 객체 생성: `fd = shm_open(name, 0_CREAT | 0_RDWR, 0666)` (인자: 이름, 존재하지 않으면 생성, 읽기/쓰기, 권한)
    (파일 오픈 성공 시, 공유 메모리 객체를 나타내는 정수형 파일 설명자 반환)
    = 객체 설정 후 `ftruncate()`: 객체의 크기를 바이트 단위로 설정)
    ex. `ftruncate(fd, 4096)`
    = 마지막으로 `mmap()` 함수가 공유 메모리 객체를 포함하는 `메모리 - 사상` 파일 구축
    (공유 메모리 객체에 접근할 때 사용될 해당 파일의 포인터 반환)
- MAP_SHARED: 공유 메모리 객체에 변경 발생 시, 객체를 공유하는 모든 프로세스가 최신의 값에 접근할지의 여부

2. Mach 메시지 전달
- Mach 커널은 프로세스와 유사, but 제어 스레드가 많고, 관련 자원이 적은 다중 태스크의 생성 및 제거를 지원
- 모든 태스크 간 통신을 포함하여 대부분의 통신은 `메시지`로 수행
    = port 라고 하는 메일박스로 메시지를 주고받음
    = port를 사용해서 태스크, 스레드, 메모리 및 프로세서와 같은 자원을 나타낸다.
- 메시지 전달은 위의 시스템 자원 및 서비스와 상호작용하기 위한 객체지향 접근방식을 제공
    = 동일한 호스트 or 분산 시스템의 별도 호스트의 두 포트 사이에서 메시지 전달이 발생할 수 있다.
- 포트와 상호작용하는데 필요한 자격을 식별하는 `포트권한` 집합이 각 포트와 연관된다.
    ex. MACH_PORT_RIGHT_RECEIVE: 태스크가 포트에서 메시지를 수신하기 위한 권한
    = 포트권한의 소유권은 태스크에게 주어진다.
    (ex. 동일한 태스크에 속하는 모든 스레드는 동일한 포트 권한을 공유)
- 태스크 생성 시, Task Self/Notify 포트 생성(special)
    = 커널은 Task Self 포트에 대한 수신 권한을 가지고 있다. (태스크가 커널에 메시지를 보낼 수 있음)
    = 다시, 커널은 이벤트 발생 알림을 작업의 Notify 포트로 보낼 수 있다. (태스크는 해당 포트의 수신권한을 가진다.)
- 각 태스크는 또한 부트스트랩 포트에 액세스 할 수 있다.
    = 태스크가 생성한 포트를 시스템 전체의 부트스트랩 서버에 등록할 수 있다.
    = 포트가 부트스트랩 서버에 등록되면? (다른 태스크가 이 레지스트리에서 포트를 검색 -> 포트로 메시지를 보낼 수 있는 권한을 얻을 수 있다.)
- Mach 메시지의 필드(헤더 with 메타 데이터, 바디)
- out-of-line: 복잡한 메시지의 경우
    = 데이터가 저장된 메모리 위치를 가리키는 포인터
    (간단한 경우 복사해서, 아닌 경우 포인터)
- 전송할 포트의 큐에 메시지가 가득찬 경우?
    1) 큐에 공간이 생길 때까지 무기한 기다린다.
    2) 최대 n 밀리초 동안 기다린다.
    3) 기다리지 말고 바로 복귀한다.
    4) 일시적으로 메시지를 캐시한다. (큐가 가득차더라도 운영체제에 전달하여 보존)
        = 송신 스레드마다 하나의 메시지만 커널에 보관가능
- 메시지 시스템의 주요 문제점
    = 송신자의 포트 -> 수신자의 포트 `메시지 복사` (성능 저하)
    = Mach 메시지 시스템은 가상메모리 관리 기술을 사용해서 복사연산을 피하려고 한다.
    (송신자의 메시지가 포함된 주소 공간을 수신자의 주소 공간에 매핑 -> 송/수신자 모두 동일한 메모리에 액세스 -> 메시지 복사X)
    = 같은 시스템 내 메시지에만 가능한 기법

### 파이프
- 두 프로세스가 통신할 수 있게하는 `전달자`로서 동작

(제약)
1. 단방향 or 양방향 통신?
2. (양방향) 반이중 or 전이중 방식?
    = 반이중: 한 순간에 한 방향 전송만
    = 전이중: 동시에 양방향 데이터 전송
3. 통신하는 두 프로세스 간에 `부모 - 자식`과 같은 특정 관계가 존재해야 하는가?
4. 파이프는 네트워크를 통하여 통신이 가능한가? 아니면 동일한 기계 안에 존재하는 두 프로세스 끼리만 통신할 수 있는가?

1) 일반 파이프
- 생산자 <-> 소비자 형태로 두 프로세스 간의 통신허용
    = 일반 파이프는 단방향 통신만 가능(양방향을 위해서는 파이프 두개 필요)
- 파이프를 생성한 프로세스 외에는 접근할 수 없다.
    = 부모 프로세스가 파이프 생성 -> fork로 생성한 자식 프로세스와 통신
- 파이프는 파일의 특수한 유형
    = 자식 프로세스는 부모로부터 파이프 상속

부모                        자식

fd[0] --------------------> fd[1]
fd[1] <-------------------- fd[0]

2) 지명 파이프(Named Pipes)
- 일반 파이프는 오로지 프로세스들이 서로 통신하는 동안에만 존재
- 지명 파이프는 좀 더 강력한 통신도구 제공
    = 양방향(반이중이므로 2개 FIFO 필요)
    = 부모-자식관계 불필요
    = 여러 프로세스들이 사용가능(다수의 writer)
    = 통신 프로세스가 종료하더라도 지명 파이프는 계속 존재
- FIFO in UNIX
    = 생성되면 일단 파일 시스템의 보통 파일처럼 존재
    mkfifo() 
    = open, read, write, close 콜로 조작
    = 명시적으로 파일 시스템에서 삭제될 때까지만 존재

### Client <-> Server environment communication
1. Socket
- 통신의 양 끝점
    = 총 두 개의 소켓이 필요하다.
- ip addr + port
- 서버는 지정된 포트에 클라이언트 요청 메시지가 도착하기를 기다림
    = 요청 수신 시, 서버는 클라이언트 소켓으로부터 연결 요청 수락
- TCP, UDP
- 스레드간에 구조화되지 않은 바이트 스트림만을 통신
    = 너무 낮은 수준(though 분산된 프로세스 간에 널리 사용되고 효율적)
    = 원시적인 바이트 스트림 데이터를 구조화하여 해석하는 것은 클라이언트/서버 책임

**well-known port**
- 표준 포트
    = SSH: 22, FTP: 21, HTTP: 80, HTTPS: 443 ...
- 1024 미만 포트는 모두 well-known으로 간주. 표준서비스 구현에 사용

### RPC: Remote Procedure Calls (원격 프로시저 호출)
- 프로시저 호출 기법의 추상화
- IPC와 유사 but 프로세스들이 서로 다른 시스템 위에 돌아가므로, 원격 서비스를 제공하기 위해서는 `메시지 기반 통신`
- IPC 방식과는 달리, RPC 통신에서 전달되는 메시지는 `구조화` 되어 있음
    = 데이터의 패킷 수준을 넘어선다.

클라이언트의 원격 호스트 프로시저 호출
    -> RPC는 그에 대응하는 스텁 호출. 원격 프로시저가 필요로하는 매개변수를 건네줌
    -> 스텁이 원격 서버의 포트를 찾고 매개변수를 정돈(marshall)
    -> 이후 스텁은 메시지 전달 기법을 사용하여 서버에 메시지 전송
    -> 서버측 스텁이 메시지 수신 후 적절한 서버의 프로시저 호출

**매개변수 정돈** 
= parameter marshalling
- 클라이언트와 서버 기기의데이터 표현 방식의 차이 문제 해결
(big endian vs little endian)
    = 컴퓨터마다 다르다.
    = 중립적인 형태의 XDR 형태로 바꾸기 (external data representation)
    = 수신측 기계에서 XDR 데이터 받으면, 매개변수를 풀어서 자기 기종의 형태로 데이터 변경 -> 서버로 전달

- RPC의 경우 네트워크 오류로 실패 or 메시지가 중복되어 호출이 여러 번 발생할 수 있다.
    = `정확히 한 번` 처리되도록 보장이 필요하다.
    = 클라이언트가 ACK 메시지를 받는다. (받지 못하면 주기적으로 RPC 호출)

**클라이언트는 서버의 포트 번호를 어떻게 알 수 있을까?**
- 일반적인 프로시저 호출의 경우 바인딩 작업이 링킹/적재/실행 시점에 행해진다.
    = 클라이언트 <-> 서버는 보통 둘 간의 공유 메모리가 없으므로, 서로에 대한 정보가 없다.

1. 고정된 포트번호(compile 시)
    = 이후 변경 불가
2. 랑데부 방식에 의해 동적 바인딩
    = 운영체제는 미리 정해져 있는 고정 RPC 포트를 통해 랑데부용 디먼을 제공(= matchmaker)
    = 클라이언트가 실행을 원하는 RPC의 이름을 담은 메시지를 랑데부 디먼에게 전송. RPC 이름에 대응하는 포트번호 질의
        -> 포트 번호가 클라이언트에게 반환
        -> 이후 클ㄹ라이언트는 해당 포트번호로 요청
    = 초기에 오버헤드가 들지만 첫 번째 방식보다 유연





