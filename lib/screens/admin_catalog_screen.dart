import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../services/admin_catalog_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';

/// Справочник для суперпользователя (купоны, контакты, категории,
/// подкатегории, бренды, валюта): список -> форма "Добавить / Изменить /
/// Удалить". Какие поля в форме — присылает сервер (core/api/admin_catalog.py).
class AdminCatalogScreen extends StatefulWidget {
  final String section; // coupons / contacts / categories / subcategories / brands / currency
  final String titleKey; // ключ перевода заголовка
  final List<List<dynamic>> icon;

  const AdminCatalogScreen({super.key, required this.section, required this.titleKey, required this.icon});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  final _service = AdminCatalogService();
  AdminSection? _data;
  String? _error;
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _service.load(widget.section);
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open([AdminRecord? record]) async {
    final data = _data;
    if (data == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AdminEditScreen(
          section: widget.section,
          title: context.read<LocaleProvider>().t(widget.titleKey),
          fields: data.fields,
          record: record,
          canDelete: !data.single,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final data = _data;
    final canAdd = data != null && !(data.single && data.results.isNotEmpty);
    final q = _search.toLowerCase();
    final items = (data?.results ?? []).where((r) => q.isEmpty || r.title.toLowerCase().contains(q) || r.subtitle.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t(widget.titleKey))),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.gradientEnd,
              foregroundColor: Colors.white,
              onPressed: () => _open(),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
              label: Text(locale.t('add')),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && data == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && data == null
                ? ListView(children: [
                    const SizedBox(height: 100),
                    Center(child: Text('${locale.t('error')}: $_error')),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    children: [
                      if ((data?.results.length ?? 0) > 8)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v.trim()),
                            decoration: InputDecoration(
                              hintText: locale.t('search'),
                              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                              isDense: true,
                            ),
                          ),
                        ),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Center(child: Text(locale.t('nothing_found'))),
                        ),
                      for (final r in items)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => _open(r),
                            leading: r.image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(r.image!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => HugeIcon(icon: widget.icon)),
                                  )
                                : CircleAvatar(
                                    backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                                    child: HugeIcon(icon: widget.icon, color: AppColors.brand),
                                  ),
                            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: r.subtitle.isEmpty ? null : Text(r.subtitle),
                            trailing: const HugeIcon(icon: HugeIcons.strokeRoundedChevronRight),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

/// Форма записи: поля по описанию с сервера.
class _AdminEditScreen extends StatefulWidget {
  final String section;
  final String title;
  final List<AdminField> fields;
  final AdminRecord? record;
  final bool canDelete;

  const _AdminEditScreen({
    required this.section,
    required this.title,
    required this.fields,
    required this.record,
    required this.canDelete,
  });

  @override
  State<_AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<_AdminEditScreen> {
  final _service = AdminCatalogService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _text = {};
  final Map<String, int?> _choice = {};
  XFile? _newImage;
  bool _removeImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final values = widget.record?.values ?? const {};
    for (final f in widget.fields) {
      if (f.type == 'choice') {
        final v = values[f.name];
        _choice[f.name] = v is num ? v.toInt() : int.tryParse('$v');
      } else if (f.type != 'image') {
        _text[f.name] = TextEditingController(text: _format(values[f.name]));
      }
    }
  }

  // 100.0 -> "100", 19.5 -> "19.5"
  String _format(dynamic v) {
    if (v == null) return '';
    if (v is num) {
      return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    }
    return '$v';
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (f != null) {
      setState(() {
        _newImage = f;
        _removeImage = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final locale = context.read<LocaleProvider>();
    setState(() => _saving = true);
    try {
      await _service.save(
        widget.section,
        id: widget.record?.id,
        values: {
          for (final e in _text.entries) e.key: e.value.text.trim(),
          for (final e in _choice.entries) e.key: e.value?.toString() ?? '',
        },
        image: _newImage,
        removeImage: _removeImage,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.t('saved'))));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final locale = context.read<LocaleProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.t('delete')),
        content: Text(locale.t('delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(locale.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(locale.t('delete'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _service.delete(widget.section, widget.record!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final lang = locale.language;
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(widget.record == null ? '${widget.title}: ${locale.t('add')}' : widget.title),
        actions: [
          if (widget.record != null && widget.canDelete)
            IconButton(
              tooltip: locale.t('delete'),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            for (final f in widget.fields) ...[
              if (f.type == 'image')
                _imageField(f, lang)
              else if (f.type == 'choice')
                DropdownButtonFormField<int>(
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01),
                  initialValue: f.choices.any((c) => c.id == _choice[f.name]) ? _choice[f.name] : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: '${f.label(lang)}${f.required ? ' *' : ''}'),
                  items: [
                    for (final c in f.choices) DropdownMenuItem(value: c.id, child: Text(c.title)),
                  ],
                  onChanged: (v) => setState(() => _choice[f.name] = v),
                  validator: (v) => f.required && v == null ? locale.t('required_field') : null,
                )
              else
                TextFormField(
                  controller: _text[f.name],
                  keyboardType: f.type == 'number' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                  decoration: InputDecoration(labelText: '${f.label(lang)}${f.required ? ' *' : ''}'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (f.required && t.isEmpty) {
                      return locale.t('required_field');
                    }
                    if (f.type == 'number' && t.isNotEmpty && double.tryParse(t.replaceAll(',', '.')) == null) {
                      return locale.t('invalid_number');
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const HugeIcon(icon: HugeIcons.strokeRoundedCheck),
              label: Text(locale.t('save')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageField(AdminField f, String lang) {
    final current = _removeImage ? null : widget.record?.image;
    Widget preview;
    if (_newImage != null) {
      preview = kIsWeb
          ? Image.network(_newImage!.path, fit: BoxFit.cover)
          : FutureBuilder(
              future: _newImage!.readAsBytes(),
              builder: (_, s) => s.hasData ? Image.memory(s.data!, fit: BoxFit.cover) : const SizedBox(),
            );
    } else if (current != null) {
      preview = Image.network(current, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01));
    } else {
      preview = HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: AppColors.bodyText, size: 36);
    }
    return Row(
      children: [
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.subtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: preview),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.label(lang), style: const TextStyle(fontWeight: FontWeight.w600)),
              TextButton(onPressed: _pickImage, child: Text(context.read<LocaleProvider>().t('choose_photo'))),
              if (_newImage != null || current != null)
                TextButton(
                  onPressed: () => setState(() {
                    _newImage = null;
                    _removeImage = true;
                  }),
                  child: Text(context.read<LocaleProvider>().t('remove_photo'), style: const TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
