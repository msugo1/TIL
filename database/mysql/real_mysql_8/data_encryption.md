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

