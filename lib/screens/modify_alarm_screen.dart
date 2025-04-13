import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ModifyAlarmScreen extends StatefulWidget {
  final Map<String, dynamic> routine;

  const ModifyAlarmScreen({Key? key, required this.routine}) : super(key: key);

  @override
  _ModifyAlarmScreenState createState() => _ModifyAlarmScreenState();
}

class _ModifyAlarmScreenState extends State<ModifyAlarmScreen> {
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;
  late FixedExtentScrollController periodController;

  int selectedHour = 8;
  int selectedMinute = 0;
  String selectedPeriod = '오전';
  bool isRepeatEnabled = false;

  TextEditingController youtubeUrlController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  List<String> selectedDays = [];

  final Map<String, String> daysMapping = {
    "월": "Monday", "화": "Tuesday",
    "수": "Wednesday", "목": "Thursday", "금": "Friday", "토": "Saturday", "일": "Sunday",
  };

  @override
  void initState() {
    super.initState();

    // // print("📌 [ModifyAlarmScreen] 받은 routineTime: ${widget.routine['routineTime']}");

    // ✅ "routineTime"을 직접 사용하여 변환 (원본 값 사용)
    _initializeTime(widget.routine['routineTime'] ?? '00:00');

    // // print("✅ 변환된 시간 - Hour: $selectedHour, Minute: $selectedMinute, Period: $selectedPeriod");

    periodController = FixedExtentScrollController(initialItem: selectedPeriod == '오전' ? 0 : 1);
    hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);

    selectedDays = (widget.routine['days'] as List<dynamic>? ?? [])
        .map<String>((day) => daysMapping.entries.firstWhere(
          (entry) => entry.value == day,
      orElse: () => MapEntry("", ""),
    ).key)
        .where((day) => day.isNotEmpty)
        .toList();

