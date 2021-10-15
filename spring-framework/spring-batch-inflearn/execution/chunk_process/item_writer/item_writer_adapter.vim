### ItemWriterAdapter
  - 이미 있는 DAO or 다른 서비스를 ItemWriter에서 사용하고자 할 때 위임 역할

### in code
1. ItemWriterAdapter.write(List<? extends T> items)
  ```
  for (T item : items) {
      invokeDelegateMethodWithArgument(item)
  }
  ```

2. AbstractMethodInvokingDelegator.invokeDeleateMethodWithArgument(Object object)
  ```
  MethodInvoker invoker = createMethodInvoker(targetObject, targetMethod)
  invoker.setArgument(new Obvject[] { object })
  return doInvoke(invoker)
  ```

3. execute the service registered

### example
```
@Bean
fun batchStep1() = stepBuilderFactory.get("batchStep1")
    .chunk<String, String>(10)
    .reader {
        i++
        if (i > 10) {
            null
        } else {
            "item $i"
        }
    }
    .writer(ItemWriterAdapter<String>().apply {
            this.setTargetObject(customerService())
            this.setTargetMethod("customWrite")
    })
    .build()
```
