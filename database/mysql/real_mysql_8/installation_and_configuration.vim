# 서버에 연결하기
```
1. mysql -u root -p (--host=localhost --socket)
2. mysql -u root -p (--host=127.0.0.1 --port=3306)
```

1. unix 소켓을 사용해서 서버에 접속
2. tcp/ip 이용해서 서버에 접속

* 원격지 서버 응답여부 체크하기
1. telenet <ip> <port>
2. nc <ip> <port>

# 5.7 -> 8.0 변경사항
1. 사용자 인증방식
- since 8.0, Caching SHA-2 Authentication (vs 5.7 Native Authentication)
    = to keep going with Native Authentication, add `--default-authentication-plugin=mysql_native_password`

2. 외래키 이름의 길이 제약
- since 8.0, only up to 64글자

3. 공용 테이블 스페이스 for partitions
- since 8.0, 파티션의 각 테이블 스페이스를 공용 테이블스페이스에 저장불가

4. 테이블 딕셔너리
- in 5.7, in 별도 파일 with .FRM
- InnoDB 테이블(with transaction support)
(for more details, turn to page 34)

# 설정파일 위치/우선순위 파악하기
- `mysqld --verbose --help`

# SET PERSIST
- 동적변수는 `SET = ` 통해 서버 기동후에도 설정변경 가능
    = But, 파일에 설정이 적용된 것은 아니므로, 서버 재시작 후에는 기존 값이 적용된다.
- 파일에 따로 저장하고 싶으면 `SET PERSIST` 활용
    = 물론, my.cnf 파일이 아닌 별도 파일에 저장된다고 한다.
    (in mysql-auto.cnf)
- SET PERSIST 명령은 세션 변수에는 적용되지 않는다.
    = MySQL 서버가 자동으로 GLOBAL 시스템 변수의 변경으로 인식/변경
- 현재 변경x, but 다음 재시작을 위해 파일에만 기록하는 방법?
    = SET PERSIST_ONLY
    = 정적인 변수의 값을 영구적으로 바꿀 때도 활용가능

* SET PERSIST 명령으로 추가된 변수 삭제?
    = RESET PERSIST





