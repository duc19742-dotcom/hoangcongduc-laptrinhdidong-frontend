import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../services/attendance_service.dart';
import '../../services/device_service.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/editor.dart';

class CheckInScreen extends StatefulWidget {
  final Session session;
  const CheckInScreen(this.session, {super.key});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late Future<PageResult> future;
  List<Json> assignments = [];
  String? selected, qr, key;
  String action = 'CheckIn';
  Position? position;
  bool busy = false;
  Json? result;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    future = widget.session.api
        .page(
          '/employee-shifts/me?from=${day(now.subtract(const Duration(days: 1)))}&to=${day(now)}&pageSize=100',
        )
        .then((page) {
          if (mounted && selected == null && page.items.length == 1) {
            selected = page.items.single['id'];
          }
          return page;
        });
  }

  void resetIntent() {
    key = null;
    result = null;
  }

  Future<void> gps() async {
    setState(() {
      busy = true;
      position = null;
    });
    try {
      final p = await DeviceService.position();
      if (mounted) {
        setState(() {
          position = p;
          resetIntent();
        });
      }
    } catch (e) {
      if (mounted) message(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (selected == null || busy) return;
    if (key == null) {
      await gps();
      if (!mounted || position == null) return;
    }
    setState(() => busy = true);
    key ??= const Uuid().v4();
    try {
      final r = await AttendanceService(widget.session.api).submit(
        action: action,
        assignmentId: selected!,
        qrToken: '',
        position: position!,
        idempotencyKey: key!,
      );
      if (mounted) {
        setState(() {
          result = r;
          qr = null;
          key = null;
        });
      }
    } catch (e) {
      if (mounted) message(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> request() async {
    final reason = await askReason(
      context,
      'Giải trình chấm công',
      minimum: 10,
    );
    if (reason == null) return;
    setState(() => busy = true);
    try {
      await widget.session.api.post('/attendance-requests', {
        'attemptId': result!['attemptId'],
        'reason': reason,
      });
      if (mounted) {
        message(
          context,
          'Đã gửi giải trình. Công chỉ được xác nhận sau khi Admin duyệt.',
        );
        setState(() => result!['canCreateRequest'] = false);
      }
    } catch (e) {
      if (mounted) message(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chấm công vào / ra')),
    body: FutureBuilder<PageResult>(
      future: future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) return ErrorPanel(s.error!, () => setState(load));
        assignments = s.data!.items;
        if (assignments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Bạn chưa được phân công ca cho hôm nay hoặc ca qua đêm. Hãy liên hệ quản trị viên.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ca được phân công'),
              items: assignments
                  .map(
                    (x) => DropdownMenuItem(
                      value: x['id'] as String,
                      child: Text(
                        '${x['shiftName']} · ${dateOnly(x['workDate'])}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      selected = v;
                      qr = null;
                      resetIntent();
                    }),
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'CheckIn',
                  label: Text('Vào ca'),
                  icon: Icon(Icons.login),
                ),
                ButtonSegment(
                  value: 'CheckOut',
                  label: Text('Ra ca'),
                  icon: Icon(Icons.logout),
                ),
              ],
              selected: {action},
              onSelectionChanged: busy
                  ? null
                  : (v) => setState(() {
                      action = v.first;
                      qr = null;
                      resetIntent();
                    }),
            ),
            const SizedBox(height: 24),
            ItemCard(
              title: position == null
                  ? 'Vị trí chấm công'
                  : 'Vị trí đã sẵn sàng',
              subtitle: position == null
                  ? 'GPS mới sẽ được lấy ngay khi bấm chấm công.'
                  : '${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}\nSai số ước tính ${position!.accuracy.toStringAsFixed(1)} m',
              icon: Icons.my_location,
              onTap: busy ? null : gps,
              trailing: IconButton(
                onPressed: busy ? null : gps,
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 12),
            BusyButton(
              busy: busy,
              label: key == null
                  ? (action == 'CheckIn' ? 'Chấm công vào' : 'Chấm công ra')
                  : 'Thử gửi lại',
              onPressed: selected != null ? submit : null,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'Thời gian theo máy chủ; vị trí phải trong bán kính cho phép. Trường hợp cần kiểm tra thêm có thể gửi giải trình.',
            ),
            if (result != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatusPill(result!['status']),
                      const SizedBox(height: 16),
                      Text(
                        result!['status'] == 'Accepted'
                            ? (result!['punctuality'] == 'Late'
                                  ? 'Đã ghi nhận · Đi trễ ${result!['lateMinutes']} phút'
                                  : result!['punctuality'] == 'OnTime'
                                  ? 'Đã ghi nhận · Đúng giờ'
                                  : result!['punctuality'] == 'EarlyLeave'
                                  ? 'Đã ghi nhận · Ra ca sớm'
                                  : 'Đã ghi nhận chấm công ra')
                            : 'Chưa xác nhận công — cần giải trình',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Thời điểm máy chủ nhận: ${vietnamTime(result!['receivedAtUtc'])}\nKhoảng cách: ${(result!['distanceMeters'] as num).toStringAsFixed(1)} m\nĐộ chính xác: ${(result!['accuracyMeters'] as num).toStringAsFixed(1)} m',
                      ),
                      if ((result!['reasonCodes'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            reasonName(
                              (result!['reasonCodes'] as List).join(', '),
                            ),
                          ),
                        ),
                      if (result!['canCreateRequest'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: OutlinedButton(
                            onPressed: busy ? null : request,
                            child: const Text('Gửi giải trình cho Admin'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
