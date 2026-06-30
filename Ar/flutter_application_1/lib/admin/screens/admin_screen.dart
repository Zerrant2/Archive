import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../theme/app_colors.dart';
import '../models/admin_ar_asset.dart';
import '../models/admin_epoch.dart';
import '../models/admin_heritage_object.dart';
import '../repositories/admin_repository.dart';
import '../services/admin_media_picker.dart';
import '../services/admin_qr_downloader.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminRepository _repository = AdminRepository();
  final _formKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _centuryController = TextEditingController();
  final _architectureController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _epochYearController = TextEditingController();
  final _epochLabelController = TextEditingController();
  final _epochDescriptionController = TextEditingController();
  final _epochPanoramaUrlController = TextEditingController();
  final _epochPanoramaAssetController = TextEditingController();
  final _epochSortOrderController = TextEditingController();
  final _arTitleController = TextEditingController();
  final _arEpochYearController = TextEditingController();
  final _arGlbUrlController = TextEditingController();
  final _arUsdzUrlController = TextEditingController();
  final _arGlbAssetController = TextEditingController();
  final _arUsdzAssetController = TextEditingController();
  final _arScaleController = TextEditingController();
  final _arPlacementController = TextEditingController();

  AdminSessionState _session = const AdminSessionState.signedOut();
  AdminObjectsResult? _objectsResult;
  AdminHeritageObject? _selectedObject;
  List<AdminEpoch> _epochs = const [];
  AdminEpoch? _selectedEpoch;
  List<AdminArAsset> _arAssets = const [];
  AdminArAsset? _selectedArAsset;
  bool _published = false;
  bool _epochPublished = false;
  bool _arPublished = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isImporting = false;
  bool _isLoadingEpochs = false;
  bool _isSavingEpoch = false;
  bool _isDeletingEpoch = false;
  bool _isUploadingPanorama = false;
  bool _isLoadingArAssets = false;
  bool _isSavingArAsset = false;
  bool _isDeletingArAsset = false;
  bool _isUploadingArModel = false;
  bool _isDownloadingQr = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _idController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _centuryController.dispose();
    _architectureController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    _epochYearController.dispose();
    _epochLabelController.dispose();
    _epochDescriptionController.dispose();
    _epochPanoramaUrlController.dispose();
    _epochPanoramaAssetController.dispose();
    _epochSortOrderController.dispose();
    _arTitleController.dispose();
    _arEpochYearController.dispose();
    _arGlbUrlController.dispose();
    _arUsdzUrlController.dispose();
    _arGlbAssetController.dispose();
    _arUsdzAssetController.dispose();
    _arScaleController.dispose();
    _arPlacementController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final session = await _repository.loadSessionState();
    final objects = await _repository.loadObjects();

    if (!mounted) return;
    setState(() {
      _session = session;
      _objectsResult = objects;
      _isLoading = false;
    });

    if (_selectedObject == null && objects.objects.isNotEmpty) {
      _selectObject(objects.objects.first);
    }
  }

  Future<void> _signIn() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _statusMessage = 'Введите email и пароль.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await _repository.signIn(email: email, password: password);
      await _reload();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'Не удалось войти в админку.';
      });
    }
  }

  Future<void> _signOut() async {
    await _repository.signOut();
    if (!mounted) return;
    setState(() {
      _selectedObject = null;
      _epochs = const [];
      _selectedEpoch = null;
      _arAssets = const [];
      _selectedArAsset = null;
      _statusMessage = null;
    });
    _clearEpochForm();
    _clearArAssetForm();
    await _reload();
  }

  void _selectObject(AdminHeritageObject object) {
    _selectedObject = object;
    _idController.text = object.id;
    _nameController.text = object.name;
    _addressController.text = object.address;
    _centuryController.text = object.century;
    _architectureController.text = object.architectureType;
    _latitudeController.text = object.latitude.toString();
    _longitudeController.text = object.longitude.toString();
    _descriptionController.text = object.shortDescription;
    _published = object.published;
    _epochs = const [];
    _selectedEpoch = null;
    _arAssets = const [];
    _selectedArAsset = null;
    _clearEpochForm();
    _clearArAssetForm();
    setState(() {});

    if (_session.schemaReady && !object.isLocalFallback) {
      _loadEpochs(object.id);
      _loadArAssets(object.id);
    }
  }

  void _startNewObject() {
    _selectedObject = null;
    _idController.clear();
    _nameController.clear();
    _addressController.clear();
    _centuryController.clear();
    _architectureController.clear();
    _latitudeController.text = '0';
    _longitudeController.text = '0';
    _descriptionController.clear();
    _published = false;
    _epochs = const [];
    _selectedEpoch = null;
    _arAssets = const [];
    _selectedArAsset = null;
    _clearEpochForm();
    _clearArAssetForm();
    setState(() {});
  }

  Future<void> _saveObject() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    final object = AdminHeritageObject(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      century: _centuryController.text.trim(),
      architectureType: _architectureController.text.trim(),
      latitude: double.tryParse(_latitudeController.text.trim()) ?? 0,
      longitude: double.tryParse(_longitudeController.text.trim()) ?? 0,
      shortDescription: _descriptionController.text.trim(),
      published: _published,
    );

    final result = await _repository.upsertObject(object);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _statusMessage = result.message;
    });

    if (result.success) {
      _selectObject(object);
      await _reload();
    }
  }

  Future<void> _importLocalObjects() async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
      _statusMessage = null;
    });

    final result = await _repository.importLocalObjects();
    if (!mounted) return;

    setState(() {
      _isImporting = false;
      _statusMessage = result.message;
      if (result.success) _selectedObject = null;
    });

    if (result.success) {
      await _reload();
    }
  }

  Future<void> _loadEpochs(String objectId, {String? preferredYear}) async {
    if (!_session.schemaReady || objectId.trim().isEmpty) return;

    setState(() {
      _isLoadingEpochs = true;
    });

    final result = await _repository.loadEpochs(objectId);
    if (!mounted) return;

    final nextEpoch = result.success
        ? _pickEpoch(result.epochs, preferredYear: preferredYear)
        : null;
    _fillEpochForm(nextEpoch);

    setState(() {
      _isLoadingEpochs = false;
      _epochs = result.success ? result.epochs : const [];
      _selectedEpoch = nextEpoch;
      if (!result.success) _statusMessage = result.message;
    });
  }

  Future<void> _loadArAssets(String objectId, {String? preferredTitle}) async {
    if (!_session.schemaReady || objectId.trim().isEmpty) return;

    setState(() {
      _isLoadingArAssets = true;
    });

    final result = await _repository.loadArAssets(objectId);
    if (!mounted) return;

    final nextAsset = result.success
        ? _pickArAsset(result.assets, preferredTitle: preferredTitle)
        : null;
    _fillArAssetForm(nextAsset);

    setState(() {
      _isLoadingArAssets = false;
      _arAssets = result.success ? result.assets : const [];
      _selectedArAsset = nextAsset;
      if (!result.success) _statusMessage = result.message;
    });
  }

  AdminEpoch? _pickEpoch(List<AdminEpoch> epochs, {String? preferredYear}) {
    if (epochs.isEmpty) return null;

    final selectedId = _selectedEpoch?.id;
    if (selectedId != null) {
      for (final epoch in epochs) {
        if (epoch.id == selectedId) return epoch;
      }
    }

    final cleanPreferredYear = preferredYear?.trim();
    if (cleanPreferredYear != null && cleanPreferredYear.isNotEmpty) {
      for (final epoch in epochs) {
        if (epoch.year.trim() == cleanPreferredYear) return epoch;
      }
    }

    return epochs.first;
  }

  AdminArAsset? _pickArAsset(
    List<AdminArAsset> assets, {
    String? preferredTitle,
  }) {
    if (assets.isEmpty) return null;

    final selectedId = _selectedArAsset?.id;
    if (selectedId != null) {
      for (final asset in assets) {
        if (asset.id == selectedId) return asset;
      }
    }

    final cleanPreferredTitle = preferredTitle?.trim();
    if (cleanPreferredTitle != null && cleanPreferredTitle.isNotEmpty) {
      for (final asset in assets) {
        if (asset.title.trim() == cleanPreferredTitle) return asset;
      }
    }

    return assets.first;
  }

  void _selectEpoch(AdminEpoch epoch) {
    _fillEpochForm(epoch);
    setState(() => _selectedEpoch = epoch);
  }

  void _selectArAsset(AdminArAsset asset) {
    _fillArAssetForm(asset);
    setState(() => _selectedArAsset = asset);
  }

  void _startNewEpoch() {
    final objectId = _currentObjectId;
    if (objectId.isEmpty) {
      setState(() {
        _statusMessage = 'Сначала сохраните объект, потом добавляйте эпохи.';
      });
      return;
    }

    _selectedEpoch = null;
    _clearEpochForm();
    _epochSortOrderController.text = (_epochs.length * 10).toString();
    _epochPublished = true;
    setState(() {});
  }

  void _startNewArAsset() {
    final objectId = _currentObjectId;
    if (objectId.isEmpty) {
      setState(() {
        _statusMessage =
            'Сначала сохраните объект, потом добавляйте 3D/AR ассеты.';
      });
      return;
    }

    _selectedArAsset = null;
    _clearArAssetForm();
    _arTitleController.text = _arAssets.isEmpty
        ? '${objectId}_default'
        : '${objectId}_model_${_arAssets.length + 1}';
    _arEpochYearController.text = _selectedEpoch?.year ?? '';
    _arPublished = true;
    setState(() {});
  }

  Future<void> _saveEpoch() async {
    if (_isSavingEpoch || !_canEdit) return;

    final object = _selectedObject;
    if (object == null || object.isLocalFallback) {
      setState(() {
        _statusMessage = 'Сначала сохраните объект в Supabase.';
      });
      return;
    }

    final year = _epochYearController.text.trim();
    if (year.isEmpty) {
      setState(() => _statusMessage = 'Укажите год или период эпохи.');
      return;
    }

    setState(() {
      _isSavingEpoch = true;
      _statusMessage = null;
    });

    final epoch = AdminEpoch(
      id: _selectedEpoch?.id,
      objectId: object.id,
      year: year,
      label: _epochLabelController.text.trim(),
      description: _epochDescriptionController.text.trim(),
      panoramaUrl: _epochPanoramaUrlController.text.trim(),
      panoramaAssetPath: _epochPanoramaAssetController.text.trim(),
      sortOrder:
          int.tryParse(_epochSortOrderController.text.trim()) ??
          _parseYearForSort(year),
      published: _epochPublished,
    );

    final result = await _repository.upsertEpoch(epoch);
    if (!mounted) return;

    setState(() {
      _isSavingEpoch = false;
      _statusMessage = result.message;
    });

    if (result.success) {
      await _loadEpochs(object.id, preferredYear: epoch.year);
    }
  }

  Future<void> _saveArAsset() async {
    if (_isSavingArAsset || !_canEdit) return;

    final object = _selectedObject;
    if (object == null || object.isLocalFallback) {
      setState(() {
        _statusMessage = 'Сначала сохраните объект в Supabase.';
      });
      return;
    }

    final title = _arTitleController.text.trim();
    if (title.isEmpty) {
      setState(() => _statusMessage = 'Укажите название 3D/AR ассета.');
      return;
    }

    final scale = double.tryParse(_arScaleController.text.trim()) ?? 1.0;
    final asset = AdminArAsset(
      id: _selectedArAsset?.id,
      objectId: object.id,
      title: title,
      epochYear: _arEpochYearController.text.trim(),
      glbUrl: _arGlbUrlController.text.trim(),
      usdzUrl: _arUsdzUrlController.text.trim(),
      glbAssetPath: _arGlbAssetController.text.trim(),
      usdzAssetPath: _arUsdzAssetController.text.trim(),
      scale: scale,
      placement: _arPlacementController.text.trim().isEmpty
          ? 'plane'
          : _arPlacementController.text.trim(),
      published: _arPublished,
    );

    setState(() {
      _isSavingArAsset = true;
      _statusMessage = null;
    });

    final result = await _repository.upsertArAsset(asset);
    if (!mounted) return;

    setState(() {
      _isSavingArAsset = false;
      _statusMessage = result.message;
    });

    if (result.success) {
      await _loadArAssets(object.id, preferredTitle: asset.title);
    }
  }

  Future<void> _deleteEpoch() async {
    final epoch = _selectedEpoch;
    final object = _selectedObject;
    if (_isDeletingEpoch || !_canEdit || epoch == null || object == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить эпоху?'),
        content: Text(
          'Эпоха "${epoch.displayTitle}" будет удалена из Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.whiteText,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isDeletingEpoch = true;
      _statusMessage = null;
    });

    final result = await _repository.deleteEpoch(epoch);
    if (!mounted) return;

    setState(() {
      _isDeletingEpoch = false;
      _statusMessage = result.message;
    });

    if (result.success) {
      await _loadEpochs(object.id);
    }
  }

  Future<void> _deleteArAsset() async {
    final asset = _selectedArAsset;
    final object = _selectedObject;
    if (_isDeletingArAsset || !_canEdit || asset == null || object == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить 3D/AR ассет?'),
        content: Text(
          'Ассет "${asset.displayTitle}" будет удален из Supabase. Файл в Storage не удаляется автоматически.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.whiteText,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isDeletingArAsset = true;
      _statusMessage = null;
    });

    final result = await _repository.deleteArAsset(asset);
    if (!mounted) return;

    setState(() {
      _isDeletingArAsset = false;
      _statusMessage = result.message;
    });

    if (result.success) {
      await _loadArAssets(object.id);
    }
  }

  Future<void> _uploadPanorama() async {
    if (_isUploadingPanorama || !_canEdit) return;

    final object = _selectedObject;
    if (object == null || object.isLocalFallback) {
      setState(() {
        _statusMessage = 'Сначала сохраните объект в Supabase.';
      });
      return;
    }

    final year = _epochYearController.text.trim();
    if (year.isEmpty) {
      setState(() {
        _statusMessage = 'Перед загрузкой панорамы заполните год или период.';
      });
      return;
    }

    final picked = await AdminMediaPicker.pickImage();
    if (!mounted || picked == null) return;

    setState(() {
      _isUploadingPanorama = true;
      _statusMessage = null;
    });

    final result = await _repository.uploadPanorama(
      objectId: object.id,
      year: year,
      fileName: picked.name,
      bytes: picked.bytes,
      contentType: picked.mimeType,
    );
    if (!mounted) return;

    if (result.success && result.publicUrl != null) {
      _epochPanoramaUrlController.text = result.publicUrl!;
    }

    setState(() {
      _isUploadingPanorama = false;
      _statusMessage = result.success
          ? '${result.message} Ссылка добавлена в panorama_url, сохраните эпоху.'
          : result.message;
    });
  }

  Future<void> _uploadArModel() async {
    if (_isUploadingArModel || !_canEdit) return;

    final object = _selectedObject;
    if (object == null || object.isLocalFallback) {
      setState(() {
        _statusMessage = 'Сначала сохраните объект в Supabase.';
      });
      return;
    }

    final picked = await AdminMediaPicker.pickFile(
      accept:
          '.glb,.usdz,model/gltf-binary,model/vnd.usdz+zip,application/octet-stream',
    );
    if (!mounted || picked == null) return;

    final lowerName = picked.name.toLowerCase();
    if (!lowerName.endsWith('.glb') && !lowerName.endsWith('.usdz')) {
      setState(() {
        _statusMessage = 'Выберите модель в формате .glb или .usdz.';
      });
      return;
    }

    setState(() {
      _isUploadingArModel = true;
      _statusMessage = null;
    });

    final result = await _repository.uploadArModel(
      objectId: object.id,
      fileName: picked.name,
      bytes: picked.bytes,
      contentType: picked.mimeType,
    );
    if (!mounted) return;

    if (result.success && result.publicUrl != null) {
      if (lowerName.endsWith('.usdz')) {
        _arUsdzUrlController.text = result.publicUrl!;
        _arUsdzAssetController.clear();
      } else {
        _arGlbUrlController.text = result.publicUrl!;
        _arGlbAssetController.clear();
      }
      if (_arTitleController.text.trim().isEmpty) {
        _arTitleController.text = _arAssets.isEmpty
            ? '${object.id}_default'
            : '${object.id}_model_${_arAssets.length + 1}';
      }
      _arPublished = true;
    }

    setState(() {
      _isUploadingArModel = false;
      _statusMessage = result.success
          ? '${result.message} Ссылка добавлена в поле модели, сохраните 3D/AR ассет.'
          : result.message;
    });
  }

  void _fillEpochForm(AdminEpoch? epoch) {
    if (epoch == null) {
      _clearEpochForm();
      return;
    }

    _epochYearController.text = epoch.year;
    _epochLabelController.text = epoch.label;
    _epochDescriptionController.text = epoch.description;
    _epochPanoramaUrlController.text = epoch.panoramaUrl ?? '';
    _epochPanoramaAssetController.text = epoch.panoramaAssetPath ?? '';
    _epochSortOrderController.text = epoch.sortOrder.toString();
    _epochPublished = epoch.published;
  }

  void _clearEpochForm() {
    _epochYearController.clear();
    _epochLabelController.clear();
    _epochDescriptionController.clear();
    _epochPanoramaUrlController.clear();
    _epochPanoramaAssetController.clear();
    _epochSortOrderController.text = '0';
    _epochPublished = false;
  }

  void _fillArAssetForm(AdminArAsset? asset) {
    if (asset == null) {
      _clearArAssetForm();
      return;
    }

    _arTitleController.text = asset.title;
    _arEpochYearController.text = asset.epochYear ?? '';
    _arGlbUrlController.text = asset.glbUrl ?? '';
    _arUsdzUrlController.text = asset.usdzUrl ?? '';
    _arGlbAssetController.text = asset.glbAssetPath ?? '';
    _arUsdzAssetController.text = asset.usdzAssetPath ?? '';
    _arScaleController.text = asset.scale.toString();
    _arPlacementController.text = asset.placement;
    _arPublished = asset.published;
  }

  void _clearArAssetForm() {
    _arTitleController.clear();
    _arEpochYearController.clear();
    _arGlbUrlController.clear();
    _arUsdzUrlController.clear();
    _arGlbAssetController.clear();
    _arUsdzAssetController.clear();
    _arScaleController.text = '1.0';
    _arPlacementController.text = 'plane';
    _arPublished = false;
  }

  Future<void> _copyQrPayload() async {
    final payload = _qrPayload;
    if (payload == null) return;

    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    setState(() => _statusMessage = 'QR payload скопирован: $payload');
  }

  Future<void> _downloadQrPng() async {
    final payload = _qrPayload;
    final objectId = _idController.text.trim();
    if (payload == null || objectId.isEmpty || _isDownloadingQr) return;

    setState(() {
      _isDownloadingQr = true;
      _statusMessage = null;
    });

    try {
      final painter = QrPainter(
        data: payload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
      );
      final imageData = await painter.toImageData(
        1200,
        format: ui.ImageByteFormat.png,
      );

      if (imageData == null) {
        throw StateError('QR PNG не был создан.');
      }

      final bytes = imageData.buffer.asUint8List();
      final downloaded = await AdminQrDownloader.downloadPng(
        bytes: bytes,
        objectId: objectId,
      );

      if (!mounted) return;
      setState(() {
        _statusMessage = downloaded
            ? 'QR PNG скачан: ${AdminQrDownloader.fileNameForObjectId(objectId)}'
            : 'QR PNG создан. Автоматическое скачивание доступно в web-админке.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Не удалось сгенерировать QR PNG. Ошибка: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isDownloadingQr = false);
      }
    }
  }

  String? get _qrPayload {
    final id = _idController.text.trim();
    if (id.isEmpty) return null;
    return 'retroar://object/$id';
  }

  bool get _canEdit => _session.isAdmin && _session.schemaReady;

  String get _currentObjectId =>
      _selectedObject?.id ?? _idController.text.trim();

  int _parseYearForSort(String year) {
    final match = RegExp(r'(\d{4})').firstMatch(year);
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              )
            : _session.isAuthenticated
            ? _buildAdminShell(context)
            : _AdminLoginPanel(
                emailController: _loginEmailController,
                passwordController: _loginPasswordController,
                statusMessage: _statusMessage,
                onSignIn: _signIn,
              ),
      ),
    );
  }

  Widget _buildAdminShell(BuildContext context) {
    final objectsResult = _objectsResult;
    final objects = objectsResult?.objects ?? const <AdminHeritageObject>[];

    return Column(
      children: [
        _AdminTopBar(
          email: _session.email ?? '',
          role: _session.role,
          onReload: _reload,
          onSignOut: _signOut,
        ),
        if (_session.message != null || objectsResult?.message != null)
          _AdminStatusBanner(
            message: _session.message ?? objectsResult!.message!,
            isBlocking: !_canEdit,
          ),
        if (_statusMessage != null)
          _AdminStatusBanner(message: _statusMessage!, isBlocking: false),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final list = _ObjectsList(
                objects: objects,
                selectedId: _selectedObject?.id,
                canImport: _canEdit,
                isImporting: _isImporting,
                onSelect: _selectObject,
                onCreate: _startNewObject,
                onImport: _importLocalObjects,
              );
              final editor = _ObjectEditor(
                formKey: _formKey,
                canEdit: _canEdit,
                isSaving: _isSaving,
                isLocalFallback: _selectedObject?.isLocalFallback == true,
                idController: _idController,
                nameController: _nameController,
                addressController: _addressController,
                centuryController: _centuryController,
                architectureController: _architectureController,
                latitudeController: _latitudeController,
                longitudeController: _longitudeController,
                descriptionController: _descriptionController,
                published: _published,
                qrPayload: _qrPayload,
                isDownloadingQr: _isDownloadingQr,
                epochs: _epochs,
                selectedEpoch: _selectedEpoch,
                arAssets: _arAssets,
                selectedArAsset: _selectedArAsset,
                epochYearController: _epochYearController,
                epochLabelController: _epochLabelController,
                epochDescriptionController: _epochDescriptionController,
                epochPanoramaUrlController: _epochPanoramaUrlController,
                epochPanoramaAssetController: _epochPanoramaAssetController,
                epochSortOrderController: _epochSortOrderController,
                arTitleController: _arTitleController,
                arEpochYearController: _arEpochYearController,
                arGlbUrlController: _arGlbUrlController,
                arUsdzUrlController: _arUsdzUrlController,
                arGlbAssetController: _arGlbAssetController,
                arUsdzAssetController: _arUsdzAssetController,
                arScaleController: _arScaleController,
                arPlacementController: _arPlacementController,
                epochPublished: _epochPublished,
                arPublished: _arPublished,
                isLoadingEpochs: _isLoadingEpochs,
                isSavingEpoch: _isSavingEpoch,
                isDeletingEpoch: _isDeletingEpoch,
                isUploadingPanorama: _isUploadingPanorama,
                isLoadingArAssets: _isLoadingArAssets,
                isSavingArAsset: _isSavingArAsset,
                isDeletingArAsset: _isDeletingArAsset,
                isUploadingArModel: _isUploadingArModel,
                onPublishedChanged: (value) =>
                    setState(() => _published = value),
                onEpochPublishedChanged: (value) =>
                    setState(() => _epochPublished = value),
                onArPublishedChanged: (value) =>
                    setState(() => _arPublished = value),
                onSave: _saveObject,
                onCopyQrPayload: _copyQrPayload,
                onDownloadQrPng: _downloadQrPng,
                onSelectEpoch: _selectEpoch,
                onSelectArAsset: _selectArAsset,
                onCreateEpoch: _startNewEpoch,
                onCreateArAsset: _startNewArAsset,
                onSaveEpoch: _saveEpoch,
                onSaveArAsset: _saveArAsset,
                onDeleteEpoch: _deleteEpoch,
                onDeleteArAsset: _deleteArAsset,
                onUploadPanorama: _uploadPanorama,
                onUploadArModel: _uploadArModel,
              );

              if (isWide) {
                return Row(
                  children: [
                    SizedBox(width: 360, child: list),
                    const VerticalDivider(width: 1),
                    Expanded(child: editor),
                  ],
                );
              }

              return ListView(
                children: [
                  SizedBox(height: 390, child: list),
                  const Divider(height: 1),
                  SizedBox(height: 2300, child: editor),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminLoginPanel extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? statusMessage;
  final VoidCallback onSignIn;

  const _AdminLoginPanel({
    required this.emailController,
    required this.passwordController,
    required this.statusMessage,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2D2D2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'АРхив admin',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    onSubmitted: (_) => onSignIn(),
                  ),
                  if (statusMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      statusMessage!,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Войти'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.whiteText,
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
}

class _AdminTopBar extends StatelessWidget {
  final String email;
  final String? role;
  final VoidCallback onReload;
  final VoidCallback onSignOut;

  const _AdminTopBar({
    required this.email,
    required this.role,
    required this.onReload,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: AppColors.primaryRed,
      child: Row(
        children: [
          const Expanded(
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.whiteText),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'АРхив admin',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      role == null ? email : '$email · $role',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Обновить',
                    onPressed: onReload,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh, color: AppColors.whiteText),
                  ),
                  TextButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Выйти'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.whiteText,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatusBanner extends StatelessWidget {
  final String message;
  final bool isBlocking;

  const _AdminStatusBanner({required this.message, required this.isBlocking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: isBlocking ? const Color(0xFFFFE4D8) : const Color(0xFFE6F4EA),
      child: Text(
        message,
        style: TextStyle(
          color: isBlocking ? AppColors.primaryRed : const Color(0xFF146C2E),
          fontWeight: FontWeight.w800,
          fontSize: 12,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}

class _ObjectsList extends StatelessWidget {
  final List<AdminHeritageObject> objects;
  final String? selectedId;
  final bool canImport;
  final bool isImporting;
  final ValueChanged<AdminHeritageObject> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onImport;

  const _ObjectsList({
    required this.objects,
    required this.selectedId,
    required this.canImport,
    required this.isImporting,
    required this.onSelect,
    required this.onCreate,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Объекты',
                    style: TextStyle(
                      color: AppColors.blueText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                if (canImport) ...[
                  IconButton.outlined(
                    tooltip: 'Импортировать локальный JSON',
                    onPressed: isImporting ? null : onImport,
                    icon: isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton.filled(
                  tooltip: 'Создать объект',
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: AppColors.whiteText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: objects.isEmpty
                ? const Center(child: Text('Нет объектов'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    itemCount: objects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final object = objects[index];
                      final isSelected = object.id == selectedId;

                      return _ObjectListTile(
                        object: object,
                        isSelected: isSelected,
                        onTap: () => onSelect(object),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ObjectListTile extends StatelessWidget {
  final AdminHeritageObject object;
  final bool isSelected;
  final VoidCallback onTap;

  const _ObjectListTile({
    required this.object,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFFFF3EF) : const Color(0xFFF8F4EF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryRed
                  : const Color(0xFFE5D8D2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      object.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  Icon(
                    object.published ? Icons.public : Icons.edit_note,
                    size: 18,
                    color: object.published
                        ? const Color(0xFF146C2E)
                        : AppColors.darkPink,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                object.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (object.isLocalFallback) ...[
                const SizedBox(height: 4),
                const Text(
                  'local JSON',
                  style: TextStyle(
                    color: AppColors.darkPink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ObjectEditor extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool canEdit;
  final bool isSaving;
  final bool isLocalFallback;
  final TextEditingController idController;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController centuryController;
  final TextEditingController architectureController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController descriptionController;
  final bool published;
  final String? qrPayload;
  final bool isDownloadingQr;
  final List<AdminEpoch> epochs;
  final AdminEpoch? selectedEpoch;
  final List<AdminArAsset> arAssets;
  final AdminArAsset? selectedArAsset;
  final TextEditingController epochYearController;
  final TextEditingController epochLabelController;
  final TextEditingController epochDescriptionController;
  final TextEditingController epochPanoramaUrlController;
  final TextEditingController epochPanoramaAssetController;
  final TextEditingController epochSortOrderController;
  final TextEditingController arTitleController;
  final TextEditingController arEpochYearController;
  final TextEditingController arGlbUrlController;
  final TextEditingController arUsdzUrlController;
  final TextEditingController arGlbAssetController;
  final TextEditingController arUsdzAssetController;
  final TextEditingController arScaleController;
  final TextEditingController arPlacementController;
  final bool epochPublished;
  final bool arPublished;
  final bool isLoadingEpochs;
  final bool isSavingEpoch;
  final bool isDeletingEpoch;
  final bool isUploadingPanorama;
  final bool isLoadingArAssets;
  final bool isSavingArAsset;
  final bool isDeletingArAsset;
  final bool isUploadingArModel;
  final ValueChanged<bool> onPublishedChanged;
  final ValueChanged<bool> onEpochPublishedChanged;
  final ValueChanged<bool> onArPublishedChanged;
  final VoidCallback onSave;
  final VoidCallback onCopyQrPayload;
  final VoidCallback onDownloadQrPng;
  final ValueChanged<AdminEpoch> onSelectEpoch;
  final ValueChanged<AdminArAsset> onSelectArAsset;
  final VoidCallback onCreateEpoch;
  final VoidCallback onCreateArAsset;
  final VoidCallback onSaveEpoch;
  final VoidCallback onSaveArAsset;
  final VoidCallback onDeleteEpoch;
  final VoidCallback onDeleteArAsset;
  final VoidCallback onUploadPanorama;
  final VoidCallback onUploadArModel;

  const _ObjectEditor({
    required this.formKey,
    required this.canEdit,
    required this.isSaving,
    required this.isLocalFallback,
    required this.idController,
    required this.nameController,
    required this.addressController,
    required this.centuryController,
    required this.architectureController,
    required this.latitudeController,
    required this.longitudeController,
    required this.descriptionController,
    required this.published,
    required this.qrPayload,
    required this.isDownloadingQr,
    required this.epochs,
    required this.selectedEpoch,
    required this.arAssets,
    required this.selectedArAsset,
    required this.epochYearController,
    required this.epochLabelController,
    required this.epochDescriptionController,
    required this.epochPanoramaUrlController,
    required this.epochPanoramaAssetController,
    required this.epochSortOrderController,
    required this.arTitleController,
    required this.arEpochYearController,
    required this.arGlbUrlController,
    required this.arUsdzUrlController,
    required this.arGlbAssetController,
    required this.arUsdzAssetController,
    required this.arScaleController,
    required this.arPlacementController,
    required this.epochPublished,
    required this.arPublished,
    required this.isLoadingEpochs,
    required this.isSavingEpoch,
    required this.isDeletingEpoch,
    required this.isUploadingPanorama,
    required this.isLoadingArAssets,
    required this.isSavingArAsset,
    required this.isDeletingArAsset,
    required this.isUploadingArModel,
    required this.onPublishedChanged,
    required this.onEpochPublishedChanged,
    required this.onArPublishedChanged,
    required this.onSave,
    required this.onCopyQrPayload,
    required this.onDownloadQrPng,
    required this.onSelectEpoch,
    required this.onSelectArAsset,
    required this.onCreateEpoch,
    required this.onCreateArAsset,
    required this.onSaveEpoch,
    required this.onSaveArAsset,
    required this.onDeleteEpoch,
    required this.onDeleteArAsset,
    required this.onUploadPanorama,
    required this.onUploadArModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F1EA),
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Карточка объекта',
                    style: TextStyle(
                      color: AppColors.blueText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: canEdit && !isSaving ? onSave : null,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSaving ? 'Сохраняем' : 'Сохранить'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: AppColors.whiteText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLocalFallback)
              const _InlineNotice(
                text:
                    'Этот объект загружен из локального JSON. После применения SQL-схемы его можно будет перенести в Supabase.',
              ),
            _AdminTextField(
              controller: idController,
              label: 'Object ID',
              enabled: canEdit,
              validator: _requiredSlug,
            ),
            _AdminTextField(
              controller: nameController,
              label: 'Название',
              enabled: canEdit,
              validator: _required,
            ),
            _AdminTextField(
              controller: addressController,
              label: 'Адрес',
              enabled: canEdit,
            ),
            Row(
              children: [
                Expanded(
                  child: _AdminTextField(
                    controller: centuryController,
                    label: 'Век',
                    enabled: canEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: architectureController,
                    label: 'Тип архитектуры',
                    enabled: canEdit,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _AdminTextField(
                    controller: latitudeController,
                    label: 'Широта',
                    enabled: canEdit,
                    keyboardType: TextInputType.number,
                    validator: _number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminTextField(
                    controller: longitudeController,
                    label: 'Долгота',
                    enabled: canEdit,
                    keyboardType: TextInputType.number,
                    validator: _number,
                  ),
                ),
              ],
            ),
            _AdminTextField(
              controller: descriptionController,
              label: 'Краткое описание',
              enabled: canEdit,
              maxLines: 5,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              value: published,
              onChanged: canEdit ? onPublishedChanged : null,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryRed,
              title: const Text(
                'Опубликован',
                style: TextStyle(
                  color: AppColors.blueText,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            const SizedBox(height: 10),
            _QrPayloadBox(
              payload: qrPayload,
              onCopy: qrPayload == null ? null : onCopyQrPayload,
              onDownload: qrPayload == null ? null : onDownloadQrPng,
              isDownloading: isDownloadingQr,
            ),
            const SizedBox(height: 14),
            _EpochsSection(
              canEdit: canEdit && !isLocalFallback,
              epochs: epochs,
              selectedEpoch: selectedEpoch,
              yearController: epochYearController,
              labelController: epochLabelController,
              descriptionController: epochDescriptionController,
              panoramaUrlController: epochPanoramaUrlController,
              panoramaAssetController: epochPanoramaAssetController,
              sortOrderController: epochSortOrderController,
              published: epochPublished,
              isLoading: isLoadingEpochs,
              isSaving: isSavingEpoch,
              isDeleting: isDeletingEpoch,
              isUploading: isUploadingPanorama,
              onPublishedChanged: onEpochPublishedChanged,
              onSelect: onSelectEpoch,
              onCreate: onCreateEpoch,
              onSave: onSaveEpoch,
              onDelete: onDeleteEpoch,
              onUploadPanorama: onUploadPanorama,
            ),
            const SizedBox(height: 14),
            _ArAssetsSection(
              canEdit: canEdit && !isLocalFallback,
              assets: arAssets,
              epochs: epochs,
              selectedAsset: selectedArAsset,
              titleController: arTitleController,
              epochYearController: arEpochYearController,
              glbUrlController: arGlbUrlController,
              usdzUrlController: arUsdzUrlController,
              glbAssetController: arGlbAssetController,
              usdzAssetController: arUsdzAssetController,
              scaleController: arScaleController,
              placementController: arPlacementController,
              published: arPublished,
              isLoading: isLoadingArAssets,
              isSaving: isSavingArAsset,
              isDeleting: isDeletingArAsset,
              isUploading: isUploadingArModel,
              onPublishedChanged: onArPublishedChanged,
              onSelect: onSelectArAsset,
              onCreate: onCreateArAsset,
              onSave: onSaveArAsset,
              onDelete: onDeleteArAsset,
              onUploadModel: onUploadArModel,
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Обязательное поле';
    return null;
  }

  static String? _requiredSlug(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Обязательное поле';
    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(text)) {
      return 'Только латиница, цифры, _ и -';
    }
    return null;
  }

  static String? _number(String? value) {
    if (double.tryParse(value?.trim() ?? '') == null) return 'Нужно число';
    return null;
  }
}

class _EpochsSection extends StatelessWidget {
  final bool canEdit;
  final List<AdminEpoch> epochs;
  final AdminEpoch? selectedEpoch;
  final TextEditingController yearController;
  final TextEditingController labelController;
  final TextEditingController descriptionController;
  final TextEditingController panoramaUrlController;
  final TextEditingController panoramaAssetController;
  final TextEditingController sortOrderController;
  final bool published;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final bool isUploading;
  final ValueChanged<bool> onPublishedChanged;
  final ValueChanged<AdminEpoch> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onUploadPanorama;

  const _EpochsSection({
    required this.canEdit,
    required this.epochs,
    required this.selectedEpoch,
    required this.yearController,
    required this.labelController,
    required this.descriptionController,
    required this.panoramaUrlController,
    required this.panoramaAssetController,
    required this.sortOrderController,
    required this.published,
    required this.isLoading,
    required this.isSaving,
    required this.isDeleting,
    required this.isUploading,
    required this.onPublishedChanged,
    required this.onSelect,
    required this.onCreate,
    required this.onSave,
    required this.onDelete,
    required this.onUploadPanorama,
  });

  @override
  Widget build(BuildContext context) {
    final selectedKey = selectedEpoch?.id ?? selectedEpoch?.year;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7C3BE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Эпохи и панорамы',
                  style: TextStyle(
                    color: AppColors.blueText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Добавить эпоху',
                onPressed: canEdit ? onCreate : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: AppColors.whiteText,
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(color: AppColors.primaryRed),
          ],
          if (!canEdit) ...[
            const SizedBox(height: 10),
            const _InlineNotice(
              text:
                  'Эпохи можно редактировать после сохранения объекта в Supabase и входа под активным администратором.',
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final list = _EpochList(
                epochs: epochs,
                selectedKey: selectedKey,
                onSelect: onSelect,
              );
              final form = _EpochForm(
                canEdit: canEdit,
                selectedEpoch: selectedEpoch,
                yearController: yearController,
                labelController: labelController,
                descriptionController: descriptionController,
                panoramaUrlController: panoramaUrlController,
                panoramaAssetController: panoramaAssetController,
                sortOrderController: sortOrderController,
                published: published,
                isSaving: isSaving,
                isDeleting: isDeleting,
                isUploading: isUploading,
                onPublishedChanged: onPublishedChanged,
                onSave: onSave,
                onDelete: onDelete,
                onUploadPanorama: onUploadPanorama,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: list),
                    const SizedBox(width: 14),
                    Expanded(child: form),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [list, const SizedBox(height: 14), form],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EpochList extends StatelessWidget {
  final List<AdminEpoch> epochs;
  final String? selectedKey;
  final ValueChanged<AdminEpoch> onSelect;

  const _EpochList({
    required this.epochs,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (epochs.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5D8D2)),
        ),
        child: const Text(
          'Эпох пока нет',
          style: TextStyle(
            color: AppColors.blueText,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: ListView.separated(
        itemCount: epochs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final epoch = epochs[index];
          final key = epoch.id ?? epoch.year;
          return _EpochListTile(
            epoch: epoch,
            isSelected: key == selectedKey,
            onTap: () => onSelect(epoch),
          );
        },
      ),
    );
  }
}

class _EpochListTile extends StatelessWidget {
  final AdminEpoch epoch;
  final bool isSelected;
  final VoidCallback onTap;

  const _EpochListTile({
    required this.epoch,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final source = epoch.panoramaSource;

    return Material(
      color: isSelected ? const Color(0xFFFFF3EF) : const Color(0xFFF8F4EF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryRed
                  : const Color(0xFFE5D8D2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      epoch.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  Icon(
                    epoch.published ? Icons.public : Icons.edit_note,
                    size: 18,
                    color: epoch.published
                        ? const Color(0xFF146C2E)
                        : AppColors.darkPink,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                epoch.year,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (source.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B5E70),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EpochForm extends StatelessWidget {
  final bool canEdit;
  final AdminEpoch? selectedEpoch;
  final TextEditingController yearController;
  final TextEditingController labelController;
  final TextEditingController descriptionController;
  final TextEditingController panoramaUrlController;
  final TextEditingController panoramaAssetController;
  final TextEditingController sortOrderController;
  final bool published;
  final bool isSaving;
  final bool isDeleting;
  final bool isUploading;
  final ValueChanged<bool> onPublishedChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onUploadPanorama;

  const _EpochForm({
    required this.canEdit,
    required this.selectedEpoch,
    required this.yearController,
    required this.labelController,
    required this.descriptionController,
    required this.panoramaUrlController,
    required this.panoramaAssetController,
    required this.sortOrderController,
    required this.published,
    required this.isSaving,
    required this.isDeleting,
    required this.isUploading,
    required this.onPublishedChanged,
    required this.onSave,
    required this.onDelete,
    required this.onUploadPanorama,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete = canEdit && selectedEpoch?.id != null && !isDeleting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _AdminTextField(
                controller: yearController,
                label: 'Год или период',
                enabled: canEdit,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: _AdminTextField(
                controller: sortOrderController,
                label: 'Порядок',
                enabled: canEdit,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        _AdminTextField(
          controller: labelController,
          label: 'Название эпохи',
          enabled: canEdit,
        ),
        _AdminTextField(
          controller: descriptionController,
          label: 'Описание эпохи',
          enabled: canEdit,
          maxLines: 4,
        ),
        _AdminTextField(
          controller: panoramaUrlController,
          label: 'panorama_url',
          enabled: canEdit,
          maxLines: 2,
        ),
        _AdminTextField(
          controller: panoramaAssetController,
          label: 'panorama_asset_path',
          enabled: canEdit,
          maxLines: 2,
        ),
        SwitchListTile(
          value: published,
          onChanged: canEdit ? onPublishedChanged : null,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primaryRed,
          title: const Text(
            'Опубликовать эпоху',
            style: TextStyle(
              color: AppColors.blueText,
              fontWeight: FontWeight.w800,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: canEdit && !isSaving ? onSave : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Сохраняем' : 'Сохранить эпоху'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.whiteText,
              ),
            ),
            OutlinedButton.icon(
              onPressed: canEdit && !isUploading ? onUploadPanorama : null,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.panorama),
              label: Text(isUploading ? 'Загружаем' : 'Загрузить панораму'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
              ),
            ),
            TextButton.icon(
              onPressed: canDelete ? onDelete : null,
              icon: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(isDeleting ? 'Удаляем' : 'Удалить'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArAssetsSection extends StatelessWidget {
  final bool canEdit;
  final List<AdminArAsset> assets;
  final List<AdminEpoch> epochs;
  final AdminArAsset? selectedAsset;
  final TextEditingController titleController;
  final TextEditingController epochYearController;
  final TextEditingController glbUrlController;
  final TextEditingController usdzUrlController;
  final TextEditingController glbAssetController;
  final TextEditingController usdzAssetController;
  final TextEditingController scaleController;
  final TextEditingController placementController;
  final bool published;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final bool isUploading;
  final ValueChanged<bool> onPublishedChanged;
  final ValueChanged<AdminArAsset> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onUploadModel;

  const _ArAssetsSection({
    required this.canEdit,
    required this.assets,
    required this.epochs,
    required this.selectedAsset,
    required this.titleController,
    required this.epochYearController,
    required this.glbUrlController,
    required this.usdzUrlController,
    required this.glbAssetController,
    required this.usdzAssetController,
    required this.scaleController,
    required this.placementController,
    required this.published,
    required this.isLoading,
    required this.isSaving,
    required this.isDeleting,
    required this.isUploading,
    required this.onPublishedChanged,
    required this.onSelect,
    required this.onCreate,
    required this.onSave,
    required this.onDelete,
    required this.onUploadModel,
  });

  @override
  Widget build(BuildContext context) {
    final selectedKey = selectedAsset?.id ?? selectedAsset?.title;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7C3BE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '3D/AR ассеты',
                  style: TextStyle(
                    color: AppColors.blueText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Добавить 3D/AR ассет',
                onPressed: canEdit ? onCreate : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: AppColors.whiteText,
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(color: AppColors.primaryRed),
          ],
          if (!canEdit) ...[
            const SizedBox(height: 10),
            const _InlineNotice(
              text:
                  '3D/AR ассеты можно редактировать после сохранения объекта в Supabase и входа под активным администратором.',
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final list = _ArAssetList(
                assets: assets,
                selectedKey: selectedKey,
                onSelect: onSelect,
              );
              final form = _ArAssetForm(
                canEdit: canEdit,
                selectedAsset: selectedAsset,
                epochs: epochs,
                titleController: titleController,
                epochYearController: epochYearController,
                glbUrlController: glbUrlController,
                usdzUrlController: usdzUrlController,
                glbAssetController: glbAssetController,
                usdzAssetController: usdzAssetController,
                scaleController: scaleController,
                placementController: placementController,
                published: published,
                isSaving: isSaving,
                isDeleting: isDeleting,
                isUploading: isUploading,
                onPublishedChanged: onPublishedChanged,
                onSave: onSave,
                onDelete: onDelete,
                onUploadModel: onUploadModel,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: list),
                    const SizedBox(width: 14),
                    Expanded(child: form),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [list, const SizedBox(height: 14), form],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ArAssetList extends StatelessWidget {
  final List<AdminArAsset> assets;
  final String? selectedKey;
  final ValueChanged<AdminArAsset> onSelect;

  const _ArAssetList({
    required this.assets,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5D8D2)),
        ),
        child: const Text(
          '3D/AR ассетов пока нет',
          style: TextStyle(
            color: AppColors.blueText,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: assets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final asset = assets[index];
          final key = asset.id ?? asset.title;
          return _ArAssetListTile(
            asset: asset,
            isSelected: key == selectedKey,
            onTap: () => onSelect(asset),
          );
        },
      ),
    );
  }
}

class _ArAssetListTile extends StatelessWidget {
  final AdminArAsset asset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArAssetListTile({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final source = asset.modelSource;
    final epochYear = asset.epochYear?.trim();
    final epochLabel = epochYear == null || epochYear.isEmpty
        ? 'all-epochs'
        : epochYear;

    return Material(
      color: isSelected ? const Color(0xFFFFF3EF) : const Color(0xFFF8F4EF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryRed
                  : const Color(0xFFE5D8D2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.view_in_ar,
                    size: 18,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  Icon(
                    asset.published ? Icons.public : Icons.edit_note,
                    size: 18,
                    color: asset.published
                        ? const Color(0xFF146C2E)
                        : AppColors.darkPink,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$epochLabel · ${asset.placement} · scale ${asset.scale}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (source.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B5E70),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArAssetForm extends StatelessWidget {
  static const _placements = ['plane', 'wall', 'marker', 'world'];

  final bool canEdit;
  final AdminArAsset? selectedAsset;
  final List<AdminEpoch> epochs;
  final TextEditingController titleController;
  final TextEditingController epochYearController;
  final TextEditingController glbUrlController;
  final TextEditingController usdzUrlController;
  final TextEditingController glbAssetController;
  final TextEditingController usdzAssetController;
  final TextEditingController scaleController;
  final TextEditingController placementController;
  final bool published;
  final bool isSaving;
  final bool isDeleting;
  final bool isUploading;
  final ValueChanged<bool> onPublishedChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onUploadModel;

  const _ArAssetForm({
    required this.canEdit,
    required this.selectedAsset,
    required this.epochs,
    required this.titleController,
    required this.epochYearController,
    required this.glbUrlController,
    required this.usdzUrlController,
    required this.glbAssetController,
    required this.usdzAssetController,
    required this.scaleController,
    required this.placementController,
    required this.published,
    required this.isSaving,
    required this.isDeleting,
    required this.isUploading,
    required this.onPublishedChanged,
    required this.onSave,
    required this.onDelete,
    required this.onUploadModel,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete = canEdit && selectedAsset?.id != null && !isDeleting;
    final placement = _placements.contains(placementController.text.trim())
        ? placementController.text.trim()
        : 'plane';
    final epochOptions = <String>[
      '',
      ...epochs
          .map((epoch) => epoch.year.trim())
          .where((year) => year.isNotEmpty),
    ];
    final currentEpochYear = epochYearController.text.trim();
    if (currentEpochYear.isNotEmpty &&
        !epochOptions.contains(currentEpochYear)) {
      epochOptions.add(currentEpochYear);
    }
    final selectedEpochYear = epochOptions.contains(currentEpochYear)
        ? currentEpochYear
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _AdminTextField(
                controller: titleController,
                label: 'Название ассета',
                enabled: canEdit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedEpochYear,
                  items: epochOptions
                      .map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.isEmpty ? 'Все эпохи' : year),
                        ),
                      )
                      .toList(),
                  onChanged: canEdit
                      ? (value) {
                          epochYearController.text = value ?? '';
                        }
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Эпоха модели',
                    filled: true,
                    fillColor: canEdit ? Colors.white : const Color(0xFFE9E1DE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD7C3BE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD7C3BE)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _AdminTextField(
          controller: glbUrlController,
          label: 'glb_url из Supabase Storage',
          enabled: canEdit,
          maxLines: 2,
        ),
        _AdminTextField(
          controller: usdzUrlController,
          label: 'usdz_url из Supabase Storage',
          enabled: canEdit,
          maxLines: 2,
        ),
        _LegacyArAssetFields(
          canEdit: canEdit,
          glbAssetController: glbAssetController,
          usdzAssetController: usdzAssetController,
        ),
        Row(
          children: [
            Expanded(
              child: _AdminTextField(
                controller: scaleController,
                label: 'Scale',
                enabled: canEdit,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: placement,
                  items: _placements
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: canEdit
                      ? (value) {
                          if (value != null) {
                            placementController.text = value;
                          }
                        }
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Placement',
                    filled: true,
                    fillColor: canEdit ? Colors.white : const Color(0xFFE9E1DE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD7C3BE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD7C3BE)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SwitchListTile(
          value: published,
          onChanged: canEdit ? onPublishedChanged : null,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primaryRed,
          title: const Text(
            'Опубликовать 3D/AR ассет',
            style: TextStyle(
              color: AppColors.blueText,
              fontWeight: FontWeight.w800,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: canEdit && !isSaving ? onSave : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Сохраняем' : 'Сохранить 3D'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.whiteText,
              ),
            ),
            OutlinedButton.icon(
              onPressed: canEdit && !isUploading ? onUploadModel : null,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(isUploading ? 'Загружаем' : 'Загрузить .glb/.usdz'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
              ),
            ),
            TextButton.icon(
              onPressed: canDelete ? onDelete : null,
              icon: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(isDeleting ? 'Удаляем' : 'Удалить'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegacyArAssetFields extends StatelessWidget {
  final bool canEdit;
  final TextEditingController glbAssetController;
  final TextEditingController usdzAssetController;

  const _LegacyArAssetFields({
    required this.canEdit,
    required this.glbAssetController,
    required this.usdzAssetController,
  });

  @override
  Widget build(BuildContext context) {
    final hasLegacyValue =
        glbAssetController.text.trim().isNotEmpty ||
        usdzAssetController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: hasLegacyValue,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          iconColor: AppColors.primaryRed,
          collapsedIconColor: AppColors.primaryRed,
          title: const Text(
            'Legacy/local asset paths',
            style: TextStyle(
              color: AppColors.blueText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'Montserrat',
            ),
          ),
          children: [
            _AdminTextField(
              controller: glbAssetController,
              label: 'glb_asset_path',
              enabled: canEdit,
              maxLines: 2,
            ),
            _AdminTextField(
              controller: usdzAssetController,
              label: 'usdz_asset_path',
              enabled: canEdit,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFE9E1DE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD7C3BE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD7C3BE)),
          ),
        ),
      ),
    );
  }
}

class _QrPayloadBox extends StatelessWidget {
  final String? payload;
  final VoidCallback? onCopy;
  final VoidCallback? onDownload;
  final bool isDownloading;

  const _QrPayloadBox({
    required this.payload,
    required this.onCopy,
    required this.onDownload,
    required this.isDownloading,
  });

  @override
  Widget build(BuildContext context) {
    final value = payload ?? 'retroar://object/<id>';
    final qrPreview = Container(
      width: 148,
      height: 148,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5D8D2)),
      ),
      child: payload == null
          ? const Icon(Icons.qr_code_2, color: AppColors.primaryRed, size: 96)
          : QrImageView(
              data: payload!,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              backgroundColor: Colors.white,
              gapless: true,
            ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'QR для таблички',
          style: TextStyle(
            color: AppColors.blueText,
            fontWeight: FontWeight.w800,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          value,
          style: const TextStyle(
            color: AppColors.blueText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Скопировать'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
              ),
            ),
            FilledButton.icon(
              onPressed: isDownloading ? null : onDownload,
              icon: isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(isDownloading ? 'Готовим PNG' : 'Скачать PNG'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.whiteText,
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7C3BE)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                qrPreview,
                const SizedBox(width: 16),
                Expanded(child: details),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              qrPreview,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: details),
            ],
          );
        },
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String text;

  const _InlineNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6C56F)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF735800),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}
