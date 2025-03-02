import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AddAlarmScreen extends StatefulWidget {
  @override
  _AddAlarmScreenState createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  int selectedHour = 7;
  int selectedMinute = 30;
  String selectedPeriod = '오전';
  bool isRepeatEnabled = false;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('삭제', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Text('루틴 추가', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              TextButton(
                onPressed: () {},
                child: Text('저장', style: TextStyle(color: Colors.black, fontSize: 18 , fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(color: Colors.grey[300]),
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
                    children: ['오전', '오후'].map((e) => Center(child: Text(e, style: TextStyle(color: Colors.black, fontSize: 22 , fontWeight: FontWeight.bold)))).toList(),
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
                    children: List.generate(12, (index) => Center(child: Text("${index + 1}", style: TextStyle(color: Colors.black, fontSize: 22 , fontWeight: FontWeight.bold)))),
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
                    children: List.generate(60, (index) => Center(child: Text("${index.toString().padLeft(2, '0')}", style: TextStyle(color: Colors.black, fontSize: 22 , fontWeight: FontWeight.bold)))),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                ListTile(
                  title: Text('반복', style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold)),
                  trailing: Text('안 함', style: TextStyle(color: Colors.grey , fontWeight: FontWeight.bold)),
                  onTap: () {},
                ),
                Divider(color: Colors.grey[300]),
                ListTile(
                  title: Text('레이블', style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold)),
                  trailing: Text('알람', style: TextStyle(color: Colors.grey , fontWeight: FontWeight.bold)),
                  onTap: () {},
                ),
                Divider(color: Colors.grey[300]),
                ListTile(
                  title: Text('사운드', style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold)),
                  trailing: Text('래디얼', style: TextStyle(color: Colors.grey , fontWeight: FontWeight.bold)),
                  onTap: () {},
                ),
                Divider(color: Colors.grey[300]),
                ListTile(
                  title: Text('다시 알림', style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

