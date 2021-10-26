### SynchronizedItemStreamReader

- not thread-safe ItemReader를 thread-safe하게 이용할 수 있도록 처리
- since SpringBatch 4.0


1. Non Thread-safe
```
                                                                Worker
                                                                  |
                                                                  |
                                                                  |
                                                                  | read()
                                                                  |
                                                                  |
                                          read()                                    read()
                          worker ---------------------------- ItemReader --------------------------- worker

                                                                  |
                                                                  |
                                                                  |
                                                                  |  query()
                                                                  |
                                                                  |
                                                                  |
                                                                  |

                                                              Database
```
- 각 스레드가 동시에 동일한 Item을 중복해서 읽어올 수 있다.


2. Thread-safe 
```
                                 worker                             worker                              worker
                                   |                                  |                                   |
                                   |                                  |                                   |
                                   | read()                           |  read()                           | read()
                                   |                                  |                                   |
                                    ----------------------------------------------------------------------
                                                                      |
                                                                      | wait()
                                                                      |
                                                                      |

                                                                Synchronized
                                                                 ItemReader
                                                                      
                                                                      |
                                                                      | query()
                                                                      |

                                                                  Database

```
- 각 스레드가 대기하고 있다가 순차적으로 Item을 읽어온다.

### in codes
* SynchronizedItemReader.read
- All this class does = this.delegate.read()
- but it is wrapped in synchronized

### examples
```
@Configuration
class RetryConfiguration(

    val jobBuilderFactory: JobBuilderFactory,

    val stepBuilderFactory: StepBuilderFactory,

    val dataSource: DataSource
) {

    @Bean
    fun job() = jobBuilderFactory.get("batchJob")
        .incrementer(RunIdIncrementer())
        .listener(StopWatchJobListener())
        .start(step1())
        .build()

    @Bean
    fun step1() = stepBuilderFactory.get("step1")
        .chunk<Customer3, Customer3>(60)
        .reader(synchronizedItemStreamReader())
        .listener(object : ItemReadListener<Customer3> {

            override fun beforeRead() {

            }

            override fun afterRead(item: Customer3) {
                println("item id: ${item.id} on thread - ${Thread.currentThread().name}")
            }

            override fun onReadError(ex: java.lang.Exception) {

            }
        })
        .writer(cursorItemWriter())
        .taskExecutor(taskExecutor())
        .build()

    @Bean
    fun synchronizedItemStreamReader() = SynchronizedItemStreamReaderBuilder<Customer3>()
        .delegate(cursorItemReader())
        .build()

    @Bean
    fun cursorItemReader() = JdbcCursorItemReaderBuilder<Customer3>()
        .name("toBeSafe")
        .dataSource(dataSource)
        .rowMapper(BeanPropertyRowMapper(Customer3::class.java))
        .sql("""
            SELECT id, first_name, last_name, birthdate
            FROM customer3
        """.trimIndent())
        .build()

    @Bean
    fun cursorItemWriter() = JdbcBatchItemWriterBuilder<Customer3>()
        .dataSource(dataSource)
        .sql("INSERT INTO customer4 VALUES (:id, :first_name, :last_name, :birthdate)" )
        .itemSqlParameterSourceProvider(BeanPropertyItemSqlParameterSourceProvider())
        .build()

  @Bean
    fun taskExecutor() = ThreadPoolTaskExecutor().apply {
        this.corePoolSize = 4
        this.maxPoolSize = 8
        this.setThreadNamePrefix("ASYNC-THREAD")
      }

    @Bean
    @StepScope
    fun jdbcItemWriter() = JdbcBatchItemWriterBuilder<Customer3>()
        .dataSource(dataSource)
        .sql("""
            INSERT INTO customer4 (id, first_name, last_name, birthdate) VALUES (:id, :first_name, :last_name, :birthdate)
        """.trimIndent())
        .itemSqlParameterSourceProvider(BeanPropertyItemSqlParameterSourceProvider())
        .build()
}
```
