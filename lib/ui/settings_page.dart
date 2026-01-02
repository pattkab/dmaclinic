import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/clinic_settings.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _svc = SettingsService();

  final _name = TextEditingController();
  final _logo = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _logo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final s = ClinicSettings(
        clinicName: _name.text.trim().isEmpty ? 'DMA Clinic' : _name.text.trim(),
        logoUrl: _logo.text.trim(),
      );
      await _svc.saveSettings(s);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _logoPreview(String url) {
    if (url.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          height: 90,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Logo URL not valid or not reachable.'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClinicSettings>(
      stream: _svc.streamSettings(),
      builder: (context, snap) {
        final settings = snap.data ?? ClinicSettings.defaults();

        // Keep controllers in sync without fighting user typing
        if (_name.text.isEmpty) _name.text = settings.clinicName;
        if (_logo.text.isEmpty) _logo.text = settings.logoUrl;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Clinic Settings'),
            actions: [
              IconButton(
                tooltip: 'Save',
                icon: _saving
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Branding',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Clinic name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _logo,
                            decoration: const InputDecoration(
                              labelText: 'Clinic logo URL (optional)',
                              hintText: 'https://example.com/logo.png',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          _logoPreview(_logo.text),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text('Version: ${AppConstants.versionLabel}'),
                          const SizedBox(height: 6),
                          Text('Developer: ${AppConstants.developer}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
