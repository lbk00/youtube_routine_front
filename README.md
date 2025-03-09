### youtube_routine_front setting

- https://www.youtube.com/watch?v=Hf8qwqjRIdo
- pubspec.yaml 파일 -> https://pub.dev/
-  firebaseauth/firecore/firestorage 추가

- 사용자가 저장 or 삭제 눌렀을때 get으로 리스트 조회 및 갱신

- 루틴 수정시
- 조회된 루틴 목록에서 id로 객체 넘겨줘서 사용 or ( 현재 사용 중 )
- 클릭한 루틴의 id로 get 메서드 호출하여 사용

- gradle sync 문제
1. run flutter clean 
2. do the Gradle sync without flutter pub get and make necessary changes to native android code. 
3. do pub get and run the app.
