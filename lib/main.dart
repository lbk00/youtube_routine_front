import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_routine_front/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;  // HTTP 요청 라이브러리 추가
import 'dart:convert';  // jsonEncode 사용을 위한 패키지 추가
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // .env 파일 로드
    await dotenv.load(fileName: "assets/.env");

    // 기기 방향 고정
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Firebase 초기화
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['API_KEY']!,
          authDomain: dotenv.env['AUTH_DOMAIN']!,
          projectId: dotenv.env['PROJECT_ID']!,
          storageBucket: dotenv.env['STORAGE_BUCKET']!,
          messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
          appId: dotenv.env['APP_ID']!,
          measurementId: dotenv.env['MEASUREMENT_ID'],
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    // 백그라운드 푸시 알림 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // FCM 초기화 및 토큰 등록 (비동기로 두지 말고 반드시 await 처리)
    await setupFirebaseMessaging();

    // FCM 토큰 변경 리스너 등록
    setupFcmTokenRefreshListener();

    // 앱 실행
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeNotifier(),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(body: Center(child: Text("앱 초기화 중 오류가 발생했습니다."))),
    ));
  }
}



//  백그라운드 또는 종료된 상태에서 푸시 알림을 클릭하면 실행될 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

//  Firebase 초기화 및 푸시 알림 리스너를 설정
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  //  단순 권한 요청만 함 (SharedPreferences 관련 저장 X)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // FCM 등록은 권한과 무관하게 계속 진행
  await _registerFcmToken();
}



// FCM 토큰 저장 및 서버에 등록
Future<void> _registerFcmToken() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? existingToken = prefs.getString('fcmToken');

    String? newFcmToken = await FirebaseMessaging.instance.getToken();

    if (newFcmToken == null) {
      // FCM 토큰을 못 가져오면 종료
      return;
    }

    if (newFcmToken != existingToken) {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/users/register'),
        body: jsonEncode({"fcmToken": newFcmToken}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        await prefs.setString('fcmToken', newFcmToken);
      }
      // 실패하더라도 앱 크래시 없음
    }
    // 기존 토큰과 같으면 아무것도 하지 않음
  } catch (_) {
    // 오류 발생 시 무시하고 앱 진행 (출력 없음)
  }
}




// FCM 토큰이 갱신될 때 자동으로 업데이트
void setupFcmTokenRefreshListener() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    // print("새로운 FCM 토큰 감지: $newToken");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? oldToken = prefs.getString('fcmToken');

    if (oldToken != newToken) {
      // 기존 SharedPreferences 값 덮어씌우기
      await prefs.setString('fcmToken', newToken);

      // 서버에도 갱신된 토큰 업데이트 요청
      await updateFcmTokenToServer(newToken);
    } else {
      // print(" FCM 토큰 변경 없음");
    }
  });
}

// 서버에 FCM 토큰 업데이트 요청 (기존 토큰 + 새로운 토큰)
Future<void> updateFcmTokenToServer(String newToken) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? oldToken = prefs.getString('fcmToken'); // 기존 토큰 가져오기

  if (oldToken == null) {
    // print("기존 FCM 토큰이 없음! 새 토큰만 저장.");
    await prefs.setString('fcmToken', newToken);
    return;
  }

  // 서버에 기존 토큰과 새로운 토큰 함께 전송
  final response = await http.put(
    Uri.parse('${dotenv.env['API_URL']}/api/users/update-fcm'),
    body: jsonEncode({
      "oldFcmToken": oldToken,
      "newFcmToken": newToken,
    }),
    headers: {"Content-Type": "application/json"},
  );


  if (response.statusCode == 200) {
    // print("서버에 FCM 토큰 업데이트 성공");

    // 서버 업데이트 성공 시 SharedPreferences 값도 변경
    await prefs.setString('fcmToken', newToken);
  } else {
    // print("서버에 FCM 토큰 업데이트 실패: ${response.body}");
  }
}



class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadThemeMode(); // 앱 실행 시 저장된 테마 불러오기
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'light';

    _themeMode = _stringToThemeMode(theme);
    notifyListeners();
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode.name);
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, // 디버그 표시 삭제 ( 스샷용 )
          title: 'YouTube Routine',
          themeMode: themeNotifier.themeMode,
          theme: ThemeData(
            fontFamily: GoogleFonts.notoSansKr().fontFamily,
            brightness: Brightness.light,
            primaryColor: Colors.white,
            scaffoldBackgroundColor: Colors.grey[100],
            // 배경색 밝게 유지
            cardColor: Colors.white,
            // 카드 배경 밝게
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blueGrey, // AppBar 배경 색
              iconTheme: IconThemeData(color: Colors.blueGrey), // 아이콘 색상 조정
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.black), // 텍스트 기본 색상
              bodyMedium: TextStyle(color: Colors.black87),
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey, // 활성화된 토글 색상
              secondary: Colors.teal, // 버튼 등의 포인트 컬러
              onSurface: Colors.black, // 비활성화된 토글 색상
            ),
            dividerColor: Colors.grey[500],
          ),
          darkTheme: ThemeData(
            fontFamily: GoogleFonts.notoSansKr().fontFamily,
            brightness: Brightness.dark,
            primaryColor: Colors.grey[900],
            // 너무 어둡지 않은 짙은 회색
            scaffoldBackgroundColor: Colors.grey[850],
            // 배경을 살짝 밝은 짙은 회색으로 조정
            cardColor: Colors.grey[800],
            // 카드 배경을 약간 밝게 조정
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[800], // AppBar도 완전 검은색이 아닌 짙은 회색
              iconTheme: IconThemeData(color: Colors.white), // 아이콘 색상 유지
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white70),
              // 완전 흰색이 아닌 흰색70% (가독성 증가)
              bodyMedium: TextStyle(color: Colors.white70),
              // 대비가 덜한 흰색60%
              headlineSmall: TextStyle(color: Colors.white), // 헤드라인은 밝게 유지
            ),
            colorScheme: ColorScheme.dark(
              primary: Colors.blueGrey, // 활성화된 토글 색상
              secondary: Colors.cyan, // 버튼 색상을 밝은 색으로 변경
              onSurface: Colors.white60, // 비활성화된 토글 색상
            ),
            dividerColor: Colors.grey[700], // 구분선 색상도 너무 어둡지 않게 조정
          ),
          home: HomeScreen(),
        );
      },
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {

      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 테마 적용
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium, // 테마 적용
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        backgroundColor: Theme.of(context).colorScheme.secondary, // 테마 적용
        child: const Icon(Icons.add),
      ),
    );
  }

}


final firebaseConfig = {
  "apiKey": dotenv.env['API_KEY'],
  "authDomain": dotenv.env['AUTH_DOMAIN'],
  "projectId": dotenv.env['PROJECT_ID'],
  "storageBucket": dotenv.env['STORAGE_BUCKET'],
  "messagingSenderId": dotenv.env['MESSAGING_SENDER_ID'],
  "appId": dotenv.env['APP_ID'],
  "measurementId": dotenv.env['MEASUREMENT_ID'],
};