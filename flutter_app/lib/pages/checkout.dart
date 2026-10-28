import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../ui/common.dart';

Future<Json?> showCheckout(
  BuildContext context,
  AppState app, {
  required Product product,
  required String title,
  required int price,
  String? storeProductId,
  Future<String?> Function()? saveDesign,
}) => showDialog<Json>(
  context: context,
  barrierDismissible: false,
  builder: (_) => CheckoutDialog(
    app: app,
    product: product,
    title: title,
    price: price,
    storeProductId: storeProductId,
    saveDesign: saveDesign,
  ),
);

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({
    super.key,
    required this.app,
    required this.product,
    required this.title,
    required this.price,
    this.storeProductId,
    this.saveDesign,
  });
  final AppState app;
  final Product product;
  final String title;
  final int price;
  final String? storeProductId;
  final Future<String?> Function()? saveDesign;
  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  bool _busy = false;
  String? _error;
  int _quantity = 1;
  String? _variant;
  bool get creator => widget.saveDesign != null;
  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _variant = textOf(widget.product.variants.first['id']);
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final expectedRole = creator ? 'CREATOR' : 'CUSTOMER';
    if (widget.app.user?.role != expectedRole) {
      setState(() => _error = 'Checkout memerlukan akun $expectedRole.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'quantity': _quantity,
        'shippingAddress': _address.text.trim(),
      };
      if (creator) {
        final id = await widget.saveDesign!();
        if (id == null) throw Exception('Desain belum berhasil disimpan.');
        body.addAll({'designId': id, 'variantId': _variant});
      } else {
        body['storeProductId'] = widget.storeProductId;
      }
      final result = object(await widget.app.api.post('/api/orders', body));
      if (mounted) Navigator.pop(context, result);
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
          Expanded(child: Text(creator ? 'Checkout produksi' : 'Pesan produk')),
          IconButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 410,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.product.name,
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        money(widget.price * _quantity),
                        style: const TextStyle(
                          color: green,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (creator) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _variant,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Varian produk',
                    ),
                    items: widget.product.variants
                        .map(
                          (variant) => DropdownMenuItem(
                            value: textOf(variant['id']),
                            child: Text(
                              '${variant['name']} · stok ${variant['stock']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    validator: (v) => v == null ? 'Pilih varian produk.' : null,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _variant = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: '1',
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (1–10)',
                    ),
                    validator: (v) {
                      final qty = int.tryParse(v ?? '');
                      return qty != null && qty >= 1 && qty <= 10
                          ? null
                          : 'Jumlah harus 1–10.';
                    },
                    onChanged: (v) => setState(
                      () => _quantity = (int.tryParse(v) ?? 1).clamp(1, 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _address,
                  enabled: !_busy,
                  maxLines: 4,
                  validator: requiredText,
                  decoration: const InputDecoration(
                    labelText: 'Alamat pengiriman',
                    hintText: 'Nama penerima, jalan, kecamatan, kota, kode pos',
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pembayaran simulasi (Mock). Pesanan langsung berstatus PAID dan masuk ke antrean Print Partner.',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
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
                        : creator
                        ? 'Konfirmasi & pesan'
                        : 'Bayar sekarang · Mock',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
