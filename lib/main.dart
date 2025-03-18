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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: "assets/.env");

  // 기기를 세로 모드로 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (kIsWeb) {
    // Web에서는 FirebaseOptions을 사용하여 초기화
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


  // 최초 실행 시 FCM 토큰을 가져와 사용자 등록
  // 비동기 실행하여 UI 스레드 차단 방지
  Future.microtask(() async {
    await checkFirstRunAndRegisterUser();
  });

  // ✅ FCM 토큰이 변경될 때 업데이트 리스너 설정
  setupFcmTokenRefreshListener();

  runApp(ChangeNotifierProvider(
    create: (context) => ThemeNotifier(),
    child: const MyApp(),
  ));
}


Future<void> checkFirstRunAndRegisterUser() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

    print("🚀 앱 최초 실행 여부: $isFirstRun");

    if (isFirstRun) {
      print("🚀 최초 실행 감지! FCM 토큰을 가져와서 사용자 등록");

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print("🔥 가져온 FCM Token: $fcmToken");
      } catch (e) {
        print("❌ FCM 토큰 가져오기 실패: $e");
        return;
      }

      if (fcmToken != null) {
        print("📡 서버에 FCM 토큰 등록 요청 중...");
        final response = await http.post(
          Uri.parse("http://192.168.0.5:8080/api/users/register"),
          body: jsonEncode({"fcmToken": fcmToken}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          print("✅ 사용자 등록 성공! FCM 토큰을 SharedPreferences에 저장");
          await prefs.setString('fcmToken', fcmToken);
          await prefs.setBool('isFirstRun', false);

          // ✅ 저장 후 즉시 값을 다시 불러와 확인
          String? savedToken = prefs.getString('fcmToken');
          print("🔄 SharedPreferences에 저장된 FCM 토큰 확인: $savedToken");
        } else {
          print("❌ 사용자 등록 실패: ${response.body}");
        }
      }
    } else {
      print("ℹ️ 앱이 이미 실행된 적 있음, 기존 FCM 토큰 확인");
      String? existingToken = prefs.getString('fcmToken');

      if (existingToken == null) {
        print("❌ SharedPreferences에 FCM Token 없음! 새로 가져와 저장해야 함.");

        // ✅ FCM 토큰 새로 가져오기
        String? newFcmToken;
        try {
          newFcmToken = await FirebaseMessaging.instance.getToken();
          print("🔥 새롭게 가져온 FCM Token: $newFcmToken");
        } catch (e) {
          print("❌ FCM 토큰 가져오기 실패: $e");
          return;
        }

        if (newFcmToken != null) {
          // ✅ 새로 가져온 토큰을 SharedPreferences에 저장
          await prefs.setString('fcmToken', newFcmToken);
          print("✅ SharedPreferences에 새로운 FCM 토큰 저장 완료!");
        }
      } else {
        print("📌 SharedPreferences에 저장된 기존 FCM Token: $existingToken");
      }
    }
  } catch (e) {
    print("❌ checkFirstRunAndRegisterUser() 실행 중 오류 발생: $e");
  }
}




// ✅ FCM 토큰이 갱신될 때 자동으로 업데이트
void setupFcmTokenRefreshListener() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 새로운 FCM 토큰 감지: $newToken");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? oldToken = prefs.getString('fcmToken');

    if (oldToken != newToken) {
      // ✅ 기존 SharedPreferences 값 덮어씌우기
      await prefs.setString('fcmToken', newToken);

      // ✅ 서버에도 갱신된 토큰 업데이트 요청
      await updateFcmTokenToServer(newToken);
    } else {
      print("ℹ️ FCM 토큰 변경 없음");
    }
  });
}

// 서버에 FCM 토큰 업데이트 요청
// 서버에 FCM 토큰 업데이트 요청 (기존 토큰 + 새로운 토큰)
Future<void> updateFcmTokenToServer(String newToken) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? oldToken = prefs.getString('fcmToken'); // 기존 토큰 가져오기

  if (oldToken == null) {
    print("❌ 기존 FCM 토큰이 없음! 새 토큰만 저장.");
    await prefs.setString('fcmToken', newToken);
    return;
  }

  // ✅ 서버에 기존 토큰과 새로운 토큰 함께 전송
  final response = await http.put(
    Uri.parse("http://192.168.0.5:8080/api/users/update-fcm"),
    body: jsonEncode({
      "oldFcmToken": oldToken,  // 기존 FCM 토큰
      "newFcmToken": newToken   // 새로운 FCM 토큰
    }),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    print("✅ 서버에 FCM 토큰 업데이트 성공!");

    // ✅ 서버 업데이트 성공 시 SharedPreferences 값도 변경
    await prefs.setString('fcmToken', newToken);
  } else {
    print("❌ 서버에 FCM 토큰 업데이트 실패: ${response.body}");
  }
}



class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'YouTube Routine',
          themeMode: themeNotifier.themeMode,
          theme: ThemeData(
            fontFamily: GoogleFonts.notoSansKr().fontFamily,
            brightness: Brightness.light,
            primaryColor: Colors.white,
            scaffoldBackgroundColor: Colors.grey[100], // ✅ 배경색 밝게 유지
            cardColor: Colors.white, // ✅ 카드 배경 밝게
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blueGrey, // ✅ AppBar 배경 색
              iconTheme: IconThemeData(color: Colors.blueGrey), // ✅ 아이콘 색상 조정
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.black), // ✅ 텍스트 기본 색상
              bodyMedium: TextStyle(color: Colors.black87),
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey, // ✅ 활성화된 토글 색상
              secondary: Colors.teal, // ✅ 버튼 등의 포인트 컬러
              onSurface: Colors.black, // ✅ 비활성화된 토글 색상
            ),
            dividerColor: Colors.grey[500],
          ),

            darkTheme: ThemeData(
              fontFamily: GoogleFonts.notoSansKr().fontFamily,
              brightness: Brightness.dark,
              primaryColor: Colors.grey[900], // ✅ 너무 어둡지 않은 짙은 회색
              scaffoldBackgroundColor: Colors.grey[850], // ✅ 배경을 살짝 밝은 짙은 회색으로 조정
              cardColor: Colors.grey[800], // ✅ 카드 배경을 약간 밝게 조정

              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey[800], // ✅ AppBar도 완전 검은색이 아닌 짙은 회색
                iconTheme: IconThemeData(color: Colors.white), // ✅ 아이콘 색상 유지
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),

              textTheme: TextTheme(
                bodyLarge: TextStyle(color: Colors.white70), // ✅ 완전 흰색이 아닌 흰색70% (가독성 증가)
                bodyMedium: TextStyle(color: Colors.white70), // ✅ 대비가 덜한 흰색60%
                headlineSmall: TextStyle(color: Colors.white), // ✅ 헤드라인은 밝게 유지
              ),
              colorScheme: ColorScheme.dark(
                primary: Colors.blueGrey, // ✅ 활성화된 토글 색상
                secondary: Colors.cyan, // ✅ 버튼 색상을 밝은 색으로 변경
                onSurface: Colors.white60, // ✅ 비활성화된 토글 색상
              ),

              dividerColor: Colors.grey[700], // ✅ 구분선 색상도 너무 어둡지 않게 조정
            ),

          home: HomeScreen(),
        );
      },
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ 테마 적용
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
              style: Theme.of(context).textTheme.headlineMedium, // ✅ 테마 적용
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        backgroundColor: Theme.of(context).colorScheme.secondary, // ✅ 테마 적용
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