### ItemReaderAdapater
- 배치 Job 안에서 이미 있는 DAO or 다른 서비스를 ItemReader 안에서 사용하고자 할 때 위임 역할

### in codes
1. SimpleChunkProvider.doRead()
  - T item = itemReader.read() ## here itemReader = itemReaderAdapter

2. ItemReaderAdapter.read()
  - invokeDelegateMethod()

3. AbstractMethodInvokingDelegator.invokeDelegateMethod
  ```
  MethodInvoker invoker = createMethodInvoker(targetObject, targetMethod)
  invoker.setArguments(arguments)
  return doInvoke(invoker)
  ```

4. AbstractMethodInvokingDelegator.doInvoke(invoker)
  ```
  invoker.prepare()
  invoker.invoke() ## reflection
  ```

5. (service or dao method) specified

### example
```
@Bean
fun itemReaderAdapter(): ItemReader<String> = ItemReaderAdapter<String>().apply {
    this.setTargetObject(customService())
    this.setTargetMethod("customRead")
}

@Bean
fun customService() = CustomService<String>()
```
  주의) Service 메소드에서 null을 반환하지 않으면 계속 읽어옴
    - reader는 null 을 리턴해야 끝이라고 판단하기 때문
