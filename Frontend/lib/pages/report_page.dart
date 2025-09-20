// lib/pages/report_page.dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  CameraDescription? _activeCamera;
  FlashMode _flashMode = FlashMode.off;
  bool _isCameraReady = false;
  bool _isTakingPicture = false;

  File? _attachedImage;

  // Form
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String category = 'Pothole';
  bool submitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    titleCtrl.dispose();
    locationCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.paused) {
      // pause if needed
    } else if (state == AppLifecycleState.resumed) {
      // try re-initializing camera
      _initCamera();
    }
  }

  Future<void> _requestPermissions() async {
    final cam = await Permission.camera.status;
    if (!cam.isGranted) {
      final res = await Permission.camera.request();
      if (!res.isGranted) throw ('Camera permission denied');
    }
    // Request gallery/storage only when needed (Android storage vs iOS photos)
  }

  Future<void> _initCamera() async {
    try {
      await _requestPermissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission is required.')));
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera found on device.')));
        return;
      }

      // prefer back camera
      _activeCamera = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => _cameras!.first);
      await _createController(_activeCamera!);
    } catch (e, st) {
      debugPrint('Camera init error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to initialize camera')));
    }
  }

  Future<void> _createController(CameraDescription camera) async {
    try {
      await _controller?.dispose();
    } catch (_) {}

    _controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    _isCameraReady = false;
    try {
      await _controller!.initialize();
      // set default flash mode if supported
      try {
        await _controller!.setFlashMode(_flashMode);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      debugPrint('Controller init failed: $e');
      if (mounted) {
        setState(() => _isCameraReady = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera failed to start')));
      }
    }
  }

  Future<void> _disposeCamera() async {
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    _isCameraReady = false;
  }

  // Capture via camera-preview
  Future<void> _capturePhoto() async {
    if (!_isCameraReady || _controller == null || _isTakingPicture) return;

    try {
      setState(() => _isTakingPicture = true);
      final XFile raw = await _controller!.takePicture();

      final tmpDir = await getTemporaryDirectory();
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}${p.extension(raw.path)}';
      final saved = await File(raw.path).copy(p.join(tmpDir.path, fileName));

      if (!mounted) return;
      setState(() => _attachedImage = saved);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo captured')));
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capture failed')));
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  // Pick from gallery
  Future<void> _pickFromGallery() async {
    // Request storage/photos permission proactively for Android
    final status = Platform.isAndroid ? await Permission.storage.request() : await Permission.photos.request();
    if (!status.isGranted && status != PermissionStatus.limited) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery permission is required.')));
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      final tmpDir = await getTemporaryDirectory();
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final saved = await File(picked.path).copy(p.join(tmpDir.path, fileName));

      if (!mounted) return;
      setState(() => _attachedImage = saved);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo selected')));
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  void _removePhoto() {
    setState(() => _attachedImage = null);
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    final currentIndex = _cameras!.indexOf(_activeCamera!);
    final next = _cameras![(currentIndex + 1) % _cameras!.length];
    _activeCamera = next;
    await _createController(next);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      // cycle through off -> auto -> always -> torch (where supported)
      final next = _flashMode == FlashMode.off
          ? FlashMode.auto
          : _flashMode == FlashMode.auto
          ? FlashMode.always
          : _flashMode == FlashMode.always
          ? FlashMode.torch
          : FlashMode.off;
      await _controller!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flash not supported')));
    }
  }

  // Simulated submit — replace this block with real upload logic
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attachedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please attach a photo (camera or gallery)')));
      return;
    }

    setState(() => submitting = true);

    try {
      // >>> Replace with upload (Firebase Storage / REST API)
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('--- Report ---');
      debugPrint('Title: ${titleCtrl.text.trim()}');
      debugPrint('Category: $category');
      debugPrint('Location: ${locationCtrl.text.trim()}');
      debugPrint('Desc: ${descCtrl.text.trim()}');
      debugPrint('Image path(local): ${_attachedImage!.path}');
      // <<<

      if (!mounted) return;
      setState(() {
        submitting = false;
        _attachedImage = null;
        titleCtrl.clear();
        locationCtrl.clear();
        descCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted — thank you')));
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        setState(() => submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
      }
    }
  }

  Widget _cameraPreview() {
    final cam = _controller;
    if (cam != null && cam.value.isInitialized) {
      return CameraPreview(cam);
    }
    return Container(
      color: Colors.black12,
      child: const Center(child: Text('Camera initializing...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _cameraPreview();

    return Scaffold(
      appBar: AppBar(title: const Text('Report (Camera / Gallery)')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Camera preview + controls
            AspectRatio(
              aspectRatio: _controller != null && _controller!.value.isInitialized ? _controller!.value.aspectRatio : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  preview,
                  if (!_isCameraReady)
                    const Center(child: CircularProgressIndicator())
                  else
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _smallRoundButton(
                            icon: Icons.cameraswitch,
                            tooltip: 'Switch camera',
                            onPressed: _cameras != null && _cameras!.length > 1 ? _toggleCamera : null,
                          ),
                          Row(
                            children: [
                              _smallRoundButton(icon: Icons.flash_on, tooltip: 'Flash', onPressed: _toggleFlash),
                              const SizedBox(width: 8),
                              Text(_flashMode.name.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery button
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.white),
                            onPressed: _pickFromGallery,
                          ),
                        ),

                        // Capture button (big)
                        GestureDetector(
                          onTap: _isTakingPicture ? null : _capturePhoto,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(width: 4, color: Colors.white54),
                            ),
                            child: Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),

                        // Thumbnail / remove
                        GestureDetector(
                          onTap: _attachedImage == null
                              ? null
                              : () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FullImageView(file: _attachedImage!)));
                          },
                          onLongPress: _attachedImage == null ? null : _removePhoto,
                          child: _attachedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_attachedImage!, width: 64, height: 64, fit: BoxFit.cover),
                          )
                              : Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white24),
                            child: const Icon(Icons.photo, color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Quick report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title (short)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: ['Pothole', 'Streetlight', 'Drain', 'Garbage', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => category = v ?? category),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location (address or landmark)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _attachedImage != null ? _removePhoto : null,
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove photo'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_attachedImage != null ? 'Photo attached' : 'No photo attached', style: const TextStyle(color: Colors.black54))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submitReport,
                      child: submitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Report'),
                    ),
                  ),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallRoundButton({required IconData icon, required String tooltip, required VoidCallback? onPressed}) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        color: Colors.white,
      ),
    );
  }
}

class _FullImageView extends StatelessWidget {
  final File file;
  const _FullImageView({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Image.file(file)),
    );
  }
}
