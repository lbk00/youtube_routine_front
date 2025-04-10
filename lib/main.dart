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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
}



class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // main()에서 이미 모든 초기화 끝났기 때문에 단순 UX용 딜레이
    Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
          ),
        ),
      ),
    );
  }
}


// 🔹 백그라운드 또는 종료된 상태에서 푸시 알림을 클릭하면 실행될 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // _handleMessage(message);
}

//  Firebase 초기화 및 푸시 알림 리스너를 설정
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("🔴 푸시 알림 권한이 거부됨!");
    return;
  }

  print("✅ 푸시 알림 권한이 허용됨!");

  await _registerFcmToken();

  // 앱이 포그라운드일 때만 알림 띄우기
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📌 [푸시 알림 도착 - Foreground]");
    _showNotification(message);
  });
}


// FCM 토큰 저장 및 서버에 등록
Future<void> _registerFcmToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? existingToken = prefs.getString('fcmToken');

  // 새로운 FCM 토큰 가져오기
  String? newFcmToken;
  try {
    newFcmToken = await FirebaseMessaging.instance.getToken();
    print("🔥 가져온 FCM Token: $newFcmToken");
  } catch (e) {
    print("❌ FCM 토큰 가져오기 실패: $e");
    return;
  }

  // 기존 토큰과 다를 경우 서버에 등록
  if (newFcmToken != null && newFcmToken != existingToken) {
    print("📡 서버에 FCM 토큰 등록 요청 중...");

    final response = await http.post(
      Uri.parse("http://192.168.0.5:8080/api/users/register"),
      body: jsonEncode({"fcmToken": newFcmToken}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print("✅ 사용자 등록 성공! FCM 토큰을 SharedPreferences에 저장");
      await prefs.setString('fcmToken', newFcmToken);
    } else {
      print("❌ 사용자 등록 실패: ${response.body}");
    }
  } else {
    print("ℹ️ 기존 FCM 토큰과 동일하여 서버에 전송하지 않음.");
  }
}


// 로컬 푸시 알림 표시
Future<void> _showNotification(RemoteMessage message) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  // 기본 유튜브 링크
  final fallbackUrl = Uri.parse("https://www.youtube.com/");

  // 🔧 initialize: 알림 클릭 시 안전한 링크 처리
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final rawPayload = response.payload;

      if (rawPayload == null || rawPayload.trim().isEmpty) {
        print("⚠️ payload 없음 → fallback 이동");
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        return;
      }

      Uri? uri;
      try {
        uri = Uri.parse(rawPayload);
      } catch (e) {
        print("❌ URI 파싱 실패 → fallback 이동");
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        return;
      }

      // scheme 확인
      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        print("❌ 잘못된 scheme: $scheme → fallback 이동");
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print("⚠️ 실행 불가능한 URL → fallback 이동");
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    },
  );

  // 알림 구성 및 표시
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'youtube_routine_channel',
    'YouTube Routine Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? "오늘의 홈트",
    message.notification?.body ?? "오늘 할 루틴이 도착했어요!",
    notificationDetails,
    payload: message.data['youtubeLink'],
  );
}



// FCM 토큰이 갱신될 때 자동으로 업데이트
void setupFcmTokenRefreshListener() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 새로운 FCM 토큰 감지: $newToken");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? oldToken = prefs.getString('fcmToken');

    if (oldToken != newToken) {
      // 기존 SharedPreferences 값 덮어씌우기
      await prefs.setString('fcmToken', newToken);

      // 서버에도 갱신된 토큰 업데이트 요청
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

  // 서버에 기존 토큰과 새로운 토큰 함께 전송
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

    // 서버 업데이트 성공 시 SharedPreferences 값도 변경
    await prefs.setString('fcmToken', newToken);
  } else {
    print("❌ 서버에 FCM 토큰 업데이트 실패: ${response.body}");
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
          home: SplashScreen(),
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