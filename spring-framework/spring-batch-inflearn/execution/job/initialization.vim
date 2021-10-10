### JobLauncherApplicationRunner
- 스프링 배치 작업을 시작하는 애플리케이션 Runner
  = BatchAutoConfiguration에서 생성
  = 스프링 부트에서 제공하는ApplicationRunner의 구현체
  = 애플리케이션이 정상적으로 구동되자마자 실행
   default: 빈으로 등록된 모든 job 실행  
   (특정 job만 실행하도록 설정가능)

### BatchProperties
- Spring Batch의 환경설정 클래스
  = 이 클래스의 환경변수를 이용해서 배치 컴포넌트 초기화
- job name, schema 초기화 설정, 테이블 prefix 등의 값들을 설정가능

ex.
```yaml
batch:
  job:
    names: ${job.name:None}
  initialize-schema: NEVER
  tablePrefix: SYSTEM
```

* Job 실행 옵션
- 지정한 배치잡만 실행하기
  `--job.name=<name>`
  `--job.name=<name1>,<name2>...`
- 인자로 넘겨줄 수 있다. (Program Args)
 
in properties
  - batch.job.names: ${job.name:NONE}
    = program args 로 job 이름을 넘길 수 있음
    = 아무것도 넘어오지 않으면 NONE -> 배치 실행x

internally
  - 위에 설정한 값이 BatchProperties 빈으로 등록
  - BatchAutoConfiguration.jobLauncherApplicationRunner 에서 가져다 쓴다.
  - `,` 를 delimiter로 나누기 때문에 ,를 기준으로 잡을 여러개 등록할 수 있다.

