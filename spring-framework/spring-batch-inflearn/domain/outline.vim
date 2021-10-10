# Spring Batch

### outline
* 탄생 배경
- 자바 기반 표준배치 기술 부재
- SpringSource meets Accenture

* 핵심 패턴
1. read - DB, File, Queue에서 다량의 데이터 조회
2. process - 특정 방법으로 데이터 가공
3. write - 데이터를 수정된 양식으로 다시 저장

* 예상 시나리오
1. 배치 프로세스를 주기적으로 commit
2. 동시 다발적인 Job의 배치 처리, 대용량 병렬처리
3. 실패 후 수동 또는 스케줄링에 의한 재시작
4. 의존관계가 있는 step 여러 개를 순차적으로 처리
5. `조건적` Flow 구성을 통한 체계적이고 `유연한` 배치 모델 구성
6. 반복, 재시도, Skip 처리

### architecture
= 3 layers

 ㅡ Application
|     | |
|  Batch Core
|     | |
 ㅡBatch infrastructure

* Application
- 스프링 배치 프레임워크를 통해 개발자가 만든 모든 배치 Job과 커스텀 코드를 포함
- 개발자는 업무로직의 구현에만 집중
  = 공통적인 기반기술은 프레임워크가 담당

* Batch Core
- Job을 실행, 모니터링, 관리하는 API로 구성
- JobLaucnher, Job, Step, Flow 등
  = Job 실행을 어떻게 구성하겠다.(Job 명세서)

* Batch Infrastructure
- Application, Core 모두 공통 Infrastructure 위에서 빌드
- Job 실행의 흐름과 처리를 위한 틀을 제공함
- Reader, Processor, Writer, Skip, Retry 등
  = 실제적인 배치 실행에 관련된 클래스들이 포함



