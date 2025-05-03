### youtube_routine_front setting

- https://www.youtube.com/watch?v=Hf8qwqjRIdo
- pubspec.yaml 파일 -> https://pub.dev/
-  firebaseauth/firecore/firestorage 추가

- 사용자가 저장 or 삭제 눌렀을때 get으로 리스트 조회 및 갱신

- 루틴 수정시
- 조회된 루틴 목록에서 id로 객체 넘겨줘서 사용 or ( 현재 사용 중 )
- 클릭한 루틴의 id로 get 메서드 호출하여 사용

> gradle sync 문제
1. run flutter clean 
2. do the Gradle sync without flutter pub get and make necessary changes to native android code. 
3. do pub get and run the app.

> 앱번들 빌드 오류
1. build 폴더 삭제
2. gradle.properties에 kotlin.incremental=false 추가
3. flutter clean
4. flutter pub get
5. flutter build appbundle


- D:\Dev\IDE\youtube_routine_front\android\app\src\main\kotlin\com\example\youtube_routine_front 
- -> Unresolved reference: FlutterActivity : android 프로젝트 open해서 실행

- aws regions -> free tier 일때, us-east1 인지 확인하기## youtube_routine_front setting

- https://www.youtube.com/watch?v=Hf8qwqjRIdo
- pubspec.yaml 파일 -> https://pub.dev/
-  firebaseauth/firecore/firestorage 추가

- 사용자가 저장 or 삭제 눌렀을때 get으로 리스트 조회 및 갱신

- 루틴 수정시
- 조회된 루틴 목록에서 id로 객체 넘겨줘서 사용 or ( 현재 사용 중 )
- 클릭한 루틴의 id로 get 메서드 호출하여 사용

> gradle sync 문제
1. run flutter clean 
2. do the Gradle sync without flutter pub get and make necessary changes to native android code. 
3. do pub get and run the app.

> 앱번들 빌드 오류
1. build 폴더 삭제
2. gradle.properties에 kotlin.incremental=false 추가
3. flutter clean
4. flutter pub get
5. flutter build appbundle

> RDS -> 퍼블릭 엑세스 : 아니오로 변경

- D:\Dev\IDE\youtube_routine_front\android\app\src\main\kotlin\com\example\youtube_routine_front 
- -> Unresolved reference: FlutterActivity : android 프로젝트 open해서 실행

- ### aws regions -> free tier 일때, us-east-1 인지 확인하기
  
