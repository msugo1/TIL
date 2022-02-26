### Dispatcher
- CPU 스케줄러가 선택한 프로세서에 CPU 할당

하는일
1. context switch
2. 사용자 모드로 전환
3. 프로그램을 다시 시작하기 위해 사용자 프로그램의 적절한 위치로 jump

- 모든 프로세스의 context switching 시 호출
    = 가능한 최고로 빨리 수행되어야 한다.
- dispatcher latency
    = 디스패처가 하나의 프로세스를 정지 ~ 다른 프로세스의 수행 시작 하는데까지 소요되는 시간
- how often context switching happens in Linux?
    = vmstat 1 3 (1초 단위로 3줄 출력)

자발적 context swtiching vs 비자발적 ...
1. 자발적 ...
- 프로세스가 CPU 제어를 포기한 경우 
ex. I/O

2. 비자발적 ...
- 타임 슬라이스 만료 or 우선순위가 더 높은 프로세스에 CPU 선점 빼앗긴 경우


