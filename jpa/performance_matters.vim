1. 컬렉션 페치조인 시, 페이징 사용이 불가능하다.
    = 메모리에 모든 것을 가져온다..
    = DB rows는 더 많으므로, 페이징 해버리면 잘못된 결과를 가져올 수 있다.
    = 페이징 자체가 불가능

+ 컬렉션 페치조인은 1개만 사용가능 (for 1:N)
    = 둘 이상에 사용하면, 데이터가 부정합하게 조회될 수 있다.
    = 1:N도 복잡한데... 1:N:N?

