import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// 사용일자 계산기 페이지
// 받아간 날짜 + 받아간 갯수 → 용량별 사용 가능 일수 및 종료일 계산
class UsageCalculatorPage extends StatefulWidget {
  const UsageCalculatorPage({super.key});

  @override
  State<UsageCalculatorPage> createState() => _UsageCalculatorPageState();
}

class _UsageCalculatorPageState extends State<UsageCalculatorPage> {

  // DateTime에서 시/분/초를 제거하고 자정(00:00:00)만 남김
  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  // 받아간 날짜 (디폴트: 오늘 -90일)
  late DateTime _pickupDate;

  // 받아간 갯수 (null = 미입력)
  double? _amount;

  // 날짜 표시 포맷 (yyyy-MM-dd)
  final DateFormat _displayFormatter = DateFormat('yyyy-MM-dd');

  // 날짜 입력 컨트롤러 (YYMMDD)
  final TextEditingController _dateCtrl = TextEditingController();

  // 갯수 입력 컨트롤러
  final TextEditingController _amountCtrl = TextEditingController();

  // 갯수 파싱 오류 여부
  bool _amountError = false;

  // 용량 매핑 테이블 (dday_cal, total_cal과 동일하게 유지)
  // 처방량 = 일수 × 계수  →  일수 = 갯수 ÷ 계수
  final Map<String, double> _dosageMap = const {
    '2.5단위': 0.08333333333,
    '3단위':   0.1,
    '4단위':   0.125,
    '4.3단위': 0.1428571429,
    '5단위':   0.1666666666,
    '6단위':   0.2,
    '7.5단위': 0.25,
  };

  // 카드 배경 그라디언트 색상 (dday_cal과 동일 순서)
  final Map<String, List<Color>> _colorMap = {
    '2.5단위': [Colors.amber.shade100,  Colors.amber.shade50],
    '3단위':   [Colors.orange.shade100, Colors.orange.shade50],
    '4단위':   [Colors.green.shade100,  Colors.green.shade50],
    '4.3단위': [Colors.teal.shade100,   Colors.teal.shade50],
    '5단위':   [Colors.blue.shade100,   Colors.blue.shade50],
    '6단위':   [Colors.purple.shade100, Colors.purple.shade50],
    '7.5단위': [Colors.pink.shade100,   Colors.pink.shade50],
  };

