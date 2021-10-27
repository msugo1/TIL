### CompletionPolicy

                    CompletionPolicy
      
          - boolean isComplete(RepeatContext, RepeatStatus)
          ## 콜백의 최종 상태 결과를 참조, 배치가 완료되었는지 확인

          - boolean isComplete(RepeatContext)
          ## 콜백이 완료될 때까지 기다리지 않음

* 구현체
1. TimeoutTerminationPolicy
  = 반복시점부터 현재시점까지 소요된 시간이 설정된 시간보다 크면 반복종료

2. SimpleCompletionPolicy
  = 현재 반복횟수가 Chunk 갯수가 크면 반복종료

3. CountingCompletionPolicy
  = 일정한 카운트를 계산 및 집계해서 카운트 제한 조건이 만족하면 반복종료


