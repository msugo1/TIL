### Architecture

1. for ItemReader (only skip is supported)


                                                             SimpleChunkProvider
                                                                    /|\
                                                                     |                                         read()
  Step ---> RepeatTemplate ---> ChunkOrientedTasklet ---> FaultTolerantChunkProvider ---> RepeatTemplate ---> ItemReader <---
                 /|\                                                                           /|\                |          |
                  |                                                                             |                 |          |  Yes
           Step 실패 종료                                                                        ---- No ---- Exception?     |  
                  |                                                                                               |          |
                  |                                                                                               | Yes      |
                  |                                                                                              \|/         |
                   ------------------------------ throw NonSkippableReadException ---------------------- No --- Skip? -------
                                                                                                                  |
                                                                                                                  |
                                                                                                      LimitCheckingItemSkipPolicy

  - 스킵 시 해당 부분은 건너 뛰고 바로 다음을 읽는다. (only for ItemReader)
    = intuitive!


2. for ItemProcessor

 TaskletStep ---> RepeatTemplate ---> ChunkOrientedTasklet ---> FaultTolerantChunkProcessor ---> ChunkIterator <----- ------------           
                       /|\                                                                             |             |            |
                        |                                                                             \|/            |            |
                        |                                                                        RetryTemplate       |            |
                        |                                                                              |             |            |
                        |                                                                              |             |            |
                        |                                                                             \|/            |            |
                        |                                                                         RetryCallback      |            |
                        |                                                                              |             |            |
                        |                                                                        No    |             |            |
                        |                                                     SimpleRetryPolicy ---- retry?          |            |
                        |                                                             |                |             |            |
                        |                                                             |                |             |            |
                        |                                                             |               \|/            |            |
                         ------- Step 재시도 ------------------------------ Yes ------------------  Exception ------ No           |
                        |                                                             |                                           |
                        |                                                             |                                           |
                        |                                                             |                                           |
                        |                                                             |                                           |
                        |                                                              -----------> RetryCallback ## 예외발생 but retryLimit 초과
                        |                                                                                 |                       |
                 Step 실패 종료                                                                           |                       |
                        |                                                                                \|/                      |
                        |                                                                               Skip? --- yes --- skip 아이템 제거
                        |                                                                                 |
                        |                                                                             No  |
                        |                                                                                 |
                         ------------------ throw SkipLimitExceededException -------------- LimitCheckingItemSkipPolicy
                                               

3. for ItemWriter
                              
  TaskletStep ---> RepeatTemplate ---> ChunkOrientedTasklet ---> FaultTolerantChunkProcessor ---> RetryTemplate <------------ 
                       /|\                                                                             |                     |
                        |                                                                             \|/                    | 
                        |                                                                         RetryCallback              |
                        |                                                                              |                     |
                        |                                                                              |     No              |
                        |                                                     SimpleRetryPolicy ---- retry? --------         |
                        |                                                                              |            |        |
                        |                                                                        Yes   |            |        |
                        |                                                                             \|/           |        |
                        |                                                                          ItemWriter       |        | ## 예외가 발생하고
                        |                                                                              |            |        | ## retryLimit 초과
                        |                                            Yes                              \|/           |        |
                        | ------ Step 재시도 ----------------------------------------------------- Exception        |        |
                        |                                             No                               |            |        |
                        | ------ Step 성공 종료 -------------------------------------------------------             |        |
                        |                                                                                           |        |
                        |                                                                           RetryCallback <--        |
                        |                                                                                 |                  |
                 Step 실패 종료                                                                           |                  |
                        |                                                                    No          \|/  Yes            |
                        |                                                            ------------------ Skip? ----- doScan으로 복구작업
                        |                                                           |                     |
                        |                                                           |                     |
                        |                                                           |                     |
                         ------------------ throw SkipLimitExceededException -------        LimitCheckingItemSkipPolicy
                              

