import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_routine_front/main.dart';

class SideMenu extends StatefulWidget {
  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset(0.4, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  void _closeMenu() {
    _controller.reverse().then((_) => Navigator.of(context).pop());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ///  "사용 방법" 팝업 함수
  void _showUsageDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // ✅ 팝업 바깥 클릭 시 닫기
      builder: (BuildContext context) {
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final Color stepColor = isDarkMode ? Colors.blueGrey[400]! : Colors.blueGrey!; // ✅ 다크/라이트 모드 색상 변경
        final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // ✅ 팝업 모서리 둥글게
          ),
          backgroundColor: Theme.of(context).dialogBackgroundColor, // ✅ 다크모드 대응
          title: Row(
            children: [
              Icon(Icons.info_outline, color: stepColor), // ✅ 아이콘 색상 변경
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "📌 YouTube Routine 사용 방법",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor, // ✅ 다크모드 대응
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUsageStep("➊", "화면 상단의 '+' 버튼을 눌러 새로운 루틴을 추가하세요.", stepColor),
              _buildUsageStep("➋", "원하는 요일과 시간을 설정하고 유튜브 링크를 입력하세요.", stepColor),
              _buildUsageStep("➌", "설정한 시간에 알림이 오면 클릭하여 저장된 유튜브 링크로 이동합니다.", stepColor),
              _buildUsageStep("➍", "토글 버튼을 통해 루틴을 ON/OFF 할 수 있습니다.", stepColor),
              _buildUsageStep("➎", "루틴은 최대 10개까지 저장 가능합니다.", stepColor),
              _buildUsageStep("➏", "오전 12시는 자정, 오후 12시는 정오를 의미합니다.", stepColor),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "확인",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: stepColor, // ✅ 버튼 색상 통일
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // ✅ 팝업 닫기
              },
            ),
          ],
        );
      },
    );
  }

  /// ✅ 설명 스타일이 자연스럽게 연결되도록 변경
  Widget _buildUsageStep(String number, String text, Color numberColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 숫자를 강조하는 스타일
          Text(
            number,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: numberColor),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color, // ✅ 다크모드 대응
              ),
            ),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Stack(
      children: [
        GestureDetector(
          onTap: _closeMenu,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
          ),
        ),
        Align(
          alignment: Alignment(1.0, -0.8),
          child: SlideTransition(
            position: _animation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.33,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '설정',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor),
                  ListTile(
                    leading: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode ,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      isDarkMode ? '밝은 테마' : '어두운 테마',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                      onTap: () {
                        // print("🌙 다크 모드 변경됨!");
                        themeNotifier.toggleTheme();
                        _closeMenu();
                      }
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: Theme.of(context).iconTheme.color),
                    title: Text(
                      '사용 방법',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    onTap: () {
                      _showUsageDialog(); // ✅ 사이드 메뉴 닫지 않고 팝업만 띄움
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.info, color: Theme.of(context).iconTheme.color),
                    title: Text('앱 정보', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      // onTap: _closeMenu,
                      onTap: () => getFCMToken(), // 임시 fcm 토큰 호출
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// 임시 함수
Future<void> getFCMToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
}