import 'package:flutter/material.dart';
import 'package:youtube_routine_front/screens/add_alarm_screen.dart';
import 'package:youtube_routine_front/screens/side_menu.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<bool> alarmStates = [true, true, true]; // 토글 상태 저장 리스트

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 밝은 회색 배경 적용
      appBar: AppBar(
        backgroundColor: Colors.white, // 상단 바 밝게 변경
        title: Text(
          '알람',
          style: TextStyle(color: Colors.black87, fontSize: 35, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.blueGrey, size: 30), // 아이콘 색상 변경
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => AddAlarmScreen(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.blueGrey, size: 30),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: SideMenu(),
                ),
              );
            },
          ),
        ],
        elevation: 1, // 가벼운 그림자 효과 추가
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('저장된 루틴 목록', style: TextStyle(color: Colors.black54, fontSize: 16)),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade300, thickness: 3),
          Expanded(
            child: ListView.builder(
              itemCount: alarmStates.length,
              itemBuilder: (context, index) {
                return AlarmTile(
                  time: ['오전 8:00', '오전 8:20', '오전 8:50'][index],
                  description: ['알람, 주중', '알람, 매일', '알람, 주말'][index],
                  isActive: alarmStates[index],
                  onToggle: (value) {
                    setState(() {
                      alarmStates[index] = value;
                    });
                  },
                );
              },
            ),
          ),
          Divider(color: Colors.grey.shade300, thickness: 1),
        ],
      ),
    );
  }
}

class AlarmTile extends StatelessWidget {
  final String time;
  final String description;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const AlarmTile({
    required this.time,
    required this.description,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold, // Bold 적용
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold, // Bold 적용
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isActive,
                onChanged: onToggle,
                activeColor: Colors.blueGrey,
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.shade300, thickness: 1), // 리스트 구분선 추가
      ],
    );
  }
}
