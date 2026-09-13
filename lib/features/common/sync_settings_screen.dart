import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  late final TextEditingController _urlController;
  bool _enabled = false;
  bool _isLoading = true;
  bool _isSyncing = false;
  DateTime? _lastSyncAt;

  static const String _appsScriptCode = '''
// Paste this into script.google.com -> New Project (Code.gs)
// Then Deploy -> New deployment -> Web app:
//   Execute as: Me
//   Who has access: Anyone
// Copy the /exec URL into this screen.

function doPost(e) {
  try {
    var body = JSON.parse(e.postData.contents);
    var ss = getOrCreateSpreadsheet_();
    var sheetName = body.sheet || 'Data';
    var sheet = ss.getSheetByName(sheetName);
    if (!sheet) { sheet = ss.insertSheet(sheetName); }
    if (body.header && body.header.length > 0) {
      var firstRow = sheet.getRange(1, 1, 1, body.header.length).getValues()[0];
      if (firstRow.join('').length === 0) {
        sheet.getRange(1, 1, 1, body.header.length).setValues([body.header]);
      }
    }
    var rows = body.rows || [];
    if (rows.length > 0) {
      sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, rows[0].length)
           .setValues(rows);
    }
    return ContentService
      .createTextOutput(JSON.stringify({ ok: true, added: rows.length }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ ok: false, error: String(err) }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function getOrCreateSpreadsheet_() {
  var props = PropertiesService.getScriptProperties();
  var id = props.getProperty('SPREADSHEET_ID');
  var ss;
  if (id) {
    try { ss = SpreadsheetApp.openById(id); } catch (err) { ss = null; }
  }
  if (!ss) {
    ss = SpreadsheetApp.create('Be Present - Synced Data');
    props.setProperty('SPREADSHEET_ID', ss.getId());
  }
  return ss;
}
''';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final dao = ref.read(settingsDaoProvider);
    final url = await dao.getValue(AppConstants.settingsSyncUrl);
    final enabled =
        (await dao.getValueOr(AppConstants.settingsSyncEnabled, 'false')) ==
            'true';
    final lastRaw = await dao.getValue(AppConstants.settingsLastSyncAt);
    if (!mounted) return;
    _urlController.text = url ?? '';
    _enabled = enabled;
    _lastSyncAt = lastRaw == null ? null : DateTime.tryParse(lastRaw);
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final dao = ref.read(settingsDaoProvider);
    await dao.setValue(AppConstants.settingsSyncUrl, _urlController.text.trim());
    await dao.setValue(
      AppConstants.settingsSyncEnabled,
      _enabled ? 'true' : 'false',
    );
    if (mounted) {
      await showAppSnackBar(context, 'Sync settings saved');
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    final result = await ref.read(cloudSyncServiceProvider).syncNow();
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _lastSyncAt = DateTime.now();
    });
    await showAppSnackBar(
      context,
      result.message,
      isError: !result.success,
    );
  }

  Future<void> _showGuide() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Sheets Setup Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  '1. Open script.google.com and create a new project.\n'
                  '2. Replace Code.gs with the script below.\n'
                  '3. Deploy → New deployment → Web app.'),
              const SizedBox(height: 8),
              const Text('4. Choose: Execute as "Me", access "Anyone".'),
              const SizedBox(height: 8),
              const Text('5. Copy the /exec URL and paste it above.'),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _appsScriptCode,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: _appsScriptCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Script copied to clipboard')),
              );
            },
            child: const Text('Copy Script'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync (Google Sheets)')),
      body: _isLoading
          ? const LoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How it works',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Attendance and homework submissions are appended '
                          'to a Google Sheet in your Drive through a free '
                          'Google Apps Script web app. No student login or '
                          'Google account is needed inside the app.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _showGuide,
                          icon: const Icon(Icons.code),
                          label: const Text('Show Setup Guide & Script'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Apps Script Web App URL',
                    hintText: 'https://script.google.com/macros/s/.../exec',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Enable automatic sync'),
                  subtitle: const Text(
                      'Push attendance & homework after each save'),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                if (_lastSyncAt != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Last sync'),
                    trailing: Text(
                        Formatters.formatDateTime(_lastSyncAt!)),
                  ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save Settings',
                  icon: Icons.save,
                  onPressed: _save,
                  backgroundColor: Colors.teal,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Sync Now',
                  icon: Icons.cloud_upload_outlined,
                  isLoading: _isSyncing,
                  onPressed: _syncNow,
                ),
              ],
            ),
    );
  }
}