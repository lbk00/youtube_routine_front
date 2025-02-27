import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
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
          TextButton(
            onPressed: () {},
            child: Text(
              '편집',
              style: TextStyle(color: Colors.orange, fontSize: 18),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.orange, size: 30),
            onPressed: () {},
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
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('설정', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade800, thickness: 1),
          Expanded(
            child: ListView(
              children: [
                AlarmTile(time: '오전 8:00', description: '알람, 주중', isActive: true),
                AlarmTile(time: '오전 8:20', description: '알람, 매일', isActive: true),
                AlarmTile(time: '오전 8:50', description: '알람, 주말', isActive: true),
              ],
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

  const AlarmTile({
    required this.time,
    required this.description,
    required this.isActive,
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
            onChanged: (value) {},
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
