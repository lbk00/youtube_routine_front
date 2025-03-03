import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class AddAlarmScreen extends StatefulWidget {
  final String fcmToken; // 각 사용자의 FCM 토큰

  const AddAlarmScreen({Key? key, required this.fcmToken}) : super(key: key);

  @override
  _AddAlarmScreenState createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  int selectedHour = 8;
  int selectedMinute = 0;
  String selectedPeriod = '오후';
  bool isRepeatEnabled = false;
  TextEditingController youtubeUrlController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  List<String> selectedDays = []; // 선택한 요일 리스트

  // ✅ 오류 메시지 상태
  String? youtubeUrlError;
  String? daysError;

  // 요일 목록 (영어 이름으로 API에 넘김)
  // ✅ UI에서는 한글, API에서는 영어로 변환하도록 매핑
  final Map<String, String> daysMapping = {
    "일": "Sunday",
    "월": "Monday",
    "화": "Tuesday",
    "수": "Wednesday",
    "목": "Thursday",
    "금": "Friday",
    "토": "Saturday",
  };

  /// 입력된 값으로 API 요청 보내기
  Future<void> _saveRoutine() async {
    bool isValid = true;
    // ✅ 입력값 검증 (유튜브 URL & 요일 선택 필수)
    setState(() {
      // ✅ 유튜브 URL 검증
      if (youtubeUrlController.text.isEmpty) {
        youtubeUrlError = "URL을 입력하세요.";
        isValid = false;
      } else {
        youtubeUrlError = null;
      }

      // ✅ 요일 선택 검증
      if (selectedDays.isEmpty) {
        daysError = "요일을 선택하세요.";
        isValid = false;
      } else {
        daysError = null;
      }
    });

    if (!isValid) return;

    // ✅ 한글 요일을 영어로 변환
    List<String> englishDays = selectedDays.map((day) => daysMapping[day]!).toList();

    // 12시간제를 24시간제로 변환
    int hour = selectedHour;
    if (selectedPeriod == '오후' && hour != 12) {
      hour += 12;
    } else if (selectedPeriod == '오전' && hour == 12) {
      hour = 0; // 오전 12시는 00:00으로 변환
    }
    String routineTime = "${hour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}";

    final url = Uri.parse("http://10.0.2.2:8080/api/routines/create/${widget.fcmToken}");
    final Map<String, dynamic> requestBody = {
      "days": englishDays,
      "routineTime": routineTime,
      "youtubeLink": youtubeUrlController.text.isNotEmpty
          ? youtubeUrlController.text
          : "https://youtube.com",
      "content": contentController.text,
      "repeatFlag": isRepeatEnabled,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print("✅ 루틴 저장 성공: $responseData");

        Navigator.pop(context, responseData);
      } else {
        print("❌ 루틴 저장 실패: ${response.body}");
      }
    } catch (error) {
      print("❌ 오류 발생: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('취소', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Text('루틴 추가', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              TextButton(
                onPressed: _saveRoutine, // 저장 버튼 클릭 시 API 호출
                child: Text('저장', style: TextStyle(color: Colors.black, fontSize: 18 , fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(color: Colors.grey[300]),

          // 시간 선택 영역 (오전/오후, 시, 분)
          Container(
            height: 200,
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: Colors.grey[100],
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(initialItem: selectedPeriod == '오전' ? 0 : 1),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedPeriod = index == 0 ? '오전' : '오후';
                      });
                    },
                    children: ['오전', '오후']
                        .map((e) => Center(child: Text(e, style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)))).toList(),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: Colors.grey[100],
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(initialItem: selectedHour - 1),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedHour = index + 1;
                      });
                    },
                    children: List.generate(12, (index) => Center(child: Text("${index + 1}", style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)))),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: Colors.grey[100],
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(initialItem: selectedMinute),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMinute = index;
                      });
                    },
                    children: List.generate(60, (index) => Center(child: Text("${index.toString().padLeft(2, '0')}", style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)))),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // 유튜브 URL 입력란
          ListTile(
            title: Text('유튜브 URL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            trailing: SizedBox(
              width: 200,
              height: 35,
              child: TextField(
                controller: youtubeUrlController,
                onChanged: (value) {
                  setState(() {
                    if (value.isNotEmpty) {
                      youtubeUrlError = null; // ✅ 값 입력 시 오류 메시지 초기화
                    }
                  });
                },
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  hintText: youtubeUrlError ?? '링크 입력', // ✅ 오류 발생 시 메시지로 변경
                  hintStyle: TextStyle(color: youtubeUrlError != null ? Colors.red : Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: youtubeUrlError != null ? Colors.red : Colors.blueGrey), // ✅ 기본은 blueGrey
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: youtubeUrlError != null ? Colors.red : Colors.blueGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: youtubeUrlError != null ? Colors.red : Colors.blueGrey , width: 2.0), // ✅ 포커스도 blueGrey
                  ),
                ),
              ),
            ),
          ),

          Divider(color: Colors.grey[300]),

          // 내용 입력란
          ListTile(
            title: Text('내용', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            trailing: SizedBox(
              width: 200,
              height: 35,
              child: TextField(
                controller: contentController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  hintText: '내용 입력',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // ✅ 기본 테두리 blueGrey
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey), // ✅ 비활성화 시 blueGrey
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), // ✅ 클릭(포커스) 시에도 blueGrey 유지
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red), // ✅ 에러 발생 시만 빨간색
                  ),
                ),
              ),
            ),
          ),
          Divider(color: Colors.grey[300]),


          // 요일 선택
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("요일 선택", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8), // ✅ 간격 추가
                    if (daysError != null)
                      Text(daysError!, style: TextStyle(color: Colors.red, fontSize: 14)), // ✅ 오류 메시지 빨간색
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: daysMapping.keys.map((day) {
                    final isSelected = selectedDays.contains(day);
                    return ChoiceChip(
                      label: Text(day, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 16)),
                      selected: isSelected,
                      selectedColor: Colors.blueGrey, // ✅ 선택된 색상 blueGrey
                      backgroundColor: Colors.grey[300],
                      showCheckmark: false,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                          if (selectedDays.isNotEmpty) {
                            daysError = null; // ✅ 선택하면 오류 메시지 제거
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

          // 매주 반복 스위치
          ListTile(
            title: Text('매 주 반복', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            trailing: Switch(
              value: isRepeatEnabled,
              activeColor: Colors.blueGrey, // ✅ blueGrey로 통일
              onChanged: (value) {
                setState(() {
                  isRepeatEnabled = value;
                });
              },
            ),
          ),
          Divider(color: Colors.grey[300]),
        ],
      ),
    );
  }

}
