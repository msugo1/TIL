데이터 크기 증가 means 더 많은 읽기 필요 from the disk to the buffer pool, more dirty pages to write to the disk, more backup data
    = DB provides us with data compression
    = two ways


1. page compression
- data page compression at the save time to the disk,
    then decompression when DB reads the data to the buffer pool

- 압축 해제 후 용량 예측 불가
    = 펀치 홀 사용(OS, and specific file system dependent)
- 여러 한계로, 많이 사용되지는 않는다.


2. table compression
- independent from os, and disk therefore more uses

but 단점
    1) 버퍼 풀 공간 활용률 낮음
    2) 쿼리 처리성능이 낮음
    3) 빈번한 데이터 변경 시 압축률이 떨어짐

- 압축을 사용하려는 테이블에 대한 별도의 테이블 스페이스 필요
    with `innodb_file_per_table` 옵션 on
    + `ROW_FORMAT=COMPRESSED`
    + `KEY_BLOCK_SIZE=2n (n >= 2)`
        = 16KB page size (buffer pool) = only 4 or 8
        = 32KB or 64KB impossible to compress

* How InnoDB compresses tables?
1. 16KB 데이터 페이지 압축
2. 목표 사이즈 이하면 디스크 저장
    초과면 원본 페이지 스플릿 & 2개의 페이지에 각각 목표 사이즈 씩 저장
3. 나뉜 페이지에 대해 1 - 2 반복

따라서, 압축 사이즈 잘못 설정하면 이러한 단계가 반복되어 처리 성능이 급감할 수 있다.
= 압축 결과를 잘 예측해서 올바른 `KEY_BLOCK_SIZE` 설정하는 것이 필요

# 압축된 테이블과 버퍼 풀
- compressed & decompressed LRU 리스트 모두 관리
    = 버퍼 풀의 이중공간 사용
    = 낭비

- 압축된 부분 해제 시, CPU 소모 크다.

이를 개선하기 위해, 리스트 별도 보관 후, MySQL 서버로 유입되는 요청 패턴에 따라 적절한 처리 수행
1. 버퍼 풀 공간확보 필요 시, LRU 리스트에서 원본은 두고, 압축본은 삭제
2. 압축된 데이터 페이지가 자주 사용되면, Unzip_LRU 리스트에 압축 해제된 페이지는 계속 유지
3. 압축된 데이터 페이지가 사용되지 않아서 LRU 리스트에서 제거된 경우, 
    Unzip_LRU에서도 함께 제거


# 테이블 압축관련 설정
= 압축 실패율을 낮추기 위해 필요한 튜닝포인트 제공

1. innodb_cmp_per_index_enabled
- on: 테이블 압축이 사용된 테이블의 모든 인덱스별로 압축 성공 및 압축 실행횟수 수집
    & information_schema.INNODB_CMP_PER_INDEX 테이블에 기록
- off: 테이블 단위로만 수집
    & information_schema.INNODB_CMP 테이블에 기록

2. innodb_compression_level
- 압축률 설정
    default: 6
    = 압축률을 높일 수록 CPU 사용량이 증가하므로 적절한 포인트를 찾아야 한다.

3. innodb_compression_failure_threshold_pct and innodb_compression_pad_pct_max
- 압축 실패율이 innodb_compression_failure_threshold_pct 값을 넘어서면, 압축 실행 전 원본 데이터 끝에 의도적으로 패딩 추가
(= 압축률을 높여서 결과가 KEY_BLOCK_SIZE 보다 작아지도록)
- 패딩 공간은 압축 실패율이 높아질수록 계속 증가
- 최대 패딩 공간의 크기는! innodb_compression_pad_pct_max
    = 전체 데이터페이지 크기 대비 패딩 공간의 비율

4. innodb_log_compressed_pages
    default: on (가능하면 on으로)

- 비정상 종료후 다시 시작 시, 압축 알고리즘 버전에 영향 받지 않도록 압축된 데이터 페이지를 리두로그에 기록
    = trade off
