1. innodb_buffer_size
  - 가장 중요한 옵션 (in InnoDB)
  - 디스크의 데이터를 메모리에 캐싱
    + 데이터의 변경 버퍼
  - (운영체제 or MySQL 클라이언트에 대해) 서버 스레드가 사용할 메모리를 제외하고 남는 거의 모든 메모리 공간 설정

2. innodb_log_file_size, innodb_log_files_in_group
  - redo 로그 파일 하나의 크기
    & redo 로그 파일을 몇 개나 사용할 것인지?

  - 이 값이 너무 작게 설정되면, InnoDB 버퍼 풀로 설정된 메모리 공간이 아무리 많아도 제대로 활용할 수 없다.
    = InnoDB의 비효율적인 동작
    
* Lock wait timeout exceeed
  - 레코드 잠금끼리만 발생 
    = 테이블 잠금에는 적용X (is it?)

3. sort_buffer
  - 정렬을 목적으로 인덱스를 사용할 수 없는 경우
    = 정렬 대상 데이터를 메모리나 디스크의 버퍼에 저장, 이후 정렬 알고리즘으로 정렬
    = 대상 건수가 많다면 시간이 오래 소요된다.

4. join_buffer
  - 조인이 발생할 때마다 사용되는 버퍼는 X
  - 적절한 조인 조건이 없을 때
    = 드리븐 테이블의 검색이 `풀 테이블 스캔`으로 유도
    = Using Buffer in EXPLAIN

5. read_buffer
  - 정체 명확X (많은 스토리지 엔진에서 다른 용도로 사용)

6. read_rnd_buffer
  - MySQL에서 인덱스를 사용해 정렬할 수 없을 경우
    = 정렬 대상 데이터의 크기에 따라 Single-pass or Two-pass 알고리즘 사용

  정렬 기준 칼럼 값만 가지고 정렬 수행
    -> 정렬이 완료되면 다시 한 번 데이터 읽기
    = Two-Pass
  (Single-pass는 위 과정을 한 번에 처리하는 것 의미)
  
  * 정렬 순서대로 데이터를 읽을 때, 동일 데이터 페이지에 있는 것들을 모아서 한 번에 읽기
    = 더 빠른 데이터 Fetch 
    = 읽어야 할 데이터 레코드를 버퍼링하는데 필요한 것 == read_rnd_buffer
