// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
//
// //D-Day계산기 페이지
// //시작일-종료일을 기준으로 계산
// class DDayCalculatorPage extends StatefulWidget {
//   const DDayCalculatorPage({super.key});
//
//   @override
//   State<DDayCalculatorPage> createState() => _DDayCalculatorPageState();
// }
//
// class _DDayCalculatorPageState extends State<DDayCalculatorPage> {
//   //정확한 날짜 계산을 위해 DateTime에서 시/분/초를 제거하고 날짜(자정 00:00:00)만 반환
//   DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);
//   //시작 날짜를 년-월-일만 저장할 변수
//   DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
//   //종료 날짜를 저장할 변수 & 사용자의 선택 전까지는 null
//   DateTime? _endDate;
//   //과거 날짜를 지정하거나했을때 오류를 띄우기 위한 변수
//   String? _errorMessage;
//   //사용자에게 YYMMDD로 입력된 날짜를 YYYY-MM-DD형태로 보여주기위한 변수
//   final DateFormat _displayFormatter = DateFormat('yyyy-MM-dd');
//   //시작일 입력 컨트롤러
//   final TextEditingController _startCtrl = TextEditingController();
//   //종료일 입력 컨트롤러
//   final TextEditingController _endCtrl = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     //시작일(_startCtrl) 입력 컨트롤러 & 값을 오늘로 초기화
//     _startCtrl.text = DateFormat('yyMMdd').format(_startDate);
//     //종료일(_endCtrl) 입력 컨트롤러는 null이므로 컨트롤러 비워두기
//   }
//
//   @override
//   void dispose() {
//     //위젯이 트리에서 제거될 때 컨트롤러 메모리 해제
//     _startCtrl.dispose();
//     _endCtrl.dispose();
//     super.dispose();
//   }
//
//   //──────────────────────────────────────────────────────────────────────────────────────────────────────
//
//   //날짜파싱 함수
//   DateTime _parseYYMMDD(String value) {
//     //입력한 날짜에서 년도인 앞 두글자 가져오기
//     int yearPrefix = int.parse(value.substring(0, 2));
//     //뒷자리 50을 기준으로 작으면 20xx 크면 19xx
//     int fullYear = (yearPrefix > 50 ? 1900 : 2000) + yearPrefix;
//     //입력한 날짜에서 월인 중간 두글자 가져오기
//     int month = int.parse(value.substring(2, 4));
//     //입력한 날짜에서 일인 마지막 두글자 가져오기
//     int day = int.parse(value.substring(4, 6));
//
//     if (month < 1 || month > 12) throw FormatException('Invalid Month');
//     // 해당 월의 실제 말일을 구해 일 유효성 검사
//     int daysInMonth = DateTime(fullYear, month + 1, 0).day;
//     if (day < 1 || day > daysInMonth) throw FormatException('Invalid Day');
//
//     return DateTime(fullYear, month, day);
//   }
//
//   //──────────────────────────────────────────────────────────────────────────────────────────────────────
//
//   //텍스트 필드(_startCtrl, _endCtrl)가 갱신될때마다 호출되는 함수
//   //디데이 계산을 업데이트하기 위함
//   void _onDateTextChanged(bool isStart, String value) {
//     // 6자리 미만이면 아직 입력 중 → 무시
//     if (value.length != 6) return;
//
//     //날짜 파싱 함수를 통해 받은 값 가져오기 + 유효한 날짜인지 검증 -> 오류면 상태 갱신으로 에러 테두리만 표시
//     try {
//       DateTime parsed = _parseYYMMDD(value);
//       setState(() {
//         if (isStart) {
//           _startDate = parsed;
//         } else {
//           _endDate = parsed;
//         }
//         _validateDates();
//       });
//     } catch (e) {
//       setState(() {});
//     }
//   }
//
//   //──────────────────────────────────────────────────────────────────────────────────────────────────────
//
//   //달력 아이콘을 눌러 날짜 피커를 열 때 호출
//   //종료일이 미선택 상태면 오늘 기준 90일 뒤(약 3개월)를 기본 표시
//   //[isStart] true = 시작일 피커, false = 종료일 피커
//   Future<void> _pickDate({required bool isStart}) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: isStart ? _startDate : (_endDate ?? _stripTime(DateTime.now().add(const Duration(days: 90)))),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       DateTime stripped = _stripTime(picked);//시간제거 -> 날짜만 반환
//       setState(() {
//         if (isStart) {
//           _startDate = stripped;
//           _startCtrl.text = DateFormat('yyMMdd').format(stripped);// 컨트롤러 동기화
//         } else {
//           _endDate = stripped;
//           _endCtrl.text = DateFormat('yyMMdd').format(stripped);// 컨트롤러 동기화
//         }
//         _validateDates();
//       });
//     }
//   }
//
//   //──────────────────────────────────────────────────────────────────────────────────────────────────────
//
//   //현재 시작일과 종료일의 논리 유효성을 검사
//   //종료일이 시작일보다 이전이면 오류 메시지 설정
//   void _validateDates() {
//     if (_endDate == null) {
//       _errorMessage = null;
//       return;
//     }
//     if (_endDate!.isBefore(_startDate)) {
//       _errorMessage = '종료일은 시작일 이후여야 합니다.';
//     } else {
//       _errorMessage = null;
//     }
//   }
//
//
//   //──────────────────────────────────────────────────────────────────────────────────────────────────────
//   //화면 빌드
//   @override
//   Widget build(BuildContext context) {
//     // D-Day 계산은 종료일 선택 + 오류 없음일 때만 계산함
//     final int? dDay = (_endDate != null && _errorMessage == null)
//         ? _endDate!.difference(_startDate).inDays
//         : null;
//
//     return Scaffold(
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           final double totalWidth = constraints.maxWidth;
//           final double leftWidth = (totalWidth * 0.30).clamp(260.0, 340.0);
//
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(
//                   width: leftWidth,
//                   child: _buildLeftPanel(dDay),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: _buildRightPanel(dDay),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildLeftPanel(int? dDay) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildDateInputRow(
//           label: '시작일',
//           controller: _startCtrl,
//           date: _startDate,
//           isStart: true,
//         ),
//
//         const SizedBox(height: 10),
//
//         // 종료일 입력
//         _buildDateInputRow(
//           label: '종료일',
//           controller: _endCtrl,
//           date: _endDate,
//           isStart: false,
//         ),
//         const SizedBox(height: 10),
//
//         // 달력 (종료일 선택용)
//         Container(
//           width: double.infinity,
//           height: 300,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: FittedBox(
//             fit: BoxFit.scaleDown,
//             child: SizedBox(
//               width: 300,
//               height: 340,
//               child: CalendarDatePicker(
//                 initialDate: _endDate ?? _stripTime(DateTime.now().add(const Duration(days: 90))),
//                 firstDate: DateTime(2000),
//                 lastDate: DateTime(2100),
//                 onDateChanged: (picked) {
//                   DateTime stripped = _stripTime(picked);
//                   setState(() {
//                     _endDate = stripped;
//                     _endCtrl.text = DateFormat('yyMMdd').format(stripped);
//                     _validateDates();
//                   });
//                 },
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//
//         // D-Day 표시
//         Center(
//           child: _errorMessage != null
//               ? Text(
//                   _errorMessage!,
//                   style: const TextStyle(
//                       color: Colors.red,
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 )
//               : dDay == null
//                   ? const Text(
//                       '종료일을 선택해주세요',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey,
//                       ),
//                     )
//                   : Text(
//                       'D-Day $dDay',
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.indigo,
//                       ),
//                     ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDateInputRow({
//     required String label,
//     required TextEditingController controller,
//     required DateTime? date,
//     required bool isStart,
//   }) {
//     bool isError = false;
//     if (controller.text.length == 6) {
//       try {
//         _parseYYMMDD(controller.text);
//       } catch (e) {
//         isError = true;
//       }
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(label,
//                 style:
//                     const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(width: 8),
//             Text(
//               date != null ? _displayFormatter.format(date) : '선택 안 됨',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: date != null ? Colors.black54 : Colors.grey.shade400,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(
//                 color: isError ? Colors.red : Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: controller,
//                   keyboardType: TextInputType.number,
//                   textAlign: TextAlign.center,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                   decoration: InputDecoration(
//                     hintText: 'YYMMDD',
//                     hintStyle:
//                         const TextStyle(color: Colors.black38, fontSize: 15),
//                     border: InputBorder.none,
//                     isDense: true,
//                     contentPadding: const EdgeInsets.symmetric(
//                         vertical: 10, horizontal: 5),
//                     errorText: isError ? '' : null,
//                     errorStyle: const TextStyle(height: 0),
//                   ),
//                   style: const TextStyle(
//                       fontSize: 20, fontWeight: FontWeight.w900),
//                   onChanged: (val) => _onDateTextChanged(isStart, val),
//                 ),
//               ),
//               Container(width: 1, height: 20, color: Colors.grey.shade300),
//               IconButton(
//                 onPressed: () => _pickDate(isStart: isStart),
//                 icon: const Icon(Icons.calendar_today,
//                     size: 18, color: Colors.indigo),
//                 padding: EdgeInsets.zero,
//                 constraints:
//                     const BoxConstraints(minWidth: 40, minHeight: 40),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildRightPanel(int? dDay) {
//     if (dDay == null) {
//       return const Center(
//         child: Text(
//           '왼쪽 달력에서\n종료일을 선택해주세요',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 18, color: Colors.grey),
//         ),
//       );
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildUnitContainer('2.5단위', dDay * 0.08333333333,
//             [Colors.amber.shade100, Colors.amber.shade50], 2.5, context),
//         _buildUnitContainer('3단위', dDay * 0.1,
//             [Colors.orange.shade100, Colors.orange.shade50], 3, context),
//         _buildUnitContainer('4단위', dDay * 0.125,
//             [Colors.green.shade100, Colors.green.shade50], 4, context),
//         _buildUnitContainer('4.3단위', dDay * 0.1428571429,
//             [Colors.teal.shade100, Colors.teal.shade50], 4.3, context),
//         _buildUnitContainer('5단위', dDay * 0.1666666666,
//             [Colors.blue.shade100, Colors.blue.shade50], 5, context),
//         _buildUnitContainer('6단위', dDay * 0.2,
//             [Colors.purple.shade100, Colors.purple.shade50], 6, context),
//         _buildUnitContainer('7.5단위', dDay * 0.25,
//             [Colors.pink.shade100, Colors.pink.shade50], 7.5, context),
//       ],
//     );
//   }
//
//   Widget _buildUnitContainer(String label, double value,
//       List<Color> gradientColors, double degree, BuildContext context) {
//     String degreeStr =
//         (degree % 1 == 0) ? degree.toInt().toString() : degree.toString();
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Flexible(
//             fit: FlexFit.loose,
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(16),
//                 onTap: () {
//                   Clipboard.setData(ClipboardData(
//                       text:
//                           'D C ($degreeStr단위) > 호르몬: 개 처방부탁드려요.(호르몬: 개 보유)'));
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                         content: Text('$degreeStr 먹는 약X 클립보드에 복사되었습니다')),
//                   );
//                 },
//                 child: Container(
//                   constraints: const BoxConstraints(
//                     maxWidth: 380,
//                     minHeight: 50,
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 12),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: gradientColors,
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         label,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       Flexible(
//                         child: FittedBox(
//                           fit: BoxFit.scaleDown,
//                           alignment: Alignment.centerRight,
//                           child: Text(
//                             ' →   ${value.toStringAsFixed(1)}',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//
//           SizedBox(
//             width: 60,
//             child: ElevatedButton(
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(
//                     text:
//                         'D C ($degreeStr단위) > 호르몬: 개 먹는 약: 알 처방부탁드려요. (호르몬: 개/먹는 약: 알 보유)'));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                       content: Text('$degreeStr 먹는 약O 클립보드에 복사되었습니다')),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.redAccent.shade200,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//               child: const Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.radio_button_unchecked, size: 14),
//                   SizedBox(height: 2),
//                   Text('먹는약', style: TextStyle(fontSize: 10)),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// D-Day계산기 페이지
// 시작일-종료일을 기준으로 계산
class DDayCalculatorPage extends StatefulWidget {
  const DDayCalculatorPage({super.key});

  @override
  State<DDayCalculatorPage> createState() => _DDayCalculatorPageState();
}

class _DDayCalculatorPageState extends State<DDayCalculatorPage> {
  // === 💡 기존 로직 유지 영역 ===

  // 정확한 날짜 계산을 위해 DateTime에서 시/분/초를 제거하고 날짜(자정 00:00:00)만 반환
  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);
  // 시작 날짜를 년-월-일만 저장할 변수
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  // 종료 날짜를 저장할 변수 & 사용자의 선택 전까지는 null
  DateTime? _endDate;
  // 과거 날짜를 지정하거나했을때 오류를 띄우기 위한 변수
  String? _errorMessage;
  // 사용자에게 YYMMDD로 입력된 날짜를 YYYY-MM-DD형태로 보여주기위한 변수
  final DateFormat _displayFormatter = DateFormat('yyyy-MM-dd');
  // 시작일 입력 컨트롤러
  final TextEditingController _startCtrl = TextEditingController();
  // 종료일 입력 컨트롤러
  final TextEditingController _endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startCtrl.text = DateFormat('yyMMdd').format(_startDate);
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  DateTime _parseYYMMDD(String value) {
    int yearPrefix = int.parse(value.substring(0, 2));
    int fullYear = (yearPrefix > 50 ? 1900 : 2000) + yearPrefix;
    int month = int.parse(value.substring(2, 4));
    int day = int.parse(value.substring(4, 6));

    if (month < 1 || month > 12) throw FormatException('Invalid Month');
    int daysInMonth = DateTime(fullYear, month + 1, 0).day;
    if (day < 1 || day > daysInMonth) throw FormatException('Invalid Day');

    return DateTime(fullYear, month, day);
  }

  void _onDateTextChanged(bool isStart, String value) {
    if (value.length != 6) return;
    try {
      DateTime parsed = _parseYYMMDD(value);
      setState(() {
        if (isStart) {
          _startDate = parsed;
        } else {
          _endDate = parsed;
        }
        _validateDates();
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _stripTime(DateTime.now().add(const Duration(days: 90)))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo, // 선택된 날짜 배경색
              onPrimary: Colors.white, // 선택된 날짜 글자색
              onSurface: Colors.black87, // 기본 글자색
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      DateTime stripped = _stripTime(picked);
      setState(() {
        if (isStart) {
          _startDate = stripped;
          _startCtrl.text = DateFormat('yyMMdd').format(stripped);
        } else {
          _endDate = stripped;
          _endCtrl.text = DateFormat('yyMMdd').format(stripped);
        }
        _validateDates();
      });
    }
  }

  void _validateDates() {
    if (_endDate == null) {
      _errorMessage = null;
      return;
    }
    if (_endDate!.isBefore(_startDate)) {
      _errorMessage = '종료일은 시작일 이후여야 합니다.';
    } else {
      _errorMessage = null;
    }
  }

  // === 💡 UI 영역 ===

  @override
  Widget build(BuildContext context) {
    final int? dDay = (_endDate != null && _errorMessage == null)
        ? _endDate!.difference(_startDate).inDays
        : null;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideScreen = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: isWideScreen
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildLeftPanel(dDay)),
                  const SizedBox(width: 32),
                  Expanded(flex: 6, child: _buildRightPanel(dDay)),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLeftPanel(dDay),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildRightPanel(dDay),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeftPanel(int? dDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateInputRow(
          label: '시작일',
          controller: _startCtrl,
          date: _startDate,
          isStart: true,
          onTodayPressed: () {
            setState(() {
              _startDate = _stripTime(DateTime.now());
              _startCtrl.text = DateFormat('yyMMdd').format(_startDate);
              _validateDates();
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDateInputRow(
          label: '종료일',
          controller: _endCtrl,
          date: _endDate,
          isStart: false,
        ),
        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CalendarDatePicker(
            initialDate: _endDate ?? _stripTime(DateTime.now().add(const Duration(days: 90))),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (picked) {
              DateTime stripped = _stripTime(picked);
              setState(() {
                _endDate = stripped;
                _endCtrl.text = DateFormat('yyMMdd').format(stripped);
                _validateDates();
              });
            },
          ),
        ),

        const SizedBox(height: 24),

        // D-Day 표시부
        Center(
          child: _errorMessage != null
              ? Text(
            _errorMessage!,
            style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          )
              : dDay == null
              ? const Text(
            '종료일을 선택해주세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          )
              : Text(
            'D-Day $dDay',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.indigo,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInputRow({
    required String label,
    required TextEditingController controller,
    required DateTime? date,
    required bool isStart,
    VoidCallback? onTodayPressed,
  }) {
    bool isError = false;
    if (controller.text.length == 6) {
      try {
        _parseYYMMDD(controller.text);
      } catch (e) {
        isError = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(
                  date != null ? _displayFormatter.format(date) : '선택 안 됨',
                  style: TextStyle(
                    fontSize: 14,
                    color: date != null ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                //오늘 버튼
                if (onTodayPressed != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onTodayPressed,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        border: Border.all(color: Colors.indigo.shade200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '오늘',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: isError ? Colors.red : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: 'YYMMDD',
                    hintStyle: const TextStyle(color: Colors.black26, fontSize: 16),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    errorText: isError ? '' : null,
                    errorStyle: const TextStyle(height: 0),
                  ),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  onChanged: (val) => _onDateTextChanged(isStart, val),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
              IconButton(
                onPressed: () => _pickDate(isStart: isStart),
                icon: const Icon(Icons.calendar_month, size: 24, color: Colors.indigo),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(int? dDay) {
    if (dDay == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40.0),
          child: Text(
            '왼쪽 달력에서\n종료일을 선택해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey, height: 1.5),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUnitContainer('2.5단위', dDay * 0.08333333333, [Colors.amber.shade100, Colors.amber.shade50], 2.5, context),
        _buildUnitContainer('3단위', dDay * 0.1, [Colors.orange.shade100, Colors.orange.shade50], 3, context),
        _buildUnitContainer('4단위', dDay * 0.125, [Colors.green.shade100, Colors.green.shade50], 4, context),
        _buildUnitContainer('4.3단위', dDay * 0.1428571429, [Colors.teal.shade100, Colors.teal.shade50], 4.3, context),
        _buildUnitContainer('5단위', dDay * 0.1666666666, [Colors.blue.shade100, Colors.blue.shade50], 5, context),
        _buildUnitContainer('6단위', dDay * 0.2, [Colors.purple.shade100, Colors.purple.shade50], 6, context),
        _buildUnitContainer('7.5단위', dDay * 0.25, [Colors.pink.shade100, Colors.pink.shade50], 7.5, context),
      ],
    );
  }

  Widget _buildUnitContainer(String label, double value, List<Color> gradientColors, double degree, BuildContext context) {
    String degreeStr = (degree % 1 == 0) ? degree.toInt().toString() : degree.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 왼쪽 큰 복사 버튼
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'D C ($degreeStr단위) > 호르몬: 개 처방부탁드려요.(호르몬: 개 보유)'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$degreeStr 먹는 약X 클립보드에 복사되었습니다'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                          ),
                          Text(
                            '→  ${value.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 오른쪽 '먹는약' 버튼
            SizedBox(
              width: 72,
              child: ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'D C ($degreeStr단위) > 호르몬: 개 먹는 약: 알 처방부탁드려요. (호르몬: 개/먹는 약: 알 보유)'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$degreeStr 먹는 약O 클립보드에 복사되었습니다'), behavior: SnackBarBehavior.floating),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade200,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medication, size: 20),
                    SizedBox(height: 4),
                    Text('먹는약', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}