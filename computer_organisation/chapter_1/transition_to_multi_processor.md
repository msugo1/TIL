단일 프로세서에서 한 프로그램의 응답시간을 줄이는 추세
    -> 이제는, 멀티 프로세서를 집적한 마이크로 프로세서로
    = 멀티코어

### 병렬 프로그래밍은 어렵다. Why?
1. 성능 중시
- 편리한 인터페이스 제공으로는 충분하지 않고, 실행시간도 빨라야 한다.

2. 프로세서가 대략 비슷한 양의 일을 동시에 수행하도록 잘 분할해줘야 한다.
    + 분할된 일을 스케줄링하고 조정하는 오버헤드가 작아야 한다.
- 부하를 어떻게 `공평`하게 분배할 수 있을까?
- 통신 및 동기화 `오버헤드`를 어떻게 줄일 수 있을까?
    = 한 일이 끝나기 전에 다른 것들을 할 수 없다면 아무 효용이 없다.
(스케줄링, 부하 균형, 동기화 시간, 통신 오버헤드 등... 신경쓸 것 투성이 ㅠㅠ)


