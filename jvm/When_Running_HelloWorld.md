## Hello World 가 화면에 찍히기까지의 과정
```kotlin
fun main(args: Array<String>) {
    println("Hello World!")
}
```

- in 코틀린

```java
public final class ...Kt {
   public static final void main(@NotNull String[] args) {
      Intrinsics.checkNotNullParameter(args, "args");
      String var1 = "Hello World!";
      System.out.println(var1);
   }
}
```
- 자바로 변환되면 위와 같은 코드가 나온다. (Kt 파일 자동생성 후 내부에 main 메소드 위치시키기)

```java
  // access flags 0x19
  public final static main([Ljava/lang/String;)V
    // annotable parameter count: 1 (invisible)
    @Lorg/jetbrains/annotations/NotNull;() // invisible, parameter 0
   L0
    ALOAD 0
    LDC "args"
    INVOKESTATIC kotlin/jvm/internal/Intrinsics.checkNotNullParameter (Ljava/lang/Object;Ljava/lang/String;)V
   L1
    LINENUMBER 24 L1
    LDC "Hello World!"
    ASTORE 1
    GETSTATIC java/lang/System.out : Ljava/io/PrintStream;
    ALOAD 1
    INVOKEVIRTUAL java/io/PrintStream.println (Ljava/lang/Object;)V
   L2
    LINENUMBER 25 L2
    RETURN
   L3
    LOCALVARIABLE args [Ljava/lang/String; L0 L3 0
    MAXSTACK = 2
    MAXLOCALS = 2
```
- 컴파일 되서 나온 결과물은 다음과 같다.
- 위 내용은 생성된 .class 파일을 Hex 편집기로 열어서 확인하는 방법도 있다.


### 컴파일 한 파일을 실행하면...
