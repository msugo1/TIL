### Job Parameter

- Job을 실행할 때 함께 포함되어 사용되는, 파라미터를 가진 도메인 객체
- 하나의 잡에 존재할 수 있는 여러 개의 잡 인스턴스를 구분하기 위한 용도
- Job Parameters (1) : Job Instance (1)

* 생성 & 바인딩
1. 어플리케이션 실행 시 주입
  ex. java -jar LogBatch.jar requestDate=20210101
  
  then with SpEL
  = @Value("#{jobParameters['requestDate']}
  이때, Scope 빈으로 선언은 필수! (lazy Binding을 위해서)
    - why? 기본 값은 null을 넣어주므로 스코프 빈이 아니라면 제대로 빈 생성이 되지 않더라

2. 코드로 생성
  JobParametersBuilder, DefaultJobParametersConverter

* relations

              JobParameters
          (Job Parameter Wrapper)
   
- (LinkedHashMap<String, JobParameter>) parameters = internally
                  
                      |
                      |
                     \ /
                Job Parameter
        - (Object) parameter
        - (ParameterType) parameterType
        - (boolean) identifying    

* ParameterType
  - String, Date, Long, Double

### 값들은 BATCH_JOB_EXECUTION_PARAM에 저장

/*
    in Tasklet
    How to get job parameters

    1. with `contribution`
 */
val jobParameters1 = contribution.stepExecution.jobExecution.jobParameters
jobParameters1.getString("name")
jobParameters1.getLong("seq")
jobParameters1.getDate("date")
jobParameters1.getDouble("age")

// 2. with `chunkContext`
// 하지만 타입이 다르다
// 위에는 JobParameters, 여기는 Map<String, Object>
val jobParameters2 = chunkContext.stepContext.jobParameters
