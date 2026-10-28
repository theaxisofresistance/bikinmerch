import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_state.dart';

const green = Color(0xff176b4d);
const lime = Color(0xffd8f27a);
const ink = Color(0xff202b25);
const muted = Color(0xff79817b);
const paper = Color(0xfff7f8f5);
const line = Color(0xffe9ece7);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: green,
    primary: green,
    surface: Colors.white,
  ),
  fontFamily: 'Arial',
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.5),
    headlineLarge: TextStyle(
      fontSize: 34,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 25,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -.7,
      color: ink,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.all(14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: green),
    ),
  ),
  dividerColor: line,
);

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      text: 'Bikin',
      children: [
        TextSpan(
          text: 'Merch',
          style: TextStyle(color: Color(0xff98ba32)),
        ),
      ],
    ),
    style: TextStyle(
      color: green,
      fontSize: 23,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
    ),
  );
}

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color = green});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.title, {
    super.key,
    this.kicker,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? kicker, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kicker != null) ...[
              Kicker(kicker!),
              const SizedBox(height: 10),
            ],
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: const TextStyle(color: muted)),
            ],
          ],
        );
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: copy),
            if (action != null) ...[const SizedBox(width: 20), action!],
          ],
        );
      },
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.message, {
    super.key,
    this.action,
    this.icon = Icons.inventory_2_outlined,
  });
  final String message;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          Icon(icon, color: muted, size: 34),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {super.key, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: const Color(0xfffff0ed),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Color(0xffa43c32))),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

class RoleGate extends StatelessWidget {
  const RoleGate({
    super.key,
    required this.app,
    required this.roles,
    required this.child,
  });
  final AppState app;
  final Set<String> roles;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (app.user == null) {
      return EmptyState(
        'Masuk sebagai ${roles.join(' / ').replaceAll('_', ' ')} untuk membuka halaman ini.',
        action: FilledButton(
          onPressed: () => showAuth(context, app),
          child: const Text('Masuk'),
        ),
      );
    }
    if (!roles.contains(app.user!.role)) {
      return const EmptyState(
        'Halaman ini tidak tersedia untuk peran akunmu.',
        icon: Icons.lock_outline,
      );
    }
    return child;
  }
}

class AsyncData extends StatefulWidget {
  const AsyncData({super.key, required this.load, required this.builder});
  final Future<dynamic> Function() load;
  final Widget Function(BuildContext, dynamic, Future<void> Function()) builder;
  @override
  State<AsyncData> createState() => AsyncDataState();
}

class AsyncDataState extends State<AsyncData> {
  dynamic _data;
  String? _error;
  bool _loading = true;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final id = ++_request;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final data = await widget.load();
      if (mounted && id == _request) setState(() => _data = data);
    } catch (e) {
      if (mounted && id == _request) setState(() => _error = e.toString());
    } finally {
      if (mounted && id == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) return ErrorNotice(_error!, retry: reload);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        widget.builder(context, _data, reload),
      ],
    );
  }
}

class FlowGrid extends StatelessWidget {
  const FlowGrid({
    super.key,
    required this.children,
    this.minWidth = 250,
    this.maxColumns = 4,
  });
  final List<Widget> children;
  final double minWidth;
  final int maxColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + 18) / (minWidth + 18))
          .floor()
          .clamp(1, maxColumns);
      final width = (constraints.maxWidth - (columns - 1) * 18) / columns;
      return Wrap(
        spacing: 18,
        runSpacing: 18,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffedf4e8),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: green,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class AppImage extends StatelessWidget {
  const AppImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });
  final String source;
  final BoxFit fit;
  final double? height, width;
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        SizedBox(
          height: height ?? 120,
          width: width,
          child: const Center(
            child: Icon(Icons.image_outlined, size: 38, color: muted),
          ),
        );
    try {
      if (source.startsWith('data:')) {
        return Image.memory(
          base64Decode(source.split(',').last),
          fit: fit,
          height: height,
          width: width,
          errorBuilder: fallback,
        );
      }
      if (source.isEmpty) return fallback(context, 'empty', null);
      return Image.network(
        source,
        fit: fit,
        height: height,
        width: width,
        errorBuilder: fallback,
      );
    } catch (error) {
      return fallback(context, error, null);
    }
  }
}

class DataPanel extends StatelessWidget {
  const DataPanel(
    this.title, {
    super.key,
    required this.columns,
    required this.rows,
    this.action,
  });
  final String title;
  final List<String> columns;
  final List<List<Widget>> rows;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Belum ada data.', style: TextStyle(color: muted)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 28,
              horizontalMargin: 0,
              headingTextStyle: const TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              dataTextStyle: const TextStyle(fontSize: 12, color: ink),
              columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: row.map((cell) => DataCell(cell)).toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Sejak toko dibuat',
          style: TextStyle(color: muted, fontSize: 10),
        ),
      ],
    ),
  );
}

void notify(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String label = 'Lanjutkan',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> showAuth(
  BuildContext context,
  AppState app, {
  bool register = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => AuthDialog(app: app, register: register),
    ) ??
    false;

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key, required this.app, this.register = false});
  final AppState app;
  final bool register;
  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  late bool _register = widget.register;
  bool _busy = false, _hidden = true;
  String _role = 'CREATOR';
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.app.authenticate({
        'name': _name.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'password': _password.text,
        'role': _role,
      }, register: _register);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('BikinMerch'),
                const SizedBox(height: 8),
                Text(
                  _register ? 'Buat akun baru' : 'Selamat datang kembali',
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _register
                      ? 'Mulai jual karyamu tanpa stok.'
                      : 'Masuk untuk melanjutkan.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                if (_register) ...[
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                    ),
                    validator: requiredText,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Masukkan email yang valid.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _hidden,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => _register && (v?.length ?? 0) < 8
                      ? 'Kata sandi minimal 8 karakter.'
                      : requiredText(v),
                  onFieldSubmitted: (_) => _busy ? null : _submit(),
                ),
                if (_register) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Saya ingin bergabung sebagai',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'CREATOR',
                        child: Text('Creator — membuat dan menjual'),
                      ),
                      DropdownMenuItem(
                        value: 'CUSTOMER',
                        child: Text('Customer — membeli merchandise'),
                      ),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _role = v!),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  ErrorNotice(_error!),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? 'Memproses…'
                        : _register
                        ? 'Daftar gratis'
                        : 'Masuk',
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _register = !_register;
                          _error = null;
                        }),
                  child: Text(
                    _register
                        ? 'Sudah punya akun? Masuk'
                        : 'Belum punya akun? Daftar',
                  ),
                ),
                const Divider(),
                const Text(
                  'Akun demo setelah seed:\ncreator@bikinmerch.id · customer@bikinmerch.id\nadmin@bikinmerch.id · partner@bikinmerch.id\nPassword: bikinmerch123',
                  style: TextStyle(color: muted, fontSize: 10, height: 1.7),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
