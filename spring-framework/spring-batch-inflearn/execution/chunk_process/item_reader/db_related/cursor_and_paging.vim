### Cursor & Paging
  - 배치 어플리케이션은 실시간적 처리가 어려운 대용량 데이터를 다룬다.
    = DB I/O의 성능 문제와 메모리 자원의 효율성 문제를 어떻게 처리?

* Cursor-Based
  - Jdbc ResultSet의 기본 메커니즘
    = 현재 행에 커서 유지, 다음 데이터 호출하면 다음 행으로 커서 이동
    = streaming

  - ResultSet이 open 될 때마다 next() 호출 -> DB 데이터 반환 -> 객체와의 매핑

  - DB Connection 연결 후 배치 처리가 완료될 때까지 데이터를 읽어온다.
    = 커넥션 유지를 위해 SocketTimeout을 충분히 큰 값으로 입력해야 한다. ## 중요 ##

  - 모든 결과를 메모리에 할당
    = 메모리 사용량이 많아진다.

  - Connection 연결 유지 시간, 메모리 공간이 충분한 경우 대량의 데이터 처리에 적합

  - fetchSize를 조절해 한번에 가져올 데이터 크기를 결정할 수 있다.

* Page-Based
  - 페이징 단위로 데이터 조회
    = PageSize 만큼 한 번에 메모리로 가지고 온 다음 하나씩 읽는다.

  - 한 페이지를 읽을 때마다 Connection을 맺고 끊는다.
    = 대량의 데이터 처리시에도 SocketTimeout 예외가 거의 없다.

  - with `offset & limit`

  - 페이징 단위의 결과만 메모리에 할당
    = 메모리 사용량이 적어지는 장점

  - 커넥션 연결 유지 시간이 길지 않고, 메모리 공간을 효율적으로 사용해야 하는 데이터 처리에 적합

### 프로세스

            
1. Cursor Based -----read----> DataBase
                <-------------    |
                   Streaming      |
                                  |
                       (fetch) item 1 <-- cursor  |
                       (fetch) item 2 <-- cursor  |
                       (fetch) item 3 <-- cursor  |
                       (fetch) item 4 <-- cursor  |
                       (fetch) item 5 <-- cursor  |  One Connection
                       (fetch) item 6 <-- cursor  |
                       (fetch) item 7 <-- cursor  |
                       (fetch) item 8 <-- cursor  |
                       (fetch) item 9 <-- cursor  |
                        

2. Paging Based -----read----> DataBase
                 offset/size      |
                                  |
                   Paging ----------------- offset
                                item 1        |
                                item 2        |
                                item 3        | One Connection
                                item 4        |
                                item 5        |
                          ----------------- size, offset
                                item 1
                                item 2
                                item 3
                                item 4
                                item 5
                          ----------------- size
