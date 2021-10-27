### FlatFileItemReader
  - 2차원 데이터(표)로 표현도니 유형의 파일을 처리
  - 일반적으로 고정위치로 정의된 데이터 필드 or 특수문자에 의해 구별된 데이터의 행을 읽는다.
    = Resource + LineMapper

        FlatFileItemReader
  
    String encoding = DEFAULT_CHARSET
   (default: Charset.defaultCharset())

    int linesToSkip
    = 무시할 라인 수 (ex. 타이틀)

    String[] comment
    = 해당 코멘트 기호가 있는 라인은 무시

    Resource resource
    = 읽어야 할 리소스

    LineMapper<T> lineMapper
    = String을 Object로 변환

    LineCallackHandler skippedLinesCallback
    = 건너 뛸 라인의 원래 내용을 전달하는 인터페이스
    (ex. linesToSkip = 2, 2번 호출)

 
### LineMapper


### FieldSet
  - 라인을 필드로 구분해서 만든 배열토큰 전달 시 토큰 필드 참조
  (similar to ResultSet in Jdbc)

### LineTokenizer
  - 입력받은 라인을 FieldSet으로 변환해서 리턴
    = LineMapper가 라인을 전달, Tokenizer가 다시 FieldSet으로 만들어 FieldSet에 전달
  - 파일마다 형식이 다르므로, 문자열을 FieldSet으로 변환하는 작업을 추상화

### FieldSetMapper
  - FieldSet 객체를 받아서, 원하는 객체로 매핑해서 리턴
  - JdbcTemplate의 RowMapper와 유사

          
        
                                         LineMapper<T>
                            T mapLine(String line, int lineNumber)
                                              |
                                              |
                    ----------------- DefaultLineMapper ------------
                   |                                                |
                   |                                                |
              LineTokenizer                                 FieldSetMapper<T>
  FieldSet tokenize(@Nullable String line)           T mapFieldSet(FieldSet fieldSet)
                   |                                                |
                   |                                                |
      -------------------------------                               |
     |                               |                              |
     |                               |                              |
DelimitedLineTokenizer      FixedLengthTokenizer         BeanWrapperFieldSetMapper    
= 구분자를 사용해 필드로    = 각 필드를 고정된 길이로    = 객체의 필들명과 일치하는 FieldSet의 필드를
    구분하는 파일에 사용      정의하는 파일에 사용          자동으로 매핑



             readLine()---->
                           |
  Step -- read --> FlatFileItemReader -- mapLine(line) --> LineMapper -- mapFieldSet() ---

                              <------- FieldSet으로 만든 객체 반환 ----------------------

-> FieldSetMapper ---- tokenize() ---> LineTokenizer -----> FieldSet 
                                                  배열토큰 전달
---  FieldSet     <-------------------               <-----
                                          배열토큰을 가진 FieldSet 다시 반환


### FlatFileItemReader API
- name(String name)
  = ExecutionContext 내에서 구분하는 Key로 사용

- resource(Resource)
  = FilePath or ClassPathResource
  = 읽어야 할 리소스 설정

- delimited().delimiter(` `) 
  = 구분자를 기준으로 파일을 읽어들이는 설정

  or

- fixedLength()
  = 파일의 고정길이를 기준으로 파일을 읽어들이는 설정

- addColumns(Range..)
  = 고정 길이 범위를 정하는 설정

- names(String[] fieldNames)
  = 토큰화된 각각의 값들 in an Array 
  = 인덱스가 아닌 실제 이름으로 배열 값을 가져올 수 있음

- targetType(Class class)
  = 각 라인과 매핑할 객체타입

- addComment(String Comment)
  = 무시할 라인의 코멘트기호 설정

- strict(boolean)
  = 라인을 읽거나 토큰화할 때 파싱 예외가 발생하지 않도록 검증생략 설정
  (when it is false)

- encoding(String encoding)
  = 파일 인코딩 설정

- linesToSkip(int linesToSkip)
  = 파일 상단에 있는 무시할 라인 수 설정

- saveState(boolean)
  = 상태정보를 저장할 것인지

- setLineMapper(LineMapper)
  = LineMapper 객체 설정

- setFieldSetMappe(FieldSetMapper)
  = FieldSetMapper 객체 설정

- setLineTokenizer(LineTokenizer)
  = LineTokenizer 객체 설정

--> 설정하지 않을 시 스프링 배치의 기본 구현체 사용

- build()

### in codes
1. taskletStep (ChunkOrientedTasklet)
 - tasklet.execute(contribution, chunkContext)
 
...

2. doRead (FlatFileItemReader)
  ```
  ...
  String line = readLine()
    ```
    reader.readLine() by `BufferedReader`
    ```
  lineMapper.mapLine(line, lineCount) ## LineMapper 구현체 메소드 호출
    ```
    (AbstractLineTokenizer)
    ...
    List<String> tokens = ArrayList<>(doTokenize(line))
    ...
    String[] values = tokens.toArray(new String[tokens.size()])
    ... 
    
    fieldSetFactory.create(values) ## 내부적으로 FieldSet을 만든다.
    ```
  ## 위에서 만들어진 FieldSet이 `fieldSetMapper.mapFieldSet()`의 인자로 전달된다.

  ...
  mapFieldSet(FieldSet fs) ## 구현체의 메소드 호출, 객체로 매핑
  ```

  = 매핑된 객체를 반환한다.
  = ChunkSize에 도달할 때까지 반복한다.


