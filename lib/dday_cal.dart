import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DDayCalculatorPage extends StatefulWidget {
  const DDayCalculatorPage({super.key});

  @override
  State<DDayCalculatorPage> createState() => _DDayCalculatorPageState();
}

class _DDayCalculatorPageState extends State<DDayCalculatorPage> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));
  String? _errorMessage;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  Future<void> _selectDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _validateDates();
      });
    }
  }

  void _validateDates() {
    if (_endDate.isBefore(_startDate)) {
      _errorMessage = '종료일은 시작일 이후여야 합니다.';
    } else {
      _errorMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int dDay = _endDate.difference(_startDate).inDays + 1;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [왼쪽 패널] 달력 (300px 고정)
            SizedBox(
              width: 300,
              child: _buildLeftPanel(dDay),
            ),

            const SizedBox(width: 15),

            // [오른쪽 패널] 남은 공간 채우기 (Expanded)
            Expanded(
              child: _buildRightPanel(dDay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(int dDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('시작일',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Text(_formatter.format(_startDate),
                style: const TextStyle(fontSize: 18)),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _selectDate(isStart: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('수정', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('종료일',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Text(_formatter.format(_endDate),
                style: const TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 10),

        // 달력 컨테이너
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 300,
              height: 340,
              child: CalendarDatePicker(
                initialDate: _endDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (picked) {
                  setState(() {
                    _endDate = picked;
                    _validateDates();
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: _errorMessage != null
              ? Text(
            _errorMessage!,
            style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          )
              : Text(
            'D-Day $dDay',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(int dDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnitContainer('2.5단위', dDay * 0.08333333333,
            [Colors.amber.shade100, Colors.amber.shade50], 2.5, context),
        _buildUnitContainer('3단위', dDay * 0.1,
            [Colors.orange.shade100, Colors.orange.shade50], 3, context),
        _buildUnitContainer('4단위', dDay * 0.125,
            [Colors.green.shade100, Colors.green.shade50], 4, context),
        _buildUnitContainer('4.3단위', dDay * 0.1428571429,
            [Colors.teal.shade100, Colors.teal.shade50], 4.3, context),
        _buildUnitContainer('5단위', dDay * 0.1666666666,
            [Colors.blue.shade100, Colors.blue.shade50], 5, context),
        _buildUnitContainer('6단위', dDay * 0.2,
            [Colors.purple.shade100, Colors.purple.shade50], 6, context),
        _buildUnitContainer('7.5단위', dDay * 0.25,
            [Colors.pink.shade100, Colors.pink.shade50], 7.5, context),

      ],
    );
  }

  Widget _buildUnitContainer(String label, double value,
      List<Color> gradientColors, double degree, BuildContext context) {
    String degreeStr =
    (degree % 1 == 0) ? degree.toInt().toString() : degree.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      // [수정] Row 자체가 화면 너비를 따라가도록 설정
      child: Row(
        children: [
          // [핵심] Flexible: 화면이 좁아지면 너비만 줄어듦 (높이 고정)
          Flexible(
            fit: FlexFit.loose, // 최대 크기(380)까지만 늘어남
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text:
                      'D C ($degreeStr단위) > 호르몬: 개 처방부탁드려요. (호르몬: 개  보유중)'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$degreeStr 먹는 약X 클립보드에 복사되었습니다')),
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 380, // PC 화면에서 너무 길어지지 않게 제한
                    minHeight: 50, // 최소 높이 보장 (찌그러짐 방지)
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // 내부 텍스트 처리
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 라벨 (2.5단위)
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      // 화면이 아주 좁을 때만 글자가 겹치지 않게 FittedBox로 '글자 크기'만 축소
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            ' →   ${value.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // [오른쪽] 먹는 약 버튼 (크기 고정)
          SizedBox(
            width: 60,
            child: ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text:
                    'D C ($degreeStr단위) > 호르몬: 개 먹는 약: 알 처방부탁드려요. (호르몬: 개  , 먹는 약: 알 보유중)'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$degreeStr 먹는 약O 클립보드에 복사되었습니다')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade200,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radio_button_unchecked, size: 14),
                  SizedBox(height: 2),
                  Text('먹는약', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}