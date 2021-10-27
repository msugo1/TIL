### StepBuilderFactory
   - jobBuilderFactory와 similar

### StepBuilder
  - 스텝을 구성하는 설정 조건에 따라 다섯 개의 하위 빌더 클래스를 생성
    then, 실제 Step 생성위임

1. TaskletStepBuilder
  - TaskletStep 생성

2. SimpleStepBuilder
  - TaskletStep 생성 but 내부적으로 청크기반 작업을 처리하는 ChunkOrientedTasklet 생성

3. PartitionStepBuilder
  - PartitionStep 생성 -> 멀티 스레드 방식으로 Job을 실행

4. JobStepBuilder
  - JobStep 생성 -> Step 내에서 Job을 실행

5. FlowStepBuilder
  - FlowStep 생성 -> Step 안에서 Flow 실행


                                                       --------> tasklet(tasklet()) ---> taskletStepBuilder
                                                      |
  StepBuilderFactory --- get(stepName) --> StepBuilder --------> chunk(chunkSize) -------
                  = API 파라미터 타입, 구분에 따라 적절한 하위빌더 생성                  |
                                                      |                                  |
                                                      |                                  |
                                                       --------> chunk(completionPolicy) -> simpleStepBuilder
                                                      |
                                                      |
                                                       --------> partitioner(stepName, partitioner) -
                                                      |                                              |
                                                      |                                              |
                                                       --------> partitioner(step) -----> PartitionerStepBuilder
                                                      |
                                                      |
                                                       --------> job(job) --------------> JobStepBuilder
                                                      |
                                                      |
                                                       --------> flow(flow) ------------> FlowStepBuilder


### StepBuilderFactory, StepBuilder
- 이름만 다르고 JobBuilderFactory <-> JobBuilder 관계와 매우 비슷하다.

                            StepBuilderFactory
                                     |
                                     |
                                    \ /
  CommonStepProperties <---- StepBuilderHelper ----> AtomicReference ----> SimpleJobRepository
                                  /  |   \           <JobRepository>
                                 /   |    \
                                /    |     \
          AbstractTaskletSteBuilder  |      --------------- ------------ ------------------
                /      \             |                     \             \                  \
               /        \             ----- StepBuilder     \             \                  \
              /          \                       |           \             \                  \
  TaskletStepBuilder <-- SimpleStepBuilder ---------- PartitionStepBuilder  JobStepBuilder FlowStepBuilder
              \           /                                           |            |              |
               \         /                                            |            |              |
                \       /                                            \ /          \ /            \ /
                 \     /                                        PartitionStep   JobStep         FlowStep
               TaskletStep

* JobRepository는 빌더 클래스를 통해 Step 객체로 전달
  = 메타데이터를 기록하는데 사용

