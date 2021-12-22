# MySQL 서버의 데이터 암호화
## DB 서버 <--> 디스크
### 1. 사이의 읽기/쓰기 지점에서 암호화 or 복호화 수행
- 디스크 입출력 부분 외에는 처리필요X
- only in IO layers
- TDE(Transparent Data Encryption)
    with AES256
 

## 2단계 키 관리
### 1. 암호화 키는 `KeyRing` 플러그인에 의해 관리
### 2. 마스터 키 & 테이블 스페이스 키
- 외부 키 관리 솔루션 or 디스크에서 `마스터 키`를 가져온다.
- 암호화 된 테이블 생성시마다 해당 테이블을 위한 임의의 `테이블 스페이스 키`를 발급
- MySQL 서버는, 마스터 키를 이용해 테이블 스페이스 키 암호화
    -> 각 테이블의 데이터 파일헤더에 저장
    -> 변경되지는 않지만, 외부로 노출X = no 보안 위협


## 암호화 & 성능
### 1. 속도
- 한 번 읽은 데이터 페이지는 복호화 되어 버퍼 풀에 저장
- 버퍼 풀에 있는 데이터 접근 시 동일한 성능

### vs not in buffer pool
- 복호화 필요 
- 그 만큼의 대기시간

### 저장시
- 디스크 동기화 시 암호화 필요하므로 추가로 시간소요
- However, it is `background thread` that handles the work = meaning no additional time is seen by clients

### 압축 + 암호화 동시 적용 시
- 압축 후 암호화

why?
1. 암호화 된 결과문 comes with random byte arrays, so much so it harms the compression rate
2. InnoDb 버퍼 풀에는 압축 o/압축 x 모든 데이터가 동시에 존재할 수 있다.
    = 암호화를 먼저하면, 버퍼 풀에 존재하는 데이터 페이지에 대해서도 매번 암복호화 작업이 필요

## 암호화와 복제
### 1. 마스터 & 테이블 스페이스 키는 복제되지 않는다.
- 마스터, 레플리카 모두 각각의 키 관리
- 암호화 전 데이터 동일, but 암호화 후 달라진다.

### 2. TDE의 키링 파일 백업
- 키링 파일을 찾지 못하면 데이터 복구 불가 ㅜㅜ
- 마스터 키 로테이션 명령으로 TDE 마스터 키가 `언제`변경되었는지 알아야 한다.

### 3. 테이블 스페이스 백업
- 테이블 스페이스 Export
```
FLUSH TABLES source_table FOR EXPORT;
```
1. source_table의 저장되지 않은 사항 모두 기록(to disk)
2. lock source_table
3. 해당 테이블 구조 기록 in source_table.cfg
4. copy `source_table.ibd, source_table.cfg` to the dest server

--- so far 테이블 스페이스 복사 without data encryption ---

additionally,
5. 임시로 사용할 마스터 키 발급 in source_table.cfp
6. 암호화 된 테이블의 테이블 스페이스 키를 기존 마스터 키로 복호화
    & 위에서 발급한 임시키로 다시 암호화 후 데이터 파일의 헤더 부분에 저장

**주의**
- `*.cfp` 파일이 없을 시 복구 불가 for encrypted ones

### 4. 언두/리두 로그 암호화
- 메모리에 존재하는 데이터는 still  복호화된 평문(암호화 ON시)
- 요 평문 데이터가 테이블의 데이터 파일 이외의 디스크 파일로 기록되는 경우 평문 유지
- 따라서, 리두/언두, 복제를 위한 바이너리 로그에 평문으로 저장
- However, since 8.0.16 리두/언두로그 암호화저장 가능
```
by, innodb_undo_log_encrypt 
    & innodb_redo_log_encrypt
```
- 평문으로 저장하다가 암호화 활성 시, 그때부터 생성되는 데이터들만 암호화 (vice versa)

### 5. 바이너리 로그 암호화
- 바이너리 로그 & 릴레이 로그 파일 암호화 기능은 `디스크`에 저장된 로그 파일에 대한 암호화만 담당
(MySQL 서버의 메모리 내부 or 소스 서버 or 레플리카 서버 간의 네트워크 구간에서 로그 데이터 암호화 X)
(복제 멤버 간 네트워크 구간에서도 바이너리 로그 암호화? = SSL!)

**NOTE)**
바이너리 로그 암호화 키도 당연히 변경 가능

그러나, 변경 시 
</break>
    기존 바이너리 로그 및 릴레이 로그 파일의 파일 키를 읽음 -> 새로운 파일 키로 암호화해서 저장
</break>
요 구간에서 오랜 시간이 소요될 수 있음에 주의하자.
