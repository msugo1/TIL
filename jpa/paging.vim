# 컬렉션을 페치조인하면 페이징이 불가능
    = 컬렉션 페치조인 시 일대다 조인이 발생 = 데이터 예측할 수 없이 증가
    = 데이터는 일대다에서 `다`쪽을 기준으로 생성된다.
    = 일 쪽을 기준으로 하고 싶어도, 다 쪽으로 row가 생성된다.
    = Hibernate는 모든 데이터를 읽어서 메모리에 적재한다.(OOME)

# 한계 돌파
1. X to One
- 모두 페치조인
    = ToOne관계는 row 수를 증가시키지 않는다.
2. 컬렉션은 지연로딩으로 조회
3. 지연로딩 성능 최적화를 위해, `hibernate.default_batch_fetch_size` 적용
    (or @BatchSize)
    = 단건 각각 조회를 in query로 바꿔준다.

    @BatchSize = 구체적으로 대상을 지정
    hibernate.default_batch_fetch_size = 글로벌한 설정

    * 1 + N -> 1 + 1
    - 조인보다 DB데이터 전송량이 최적화된다.
        = X to Many: 컬렉션 수만큼 중복조회
        = batchSize: 각각 조회하므로, 중복 데이터 없음
    - 페치 조인과 비교해서, 쿼리 호출 수는 약간 증가하지만 DB 데이터 전송량이 감소한다.
    - 이 방법은 페이징이 가능
    (컬렉션 페치조인은 불가)

* to One은 fetch join, to Many는 batchSize
* default_batch_fetch_size는 100 ~ 1000 사이 권장
    100: DB와의 네트워크 비용 및 쿼리 수행 시간 증가
    1000: DB, 애플리케이션 단에서 순간 부하 증가
    (trade off - 자기 상황에 맞게)

# 컬렉션 조회
1. x To One 조회 먼저 then, collection 조회 이어서
```
    fun findOrderQueryDtos(): List<OrderQueryDto> {
        val result = findOrders()
        return result.onEach { o ->
            val orderItems = findOrderItems(o.orderId)
            o.orderItems = orderItems
        }
    }

    fun findOrderItems(orderId: Long): List<OrderItemQueryDto> {
        return em.createQuery(
            """
                SELECT
                    new jpabook.jpashop.api.OrderItemQueryDto(
                        oi.order.id,
                        i.name,
                        oi.orderPrice,
                        oi.count
                    )
                FROM OrderItem oi
                JOIN oi.item i
                WHERE oi.order.id = :orderId
            """.trimIndent(), OrderItemQueryDto::class.java
        )
            .setParameter("orderId", orderId)
            .resultList
    }

    fun findOrders(): List<OrderQueryDto> {
        return em.createQuery("""
            SELECT new jpabook.jpashop.api.OrderQueryDto(
                o.id,
                m.name,
                o.orderDate,
                o.status,
                d.address
            ) FROM Order o
            JOIN o.member m
            JOIN o.delivery d
        """.trimIndent(), OrderQueryDto::class.java)
            .resultList
    }

```
= 여전히 N + 1

* Better = result with 2 queries
```
fun findAllByDto_Optimisation(): List<OrderQueryDto> {
    val result = findOrders() # refer to above
    val orderIds = result.map { it.orderId }
    val orderItems = em.createQuery(
        """
            SELECT
                new jpabook.jpashop.api.OrderItemQueryDto(
                    oi.order.id,
                    i.name,
                    oi.orderPrice,
                    oi.count
                )
            FROM OrderItem oi
            JOIN oi.item i
            WHERE oi.order.id in :orderIds
        """.trimIndent(), OrderItemQueryDto::class.java
    )
        .setParameter("orderIds", orderIds)
        .resultList

    val orderIdToOrderItem = orderItems.groupBy{ it.orderId }
    result.forEach { it.orderItems = orderIdToOrderItem[it.orderId] }
    return result
}
```

* Query 1번으로도 가능하지만.... 
- JOIN a lot
- 애플리케이션에서 too much 추가작업
- 페이징 불가능
