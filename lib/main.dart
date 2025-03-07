import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_routine_front/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: "assets/.env");

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

  runApp(ChangeNotifierProvider(
    create: (context) => ThemeNotifier(),
    child: const MyApp(),
  ));
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