## System Account vs Regular Account
1. System Account
- DB 서버 관리자를 위한 계정
- 시스템 계정과 일반 계정관리 가능 & 그 외 중요작업(계정 생성, 삭제, 권한부여 등 && 실행중인 쿼리 강제종료 ... )

2. Regular Account
- for developers or programs
- 시스템 계정 관리 불가

## Account Lock vs UnLock
- 사용 못하게 잠그거나 or 풀거나

## 권한
- 필요한 권한 찾아쓰기 (p. 65)
- 8.0 부터는 `동적권한`도 추가

what is?
- MySQL 서버가 시작되면서 동적으로 생성하는 권한

**컬럼 단위의 권한은 잘 설정하지 않는다.**
- 나머지 모든 테이블의 모든 컬럼에 대해서 권한 체크가 필요해진다.
- 전체적인 성능 악화
- 권한이 필요한 컬럼만을 모아 별도로 `View`를 만들자

## 역할(Role)
- from 8.0, 권한을 묶어서 `역할`로
- 내부적으로 사용자 계정과 동일한 객체로 취급
    = 하나의 계정에 다른 계정의 권한을 `병합`하기만 하면되므로, MySQL 서버는 역할과 계정을 구분할 필요가 없다.
    = CREATE ROLE로 역할 생성 시, 뒤에 호스트를 명시하지 않으면 자동으로 `%`

### ROLE 생성하기
CREATE ROLE
    role_emp_read,
    role_emp_write;

### ROLE에 권한 부여하기 (권한이 부여되지 않은 ROLE은 껍데기)
GRANT SELECT ON employees.* TO role_emp_read;
GRANT INSERT, UPDATE, DELETE ON employees.* TO role_emp_write;

### 유저 생성하기
CREATE USER reader@'127.0.0.1' IDENTIFIED BY 'qwerty';
CREATE USER writer@'127.0.0.1' IDENTIFIED BY 'qwerty';

### 유저에 ROLE 부여하기
GRANT role_emp_read TO reader@'127.0.0.1';
GRANT role_emp_read, role_emp_write TO writer@'127.0.0.1';

### 확인하기
SHOW GRANTS;
SELECT current_role();

### 권한 활성화
SET ROLE 'role_emp_read';
    = 재 로그인 시 권한 초기화
    = `activate_all_roles_on_login=ON;` # 권한을 자동으로 활성화한다.
```



