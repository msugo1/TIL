### Parallel Steps
  - SplitState를 사용해서 여러 개의 Flow 들을 병렬적으로 실행하는 구조
  - 실행이 다 완료된 후, FlowExecutionStatus 결과들을 취합해서 다음 단계 결정을 한다.


                                                                 -----> Woker (FutureTask with SimpleFlow)
                                                                |
                                                                |
    Job ---> Flow ---> SplitState(flows) ---> TaskExecutor -----------> Woker (FutureTask with SimpleFlow)
                                                                |
                                                                |
                                                                 -----> Woker (FutureTask with SimpleFlow) 


   results
--------------> FlowExecutionAggregator




                              SplitState
  
                      - Collection<Flow> flows 
                 ## 병렬로 수행할 Flow 들을 담은 컬렉션

                      - TaskExecutor taskExecutor
                    ## Thread를 생성하고 Task를 할당

                  - FlowExecutionAggregator aggregator
              ## 병렬로 수행 후 하나의 종료상태로 집계하는 클래스

            - FlowExecutionStatus handle(FlowExecutor executor)
     



                      Job
                       |
                       |
                       |
                  SimpleFlow <------------------------------------
                       |                                          |
                       |                                          |
                       |                                          |
                  SplitState                                      |
                       |                                          |
                       |                                          |
                       |                                          |
                  TaskExecutor                                    |
                       |                                          |   return FlowExecutionStatus
   -----------------------------------------                      |   = COMPLETED, STOPPED, FAILED, UNKNOWN
  |                    |                    |                     | (최종 실행결과의 상태값을 반환
Worker1             Worker2             Worker2                   |     -> 다음 Step 결정)
  |                    |                    |                     |
  |                    |                    |                     |
FutureTask        FutureTask            FutureTask                |
(SimpleFlow)      (SimpleFlow)          (SimpleFlow)              |
  |                    |                    |                     |
  |                    |                    |                     |
FlowExecution     FlowExecution         FlowExecution             |
   \                   |                   /                      |
    \                  |                  /                       |
                                                                  |
          Collection <FlowExecution>                              |
                       |                                          |
                        ----------------------------> FlowExecutionAggregator
                        aggregator.aggregate(results)


### API
1. start(flow) ## flow 생성
2. split(taskExecutor).add(flow2(), flow3()) ## taskExecutor에서 flow 개수만큼 스레드 생성, 실행


### in codes
1. .split(taskExecutor()).add(flow2())
  - FlowBuilder.add(Flow ... flows)
  ...
  - State next = parent.createState(list, execution)

2. FlowBuilder.createState(Collection<Flow> flows, TaskExecutor executor): SplitState
  ```
  if (!state.containsKey(flows)) {
      states.put(flows, new SplitState(flows, prefix + "split" + (splitCounter++)))
  }

  SpliState result = (SplitState) states.get(flows)
  if (executor != null) {
      result.setTaskExecutor(executor)
  }
  
  dirty = true
  return result
  ```

3. in SplitState
  ```
  for (Flow flow: flows) {
      FutureTask<FlowExecution> task = new FutureTask<>(new Callable<FlowExecution>() {
          @Override
          public FlowExecution call() throws Exception {
              return flow.start(executor)
          }
      }
  }

  tasks.add(task)

  ...

  taskExecutor.execute(task)
  ```

- 이후 각 태스크에 담긴 플로우 실행
  (구현체)

4. 플로우에 모든 과정이 끝난 후(SplitState)
  ```
  for (Future<FlowExecution> task : tasks) {
      try {
          results.add(task.get())
      }
  }

  ## 결과값들 취합 후 보내기

  doAggregation(results, executor)
  ```

5. SplitState.doAggregation(Collection<FlowExecution> results, FlowExecution executor): FlowExecutionStatus 
  - aggregator.aggregate(results)

6. MaxValueFlowExecutionAggregator.aggregate(Collection<FlowExecution> executions)
  ```
  if (executions == null || executions.size() == 0) {
      return FlowExecution.UNKNOWN
  }

  return Collections.max(executions).getStatus()


* 멤버변수 공유 시, 동기화 처리에 대한 주의가 필요하다.

### examples
```
    @Bean
    fun job() = jobBuilderFactory.get("batchJob")
        .incrementer(RunIdIncrementer())
        .listener(StopWatchJobListener())
        .start(flow1())
        .split(taskExecutor()).add(flow2())
        .end()
        .build()

    @Bean
    fun flow1(): Flow {
        val step1 = stepBuilderFactory.get("step1")
            .tasklet(tasklet()).build()

        return FlowBuilder<Flow>("flow1")
            .start(step1)
            .build()
    }

    @Bean
    fun flow2(): Flow {
        val step2 = stepBuilderFactory.get("step2")
            .tasklet(tasklet()).build()

        val step3 = stepBuilderFactory.get("step2")
            .tasklet(tasklet()).build()

        return FlowBuilder<Flow>("flow2")
            .start(step2)
            .next(step3)
            .build()
    }
```
