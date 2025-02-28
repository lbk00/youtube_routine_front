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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '알람',
          style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.orange, size: 30),
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
            icon: Icon(Icons.settings, color: Colors.orange, size: 30),
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
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('수면 | 기상', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade800, thickness: 1),
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
          Divider(color: Colors.grey.shade800, thickness: 1),
          BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.language), label: '세계 시계'),
              BottomNavigationBarItem(icon: Icon(Icons.alarm, size: 30), label: '알람'),
              BottomNavigationBarItem(icon: Icon(Icons.timer), label: '타이머'),
            ],
          ),
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
    return Padding(
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
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Switch(
            value: isActive,
            onChanged: onToggle,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
