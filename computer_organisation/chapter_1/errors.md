### 함정
1. 컴퓨터의 한 부분만 개선하고, 그 개선된 양에 비례해서 전체 성능이 좋아지리라고 기대하는 것

**Amdahl의 법칙**
```

개선 후 실행시간 = 개선에 영향을 받는 실행시간 / 개선의 크기 + 영향을 받지 않는 실행시간

```

2. 이용률이 낮은 컴퓨터는 전력소모가 작다? (p. 57)
- Not Always

3. 성능에 초점을 둔 설계와 에너지 효율에 초점을 둔 설계는 서로 무관하다?
- 에너지는 전력을 시간에 대해 적분한 것
- 어떤 하드웨어나 소프트웨어 최적화 기술이 에너지를 더 소비하더라도 실행시간을 줄여서 전체 에너지를 절약하기도 한다.
- 실행시간이 짧아지면 시스템의 전체 에너지가 절약된다.
    = 프로그램이 수행되는 동안 최적화와 관련 없는 다른 부분이 에너지를 소모하기 때문

4. 성능식의 일부분을 성능의 척도로 사용하는 것
- 클럭 속도, 명령어 개수 or CPI 하나만 가지고 성능을 예측하는 방법은 위험하다.
- 세 인자 중 두 인자만 사용하는 것도 안된다.


