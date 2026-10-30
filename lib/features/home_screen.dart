import 'timesheets_screen.dart';
import 'leave_screen.dart';
import 'admin/dashboard_screen.dart';
import 'admin/schedule_screen.dart';
import 'admin/site_qr_screen.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import '../widgets/editor.dart';
import 'admin/catalog_screen.dart';
import 'admin/operations_screens.dart';
import 'attendance/check_in_screen.dart';
import 'attendance/requests_screen.dart';
import 'device/device_screens.dart';
import 'employee/records_screens.dart';

typedef _HomeAction = ({
  String title,
  String detail,
  IconData icon,
  Widget screen,
});

class HomeScreen extends StatefulWidget {
  final Session session;
  const HomeScreen(this.session, {super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;
  late Future<Json> summary;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    final now = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 7))
        .toIso8601String()
        .substring(0, 10);
    summary = widget.session.user!.isAdmin
        ? widget.session.api.get('/dashboard?date=$now')
        : widget.session.api.get(
            '/timesheets/${int.parse(now.substring(0, 4))}/${int.parse(now.substring(5, 7))}',
          );
  }

  Future<void> open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted && widget.session.user != null) setState(load);
  }

  Widget actionTile(_HomeAction entry) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(entry.icon, color: Theme.of(context).colorScheme.primary),
    ),
    title: Text(
      entry.title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(entry.detail),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => open(entry.screen),
  );

  Widget actionGroup(String title, List<_HomeAction> entries) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      Card(
        margin: EdgeInsets.zero,
        child: Column(children: entries.map(actionTile).toList()),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final s = widget.session, u = s.user!;
    final profileIndex = u.isAdmin ? 2 : 3;
    final sheetIndex = u.isAdmin ? 1 : 2;
    return Scaffold(
      appBar: selected == sheetIndex || !u.isAdmin && selected == 1
          ? null
          : AppBar(
              title: Text(
                selected == profileIndex ? 'Hồ sơ' : 'Đức Attendance',
              ),
              actions: [
                if (selected == 0)
                  IconButton(
                    tooltip: 'Làm mới tổng quan',
                    onPressed: () => setState(load),
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: u.isAdmin ? 'Tổng quan' : 'Hôm nay',
          ),
          if (!u.isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Lịch làm',
            ),
          const NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            label: 'Bảng công',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
      body: selected == profileIndex
          ? ProfileScreen(s)
          : selected == sheetIndex
          ? TimesheetsScreen(s)
          : !u.isAdmin && selected == 1
          ? TimesheetsScreen(s, scheduleOnly: true)
          : RefreshIndicator(
              onRefresh: () async {
                setState(load);
                await summary;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Color.lerp(
                            Theme.of(context).colorScheme.primary,
                            Colors.black,
                            .2,
                          )!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.isAdmin
                              ? 'KHÔNG GIAN QUẢN TRỊ'
                              : 'NGÀY LÀM VIỆC CỦA BẠN',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Xin chào, ${u.name}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          u.isAdmin
                              ? 'Quản lý đội ngũ và xác minh công minh bạch.'
                              : 'Quét QR tại công ty và theo dõi công của bạn.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!u.isAdmin) ...[
                    BusyButton(
                      busy: false,
                      label: 'Chấm công vào / ra',
                      icon: Icons.qr_code_scanner_rounded,
                      onPressed: () => open(CheckInScreen(s)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FutureBuilder<Json>(
                    future: summary,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const LinearProgressIndicator();
                      }
                      if (snap.hasError) {
                        return ItemCard(
                          title: 'Chưa tải được tổng quan',
                          subtitle: snap.error.toString(),
                          icon: Icons.cloud_off,
                          onTap: () => setState(load),
                        );
                      }
                      final d = snap.data!;
                      if (u.isAdmin) return DashboardPanel(s, d);
                      return _TodayPanel(s, d);
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final entries = <_HomeAction>[
                        (
                          title: u.isAdmin ? 'Duyệt nghỉ phép' : 'Nghỉ phép',
                          detail: 'Đơn nghỉ và kết quả xử lý',
                          icon: Icons.beach_access_outlined,
                          screen: LeaveScreen(s),
                        ),
                        (
                          title: 'Lịch sử chấm công',
                          detail: 'Các lượt vào/ra đã ghi nhận',
                          icon: Icons.history,
                          screen: HistoryScreen(s),
                        ),
                        if (u.isAdmin)
                          (
                            title: 'Tổng quan theo ngày',
                            detail: 'Lọc ngày, phòng ban và danh sách ca',
                            icon: Icons.dashboard_outlined,
                            screen: DashboardScreen(s),
                          ),
                        if (u.isAdmin) ...[
                          (
                            title: 'Nhân viên',
                            detail: 'Hồ sơ, tìm kiếm, trạng thái',
                            icon: Icons.groups_outlined,
                            screen: CatalogScreen(s, CatalogKind.employees),
                          ),
                          (
                            title: 'Phòng ban',
                            detail: 'Tổ chức đội ngũ',
                            icon: Icons.apartment,
                            screen: CatalogScreen(s, CatalogKind.departments),
                          ),
                          (
                            title: 'Ca làm việc',
                            detail: 'Giờ vào, ra và ca qua đêm',
                            icon: Icons.schedule,
                            screen: CatalogScreen(s, CatalogKind.shifts),
                          ),
                          (
                            title: 'Lịch định kỳ',
                            detail: 'Ngày làm và ca theo nhân viên',
                            icon: Icons.repeat,
                            screen: WorkSchedulesScreen(s),
                          ),
                          (
                            title: 'Phân công',
                            detail: 'Lịch làm theo nhân viên',
                            icon: Icons.event_available,
                            screen: AssignmentScreen(s),
                          ),
                          (
                            title: 'Địa điểm',
                            detail: 'Tâm và bán kính GPS',
                            icon: Icons.location_on_outlined,
                            screen: CatalogScreen(s, CatalogKind.locations),
                          ),
                          (
                            title: 'Tạo QR',
                            detail: 'Phiên chấm công ngắn hạn',
                            icon: Icons.qr_code,
                            screen: SiteQrScreen(s),
                          ),
                          (
                            title: 'Thống kê',
                            detail: 'Công đã xác nhận',
                            icon: Icons.bar_chart_rounded,
                            screen: StatisticsScreen(s),
                          ),
                          (
                            title: 'Hỗ trợ lịch và thiếu công',
                            detail: 'Xử lý yêu cầu nhân viên',
                            icon: Icons.support_agent,
                            screen: AttendanceSupportScreen(s),
                          ),
                          (
                            title: 'Duyệt tài khoản',
                            detail: 'Liên kết hồ sơ nhân viên',
                            icon: Icons.person_add_alt_1_outlined,
                            screen: PendingUsersScreen(s),
                          ),
                          (
                            title: 'Duyệt giải trình',
                            detail: 'Bằng chứng và nhật ký',
                            icon: Icons.fact_check_outlined,
                            screen: RequestsScreen(s),
                          ),
                          (
                            title: 'Nhật ký hệ thống',
                            detail: 'Theo dõi thao tác quản trị',
                            icon: Icons.manage_history,
                            screen: AuditScreen(s),
                          ),
                        ] else ...[
                          (
                            title: 'Chấm công',
                            detail: 'QR và GPS vào / ra ca',
                            icon: Icons.fingerprint,
                            screen: CheckInScreen(s),
                          ),
                          (
                            title: 'Lịch làm việc',
                            detail: 'Ca đã được phân công',
                            icon: Icons.calendar_month_outlined,
                            screen: TimesheetsScreen(s, scheduleOnly: true),
                          ),
                          (
                            title: 'Giải trình',
                            detail: 'Theo dõi kết quả xử lý',
                            icon: Icons.fact_check_outlined,
                            screen: RequestsScreen(s),
                          ),
                          (
                            title: 'Hỗ trợ lịch và thiếu công',
                            detail: 'Bổ sung lịch hoặc quên ra ca',
                            icon: Icons.support_agent,
                            screen: AttendanceSupportScreen(s),
                          ),
                          (
                            title: 'Lần cần xác minh',
                            detail: 'Xem lượt quét và gửi giải trình',
                            icon: Icons.pending_actions,
                            screen: AttemptsScreen(s),
                          ),
                        ],
                        (
                          title: 'GPS hiện tại',
                          detail: 'Tọa độ và độ chính xác',
                          icon: Icons.my_location,
                          screen: GpsScreen(s),
                        ),
                        (
                          title: 'Chuyển động',
                          detail: 'Gia tốc và biểu đồ thật',
                          icon: Icons.vibration,
                          screen: const MotionScreen(),
                        ),
                      ];
                      const toolNames = {
                        'GPS hiện tại',
                        'Chuyển động',
                        'Nhật ký hệ thống',
                        'Lần cần xác minh',
                      };
                      final tools = entries
                          .where((e) => toolNames.contains(e.title))
                          .toList();
                      final main = entries
                          .where(
                            (e) =>
                                !toolNames.contains(e.title) &&
                                e.title != 'Chấm công',
                          )
                          .toList();
                      final review = main
                          .where(
                            (e) =>
                                e.title.startsWith('Duyệt') ||
                                e.title.startsWith('Hỗ trợ'),
                          )
                          .toList();
                      const teamNames = {
                        'Nhân viên',
                        'Phòng ban',
                        'Ca làm việc',
                        'Lịch định kỳ',
                        'Phân công',
                        'Địa điểm',
                      };
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (u.isAdmin) ...[
                            actionGroup('Cần xử lý', review),
                            actionGroup(
                              'Đội ngũ và lịch làm',
                              main
                                  .where((e) => teamNames.contains(e.title))
                                  .toList(),
                            ),
                            actionGroup(
                              'Chấm công và báo cáo',
                              main
                                  .where(
                                    (e) =>
                                        !teamNames.contains(e.title) &&
                                        !review.contains(e),
                                  )
                                  .toList(),
                            ),
                          ] else
                            actionGroup('Công việc của tôi', main),
                          const SizedBox(height: 20),
                          Card(
                            margin: EdgeInsets.zero,
                            child: ExpansionTile(
                              key: const PageStorageKey('home-utilities'),
                              leading: const Icon(Icons.tune_rounded),
                              title: const Text('Tiện ích'),
                              subtitle: const Text(
                                'Vị trí, cảm biến và nhật ký',
                              ),
                              children: tools.map(actionTile).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class AttemptsScreen extends StatefulWidget {
  final Session session;
  const AttemptsScreen(this.session, {super.key});
  @override
  State<AttemptsScreen> createState() => _AttemptsScreenState();
}

class _AttemptsScreenState extends State<AttemptsScreen> {
  int revision = 0;
  Future<void> request(Json row) async {
    if (row['outcome'] != 'NeedsReview' || row['hasRequest'] == true) return;
    final reason = await askReason(
      context,
      'Giải trình lần chấm công',
      minimum: 10,
    );
    if (reason == null) return;
    try {
      await widget.session.api.post('/attendance-requests', {
        'attemptId': row['id'],
        'reason': reason,
      });
      if (mounted) {
        message(context, 'Đã gửi yêu cầu xác minh.');
        setState(() => revision++);
      }
    } catch (e) {
      if (mounted) message(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => DataPage(
    key: ValueKey(revision),
    title: 'Các lần chấm công',
    load: (p) =>
        widget.session.api.page('/attendance/attempts?page=$p&pageSize=20'),
    item: (r, reload) => ItemCard(
      title: actionName(r['action']),
      subtitle:
          '${vietnamTime(r['receivedAtUtc'])}\n${reasonName(r['reasonCode'])}${r['hasRequest'] == true ? '\nĐã có yêu cầu giải trình' : ''}',
      trailing: StatusPill(r['outcome']),
      icon: Icons.fact_check_outlined,
      onTap: () => request(r),
    ),
  );
}

class AuditScreen extends StatelessWidget {
  final Session session;
  const AuditScreen(this.session, {super.key});
  @override
  Widget build(BuildContext context) => DataPage(
    title: 'Nhật ký hệ thống',
    load: (p) => session.api.page('/audit-logs?page=$p&pageSize=20'),
    item: (r, reload) => ItemCard(
      title: '${r['entityType']} · ${r['action']}',
      subtitle:
          '${vietnamTime(r['createdAtUtc'])}\nMã đối tượng: ${r['entityId'] ?? '—'}',
      icon: Icons.manage_history,
    ),
  );
}

class _TodayPanel extends StatelessWidget {
  final Session session;
  final Json data;
  const _TodayPanel(this.session, this.data);
  @override
  Widget build(BuildContext context) {
    final today = DateTime.parse(data['serverTimeUtc'])
        .toUtc()
        .add(const Duration(hours: 7))
        .toIso8601String()
        .substring(0, 10);
    final entries = (data['items'] as List).cast<Json>();
    final lines = entries
        .expand((x) => (x['data']['lines'] as List).cast<Json>())
        .where((x) => x['date'] == today)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ca hôm nay · Giờ Việt Nam',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (lines.isEmpty)
              const Text(
                'Hôm nay chưa có lịch làm. Không tính là vắng khi không có lịch.',
              ),
            ...lines.map(
              (l) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text('${l['shift']} · ${l['location']}'),
                subtitle: Text(
                  '${vietnamTime(l['startUtc'])} → ${vietnamTime(l['endUtc'])}\n${workStatus(l['status'])}\nVào: ${vietnamTime(l['checkInUtc'])} · Ra: ${vietnamTime(l['checkOutUtc'])}',
                ),
              ),
            ),
            for (final item in entries)
              if (item['responseStatus'] == 'Pending' &&
                  data['status'] == 'Published')
                TextButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Bảng công cần bạn xác nhận'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TimesheetsScreen(session),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
