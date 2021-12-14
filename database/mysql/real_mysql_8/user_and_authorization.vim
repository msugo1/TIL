# System Account vs Regular Account
1. System Account
- DB 서버 관리자를 위한 계정
- 시스템 계정과 일반 계정관리 가능 & 그 외 중요작업(계정 생성, 삭제, 권한부여 등 && 실행중인 쿼리 강제종료 ... )

2. Regular Account
- for developers or programs
- 시스템 계정 관리 불가


# create accounts
from 8.0
    create user: 계정 생성
    grant: 권한 부여 (분리)

* 계정 생성 시 부여가능한 옵션
- 계정의 인증방식/비밀번호
- 비밀번호 관련 옵션(유효기간, 이력 개수, 재사용 불가기간)
- 기본 역할
- SSL 옵션
- 계정 잠금여부

ex.
```
CREATE USER 'user'@'%'
    IDENTIFIED WITH 'mysql_native_password' BY 'password'
    REQUIRE NONE
    PASSWORD EXPIRE INTERVAL 30 DAY
    ACCOUNT UNLOCK
    PASSWORD HISTORY DEFAULT
    PASSWORD REUSE DEFAULT
    PASSWORD REQUIRE CURRENT DEFAULT
```

1. IDENTIFIED WITH
- 사용자의 인증방식과 비밀번호 설정
- IDENTIFIED WITH + 인증방식 

* 인증방식
: 플러그인 형태로 제공
    1) Native Pluggable Authentication (up to 5.7)
    with SHA-1 알고리즘

    2) Caching SHA-2 Pluggable Authentication (default)
    with SHA-2 (보완된 버전)
    = Native Authentication -> 동일 해시값
    = SHA-2 -> Salt 활용 with 수천 번의 해시 계산 therefore, 동일 키로도 다른 결과가 만들어질 수 있다.
    = 연산 수행 시 오버헤드가 발생하므로, MySQL 서버가 해시 결과값을 메모리에 캐시해서 사용한다.
        (SCRAM 인증방식 - 평문 번호를 5천번 이상 암호화 해시함수를 실행해야 로그인 가능
            -> 무차별 대입 공격등을 어렵게 만들지만, 일반 유저도 접속이 느리게 만들 수 있다...)
    = 요 방식을 사용하려면 SSL/TLS or RSA 키페어를 반드시 사용해야 한다. == 클라이언트에서 접속 시, SSL 옵션 활성화 required

    * 기존과 인증방식이 다르므로, 5.7과의 호환이 필요하다면,
        SET GLOBAL default_authentication_plugin="mysql_native_password"
        (or in my.cnf)
        = 물론, 보안수준은 낮아진다.

    3) PAM Pluggable Authentication
    = 유닉스 or 리눅스 패스워드 또는 LDAP(Lightweight Directory Access Protocol) 같은 외부 인증을 사용할 수 있게 해준다.
    (only in MySQL Enterprise)

    4) LDAP Pluggable Authentication
    = Authentication with LDAP (only in MySQL Enterprise)

2. REQUIRE
- MySQL 서버 접속시, SSL/TLS 채널을 사용할지?
    = 별도 설정이 없으면, 비암호화 채널로 연결
    (Caching SHA-2 Authentication 사용 시, 암호화된 채널만으로 서버 접속가능)

3. PASSWORD EXPIRE
- 비밀번호의 유효기간 설정
    = 별도 설정 없으면 `default_password_lifetime` 만큼
    (응용 프로그램 접속용 계정에 유효기간 설정 시 위험할 수 있음)

* PASSWORD EXPIRE: 계정 생성과 동시에 비밀번호의 만료처리
* PASSWORD EXPIRE NEVER: 계정 비밀번호 만료X
* PASSWORD EXPIRE DEFAULT: follow default_password_lifetime
* PASSWORD EXPIRE INTERVAL n DAY: 당일부터 n일까지 유효

4. PASSWORD HISTORY
- 한 번 사용했던 비밀번호는 다시 사용하지 못하게 하도록 기억하기
    = `password_history` 테이블 사용

