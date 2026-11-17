import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/manage_models.dart';
import '../providers/locale_provider.dart';
import '../services/manage_service.dart';
import '../theme/app_theme.dart';
import '../utils/html_utils.dart';
import '../widgets/gradient_app_bar.dart';

/// Добавление ([itemId] == null) или изменение товара. Возвращает true через
/// Navigator.pop, если товар сохранён/удалён — список обновится.
class ProductEditorScreen extends StatefulWidget {
  final int? itemId;
  const ProductEditorScreen({super.key, this.itemId});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _service = ManageService();
  final _picker = ImagePicker();

  ManageMeta? _meta;
  ManageItemDetail? _item;
  String? _loadError;
  bool _saving = false;
  double _progress = 0;

  final _titleRu = TextEditingController();
  final _titleTk = TextEditingController();
  final _titleEn = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _delivery = TextEditingController();
  final _descRu = TextEditingController();
  final _descTk = TextEditingController();
  final _descEn = TextEditingController();
  String _initialDescRu = '';
  String _initialDescTk = '';
  String _initialDescEn = '';

  int? _parentCategoryId;
  int? _categoryId;
  int? _brandId;
  bool _published = true;
  bool _inStock = false; // новый товар — "Нет в наличии", как в админке
  List<RefOption> _sizes = [];
  List<RefOption> _colors = [];
  // Свои цены размеров (CNY) по id размера; пустое поле — цена товара.
  final Map<int, TextEditingController> _sizePrice = {};
  final Map<int, TextEditingController> _sizeDiscount = {};

  // Фото
  String? _mainImageUrl; // текущее (при изменении)
  XFile? _newMainImage;
  List<ManageImage> _existingExtra = [];
  final Set<int> _removedExtraIds = {};
  final List<XFile> _newExtra = [];

  bool get _isNew => widget.itemId == null;

  @override
  void initState() {
    super.initState();
    _load();
    _price.addListener(() => setState(() {}));
    _discount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _titleRu,
      _titleTk,
      _titleEn,
      _price,
      _discount,
      _quantity,
      _delivery,
      _descRu,
      _descTk,
      _descEn,
      ..._sizePrice.values,
      ..._sizeDiscount.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final meta = await _service.getMeta();
      ManageItemDetail? item;
      if (!_isNew) item = await _service.getItem(widget.itemId!);
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _item = item;
        if (item != null) _fillFrom(item);
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  void _fillFrom(ManageItemDetail it) {
    _titleRu.text = it.titleRu;
    _titleTk.text = it.titleTk;
    _titleEn.text = it.titleEn;
    _price.text = _num(it.price);
    _discount.text = it.discountPrice != null ? _num(it.discountPrice!) : '';
    _quantity.text = '${it.quantity}';
    _delivery.text = it.delivery?.toString() ?? '';
    // Описание с сайта — HTML. Показываем текстом; на сервер отправляем,
    // только если его действительно изменили (иначе форматирование не трогаем).
    _initialDescRu = stripHtml(it.descriptionRu);
    _initialDescTk = stripHtml(it.descriptionTk);
    _initialDescEn = stripHtml(it.descriptionEn);
    _descRu.text = _initialDescRu;
    _descTk.text = _initialDescTk;
    _descEn.text = _initialDescEn;
    _categoryId = it.categoryId;
    _parentCategoryId = it.allCategoryId ?? _findParent(it.categoryId);
    _brandId = it.brandId;
    _published = it.isPublished;
    _inStock = it.inStock;
    _sizes = List.of(it.sizes);
    _colors = List.of(it.colors);
    for (final sp in it.sizePrices) {
      _sizeCtrl(_sizePrice, sp.sizeId).text = _num(sp.price);
      if (sp.discountPrice != null) {
        _sizeCtrl(_sizeDiscount, sp.sizeId).text = _num(sp.discountPrice!);
      }
    }
    _mainImageUrl = it.image;
    _existingExtra = List.of(it.images);
  }

  int? _findParent(int? categoryId) {
    for (final p in _meta?.categories ?? const <CategoryNode>[]) {
      if (p.children.any((c) => c.id == categoryId)) return p.id;
    }
    return null;
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  TextEditingController _sizeCtrl(Map<int, TextEditingController> map, int sizeId) => map.putIfAbsent(sizeId, () => TextEditingController()..addListener(() => setState(() {})));

  /// Цены только для выбранных сейчас размеров и только заполненные.
  List<SizePrice> _collectSizePrices() {
    final result = <SizePrice>[];
    for (final s in _sizes) {
      final price = _parse(_sizePrice[s.id]?.text ?? '');
      if (price == null || price <= 0) continue;
      final discount = _parse(_sizeDiscount[s.id]?.text ?? '');
      result.add(SizePrice(sizeId: s.id, price: price, discountPrice: discount != null && discount > 0 ? discount : null));
    }
    return result;
  }

  // ------------------------------------------------------------------ фото
  Future<ImageSource?> _askSource() {
    final locale = context.read<LocaleProvider>();
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedAlbum01),
              title: Text(locale.t('from_gallery')),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01),
              title: Text(locale.t('from_camera')),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMain() async {
    final source = await _askSource();
    if (source == null) return;
    final f = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (f != null) setState(() => _newMainImage = f);
  }

  /// Несколько фото за один раз из галереи (или одно с камеры).
  Future<void> _pickExtra() async {
    final source = await _askSource();
    if (source == null) return;
    if (source == ImageSource.gallery) {
      final files = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1600);
      if (files.isNotEmpty) setState(() => _newExtra.addAll(files));
    } else {
      final f = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (f != null) setState(() => _newExtra.add(f));
    }
  }

