https://docs.gradle.org/current/userguide/base_plugin.html#sec:base_tasks


- common tasks, convetions 제공
  - 그 중에서 가장 중요한 것은 `lifecyle tasks`


**class BasePlugin**
```java
public abstract class BasePlugin implements Plugin<Project> {
    public static final String CLEAN_TASK_NAME = "clean";
    public static final String ASSEMBLE_TASK_NAME = "assemble";
    public static final String BUILD_GROUP = "build";

    public BasePlugin() {
    }

    public void apply(final Project project) {
        project.getPluginManager().apply(LifecycleBasePlugin.class);
        ...
    }
}
```

**class LifecycleBasePlugin**
```java
public abstract class LifecycleBasePlugin implements Plugin<Project> {
    public static final String CLEAN_TASK_NAME = "clean";
    public static final String ASSEMBLE_TASK_NAME = "assemble";
    public static final String CHECK_TASK_NAME = "check";
    public static final String BUILD_TASK_NAME = "build";
    public static final String BUILD_GROUP = "build";
    public static final String VERIFICATION_GROUP = "verification";

    public void apply(final Project project) {
        ProjectInternal projectInternal = (ProjectInternal)project;
        this.addClean(projectInternal);
        this.addCleanRule(project);
        this.addAssemble(project);
        this.addCheck(project);
        this.addBuild(project);
    }

    ...
}
```

## Tasks

```kotlin
// actionable task
tasks.register("buildApp") {
    group = "build"
    description = "Builds the Java application"
    doLast {
        println("Build completed.")
    }
}

// lifecycle task
tasks.name("build") {
    dependsOn("buildApp")
}
```

### actionable tasks
- 실제 작업을 수행하는 태스크
- ex. compiling code 
### lifecycle tasks
> Lifecycle tasks are tasks that do not do work themselves. These tasks have no actions, instead, they bundle actionable tasks and serve as targets for the build.
- 작업을 나누는데 활용가능
  - ex. 코드 퀄리티 체크 시 테스트는 수행하고 싶지 않은 경우. local vs CI 태스크 구분하고 싶은 경우
```kotlin
plugins {
    id("com.github.spotbugs") version "6.0.7"           // spotbugs plugin
}

tasks.register("qualityCheck") {                        // qualityCheck task
    group = myBuildGroup                                // group
    description = "Runs checks (excluding tests)."      // description
    dependsOn(tasks.classes, tasks.spotbugsMain)        // dependencies
    dependsOn(tasks.testClasses, tasks.spotbugsTest)    // dependencies
}
```

TIP) 필요한 모든 태스크를 dependsOn 에 나열할 필요 없음
- 수행할 타겟만 명시하면 Gradle 이 필요한 하위 태스크들은 알아서 찾아준다.


### Global lifecycle tasks
= lifecycle tasks within the root build (especially useful for CI)

```kotlin
val globalBuildGroup = "My global build"
val ciBuildGroup = "My CI build"

// ./gradlew tasks
tasks.named<TaskReportTask>("tasks") {
    displayGroups = listOf<String>(globalBuildGroup, ciBuildGroup)
}

---

// global
tasks.register("qualityCheckApp") {
    group = globalBuildGroup
    description = "Runs checks on app (globally)"
    dependsOn(":app:qualityCheck" )
}

// ci only
tasks.register("checkAll") {
    group = ciBuildGroup
    description = "Runs checks for all projects (CI)"
    dependsOn(subprojects.map { ":${it.name}:check" })
    dependsOn(gradle.includedBuilds.map { it.task(":checkAll") })
}
```

### Tasks in BasePlugin

- clean
  - delete built directory
- clean`<Task>`
  - 뒤에 명시된 부분 clean 
  - ex. cleanJar
- check
  - verification task 에 붙여야 하는 lifecycle task
  - such as ones that run tests, to this lifecycle task using `check.dependsOn(...)`
- assemble
  - distributions 혹은 consumable artifacts 를 만드는 task 에 붙여야 하는 lifecycle task
  - `assemble.dependsOn(...)`
  - ex. jar: produces consumable artifact for Java libraries.
- build
  - dependsOn: check, assemble
  - = run tests + produce artifacts + documentation ...
- build`<Configuration>`
  - 뒤에 명시된 부분에 대한 build
  - ex. buildRuntimeElements 시 runtimeElements 에 설정된 artifact 빌드

### Dependency Management in BasePlugin
- default
  - `request attributes` 없을 때 fallback 으로 dependency resolution 을 수행하기 위한 용도
  - 새롭게 빌드, 플러그인 정의하는 것들은 이거 쓰면 안됨. 하위호환성을 위해 있는 것
- archives
  - archives 설정에 정의된 모든 아티팩트는 assemble 태스크에 의해 만들어짐
  - 마찬가지로 새롭게 정의할 때 이거 쓰면 안됨. 대신 assemble 에 정의해야 함

### BaseExtension
```kotlin
base {
    archivesName = "gradle" // 아카이브에 들어가는 이름
    distsDirectory = layout.buildDirectory.dir("custom-dist") // distributions archives 생성할 디렉토리
    libsDirectory = layout.buildDirectory.dir("custom-libs")  // library archives 생성할 디렉토리 
}
```