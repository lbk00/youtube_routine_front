import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_routine_front/screens/add_alarm_screen.dart';
import 'package:youtube_routine_front/screens/side_menu.dart';
import 'package:youtube_routine_front/screens/modify_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> alarms = []; // ✅ API에서 가져온 루틴 데이터 저장
  List<bool> alarmStates = []; // ✅ ON/OFF 상태 저장

  @override
  void initState() {
    super.initState();
    fetchAlarms(); // ✅ 앱 실행 시 API 호출
  }

  String formatTime(String routineTime) {
    if (routineTime.isEmpty || !routineTime.contains(":")) {
      return "오전 12:00"; // 기본값
    }

    List<String> parts = routineTime.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    String period = hour < 12 ? "오전" : "오후";
    int hour12 = hour % 12 == 0 ? 12 : hour % 12; // 0시는 12로 변환

    return "$period $hour12:${minute.toString().padLeft(2, '0')}";
  }



  /// ✅ 모든 루틴 조회
  Future<void> fetchAlarms() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/api/routines/user/fcm1'));

    if (response.statusCode == 200) {
      final decodedData = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(decodedData);

      setState(() {
        alarms = data.map((item) {
          String rawTime = item['routineTime']; // ✅ 원본 시간값 저장
          print("📌 API에서 받은 routineTime: $rawTime"); // 디버깅용 로그

          return {
            'id': item['id'],
            'time': formatTime(rawTime), // ✅ 변환된 시간 (오전/오후 적용)
            'routineTime': rawTime, // ✅ 원본 시간값 추가
            'description': item['content'] ?? '',
            'days': item['days'] as List<dynamic> ?? [],
            'isActive': item['active'] ?? false,
            'youtubeLink': item['youtubeLink'] ?? '',
            'repeatFlag': item['repeatFlag'] ?? false,
          };
        }).toList();

        alarmStates = alarms.map((alarm) => alarm['isActive'] as bool).toList();
      });
    } else {
      throw Exception('Failed to load alarms');
    }
  }

  //  토글 버튼
  Future<void> toggleRoutine(int routineId) async {
    final url = Uri.parse("http://10.0.2.2:8080/api/routines/toggle/$routineId");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // print("✅ 루틴 활성 상태 변경 성공 (ID: $routineId)");

        setState(() {
          // ✅ alarms 리스트에서 해당 루틴의 isActive 상태를 반전
          for (var alarm in alarms) {
            if (alarm['id'] == routineId) {
              alarm['isActive'] = !alarm['isActive'];
              break;
            }
          }
        });
      } else {
        print("❌ 루틴 활성 상태 변경 실패: ${response.body}");
      }
    } catch (error) {
      print("❌ 오류 발생: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
            onPressed: () async {
              final result = await showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                useRootNavigator: true, // ✅ 추가
                builder: (context) => AddAlarmScreen(fcmToken: 'fcm1'),
              );

              if (result == true) {
                fetchAlarms(); // ✅ 루틴 저장 후 자동 갱신
              }
            },
          ),


          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
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
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('저장된 루틴', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade600),
          Expanded(
            child: alarms.isEmpty
                ? Center(
              child: Text(
                "저장된 루틴이 없습니다.",
                style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            )
                : ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return GestureDetector(
                  onTap: () {
                    final routine = {
                      'id': alarm['id'],
                      'time': alarm['time'] ?? '00:00', // ✅ 변환된 시간 (오전/오후 적용)
                      'routineTime': alarm['routineTime'] ?? '00:00', // ✅ 원본 24시간제 시간
                      'description': alarm['description'] ?? '',
                      'days': alarm['days'] ?? [],
                      'isActive': alarm['isActive'] ?? false,
                      'youtubeLink': alarm['youtubeLink'] ?? '',
                      'repeatFlag': alarm['repeatFlag'] ?? false,
                    };

                    // print("📌 [HomeScreen] ModifyAlarmScreen에 넘기는 routineTime: ${routine['routineTime']}");

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ModifyAlarmScreen(routine: routine),
                    ).then((result) {
                      if (result == true) {
                        fetchAlarms(); // ✅ 루틴 수정 , 삭제 후 자동 갱신
                      }
                    });
                  },

                  child:
                  AlarmTile(
                    time: alarm['time'],
                    description: alarm['description'],
                    days: alarm['days'].cast<String>(),
                    isActive: alarm['isActive'],
                    onToggle: (bool newValue) { // ✅ bool 값을 받아서 toggleRoutine 호출
                      toggleRoutine(alarm['id']);
                    },
                  ),


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

//  알람 개별 항목 위젯
class AlarmTile extends StatelessWidget {
  final String time;
  final String description;
  final List<String> days;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  //  영어 요일을 한 글자 한글로 변환하는 Map
  static const Map<String, String> dayTranslations = {
    "Sunday": "일",
    "Monday": "월",
    "Tuesday": "화",
    "Wednesday": "수",
    "Thursday": "목",
    "Friday": "금",
    "Saturday": "토",
  };

  const AlarmTile({
    required this.time,
    required this.description,
    required this.days,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  시간 + 내용 (같은 줄에 배치)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // ✅ Row 내부에서 공간 조정 (overflow 방지)
                  child: Row(
                    children: [
                      Text(
                        time, // ⏰ 시간
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10), // 간격 추가
                      Expanded( // ✅ 설명이 길 경우 자동 줄바꿈 또는 생략 처리
                        child: Text(
                          description,
                          style: TextStyle(fontSize: 22),
                          overflow: TextOverflow.ellipsis, // ✅ 길 경우 ...으로 표시
                          maxLines: 1, // ✅ 한 줄까지만 표시
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (bool newValue) {
                    onToggle(newValue);
                  },
                  activeTrackColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[800] // 다크 모드에서 활성화된 배경
                      : Colors.blue[800], // 밝은 모드에서 활성화된 배경
                  activeColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300] // 다크 모드에서 활성화된 스위치 원 색상
                      : Colors.white, // 밝은 모드에서 활성화된 스위치 원 색상
                  inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[500] // 다크 모드에서 비활성화된 배경
                      : Colors.white, // 밝은 모드에서 비활성화된 배경
                  inactiveThumbColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800] // 다크 모드에서 비활성화된 원 색상
                      : Colors.black, // 밝은 모드에서 비활성화된 원 색상
                )



              ],
            ),
            SizedBox(height: 8), //  간격 추가
            //  요일 정보 추가 (월, 화, 수, 목, 금 형태, 스타일 적용)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" // ✅ 고정된 순서
              ]
                  .where((day) => days.contains(day)) // ✅ 선택된 요일만 필터링
                  .map((day) {
                String koreanDay = dayTranslations[day] ?? day; //  영어 → 한글 변환
                return Container(
                  width: 32, height: 32, //  크기 고정
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]  // ✅ 다크 모드에서는 밝은 회색 배경
                        : Colors.grey[300],  // ✅ 라이트 모드에서는 기존 회색
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      koreanDay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black87  // ✅ 다크 모드에서는 검은색 텍스트
                            : Colors.black,    // ✅ 기본 모드에서도 가독성 유지
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

}