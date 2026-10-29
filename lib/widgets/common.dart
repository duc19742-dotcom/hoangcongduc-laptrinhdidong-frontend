import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

String vietnamTime(dynamic value) {
  if (value == null) return '—';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return DateFormat('dd/MM/yyyy HH:mm')
      .format(date.toUtc().add(const Duration(hours: 7)));
}

String dateOnly(dynamic value) {
  if (value == null) return '—';
  final date = DateTime.tryParse(value.toString());
  return date == null
      ? value.toString()
      : DateFormat('dd/MM/yyyy').format(date);
}

String actionName(dynamic value) =>
    value == 'CheckOut' ? 'Chấm công ra' : 'Chấm công vào';
String stateName(dynamic value) => switch (value) {
  'Pending' => 'Chờ xử lý',
  'Approved' => 'Đã duyệt',
  'Rejected' => 'Từ chối',
  'Cancelled' => 'Đã hủy',
  'Accepted' => 'Đã xác nhận',
  'NeedsReview' => 'Cần xác minh',
  _ => value?.toString() ?? '—',
};
String reasonName(String value) => value
    .replaceAll('OutsideGeofence', 'Ngoài bán kính công ty')
    .replaceAll('LowGpsAccuracy', 'Độ chính xác GPS chưa đạt');
void message(BuildContext context, String text, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
Future<bool> confirm(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ??
    false;

class BusyButton extends StatelessWidget {
  final bool busy;
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const BusyButton({
    super.key,
    required this.busy,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: busy ? null : onPressed,
    icon: busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    label: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label),
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  final Object error;
  final VoidCallback retry;
  const ErrorPanel(this.error, this.retry, {super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.blueGrey),
          const SizedBox(height: 16),
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  final String value;
  const StatusPill(this.value, {super.key});
  @override
  Widget build(BuildContext context) {
    final good = ['Approved', 'Accepted'].contains(value);
    final bad = ['Rejected', 'Cancelled'].contains(value);
    final color = good
        ? Colors.teal
        : bad
        ? Colors.red
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stateName(value),
        style: TextStyle(
          color: color.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class DataPage extends StatefulWidget {
  final String title;
  final Future<PageResult> Function(int page) load;
  final Widget Function(Json row, VoidCallback reload) item;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? header;
  const DataPage({
    super.key,
    required this.title,
    required this.load,
    required this.item,
    this.actions,
    this.floatingActionButton,
    this.header,
  });
  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  int page = 1;
  late Future<PageResult> future;
  @override
  void initState() {
    super.initState();
    future = widget.load(page);
  }

  void reload() {
    setState(() => future = widget.load(page));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(onPressed: reload, icon: const Icon(Icons.refresh)),
        ...?widget.actions,
      ],
    ),
    floatingActionButton: widget.floatingActionButton,
    body: Column(
      children: [
        if (widget.header != null) widget.header!,
        Expanded(
          child: FutureBuilder<PageResult>(
            future: future,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) return ErrorPanel(s.error!, reload);
              final data = s.data!;
              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        reload();
                        await future;
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: data.items.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 48,
                                        color: Colors.blueGrey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Chưa có dữ liệu',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            : data.items
                                  .map((x) => widget.item(x, reload))
                                  .toList(),
                      ),
                    ),
                  ),
                  if (data.totalCount > data.pageSize)
                    SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: page > 1
                                ? () {
                                    page--;
                                    reload();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('Trang $page · ${data.totalCount} mục'),
                          IconButton(
                            onPressed: page * data.pageSize < data.totalCount
                                ? () {
                                    page++;
                                    reload();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class ItemCard extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData icon;
  const ItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.icon = Icons.description_outlined,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(subtitle),
      ),
      trailing: trailing,
      onTap: onTap,
    ),
  );
}
