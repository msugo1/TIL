### Reflection

* starting point
  - `Class<T>` API
    = 클래스의 필드, 상위 클래스, 인터페이스, 메소드 목록 등에 모두 접근이 가능하다.

### code with comments!
(편의를 위해 자바로 진행)

1. basic
``` java
Class<Book> bookClass = Book.class; // from Type

  Book book = new Book();
  Class<? extends Book> bookClassFromObject = book.getClass(); // from an object

  // from FQCN = full qualified class name (ex. me.soo.Book = including the package structures)
  String bookLocation = "me.soo.Book";
  Class<?> bookClassFromName = Class.forName(bookLocation);

  // 이름을 지정하면 특정 필드를 가져올 수 있다. 물론 기존 제약사항을 따른다.
  // getFields = public 데이터만 리턴
  System.out.println("=======================bookClass.getFields========================");
  Arrays.stream(bookClass.getFields()).forEach(System.out::println);

  // getDeclaredFields = private 까지 모두 리턴
  System.out.println("=======================bookClass.getFields========================");
  Arrays.stream(bookClass.getDeclaredFields()).forEach(System.out::println);

  System.out.println("==================================================================");
  Arrays.stream(bookClass.getDeclaredFields()).forEach(f -> {
      try {
          // private 필드를 가져올 수 있다고 모두 접근가능한 것은 아니다.
          // setAccessible = true 로 설정하지 않으면 접근 불가 예외가 난다.
          f.setAccessible(true);
          System.out.printf("%s %s \n", f, f.get(book));
      } catch (IllegalAccessException e) {
          e.printStackTrace();
      }
  });

  System.out.println("==================================================================");
  // 내부 메소드, 생성자, 상위 클래스, 구현한 인터페이스, 리턴타입 또한 출력이 가능하다.
  // even 접근제어자들 및 어노테이션도, 제네릭 타입, 파라미터 타입 및 개수까지도 출력 가능
  Arrays.stream(Book.class.getDeclaredFields()).forEach(f -> {
      int modifiers = f.getModifiers();
      System.out.println(f);
      System.out.println(Modifier.isPrivate(modifiers));
      System.out.println(Modifier.isStatic(modifiers));
  });
```


