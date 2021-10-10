### Spring Batch 활성화

* `@EnableBatchProcessing`
  - 스프링 배치가 작동하기 위해 선언해야 하는 어노테이션
  - 총 4개의 클래스를 실행시킴
  - 스프링 배치의 모든 초기화 및 실행 구성도 이루어짐
  - 스프링 부트 배치의 자동 설정 클래스가 실행됨으로, 빈으로 등록된 모든 Job을 검색해서 초기화와 동시에 Job을 수행하도록 구성됨

### 스프링 배치 초기화 설정 클래스
1. BatchAutoConfiguration
  - 스프링 배치가 초기화 될 때 자동으로 실행되는 설정 클래스
  - Job을 수행하는 `JobLaucnherApplicationRunner` 빈을 생성
    (ApplicationRunner - 스프링 부트가 초기화 후 해당 클래스를 구현한 구현체를 모두 실행시킴)

2. SimpleBatchConfiguration
  - JobBuilderFactory & StepBuilderFactory 생성
  - 스프링 배치의 주요 구성요소 생성 as Proxy

3. BatchConfigurerConfiguration
  1) BasicBatchConfigurer
    - SimpleBatchConfiguration에서 생성한 프록시 객체의 실제 대상 객체를 생성하는 설정 클래스
  2) JpaBatchConfigurer
    - JPA 관련 객체를 생성하는 설정 클래스
  (커스텀 BatchConfigurer 인터페이스도 구현이 가능하다.)

### 순서
    @EnableBatchProcessing
              |
              |
    SimpleBatchConfiguration
              |
              |
    BatchConfigurerConfiguration
(BasicBatchConfigurer -> JpaBatchConfigurer)
              |
              |
    BatchAutoConfiguration 

### 스프링 배치 시작
1. 스프링 배치 메타 데이터
  - Job -> Step -> Tasklet(or Chunk) 순으로 실행
  - Job이 구성되면 Job이 실행되는 동안 JobExecution 생성
  - Step이 실행되면 StepExecution 생성
  - 이러한 클래스들이 가지고 있는 데이터를 DB에 저장 for 상태 관리/추적
    (과거, 현재의 실행에 대한 세세한 정보, 실행에 대한 성공과 실패 여부 등을 일목요연하게 관리
      -> 배치운용에 있어 리스크 발생 시 빠른 대처)
  - DB와 연동 시 필수적으로 메타 테이블이 생성되어야 함
    = 스프링 배치에서 스크립트 제공
    = 수동생성 -> 스크립트 실행
    = 자동생성 -> spring.batch.jdbc.initialize-schema
      ALWAYS: 스크립트 항상 실행
      EMBEDDED: 내장 DB인 경우만 실행 (default)
      NEVER: 스크립트 항상 실행 안함(내장 DB일 경우 스키마 생성X -> 오류발생)

### DB 스키마
* Job related
1. BATCH_JOB_INSTANCE
  - Job이 실행될 때 JobInstance 정보 저장
    = job_name, job_key를 키로 하여 하나의 데이터가 저장
      (동일한 job_name, job_key로 중복저장이 불가능하다.)

  - job_key?
    = job_name + jobParameter then hash

2. BATCH_JOB_EXECUTION
  - job의 실행정보 저장
    = job 생성, 시작, 종료시간, 실행상태, 메시지 등을 관리
  
  - end_time
    = 실행이 종료된 시점을 timestampe로 기록
    = job 실행 도중 오류가 발생해서 job이 중단된 경우 값이 저장되지 않을 수도 있음

  - status
    = 실행상태를 저장(COMPLETED, FAILED, STOPPED ...)

3. BATCH_JOB_EXECUTION_PARAMS
  - job과 함께 실행되는 job parameters를 저장
  
  - job parameters에 대한 타입 정보도 담고있다.
 
4. BATCH_JOB_EXECUTION_CONTEXT
  - job의 실행동안 여러가지 상태정보, 공유 데이터를 직렬화해서 저장
  - step 간 서로 공유가능

  - short_context
    = job의 실행 상태정보, 공유데이터를 문자열로 저장
  - serialized_context
    = 직렬화 된 전체 컨텍스트 

* Step related
1. BATCH_STEP_EXECUTION
  - job execution과 동일한 목적, 내용 but for steps

  - end_time
    = job_execution과 마찬가지로 step 실행 중 에러가 발생해서 중단된 경우 값이 없을 수 있음
  
  `chunk-related`
  - commit_count
    = 트랜잭션 당 커밋되는 수
  - read_count
    = 실행시점에 read한 Item 수를 기록
  - filter_count
    = 실행 도중 필터링 된 item 수 기록
  - write_count
    = 실행 도중 저장되고 커밋된 아이템 수 기록
  - read_skip_count
    = 실행도중 read가 스킵된 아이템 수를 기록
  - write_skip_count
    = 실행도중 write가 스킵된 아이템 수를 기록
  - process_skip_count
    = 실행도중 process가 스킵된 아이템 수를 기록
  - rollback_count
    = 실행도중 rollback이 일어난 수를 기록
  - exit_message
    = status가 실패일 경우 실패 원인 등의 내용을 저장

2. BATCH_STEP_EXECUTION_CONTEXT
  - job execution context와 동일한 목적, 내용 but for steps

  - 스텝 생성마다 생성되고, 스텝 종료시 사라진다.
    = 스텝간 데이터를 공유하기 위해서는 stepExecutionContext가 아닌 jobExecutionContext를 사용해야 한다.
