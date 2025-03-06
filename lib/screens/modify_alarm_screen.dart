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
    "일": "Sunday", "월": "Monday", "화": "Tuesday",
    "수": "Wednesday", "목": "Thursday", "금": "Friday", "토": "Saturday",
  };

  @override
  void initState() {
    super.initState();

    // print("📌 [ModifyAlarmScreen] 받은 routineTime: ${widget.routine['routineTime']}");

    // ✅ "routineTime"을 직접 사용하여 변환 (원본 값 사용)
    _initializeTime(widget.routine['routineTime'] ?? '00:00');

    // print("✅ 변환된 시간 - Hour: $selectedHour, Minute: $selectedMinute, Period: $selectedPeriod");

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
    final url = Uri.parse("http://10.0.2.2:8080/api/routines/$routineId");

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
        print("✅ 루틴 수정 성공");

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
        print("❌ 루틴 수정 실패: ${response.body}");
      }
    } catch (error) {
      print("❌ 오류 발생: $error");
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
    final url = Uri.parse("http://10.0.2.2:8080/api/routines/$routineId"); // ✅ 루틴 ID 기반 삭제 요청

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ 루틴 삭제 성공");
        Navigator.pop(context, true); // ✅ 삭제 성공 후 true 반환하여 홈 화면에서 fetchAlarms() 실행
      } else {
        print("❌ 루틴 삭제 실패: ${response.body}");
      }
    } catch (error) {
      print("❌ 오류 발생: $error");
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        onPressed: () => Navigator.pop(context), // ✅ 단순히 화면 닫기 (취소 기능)
                        child: Text('취소', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),


                      Text('루틴 수정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => _updateRoutine(widget.routine['id']), // ✅ 루틴 ID 전달
                        child: Text('저장', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey[300]),

                  // ✅ 시간 선택 UI 수정
                  Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: periodController, // ✅ 컨트롤러 적용
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedPeriod = index == 0 ? '오전' : '오후';
                              });
                            },
                            children: ['오전', '오후'].map((e) => Center(child: Text(e, style: TextStyle(fontSize: 22 , fontWeight: FontWeight.bold)))).toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: hourController, // ✅ 컨트롤러 적용
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedHour = index + 1;
                              });
                            },
                            children: List.generate(12, (index) => Center(child: Text("${index + 1}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: minuteController, // ✅ 컨트롤러 적용
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedMinute = index;
                              });
                            },
                            children: List.generate(60, (index) => Center(child: Text("${index.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                      ],
                    ),
                  ),


                  SizedBox(height: 20),

                  // ✅ 유튜브 URL 입력란
                  ListTile(
                    title: Text('유튜브 URL', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: SizedBox(
                      width: 200,
                      height: 40, // ✅ 높이를 통일하여 균형 맞춤
                      child: TextField(
                        controller: youtubeUrlController,
                        textAlignVertical: TextAlignVertical.center, // ✅ 텍스트 중앙 정렬
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10), // ✅ 위아래 패딩 균형 맞춤
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Colors.grey[300]),

                  ListTile(
                    title: Text('내용', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: SizedBox(
                      width: 200,
                      height: 40, // ✅ 높이 동일
                      child: TextField(
                        controller: contentController,
                        textAlignVertical: TextAlignVertical.center, // ✅ 텍스트 중앙 정렬
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10), // ✅ 패딩 조정
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Colors.grey[300]),

                  Divider(color: Colors.grey[300]),

                  // ✅ 요일 선택
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("요일 선택", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: daysMapping.keys.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return ChoiceChip(
                              label: Text(
                                day,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.blueGrey, // ✅ 선택 시 색상 blueGrey
                              backgroundColor: Colors.grey[300], // ✅ 미선택 시 색상 grey[300]
                              showCheckmark: false, // ✅ 체크 표시 제거
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


                  Divider(color: Colors.grey[300]),

                  // ✅ 매주 반복
                  ListTile(
                    title: Text('매 주 반복', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Switch(
                      value: isRepeatEnabled,
                      activeColor: Colors.blueGrey,
                      onChanged: (value) {
                        setState(() {
                          isRepeatEnabled = value;
                        });
                      },
                    ),
                  ),
                  Divider(color: Colors.grey[300]),
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