* PASSWORD HISTORY DEFAULT: password_history에 저장된 개수만큼 비밀번호 저장
* PASSWORD HISTORY: 최근 n개 까지만 저장

5. PASSWORD REUSE INTERVAL
- 한 번 사용했던 비밀번호의 재사용 금지기간 설정
    = default: password_reuse_interval

* PASSWORD REUSE INTERVAL DEFAULT: `password_reuse_interval`
* PASSWORD REUSE INTERVAL n DAY: n일자 이후에 비밀번호 재사용가능

6. PASSWORD REQUIRE
- 비밀번호가 만료되어 새로운 비밀번호로 변경할 때, 현재 비밀번호를 필요로 할지?
    = default: decided by `password_require_current`

* PASSWORD REQUIRE CURRENT: 현재 비밀번호 필요 (비밀번호 변경 시)
* PASSWORD REQUIRE OPTIONAL: 현재 비밀번호 반드시 필요X
* PASSWORD REQUIRE DEFAULT: follow `password_require_current`

7. ACCOUNT LOCK/UNLOCK
- create user or alter user 시, 계정을 사용하지 못하게 잠글지?

* ACCOUNT LOCK: 계정을 사용하지 못하게 잠근다.
* ACCOUNT UNLOCK: 잠긴 계정을 다시 사용가능상태로 잠금해제


# 고수준 비밀번호 관리
(with validate_password component) p.60
- 쉽게 유추할 수 있는 비밀번호 or 조합들 금지 등

* 수준
LOW: 비밀번호 길이만 검증
MEDIUM: additionally, 숫자/대소문자, 특수문자 배합 검증
STRONG: on top of MEDIUM, 금칙어 포함여부 검증
(금칙어 검증 등은 테이블을 활용한다.)


# 이중 비밀번호
- 비밀번호 변경 시 기존 비밀번호는 Secondary, 새 비밀번호는 Primary로 지정하기
(DB는 한 번 비밀번호를 지정하면 바꾸기 힘드므로)

ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password' RETAIN CURRENT PASSWORD;

(Secondary Password 삭제하기)
ALTER USER 'root'@'localhost' DISCARD OLD PASSWORD;
(이제 더이상 Secondary로는 로그인 불가능)


# 권한
up to 5.7, 글로벌 권한 + 객체단위 권한
in 8.0, 여기에 동적권한 추가

* 동적권한: 서버가 시작되면서 동적으로 생성하는 권한 (ex. 컴포넌트 or 플러그인 설치 시 등록되는 권한)
    = SUPER 권한이 잘게 쪼개어져, 동적권한으로 분산 
    p. 67 참조


# 역할
- 8.0부터 권한을 묶어서 역할을 사용가능
- 내부적으로 사용자 계정과 동일한 객체로 취급
    = 하나의 계정에 다른 계정의 권한을 `병합`하기만 하면되므로, MySQL 서버는 역할과 계정을 구분할 필요가 없다.
    = CREATE ROLE로 역할 생성 시, 뒤에 호스트를 명시하지 않으면 자동으로 `%`

ex.
```
# ROLE 생성하기
CREATE ROLE
    role_emp_read,
    role_emp_write;

# ROLE에 권한 부여하기 (권한이 부여되지 않은 ROLE은 껍데기)
GRANT SELECT ON employees.* TO role_emp_read;
GRANT INSERT, UPDATE, DELETE ON employees.* TO role_emp_write;

# 유저 생성하기
CREATE USER reader@'127.0.0.1' IDENTIFIED BY 'qwerty';
CREATE USER writer@'127.0.0.1' IDENTIFIED BY 'qwerty';

# 유저에 ROLE 부여하기
GRANT role_emp_read TO reader@'127.0.0.1';
GRANT role_emp_read, role_emp_write TO writer@'127.0.0.1';

# 확인하기
SHOW GRANTS;
SELECT current_role();

# 권한 활성화
SET ROLE 'role_emp_read';
    = 재 로그인 시 권한 초기화
    = `activate_all_roles_on_login=ON;` # 권한을 자동으로 활성화한다.
```