  @override
  void initState() {
    super.initState();
    // 디폴트 날짜: 오늘 - 90일
    _pickupDate = _stripTime(DateTime.now().subtract(const Duration(days: 90)));
    _dateCtrl.text = DateFormat('yyMMdd').format(_pickupDate);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────
  // 날짜 파싱 (dday_cal, total_cal과 동일한 로직)
  // ───────────────────────────────────────────────────

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

  // ───────────────────────────────────────────────────
  // 이벤트 핸들러
  // ───────────────────────────────────────────────────

  // 날짜 텍스트 입력 (6자리 완성 시 파싱)
  void _onDateTextChanged(String value) {
    if (value.length != 6) return;
    try {
      DateTime parsed = _parseYYMMDD(value);
      setState(() {
        _pickupDate = parsed;
      });
    } catch (e) {
      setState(() {});
    }
  }

  // 달력 피커로 날짜 선택
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      DateTime stripped = _stripTime(picked);
      setState(() {
        _pickupDate = stripped;
        _dateCtrl.text = DateFormat('yyMMdd').format(stripped);
      });
    }
  }

  // 갯수 입력 변경
  // 양수이면 정상, 0 이하이거나 파싱 실패이면 오류
  void _onAmountChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _amount = null;
        _amountError = false;
        return;
      }
      final parsed = double.tryParse(value);
      if (parsed == null || parsed <= 0) {
        _amount = null;
        _amountError = true;
      } else {
        _amount = parsed;
        _amountError = false;
      }
    });
  }

  // ───────────────────────────────────────────────────
  // 빌드
  // ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 700px 이상 → 좌우 2단, 미만 → 상하 1단
            final bool isWide = constraints.maxWidth >= 700;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildLeftPanel()),
                        const SizedBox(width: 32),
                        Expanded(flex: 6, child: _buildRightPanel()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeftPanel(),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildRightPanel(),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // 왼쪽 패널: 날짜 + 갯수 입력
  // ───────────────────────────────────────────────────

  Widget _buildLeftPanel() {
    // 텍스트 6자리인데 파싱 실패 시 에러 테두리
    bool isDateError = false;
    if (_dateCtrl.text.length == 6) {
      try {
        _parseYYMMDD(_dateCtrl.text);
      } catch (e) {
        isDateError = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── 받아간 날짜 입력 ──────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('받아간 날짜',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                // 선택된 날짜 표시
                Text(
                  _displayFormatter.format(_pickupDate),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(width: 8),
                // 오늘 버튼: 탭 시 오늘 날짜로 즉시 설정
                InkWell(
                  onTap: () {
                    setState(() {
                      _pickupDate = _stripTime(DateTime.now());
                      _dateCtrl.text = DateFormat('yyMMdd').format(_pickupDate);
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
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
                          color: Colors.indigo),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // YYMMDD 텍스트 필드 + 달력 아이콘
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: isDateError ? Colors.red : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: 'YYMMDD',
                    hintStyle: const TextStyle(
                        color: Colors.black26, fontSize: 16),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    errorText: isDateError ? '' : null,
                    errorStyle: const TextStyle(height: 0),
                  ),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                  onChanged: _onDateTextChanged,
                ),
              ),
              Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 8)),
              IconButton(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month,
                    size: 24, color: Colors.indigo),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── 받아간 갯수 입력 ──────────────────────────
        const Text('받아간 갯수',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: _amountError ? Colors.red : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            inputFormatters: [
              // 숫자와 소수점만 허용
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: '예) 9 또는 9.5',
              hintStyle:
                  const TextStyle(color: Colors.black26, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 8),
              errorText: _amountError ? '' : null,
              errorStyle: const TextStyle(height: 0),
              suffixText: '개',
              suffixStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
            onChanged: _onAmountChanged,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────
  // 오른쪽 패널: 용량별 결과 카드
  // ───────────────────────────────────────────────────

  Widget _buildRightPanel() {
    // 갯수 미입력 또는 오류 상태
    if (_amount == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            _amountError
                ? '올바른 갯수를 입력해주세요'
                : '받아간 갯수를 입력해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: _amountError ? Colors.red : Colors.grey,
              fontWeight: _amountError ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 요약 카드: 받아간 날짜 + 갯수
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '받아간 날짜  ${_displayFormatter.format(_pickupDate)}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                // 정수면 정수 표기, 소수면 소수점 1자리
                '${_amount! % 1 == 0 ? _amount!.toInt() : _amount!.toStringAsFixed(1)}개',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 용량별 결과 카드 7종
        ..._dosageMap.entries.map((entry) =>
            _buildResultCard(entry.key, entry.value)),
      ],
    );
  }

  // ───────────────────────────────────────────────────
  // 개별 용량 결과 카드
  // ───────────────────────────────────────────────────

  Widget _buildResultCard(String label, double coefficient) {
    // 사용 가능 일수 = floor(갯수 ÷ 용량계수)
    // floor 사용 이유: 마지막 날 하루치가 안되면 사용 불가
    final int days = (_amount! / coefficient).floor();

    // 사용 종료일 = 받아간 날짜 + 사용 가능 일수
    final DateTime endDate = _pickupDate.add(Duration(days: days));

    final List<Color> colors =
        _colorMap[label] ?? [Colors.grey.shade100, Colors.grey.shade50];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // 용량 라벨: 남은 공간 차지
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
            ),
            // 종료일: 고정 너비 + 우측 정렬 → 카드마다 같은 x좌표
            SizedBox(
              width: 240,
              child: Text(
                '~ ${_displayFormatter.format(endDate)} 까지',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ),
            // 구분선: 고정 패딩으로 간격 통일
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '|',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38),
              ),
            ),
            // 일수: 고정 너비 + 우측 정렬 → 2자리·3자리 모두 같은 열에 정렬
            SizedBox(
              width: 80,
              child: Text(
                '$days일',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
