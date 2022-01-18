## 통계정보
- 비용기반 최적화에서 가장 중요
    = 통계정보가 정확하지 않으면 엉뚱한 쿼리실행
- up to 5.7, 테이블과 인덱스에 대한 `개괄적`인 정보를 가지고 실행계획 수립
    = 실제 값들이 어떻게 분포되어있는지에 대한 정보가 없어서 실행계획의 정확도 저하
- from 8.0, 인덱스되지 않은 컬럼들에 대해서도 `데이터 분포도` 수집해서 저장
    = 히스토그램
- 영구적인 통계정보 저장으로 의도치 않은 통계정보 변경을 막을 수 있게 되었다.
    or `innodb_stats_auto_recalc=OFF`
    or `STATS_AUTO_RECALC=0`

**innodb_index_stats**
1. stat_name = 'n_diff_pf%'
- 인덱스가 가진 유니크한 값의 개수

2. stat_name = 'n_leaf_pages'
- 인덱스의 리프 노드 페이지 개수

3. stat_name = 'size'
- 인덱스 트리의 전체 페이지 개수

4. n_rows
- 테이블 전체 레코드 건수

5. clustered_index_size
- 프라이머리 키의 크기(= InnoDB 페이지 개수)

6. sum_of_other_index_size
- 프라이머리 키를 제외한 인덱스의 크기(= InnoDB 페이지 개수)

**innodb_stats_transient_sample_pages**
- default: 8
- 자동으로 통계정보 수집 실행 시, 지정된 페이지만큼 임의로 샘플링/분석
    = 해당 결과를 통계정보로 활용

**innodb_stats_persistent_sample_pages**
- default: 20
- ANALYZE TABLE 실행 시, 임의로 페이지 만큼 샘플링/분석, 결과는 영구적인 통계정보 테이블에 저장/활용

### 히스토그램
- up to 5.7, 통계정보 only has 단순히 인덱스된 컬럼의 유니크한 값의 개수
    = 옵티마이저가 최적의 실행계획을 수립하기엔 부족
    = 이 부족함을 메우기 위해, 실행계획 수립 시 실제 인덱스의 일부 페이지를 랜덤으로 가져와 참조

- 8.0부터 히스토그램 정보를 컬럼단위로 관리
    = ANALYZE TABLE ... UPDATE HISTOGRAM 명령 실행(수동 수집/관리)
    = `column_statistics` 테이블
- 히스토그램의 모든 레코드 건수 비율은 `누적`

### Histogram Type
1. Singleton
- 칼럼값 개별로 레코드 건수 관리
- Value-Based Histogram or 도수 분포
    = 컬럼, 발생 빈도의 비율(2개 값)
    = 컬럼이 가지는 값 별로 버킷 할당
- 유니크한 값의 개수가 상대적으로 적은경우
    ex. 코드 값

2. Equi-Height(높이 균형 히스토그램)
- 칼럼 값의 범위를 균등한 개수로 구분/관리
- Height-Balanced 히스토그램
    = 범위의 시작/마지막 값, 그리고 발생 빈도율, 각 버킷에 포함된 유니크한 값의 개수(4개 값)
    = 범위 별로 버킷 할당

### Histogram Usage
1. more accurate prediction
- 버킷 별로 레코드의 건수, 유니크한 값의 개수 정보를 가지기 때문
ex. 조인 시
    = 히스토그램이 없으면 분포 정보 없이 실행계획 수립
    = 데이터가 많은 테이블이 드라이빙 테이블이 되어 성능차이가 발생할 수 있다.
    = 히스토그램이 있다면, 어느 테이블을 먼저 읽어야 조인횟수를 줄일 수 있을지 옵티마이저가 더 정확히 판단

2. histogram and index
- 인덱스 된 컬럼의 실행계획
    = done with index dive
    = 실제 인덱스의 B-Tree를 샘플링해서 레코드 건수 예측

- 인덱스 되지 않은 컬럼의 실행계획
    = 이때 히스토그램 참조
    why? 인덱스를 샘플링하는 것이 더 정확도가 높으므로