    youtubeUrlController.text = widget.routine['youtubeLink'] ?? 'https://youtube.com';
    contentController.text = widget.routine['description'] ?? '';
    isRepeatEnabled = widget.routine['repeatFlag'] ?? false;
  }


  void _initializeTime(String timeString) {
    if (timeString.isEmpty || !timeString.contains(":")) {
      timeString = "00:00"; // 기본값 설정
    }

    List<String> timeParts = timeString.split(":");
    int hour = int.tryParse(timeParts[0]) ?? 0;
    int minute = int.tryParse(timeParts[1]) ?? 0;

    setState(() {
      selectedMinute = minute;

      if (hour == 0) {
        selectedPeriod = '오전';
        selectedHour = 12; // 00:00 → 오전 12시
      } else if (hour < 12) {
        selectedPeriod = '오전';
        selectedHour = hour; // ✅ 변환 없이 그대로 유지
      } else if (hour == 12) {
        selectedPeriod = '오후';
        selectedHour = 12;
      } else {
        selectedPeriod = '오후';
        selectedHour = hour - 12;
      }
    });

    periodController = FixedExtentScrollController(initialItem: selectedPeriod == '오전' ? 0 : 1);
    hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }







  // 루틴 수정
  Future<void> _updateRoutine(int routineId) async {
    final url = Uri.parse("http://192.168.0.5:8080/api/routines/$routineId");

    List<String> englishDays = selectedDays.map((day) => daysMapping[day]!).toList();

    // ✅ 12시간제를 24시간제로 변환
    int hour = selectedHour;
    if (selectedPeriod == '오후' && hour != 12) {
      hour += 12;
    } else if (selectedPeriod == '오전' && hour == 12) {
      hour = 0;
    }

    String routineTime = "${hour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}";

    final Map<String, dynamic> requestBody = {
      "days": englishDays,
      "routineTime": routineTime,
      "youtubeLink": youtubeUrlController.text,
      "content": contentController.text,
      "repeatFlag": isRepeatEnabled,
    };

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // print("✅ 루틴 수정 성공");

        // ✅ 수정된 데이터를 `widget.routine`에 반영
        setState(() {
          widget.routine['time'] = routineTime; // ✅ UI 업데이트
          widget.routine['days'] = englishDays;
          widget.routine['youtubeLink'] = youtubeUrlController.text;
          widget.routine['description'] = contentController.text;
          widget.routine['repeatFlag'] = isRepeatEnabled;

          // ✅ 새로운 시간값을 반영하여 업데이트
          _updateTimeState(routineTime);
        });

        Navigator.pop(context, true); // ✅ true 반환하여 홈 화면에서 fetchAlarms() 실행
      } else {
        // print("❌ 루틴 수정 실패: ${response.body}");
      }
    } catch (error) {
      // print("❌ 오류 발생: $error");
    }
  }


  void _updateTimeState(String timeString) {
    List<String> timeParts = timeString.split(":");
    int hour = int.tryParse(timeParts[0]) ?? 0;
    int minute = int.tryParse(timeParts[1]) ?? 0;

    setState(() {
      selectedMinute = minute;

      if (hour == 0) {
        selectedPeriod = '오전';
        selectedHour = 12; // 00:00 → 오전 12시
      } else if (hour < 12) {
        selectedPeriod = '오전';
        selectedHour = hour;
      } else if (hour == 12) {
        selectedPeriod = '오후';
        selectedHour = 12;
      } else {
        selectedPeriod = '오후';
        selectedHour = hour - 12;
      }
    });
  }



  // 루틴 삭제
  Future<void> _deleteRoutine(int routineId) async {
    final url = Uri.parse("http://192.168.0.5:8080/api/routines/$routineId"); // ✅ 루틴 ID 기반 삭제 요청

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // print("✅ 루틴 삭제 성공");
        Navigator.pop(context, true); // ✅ 삭제 성공 후 true 반환하여 홈 화면에서 fetchAlarms() 실행
      } else {
        // print("❌ 루틴 삭제 실패: ${response.body}");
      }
    } catch (error) {
      // print("❌ 오류 발생: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor, // ✅ 다크 모드 배경 적용
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor, // ✅ 다크 모드 적용
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 상단 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('취소', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Text('루틴 수정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      TextButton(
                        onPressed: () => _updateRoutine(widget.routine['id']),
                        child: Text('저장', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Divider(color: Theme.of(context).dividerColor), // ✅ 다크 모드 적용

                  // ✅ 시간 선택 UI 수정
                  Container(
                    height: 200,
                    color: Theme.of(context).cardColor, // ✅ 다크 모드 적용
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ 다크 모드 적용
                            itemExtent: 40,
                            scrollController: periodController,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedPeriod = index == 0 ? '오전' : '오후';
                              });
                            },
                            children: ['오전', '오후'].map(
                                  (e) => Center(child: Text(e, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold))),
                            ).toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            itemExtent: 40,
                            scrollController: hourController,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedHour = index + 1;
                              });
                            },
                            children: List.generate(12, (index) => Center(child: Text("${index + 1}", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            itemExtent: 40,
                            scrollController: minuteController,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedMinute = index;
                              });
                            },
                            children: List.generate(60, (index) => Center(child: Text("${index.toString().padLeft(2, '0')}", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: Theme.of(context).dividerColor),

                  // ✅ 유튜브 URL 입력란
                  ListTile(
                    title: Text('유튜브 URL', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                    trailing: SizedBox(
                      width: 200,
                      height: 40,
                      child: TextField(
                        controller: youtubeUrlController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          hintText: '링크 입력',
                          hintStyle: TextStyle(color: Theme.of(context).hintColor),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor),

                  ListTile(
                    title: Text('내용', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                    trailing: SizedBox(
                      width: 200,
                      height: 40,
                      child: TextField(
                        controller: contentController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          hintText: '내용 입력',
                          hintStyle: TextStyle(color: Theme.of(context).hintColor),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor),

                  // ✅ 요일 선택
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("요일 선택", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color,fontSize: 16  , fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: daysMapping.keys.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return ChoiceChip(
                              label: Text(day, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
                              selected: isSelected,
                              selectedColor: Colors.blueGrey,
                              backgroundColor: Theme.of(context).cardColor, // ✅ 다크 모드 적용
                              showCheckmark: false,
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedDays.add(day);
                                  } else {
                                    selectedDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor),

                  // ✅ 매주 반복
                  ListTile(
                    title: Text('매 주 반복', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                    trailing: Switch(
                      value: isRepeatEnabled, // 추가 화면에서는 isRepeatEnabled 상태 사용
                      onChanged: (bool newValue) {
                        setState(() {
                          isRepeatEnabled = newValue;
                        });
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

                  ),
                  Divider(color: Theme.of(context).dividerColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => _deleteRoutine(widget.routine['id']), // ✅ 삭제 기능 호출
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey, // 빨간색 버튼
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          '삭제',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
