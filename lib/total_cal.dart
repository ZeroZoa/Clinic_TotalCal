import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TotalCalculatorPage extends StatefulWidget {
  const TotalCalculatorPage({super.key});

  @override
  State<TotalCalculatorPage> createState() => _TotalCalculatorPageState();
}

// 주사 치료 구간
class TreatmentSegment {
  DateTime startDate;
  String dosageLabel;
  final TextEditingController dateController;

  TreatmentSegment({required this.startDate, this.dosageLabel = '3단위'})
      : dateController = TextEditingController(
      text: DateFormat('yyMMdd').format(startDate));

  void dispose() {
    dateController.dispose();
  }
}

class _TotalCalculatorPageState extends State<TotalCalculatorPage> {
  final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  //먹는 약
  late DateTime _oralStartDate;
  late DateTime _oralEndDate;
  final TextEditingController _oralStartCtrl = TextEditingController();
  final TextEditingController _oralEndCtrl = TextEditingController();
  int _totalOralDays = 0;


  //주사 치료
  // 전체 종료일 (기본값: 오늘)
  DateTime _injectionGlobalEndDate = DateTime.now();
  // 전체 종료일 컨트롤러 (yymmdd 입력용)
  final TextEditingController _injectionGlobalEndCtrl = TextEditingController();

  // 구간 리스트
  late List<TreatmentSegment> _segments;

  // 계산 결과 캐싱
  double _totalInjections = 0;
  List<Map<String, dynamic>> _resultDetails = [];
  bool _hasInjectionDateError = false;

  // 용량 매핑 테이블
  final Map<String, double> _dosageMap = const {
    '2.5단위': 0.08333333333,
    '3단위': 0.1,
    '4단위': 0.125,
    '4.3단위': 0.1428571429,
    '5단위': 0.1666666666,
    '6단위': 0.2,
    '7.5단위': 0.25,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    //시간 제거(Strip Time)하여 초기화
    final now = _stripTime(DateTime.now());

    // 먹는 약 초기화
    _oralStartDate = DateTime(now.year, 1, 1);
    _oralEndDate = now;
    _oralStartCtrl.text = DateFormat('yyMMdd').format(_oralStartDate);
    _oralEndCtrl.text = DateFormat('yyMMdd').format(_oralEndDate);
    _calculateOralDays();

    // 주사 치료 초기화
    _injectionGlobalEndDate = now;
    _injectionGlobalEndCtrl.text = DateFormat('yyMMdd').format(now);

    _segments = [
      TreatmentSegment(startDate: DateTime(2025, 1, 1)),
    ];
    _updateInjectionCalculations();
  }

  @override
  void dispose() {
    _oralStartCtrl.dispose();
    _oralEndCtrl.dispose();
    _injectionGlobalEndCtrl.dispose();
    for (var segment in _segments) {
      segment.dispose();
    }
    super.dispose();
  }

  //날짜 유틸리티
  // ---------------------------------------------------------------------------
  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _parseYYMMDD(String value) {
    int yearPrefix = int.parse(value.substring(0, 2));
    int fullYear = (yearPrefix > 50 ? 1900 : 2000) + yearPrefix;
    int month = int.parse(value.substring(2, 4));
    int day = int.parse(value.substring(4, 6));

    if (month < 1 || month > 12) throw FormatException("Invalid Month");
    int daysInMonth = DateTime(fullYear, month + 1, 0).day;
    if (day < 1 || day > daysInMonth) throw FormatException("Invalid Day");

    return DateTime(fullYear, month, day);
  }

  // 먹는 약 로직
  // ---------------------------------------------------------------------------
  void _calculateOralDays() {
    setState(() {
      if (_oralEndDate.isBefore(_oralStartDate)) {
        _totalOralDays = 0;
      } else {
        _totalOralDays = _oralEndDate.difference(_oralStartDate).inDays + 1;
      }
    });
  }

