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
              height: MediaQuery.of(context).size.height * 0.4,
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
                  SizedBox(height: 10),
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
                        print("🌙 다크 모드 변경됨!");
                        themeNotifier.toggleTheme();
                        _closeMenu();
                      }
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
                    title: Text('사용 방법', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    onTap: _closeMenu,
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: Theme.of(context).iconTheme.color),
                    title: Text('앱 정보', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    onTap: _closeMenu,
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
