import 'package:flutter/material.dart';

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
      begin: Offset(1.0, 0.0), // 화면 밖에서 시작
      end: Offset(0.4, 0.0), // 오른쪽 벽에 딱 붙도록 설정
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
    return Stack(
      children: [
        // 메뉴 바깥 터치 시 닫히도록 GestureDetector 추가
        GestureDetector(
          onTap: _closeMenu, // 배경 터치 시 닫기
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent, // 투명 배경으로 설정
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: _animation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: Colors.black,
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
                  SizedBox(height: 50),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '설정 메뉴',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(color: Colors.grey),
                  ListTile(
                    leading: Icon(Icons.notifications, color: Colors.white),
                    title: Text('어두운 테마', style: TextStyle(color: Colors.white)),
                    onTap: _closeMenu,
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.white),
                    title: Text('앱 설정', style: TextStyle(color: Colors.white)),
                    onTap: _closeMenu,
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: Colors.white),
                    title: Text('앱 정보', style: TextStyle(color: Colors.white)),
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