  // ------------------------------------------------------- размеры / цвета
  Future<void> _editRefs({required bool colors}) async {
    final result = await showModalBottomSheet<List<RefOption>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RefPickerSheet(
        colors: colors,
        initial: colors ? _colors : _sizes,
        service: _service,
      ),
    );
    if (result != null) {
      setState(() => colors ? _colors = result : _sizes = result);
    }
  }

  // ------------------------------------------------------------ сохранение
  Future<void> _save() async {
    final locale = context.read<LocaleProvider>();
    String? problem;
    final price = _parse(_price.text);
    if (_titleRu.text.trim().isEmpty) {
      problem = locale.t('need_title');
    } else if (_categoryId == null) {
      problem = locale.t('need_category');
    } else if (price == null || price <= 0) {
      problem = locale.t('need_price');
    } else if (_isNew && _newMainImage == null) {
      problem = locale.t('need_main_photo');
    }
    final discount = _parse(_discount.text);
    if (problem == null && discount != null && price != null && discount >= price) {
      problem = locale.t('discount_too_big');
    }
    final sizePrices = _collectSizePrices();
    if (problem == null && sizePrices.any((sp) => sp.discountPrice != null && sp.discountPrice! >= sp.price)) {
      problem = locale.t('size_discount_too_big');
    }
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    final fields = <String, dynamic>{
      'title_ru': _titleRu.text.trim(),
      'title_tk': _titleTk.text.trim(),
      'title_en': _titleEn.text.trim(),
      'category_id': _categoryId,
      'brand_id': _brandId ?? '',
      'price': _price.text.trim().replaceAll(',', '.'),
      'discount_price': discount != null && discount > 0 ? discount : '',
      'quantity': int.tryParse(_quantity.text.trim()) ?? 1,
      'delivery': _delivery.text.trim(),
      'is_published': _published,
      'in_stock': _inStock,
      'size_ids': _sizes.map((e) => e.id).toList(),
      // JSON-строкой: ManageService склеивает списки через запятую
      'size_prices': jsonEncode(sizePrices.map((e) => e.toJson()).toList()),
      'color_ids': _colors.map((e) => e.id).toList(),
    };
    // Описание — только новое или изменённое: старое HTML-оформление с сайта
    // не перезаписываем без необходимости.
    if (_isNew || _descRu.text.trim() != _initialDescRu.trim()) {
      fields['description_ru'] = _descRu.text;
    }
    if (_isNew || _descTk.text.trim() != _initialDescTk.trim()) {
      fields['description_tk'] = _descTk.text;
    }
    if (_isNew || _descEn.text.trim() != _initialDescEn.trim()) {
      fields['description_en'] = _descEn.text;
    }

    setState(() {
      _saving = true;
      _progress = 0;
    });
    try {
      await _service.save(
        id: widget.itemId,
        fields: fields,
        mainImage: _newMainImage,
        extraImages: _newExtra,
        removeImageIds: _removedExtraIds.toList(),
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isNew ? locale.t('product_created') : locale.t('product_saved'))),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final locale = context.read<LocaleProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('delete_product')),
        content: Text(locale.t('delete_product_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(locale.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(locale.t('delete'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _service.delete(widget.itemId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.t('product_deleted'))));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final meta = _meta;
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(_isNew ? locale.t('add_product') : locale.t('edit_product')),
        actions: [
          if (!_isNew && (meta?.canDelete ?? false))
            IconButton(
              tooltip: locale.t('delete_product'),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      bottomNavigationBar: meta == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _saving
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinearProgressIndicator(value: _progress > 0 && _progress < 1 ? _progress : null),
                          const SizedBox(height: 8),
                          Text(_progress < 1 ? '${locale.t('uploading')} ${(_progress * 100).round()}%' : locale.t('saving')),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: _save,
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheck),
                        label: Text(locale.t('save')),
                      ),
              ),
            ),
      body: meta == null
          ? Center(
              child: _loadError != null ? Padding(padding: const EdgeInsets.all(24), child: Text('${locale.t('error')}: $_loadError')) : const CircularProgressIndicator(),
            )
          : AbsorbPointer(
              absorbing: _saving,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section(locale.t('photos')),
                  _buildPhotos(locale),
                  const SizedBox(height: 20),
                  _section(locale.t('main_info')),
                  TextField(
                    controller: _titleRu,
                    maxLength: 100,
                    decoration: InputDecoration(labelText: '${locale.t('title_ru')} *'),
                  ),
                  TextField(
                    controller: _titleTk,
                    maxLength: 100,
                    decoration: InputDecoration(labelText: locale.t('title_tk')),
                  ),
                  TextField(
                    controller: _titleEn,
                    maxLength: 100,
                    decoration: InputDecoration(labelText: locale.t('title_en')),
                  ),
                  _buildCategory(locale, meta),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01),
                    initialValue: meta.brands.any((b) => b.id == _brandId) ? _brandId : null,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: locale.t('brand')),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text(locale.t('no_brand'))),
                      ...meta.brands.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.titleRu))),
                    ],
                    onChanged: (v) => setState(() => _brandId = v),
                  ),
                  const SizedBox(height: 20),
                  _section(locale.t('price_section')),
                  _priceField(locale, meta, _price, '${locale.t('price_cny')} *'),
                  const SizedBox(height: 12),
                  _priceField(locale, meta, _discount, locale.t('discount_price_cny')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantity,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(labelText: locale.t('quantity')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _delivery,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(labelText: locale.t('delivery_days')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _section(locale.t('sizes_and_colors')),
                  _refRow(locale, locale.t('size'), _sizes, locale.language, () => _editRefs(colors: false)),
                  if (_sizes.isNotEmpty) _buildSizePrices(locale, meta),
                  const SizedBox(height: 8),
                  _refRow(locale, locale.t('color'), _colors, locale.language, () => _editRefs(colors: true)),
                  const SizedBox(height: 20),
                  _section(locale.t('description')),
                  if (!_isNew && (_item?.descriptionRu.contains('<') ?? false))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(locale.t('description_format_note'), style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
                    ),
                  TextField(
                    controller: _descRu,
                    minLines: 3,
                    maxLines: 10,
                    decoration: InputDecoration(labelText: locale.t('description_ru'), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descTk,
                    minLines: 3,
                    maxLines: 10,
                    decoration: InputDecoration(labelText: locale.t('description_tk'), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descEn,
                    minLines: 3,
                    maxLines: 10,
                    decoration: InputDecoration(labelText: locale.t('description_en'), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(locale.t('published')),
                    subtitle: Text(locale.t('published_hint'), style: const TextStyle(fontSize: 12)),
                    value: _published,
                    onChanged: (v) => setState(() => _published = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(locale.t('stock_yes')),
                    subtitle: Text(locale.t('stock_switch_hint'), style: const TextStyle(fontSize: 12)),
                    value: _inStock,
                    onChanged: (v) => setState(() => _inStock = v),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _buildPhotos(LocaleProvider locale) {
    final extraCount = _existingExtra.where((i) => !_removedExtraIds.contains(i.id)).length + _newExtra.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Главное фото
        GestureDetector(
          onTap: _pickMain,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.subtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_newMainImage != null)
                  _XFileImage(file: _newMainImage!, fit: BoxFit.contain)
                else if (_mainImageUrl != null)
                  Image.network(_mainImageUrl!, fit: BoxFit.contain)
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedCameraAdd01, size: 40, color: AppColors.accent),
                      const SizedBox(height: 8),
                      Text('${locale.t('main_photo')} *', style: const TextStyle(color: AppColors.accent)),
                    ],
                  ),
                if (_newMainImage != null || _mainImageUrl != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text(locale.t('change_photo'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('${locale.t('extra_photos')} ($extraCount)', style: TextStyle(color: AppColors.bodyText)),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Кнопка "добавить" — несколько фото за раз
              GestureDetector(
                onTap: _pickExtra,
                child: Container(
                  width: 88,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent, width: 1.4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: AppColors.accent),
                      const SizedBox(height: 4),
                      Text(locale.t('add_photos'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.accent, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              for (final img in _existingExtra.where((i) => !_removedExtraIds.contains(i.id)))
                _thumb(
                  Image.network(img.image, fit: BoxFit.cover),
                  onRemove: () => setState(() => _removedExtraIds.add(img.id)),
                ),
              for (final f in _newExtra)
                _thumb(
                  _XFileImage(file: f, fit: BoxFit.cover),
                  isNew: true,
                  onRemove: () => setState(() => _newExtra.remove(f)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thumb(Widget image, {required VoidCallback onRemove, bool isNew = false}) {
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: image)),
          if (isNew)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6)),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(LocaleProvider locale, ManageMeta meta) {
    final parents = meta.categories;
    CategoryNode? parent;
    for (final p in parents) {
      if (p.id == _parentCategoryId) parent = p;
    }
    final children = parent?.children ?? const <CategoryNode>[];
    return Column(
      children: [
        DropdownButtonFormField<int>(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01),
          initialValue: parent?.id,
          isExpanded: true,
          decoration: InputDecoration(labelText: '${locale.t('category')} *'),
          items: parents.map((p) => DropdownMenuItem(value: p.id, child: Text(p.titleFor(locale.language)))).toList(),
          onChanged: (v) => setState(() {
            _parentCategoryId = v;
            _categoryId = null; // подкатегорию выбрать заново
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01),
          initialValue: children.any((c) => c.id == _categoryId) ? _categoryId : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: '${locale.t('subcategory')} *'),
          items: children.map((c) => DropdownMenuItem(value: c.id, child: Text(c.titleFor(locale.language)))).toList(),
          onChanged: children.isEmpty ? null : (v) => setState(() => _categoryId = v),
        ),
      ],
    );
  }

  Widget _priceField(LocaleProvider locale, ManageMeta meta, TextEditingController c, String label) {
    final tmt = meta.toTmt(_parse(c.text));
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'CNY',
        helperText: tmt != null ? '≈ $tmt TMT ${locale.t('for_customers')}' : null,
      ),
    );
  }

  /// Для каждого выбранного размера — своя цена и цена со скидкой (CNY).
  Widget _buildSizePrices(LocaleProvider locale, ManageMeta meta) {
    Widget field(TextEditingController c, String label) {
      final tmt = meta.toTmt(_parse(c.text));
      return TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixText: 'CNY',
          helperText: tmt != null ? '≈ $tmt TMT' : null,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.t('size_prices'), style: Theme.of(context).textTheme.titleSmall),
          Text(locale.t('size_prices_hint'), style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
          const SizedBox(height: 8),
          for (final s in _sizes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(s.titleFor(locale.language), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Expanded(child: field(_sizeCtrl(_sizePrice, s.id), locale.t('price_cny'))),
                  const SizedBox(width: 8),
                  Expanded(child: field(_sizeCtrl(_sizeDiscount, s.id), locale.t('discount_price_cny'))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _refRow(LocaleProvider locale, String label, List<RefOption> values, String lang, VoidCallback onEdit) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      onTap: onEdit,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedEdit02)),
        child: values.isEmpty
            ? Text(locale.t('not_selected'), style: TextStyle(color: AppColors.bodyText))
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: values
                    .map((v) => Chip(
                          label: Text(v.titleFor(lang), style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
      ),
    );
  }
}

/// Превью выбранного (ещё не загруженного) фото — через байты, работает и на Web.
class _XFileImage extends StatefulWidget {
  final XFile file;
  final BoxFit fit;
  const _XFileImage({required this.file, required this.fit});

  @override
  State<_XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<_XFileImage> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant _XFileImage old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path) _bytes = widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, s) => s.hasData ? Image.memory(s.data!, fit: widget.fit) : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// Выбор размеров или цветов: поиск, отметки, создание нового значения.
class _RefPickerSheet extends StatefulWidget {
  final bool colors;
  final List<RefOption> initial;
  final ManageService service;
  const _RefPickerSheet({required this.colors, required this.initial, required this.service});

  @override
  State<_RefPickerSheet> createState() => _RefPickerSheetState();
}

class _RefPickerSheetState extends State<_RefPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  late final List<RefOption> _selected = List.of(widget.initial);
  List<RefOption>? _options;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    try {
      final list = widget.colors ? await widget.service.getColors(search: q) : await widget.service.getSizes(search: q);
      if (mounted) setState(() => _options = list);
    } catch (_) {
      if (mounted) setState(() => _options = []);
    }
  }

  bool _isSelected(RefOption o) => _selected.any((s) => s.id == o.id);

  void _toggle(RefOption o) => setState(() {
        if (_isSelected(o)) {
          _selected.removeWhere((s) => s.id == o.id);
        } else {
          _selected.add(o);
        }
      });

  Future<void> _create() async {
    final locale = context.read<LocaleProvider>();
    final text = _search.text.trim();
    RefOption? created;
    setState(() => _creating = true);
    try {
      if (widget.colors) {
        final ru = TextEditingController(text: text);
        final tk = TextEditingController();
        final en = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(locale.t('new_color')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ru, decoration: InputDecoration(labelText: locale.t('title_ru'))),
                TextField(controller: tk, decoration: InputDecoration(labelText: locale.t('title_tk'))),
                TextField(controller: en, decoration: InputDecoration(labelText: locale.t('title_en'))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(locale.t('cancel'))),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(locale.t('save'))),
            ],
          ),
        );
        if (ok == true && ru.text.trim().isNotEmpty) {
          created = await widget.service.createColor(ru.text.trim(), tk.text.trim(), en.text.trim());
        }
      } else {
        created = await widget.service.createSize(text);
      }
      if (created != null && mounted) {
        final c = created;
        setState(() {
          if (!_isSelected(c)) _selected.add(c);
          _options = [c, ...?_options?.where((o) => o.id != c.id)];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final q = _search.text.trim();
    final options = _options;
    final exact = options?.any((o) => o.titleRu.toLowerCase() == q.toLowerCase() || o.titleTk.toLowerCase() == q.toLowerCase() || o.titleEn.toLowerCase() == q.toLowerCase()) ?? false;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.colors ? locale.t('color') : locale.t('size'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: Text('${locale.t('done')} (${_selected.length})'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (v) {
                    setState(() {});
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () => _load(v.trim()));
                  },
                  decoration: InputDecoration(
                    hintText: locale.t('search_or_create'),
                    prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                    isDense: true,
                  ),
                ),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selected
                          .map((s) => InputChip(
                                label: Text(s.titleFor(locale.language), style: const TextStyle(fontSize: 12)),
                                onDeleted: () => _toggle(s),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              if (q.isNotEmpty && !exact)
                ListTile(
                  leading: _creating
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, color: AppColors.accent),
                  title: Text('${locale.t('create_new')} «$q»', style: const TextStyle(color: AppColors.accent)),
                  onTap: _creating ? null : _create,
                ),
              const Divider(height: 1),
              Expanded(
                child: options == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, i) {
                          final o = options[i];
                          return CheckboxListTile(
                            value: _isSelected(o),
                            onChanged: (_) => _toggle(o),
                            title: Text(o.titleFor(locale.language)),
                            subtitle: widget.colors && o.titleTk.isNotEmpty && locale.language == 'ru' ? Text(o.titleTk, style: const TextStyle(fontSize: 12)) : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