  void _onOralDateTextChanged(bool isStart, String value) {
    if (value.length != 6) return;
    try {
      DateTime parsed = _parseYYMMDD(value);
      setState(() {
        if (isStart) {
          _oralStartDate = parsed;
        } else {
          _oralEndDate = parsed;
        }
        _calculateOralDays();
      });
    } catch (e) {
      setState(() {}); // 에러 UI 갱신용
    }
  }

  Future<void> _pickOralDate(bool isStart) async {
    final DateTime initial = isStart ? _oralStartDate : _oralEndDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      DateTime stripped = _stripTime(picked);
      setState(() {
        if (isStart) {
          _oralStartDate = stripped;
          _oralStartCtrl.text = DateFormat('yyMMdd').format(stripped);
        } else {
          _oralEndDate = stripped;
          _oralEndCtrl.text = DateFormat('yyMMdd').format(stripped);
        }
        _calculateOralDays();
      });
    }
  }

  // 주사 치료 로직
  // ---------------------------------------------------------------------------
  // 주사 치료 로직 수정
  void _updateInjectionCalculations() {
    // 1. 날짜순 정렬
    _segments.sort((a, b) => a.startDate.compareTo(b.startDate));

    double tempTotal = 0;
    List<Map<String, dynamic>> tempDetails = [];
    bool tempHasError = false;

    for (int i = 0; i < _segments.length; i++) {
      DateTime start = _segments[i].startDate;
      DateTime end;

      // 다음 구간의 시작일, 혹은 전체 종료일이 현재 구간의 끝
      if (i < _segments.length - 1) {
        end = _segments[i + 1].startDate;
      } else {
        end = _injectionGlobalEndDate;
      }

      int days;
      if (end.isBefore(start)) {
        days = 0;
        tempHasError = true;
      } else {
        if (i < _segments.length - 1) {
          days = end.difference(start).inDays;
        } else {
          days = end.difference(start).inDays;
        }
      }

      double dosageVal = _dosageMap[_segments[i].dosageLabel] ?? 0.0;
      double calcAmount = days * dosageVal;

      tempTotal += calcAmount;

      DateTime displayEndDate = end;
      if (days > 0) {
        displayEndDate = end.subtract(const Duration(days: 1));
      }

      tempDetails.add({
        'start': start,
        'end': displayEndDate, // 수정됨: UI상 24일로 표시되도록 변경
        'days': days,
        'label': _segments[i].dosageLabel,
        'amount': calcAmount,
        'isError': end.isBefore(start),
      });
    }

    setState(() {
      _totalInjections = tempTotal;
      _resultDetails = tempDetails;
      _hasInjectionDateError = tempHasError;
    });
  }

  // 주사 치료 종료일 변경 (YYMMDD)
  void _onInjectionGlobalEndDateChanged(String value) {
    if (value.length != 6) return;
    try {
      DateTime parsed = _parseYYMMDD(value);
      setState(() {
        _injectionGlobalEndDate = parsed;
        _updateInjectionCalculations();
      });
    } catch (e) {
      setState(() {});
    }
  }

  // 주사 치료 종료일 변경 (Calendar)
  Future<void> _pickInjectionGlobalEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _injectionGlobalEndDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      DateTime stripped = _stripTime(picked);
      setState(() {
        _injectionGlobalEndDate = stripped;
        _injectionGlobalEndCtrl.text = DateFormat('yyMMdd').format(stripped);
        _updateInjectionCalculations();
      });
    }
  }

  // 세그먼트(구간) 날짜 변경
  void _onSegmentDateChanged(int index, String value) {
    if (value.length != 6) return;
    try {
      DateTime parsed = _parseYYMMDD(value);
      setState(() {
        _segments[index].startDate = parsed;
        _updateInjectionCalculations();
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _pickSegmentDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _segments[index].startDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      DateTime stripped = _stripTime(picked);
      setState(() {
        _segments[index].startDate = stripped;
        _segments[index].dateController.text =
            DateFormat('yyMMdd').format(stripped);
        _updateInjectionCalculations();
      });
    }
  }

  void _addSegment() {
    DateTime lastStart = _segments.last.startDate;
    DateTime newDate;

    // 다음 날짜 제안 (종료일 넘어가지 않게)
    if (_injectionGlobalEndDate.isAfter(lastStart)) {
      int daysDiff = _injectionGlobalEndDate.difference(lastStart).inDays;
      newDate = lastStart.add(Duration(days: (daysDiff / 2).round()));
      if (daysDiff <= 1) {
        newDate = lastStart.add(const Duration(days: 1));
        if (newDate.isAfter(_injectionGlobalEndDate)) {
          newDate = _injectionGlobalEndDate;
        }
      }
    } else {
      newDate = _injectionGlobalEndDate;
    }

    newDate = _stripTime(newDate);
    String lastDosage = _segments.last.dosageLabel;

    setState(() {
      _segments.add(TreatmentSegment(startDate: newDate, dosageLabel: lastDosage));
      _updateInjectionCalculations();
    });
  }

  void _removeSegment(int index) {
    setState(() {
      _segments[index].dispose();
      _segments.removeAt(index);
      _updateInjectionCalculations();
    });
  }

  // ===========================================================================
  // [UI Build]
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // 3단 레이아웃을 위한 Row
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 높이 꽉 채우기
        children: [
          // -----------------------------------------------------
          // 1. 왼쪽 패널: 주사 치료 설정 (Fixed Width)
          // -----------------------------------------------------
          SizedBox(
            width: 350,
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GH 치료 기간',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGlobalEndDatePicker(),
                          const SizedBox(height: 20),
                          _buildSegmentControlHeader(),
                          const SizedBox(height: 10),
                          _buildSegmentList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1),

          // -----------------------------------------------------
          // 2. 가운데 패널: 주사 치료 상세 내역 (Expanded)
          // -----------------------------------------------------
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('상세 내역 및 결과',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 20),
                  // 총 합계 카드
                  _buildInjectionSummaryCard(),
                  const SizedBox(height: 20),
                  const Text('구간별 상세 계산', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // 상세 리스트 (스크롤 가능)
                  Expanded(
                    child: _buildResultDetailList(),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1),

          // -----------------------------------------------------
          // 3. 오른쪽 패널: 먹는 약 설정 (Fixed Width)
          // -----------------------------------------------------
          SizedBox(
            width: 320,
            child: Container(
              color: Colors.orange.shade50.withOpacity(0.3),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI 치료 기간',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange)),
                  const SizedBox(height: 20),

                  // 먹는 약 입력 폼
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildDateInputRow(
                            '시작일', _oralStartCtrl, _oralStartDate, () => _pickOralDate(true)),
                        const SizedBox(height: 16),
                        _buildDateInputRow(
                            '종료일', _oralEndCtrl, _oralEndDate, () => _pickOralDate(false)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 먹는 약 결과 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('총 복용 일수',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('$_totalOralDays일',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // [Widget Components] - Left Panel
  // ===========================================================================

  // 전체 치료 종료일 입력 위젯
  Widget _buildGlobalEndDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('전체 치료 종료일', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildDateInputContent(_injectionGlobalEndCtrl, _injectionGlobalEndDate, _onInjectionGlobalEndDateChanged, _pickInjectionGlobalEndDate),
        ),
      ],
    );
  }

  Widget _buildSegmentControlHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('구간별 용량 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _addSegment,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('구간 추가'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            textStyle: const TextStyle(fontSize: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 라운드 12 설정
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _segments.length,
      itemBuilder: (context, index) {
        return _buildSegmentTile(index);
      },
    );
  }

  Widget _buildSegmentTile(int index) {
    bool isFirst = index == 0;

    // 에러 체크: 텍스트 6자리인데 파싱 실패 시
    bool isTextError = false;
    if (_segments[index].dateController.text.length == 6) {
      try { _parseYYMMDD(_segments[index].dateController.text); } catch(e) { isTextError = true; }
    }

    // 논리 에러: 현재 시작일이 다음 시작일보다 뒤면 에러
    bool isLogicError = false;
    DateTime currentStart = _segments[index].startDate;
    if (index < _segments.length - 1) {
      if (currentStart.isAfter(_segments[index + 1].startDate)) isLogicError = true;
    } else {
      if (currentStart.isAfter(_injectionGlobalEndDate)) isLogicError = true;
    }

    bool isError = isTextError || isLogicError;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isError ? Colors.red : Colors.grey.shade300,
          width: isError ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isFirst ? Colors.indigo : Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFirst ? '치료 시작일' : '용량 변경일',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (!isFirst)
                InkWell(
                  onTap: () => _removeSegment(index),
                  child: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                )
            ],
          ),
          const SizedBox(height: 10),

          // 날짜 입력
          _buildDateInputContent(
              _segments[index].dateController,
              _segments[index].startDate,
                  (val) => _onSegmentDateChanged(index, val),
                  () => _pickSegmentDate(index)
          ),

          const SizedBox(height: 10),

          // 용량 선택
          DropdownButtonFormField<String>(
            value: _segments[index].dosageLabel,
            isDense: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              border: OutlineInputBorder(),
              labelText: '용량',
            ),
            items: _dosageMap.keys.map((String key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(key),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _segments[index].dosageLabel = newValue;
                  _updateInjectionCalculations();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // [Widget Components] - Center Panel
  // ===========================================================================

  Widget _buildInjectionSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: _hasInjectionDateError ? Colors.red.shade50 : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hasInjectionDateError ? Colors.red.shade200 : Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasInjectionDateError)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                children: const [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text("날짜 설정 오류: 기간을 확인해주세요.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const Text('총 필요 주사량', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 5),
          Text('${_totalInjections.toStringAsFixed(2)} 개',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
        ],
      ),
    );
  }

  Widget _buildResultDetailList() {
    return ListView.separated(
      itemCount: _resultDetails.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        var detail = _resultDetails[index];
        bool isErr = detail['isError'];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          color: isErr ? Colors.red.shade50 : Colors.transparent,
          child: Row(
            children: [
              // 기간
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatter.format(detail['start'])} ~ ${_formatter.format(detail['end'])}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isErr ? Colors.red : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isErr ? '기간 오류' : '${detail['days']}일간',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // 용량
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(
                    detail['label'],
                    style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // 결과
              Expanded(
                flex: 2,
                child: Text(
                  '${(detail['amount'] as double).toStringAsFixed(2)}개',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isErr ? Colors.grey : Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // [Widget Components] - Shared / Right Panel
  // ===========================================================================

  Widget _buildDateInputRow(String label, TextEditingController controller, DateTime date, VoidCallback onTapCalendar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildDateInputContent(controller, date, (val) {
            // 먹는 약 콜백 연결
            if (label == '시작일') _onOralDateTextChanged(true, val);
            if (label == '종료일') _onOralDateTextChanged(false, val);
          }, onTapCalendar),
        ),
      ],
    );
  }

  // 텍스트필드와 달력 아이콘이 결합된 내부 위젯
  Widget _buildDateInputContent(TextEditingController controller, DateTime date, Function(String) onChanged, VoidCallback onTapCalendar) {
    bool isError = false;
    if (controller.text.length == 6) {
      try { _parseYYMMDD(controller.text); } catch(e) { isError = true; }
    }

    return Row(
      children: [
        Expanded(// 6글자(YYMMDD)가 넉넉히 들어가는 고정 너비
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
              hintStyle: const TextStyle(color: Colors.black, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              errorText: isError ? '' : null,
              errorStyle: const TextStyle(height: 0),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            onChanged: onChanged,
          ),
        ),
        Container(width: 1, height: 20, color: Colors.grey.shade300),
        IconButton(
          onPressed: onTapCalendar,
          icon: const Icon(Icons.calendar_today, size: 18, color: Colors.indigo),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }
}
