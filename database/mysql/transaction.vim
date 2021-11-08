* transaction - for atomicity, consistency
* lock - for concurrency, isolation

# 트랜잭션의 범위는 가능한 작게!
  - 특히 커넥션 풀을 사용하는 경우, 불필요한 트랜잭션은 대기 시간을 발생시킬 수 있다.

# Lock in MySQL
