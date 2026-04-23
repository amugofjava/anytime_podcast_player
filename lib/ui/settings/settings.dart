// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:anytime/bloc/podcast/opml_bloc.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/core/environment.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/analysis/background/analysis_model_catalog.dart';
import 'package:anytime/services/analysis/background/background_analysis_dispatcher.dart';
import 'package:anytime/services/analysis/background/model_download_service.dart';
import 'package:anytime/services/analysis/episode_analysis_service.dart';
import 'package:anytime/services/analysis/openai_episode_analysis_service.dart';
import 'package:anytime/services/secrets/secure_secrets_service.dart';
import 'package:anytime/state/opml_state.dart';
import 'package:anytime/ui/library/opml_export.dart';
import 'package:anytime/ui/library/opml_import.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

/// This is the settings page and allows the user to select various options for the app.
class Settings extends StatefulWidget {
  const Settings({
    super.key,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool sdcard = false;
  int _versionTapCount = 0;
  bool? _gemmaInstalled;
  BackgroundAnalysisLocalModel? _checkedVariant;
  GemmaDownloadProgress? _downloadProgress;
  String? _downloadError;
  StreamSubscription<GemmaDownloadProgress>? _downloadSub;
  bool _runningBackgroundAnalysis = false;

  @override
  void initState() {
    super.initState();

    hasExternalStorage().then((value) {
      if (mounted) {
        setState(() {
          sdcard = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshGemmaInstallState(BackgroundAnalysisLocalModel variant) async {
    if (_downloadSub != null) return; // mid-download; skip redundant poll
    final service = Provider.of<GemmaModelDownloadService>(context, listen: false);
    final installed = await service.isInstalled(variant);
    if (!mounted) return;
    setState(() {
      _gemmaInstalled = installed;
      _checkedVariant = variant;
    });
  }

  void _startGemmaDownload(BackgroundAnalysisLocalModel variant, String? hfToken) {
    final service = Provider.of<GemmaModelDownloadService>(context, listen: false);
    _downloadSub?.cancel();
    setState(() {
      _downloadProgress = const GemmaDownloadProgress(percent: 0, filename: '');
      _downloadError = null;
    });
    _downloadSub = service.download(variant, huggingFaceToken: hfToken).listen(
      (progress) {
        if (!mounted) return;
        setState(() => _downloadProgress = progress);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _downloadSub = null;
          _downloadProgress = null;
          _downloadError = error.toString();
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _downloadSub = null;
          _downloadProgress = null;
          _gemmaInstalled = true;
          _checkedVariant = variant;
        });
      },
    );
  }

  Future<void> _cancelGemmaDownload(BackgroundAnalysisLocalModel variant) async {
    await _downloadSub?.cancel();
    final service = Provider.of<GemmaModelDownloadService>(context, listen: false);
    try {
      await service.delete(variant);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _downloadSub = null;
      _downloadProgress = null;
      _gemmaInstalled = false;
      _checkedVariant = variant;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0.0,
          title: Text(L.of(context)!.settings_label),
        ),
        body: StreamBuilder<AppSettings>(
          stream: settingsBloc.settings,
          initialData: settingsBloc.currentSettings,
          builder: (context, snapshot) {
            final settings = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
              children: [
                _SettingsHeader(
                  title: L.of(context)!.settings_label,
                  subtitle: 'Fine-tune your listening environment.',
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Account'),
                _SettingsCard(
                  children: [
                    _ActionSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Listening profile',
                      subtitle:
                          settings.searchProvider == 'itunes' ? 'iTunes search catalog' : 'PodcastIndex search catalog',
                      onTap: () => _showSearchProviderDialog(settings),
                    ),
                    _ActionSettingsTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Search provider',
                      subtitle: settings.searchProvider == 'itunes' ? 'iTunes' : 'PodcastIndex',
                      onTap: () => _showSearchProviderDialog(settings),
                    ),
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Playback'),
                _SettingsCard(
                  padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 18.0),
                  children: [
                    _SpeedControlCard(
                      speed: settings.playbackSpeed,
                      onChanged: settingsBloc.setPlaybackSpeed,
                    ),
                    const SizedBox(height: 16.0),
                    const Row(
                      children: [
                        Expanded(
                          child: _StaticPlaybackCard(
                            label: 'Skip Back',
                            value: '10s',
                            icon: Icons.replay_10_rounded,
                          ),
                        ),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: _StaticPlaybackCard(
                            label: 'Skip Forward',
                            value: '30s',
                            icon: Icons.forward_30_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    _ToggleSettingsTile(
                      title: 'Trim Silence',
                      subtitle: 'Automatically skip quiet gaps',
                      value: settings.trimSilence,
                      onChanged: settingsBloc.trimSilence,
                    ),
                    _ToggleSettingsTile(
                      title: 'Volume Boost',
                      subtitle: 'Enhance vocal clarity in louder spaces',
                      value: settings.volumeBoost,
                      onChanged: settingsBloc.volumeBoost,
                    ),
                    _ToggleSettingsTile(
                      title: L.of(context)!.settings_auto_open_now_playing,
                      subtitle: 'Jump to the player as soon as playback starts',
                      value: settings.autoOpenNowPlaying,
                      onChanged: settingsBloc.setAutoOpenNowPlaying,
                    ),
                    _ToggleSettingsTile(
                      title: L.of(context)!.settings_continuous_play_option,
                      subtitle: L.of(context)!.settings_continuous_play_subtitle,
                      value: settings.autoPlay,
                      onChanged: settingsBloc.autoPlay,
                    ),
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Transcription'),
                _SettingsCard(
                  children: [
                    _ActionSettingsTile(
                      icon: Icons.subtitles_outlined,
                      title: 'Transcription provider',
                      subtitle: _transcriptionProviderLabel(settings.transcriptionProvider),
                      onTap: () => _showTranscriptionProviderDialog(settings),
                    ),
                    if (settings.transcriptionProvider == TranscriptionProvider.openAi)
                      FutureBuilder<String?>(
                        future: Provider.of<SecureSecretsService>(context, listen: false).read(openAiApiKeySecret),
                        builder: (context, snapshot) {
                          return _ActionSettingsTile(
                            icon: Icons.key_outlined,
                            title: 'OpenAI API key',
                            subtitle: _apiKeyLabel(snapshot.data),
                            onTap: () => _showApiKeyDialog(
                              title: 'OpenAI API key',
                              secretKey: openAiApiKeySecret,
                              hintText: 'sk-...',
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Background ad analysis'),
                _SettingsCard(
                  children: [
                    _ToggleSettingsTile(
                      title: 'Auto-analyze downloaded episodes',
                      subtitle: _backgroundAnalysisSubtitle(),
                      value: settings.backgroundAnalysisEnabled && _backgroundAnalysisSupported(),
                      onChanged: _backgroundAnalysisSupported()
                          ? (enabled) => _handleBackgroundAnalysisToggle(settingsBloc, settings, enabled)
                          : (_) {},
                    ),
                    if (settings.backgroundAnalysisEnabled && _backgroundAnalysisSupported()) ...[
                      _ActionSettingsTile(
                        icon: Icons.memory_outlined,
                        title: 'On-device model',
                        subtitle: _backgroundLocalModelLabel(settings.backgroundLocalModel),
                        onTap: () => _showBackgroundLocalModelDialog(settings),
                      ),
                      _buildGemmaInstallTile(settings),
                      _ActionSettingsTile(
                        icon: Icons.vpn_key_outlined,
                        title: 'HuggingFace token',
                        subtitle: settings.huggingFaceAccessToken.isEmpty
                            ? 'Optional — required only for gated model files'
                            : '•••••••• (set)',
                        onTap: () => _showHuggingFaceTokenDialog(settings, settingsBloc),
                      ),
                      if (settings.showAnalysisHistory)
                        _ActionSettingsTile(
                          icon: Icons.play_arrow_outlined,
                          title: 'Run background analysis now (dev)',
                          subtitle: _runningBackgroundAnalysis
                              ? 'Running…'
                              : 'Processes the next queued episode on the UI isolate',
                          onTap: _runBackgroundAnalysisNow,
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'On-demand analysis'),
                _SettingsCard(
                  children: [
                    _ToggleSettingsTile(
                      title: 'Enable "Analyze now" (Gemini)',
                      subtitle: 'Uploads audio to Google Gemini to detect ads on demand.',
                      value: settings.onDemandAnalysisEnabled,
                      onChanged: (enabled) {
                        settingsBloc.setOnDemandAnalysisEnabled(enabled);
                        settingsBloc.setTranscriptUploadProvider(
                          enabled ? TranscriptUploadProvider.gemini : TranscriptUploadProvider.disabled,
                        );
                      },
                    ),
                    if (settings.onDemandAnalysisEnabled) ...[
                      FutureBuilder<String?>(
                        future: Provider.of<SecureSecretsService>(context, listen: false).read(geminiApiKeySecret),
                        builder: (context, snapshot) {
                          return _ActionSettingsTile(
                            icon: Icons.vpn_key_outlined,
                            title: 'Gemini API key',
                            subtitle: _apiKeyLabel(snapshot.data),
                            onTap: () => _showApiKeyDialog(
                              title: 'Gemini API key',
                              secretKey: geminiApiKeySecret,
                              hintText: 'AIza...',
                            ),
                          );
                        },
                      ),
                      _ActionSettingsTile(
                        icon: Icons.tune_outlined,
                        title: 'Gemini model',
                        subtitle: settings.geminiAnalysisModel,
                        onTap: () => _showAnalysisModelDialog(settings),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Ad playback'),
                _SettingsCard(
                  children: [
                    _ActionSettingsTile(
                      icon: Icons.skip_next_outlined,
                      title: 'Ad skip mode',
                      subtitle: _adSkipModeLabel(settings.adSkipMode),
                      onTap: () => _showAdSkipModeDialog(settings),
                    ),
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Visual Theme'),
                _ThemeChoiceRow(
                  selectedTheme: settings.theme,
                  onChanged: settingsBloc.theme,
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Library & Sync'),
                _SettingsCard(
                  children: [
                    _ActionSettingsTile(
                      icon: Icons.schedule_outlined,
                      title: L.of(context)!.settings_auto_update_episodes,
                      subtitle: _episodeRefreshLabel(context, settings.autoUpdateEpisodePeriod),
                      onTap: () => _showEpisodeRefreshDialog(settings),
                    ),
                    _ToggleSettingsTile(
                      title: L.of(context)!.settings_background_refresh_option,
                      subtitle: L.of(context)!.settings_background_refresh_option_subtitle,
                      value: settings.backgroundUpdate,
                      onChanged: settingsBloc.backgroundUpdates,
                    ),
                    _ToggleSettingsTile(
                      title: L.of(context)!.settings_background_refresh_mobile_data_option,
                      subtitle: L.of(context)!.settings_background_refresh_mobile_data_option_subtitle,
                      value: settings.backgroundUpdateMobileData,
                      onChanged: settingsBloc.backgroundUpdatesMobileData,
                    ),
                    _ToggleSettingsTile(
                      title: L.of(context)!.settings_mark_deleted_played_label,
                      value: settings.markDeletedEpisodesAsPlayed,
                      onChanged: settingsBloc.markDeletedAsPlayed,
                    ),
                    _ToggleSettingsTile(
                      title: L.of(context)!.settings_delete_played_label,
                      value: settings.deleteDownloadedPlayedEpisodes,
                      onChanged: settingsBloc.deleteDownloadedPlayedEpisodes,
                    ),
                    if (sdcard)
                      _ToggleSettingsTile(
                        title: L.of(context)!.settings_download_sd_card_label,
                        value: settings.storeDownloadsSDCard,
                        onChanged: (value) {
                          _showStorageDialog(enableExternalStorage: value);
                          settingsBloc.storeDownloadonSDCard(value);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Notifications'),
                _SettingsCard(
                  children: [
                    _ToggleSettingsTile(
                      title: L.of(context)!.settings_refresh_notification_option,
                      subtitle: L.of(context)!.settings_refresh_notification_option_subtitle,
                      value: settings.updatesNotification,
                      onChanged: settingsBloc.updateNotification,
                    ),
                    _ToggleSettingsTile(
                      title: 'Funding links',
                      subtitle: 'Show support links when a podcast offers them',
                      value: settings.showFunding,
                      onChanged: settingsBloc.setShowFunding,
                    ),
                  ],
                ),
                const SizedBox(height: 28.0),
                const _SectionLabel(label: 'Data'),
                _SettingsCard(
                  children: [
                    _ActionSettingsTile(
                      icon: Icons.file_upload_outlined,
                      title: L.of(context)!.settings_import_opml,
                      subtitle: 'Bring in subscriptions from another app',
                      onTap: _importOpml,
                    ),
                    _ActionSettingsTile(
                      icon: Icons.file_download_outlined,
                      title: L.of(context)!.settings_export_opml,
                      subtitle: 'Export your current show list',
                      onTap: _exportOpml,
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleVersionTap(context, settings, settingsBloc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        settings.showAnalysisHistory
                            ? 'Version ${Environment.projectVersion} • debug'
                            : 'Version ${Environment.projectVersion}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportOpml() async {
    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => BasicDialogAlert(
        content: const OPMLExport(),
      ),
    );
  }

  Future<void> _importOpml() async {
    final podcastBloc = Provider.of<PodcastBloc>(context, listen: false);
    final opmlBloc = Provider.of<OPMLBloc>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.count == 0) {
      return;
    }

    final file = result.files.first;

    if (!mounted) {
      return;
    }

    final cancelled = await showPlatformDialog<bool>(
      androidBarrierDismissible: false,
      useRootNavigator: false,
      context: context,
      builder: (_) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async => false,
        child: BasicDialogAlert(
          title: Text(L.of(context)!.settings_import_opml),
          content: OPMLImport(file: file.path!),
          actions: <Widget>[
            BasicDialogAction(
              title: ActionText(L.of(context)!.cancel_button_label),
              onPressed: () {
                return Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );

    if (cancelled != null && cancelled) {
      opmlBloc.opmlEvent(OPMLCancelEvent());
    }

    podcastBloc.podcastEvent(PodcastEvent.reloadSubscriptions);
  }

  String _episodeRefreshLabel(BuildContext context, int period) {
    return switch (period) {
      -1 => L.of(context)!.settings_auto_update_episodes_never,
      0 => L.of(context)!.settings_auto_update_episodes_always,
      10 => L.of(context)!.settings_auto_update_episodes_10min,
      30 => L.of(context)!.settings_auto_update_episodes_30min,
      60 => L.of(context)!.settings_auto_update_episodes_1hour,
      180 => L.of(context)!.settings_auto_update_episodes_3hour,
      360 => L.of(context)!.settings_auto_update_episodes_6hour,
      720 => L.of(context)!.settings_auto_update_episodes_12hour,
      1440 => L.of(context)!.settings_auto_update_episodes_24hour,
      2880 => L.of(context)!.settings_auto_update_episodes_48hour,
      _ => L.of(context)!.settings_auto_update_episodes_never,
    };
  }

  Future<void> _showEpisodeRefreshDialog(AppSettings settings) async {
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        var selected = settings.autoUpdateEpisodePeriod;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                L.of(context)!.settings_auto_update_episodes_heading,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in _refreshOptions(context))
                      _SelectionDialogTile(
                        title: option.label,
                        selected: selected == option.value,
                        onTap: () {
                          setDialogState(() {
                            selected = option.value;
                          });
                          settingsBloc.autoUpdatePeriod(option.value);
                          Navigator.pop(dialogContext);
                        },
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: ActionText(L.of(context)!.close_button_label),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_ValueLabel<int>> _refreshOptions(BuildContext context) {
    return [
      _ValueLabel(-1, L.of(context)!.settings_auto_update_episodes_never),
      _ValueLabel(60, L.of(context)!.settings_auto_update_episodes_1hour),
      _ValueLabel(180, L.of(context)!.settings_auto_update_episodes_3hour),
      _ValueLabel(360, L.of(context)!.settings_auto_update_episodes_6hour),
      _ValueLabel(720, L.of(context)!.settings_auto_update_episodes_12hour),
      _ValueLabel(1440, L.of(context)!.settings_auto_update_episodes_24hour),
      _ValueLabel(2880, L.of(context)!.settings_auto_update_episodes_48hour),
    ];
  }

  Future<void> _showSearchProviderDialog(AppSettings settings) async {
    if (settings.searchProviders.length <= 1) {
      return;
    }

    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        var selected = settings.searchProvider ?? 'itunes';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                L.of(context)!.search_provider_label,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final provider in settings.searchProviders)
                    _SelectionDialogTile(
                      title: provider.name,
                      selected: selected == provider.key,
                      onTap: () {
                        setDialogState(() {
                          selected = provider.key;
                        });
                        settingsBloc.setSearchProvider(provider.key);
                        Navigator.pop(dialogContext);
                      },
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: ActionText(L.of(context)!.close_button_label),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStorageDialog({required bool enableExternalStorage}) {
    showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => BasicDialogAlert(
        title: Text(L.of(context)!.settings_download_switch_label),
        content: Text(
          enableExternalStorage
              ? L.of(context)!.settings_download_switch_card
              : L.of(context)!.settings_download_switch_internal,
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text(L.of(context)!.ok_button_label),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _transcriptionProviderLabel(TranscriptionProvider provider) {
    switch (provider) {
      case TranscriptionProvider.localAi:
        return 'On-device Whisper';
      case TranscriptionProvider.openAi:
        return 'OpenAI Whisper API';
    }
  }

  String _apiKeyLabel(String? key) {
    final trimmed = key?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Not configured';
    }

    if (trimmed.length <= 4) {
      return 'Stored securely';
    }

    return 'Stored securely ••••${trimmed.substring(trimmed.length - 4)}';
  }

  String _adSkipModeLabel(AdSkipMode mode) {
    switch (mode) {
      case AdSkipMode.disabled:
        return 'Disabled';
      case AdSkipMode.prompt:
        return 'Prompt before skipping';
      case AdSkipMode.auto:
        return 'Skip automatically';
    }
  }

  void _handleVersionTap(BuildContext context, AppSettings settings, SettingsBloc settingsBloc) {
    _versionTapCount++;
    if (_versionTapCount < 7) {
      return;
    }
    _versionTapCount = 0;

    final enabling = !settings.showAnalysisHistory;
    settingsBloc.setShowAnalysisHistory(enabling);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabling ? 'Analysis history enabled.' : 'Analysis history disabled.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _runBackgroundAnalysisNow() async {
    if (_runningBackgroundAnalysis) return;
    setState(() => _runningBackgroundAnalysis = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'dev_background_analysis_run'),
          builder: (_) => const _BackgroundAnalysisRunPage(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _runningBackgroundAnalysis = false);
      }
    }
  }

  Future<void> _handleBackgroundAnalysisToggle(
    SettingsBloc settingsBloc,
    AppSettings settings,
    bool enabled,
  ) async {
    if (!enabled) {
      settingsBloc.setBackgroundAnalysisEnabled(false);
      return;
    }

    if (settings.backgroundAnalysisDiskCostAccepted) {
      settingsBloc.setBackgroundAnalysisEnabled(true);
      _maybeStartGemmaDownload(settings);
      return;
    }

    final confirmed = await _showBackgroundAnalysisDiskCostDialog(settings.backgroundLocalModel);
    if (!confirmed) {
      return;
    }
    settingsBloc.setBackgroundAnalysisDiskCostAccepted(true);
    settingsBloc.setBackgroundAnalysisEnabled(true);
    _maybeStartGemmaDownload(settings);
  }

  Future<void> _maybeStartGemmaDownload(AppSettings settings) async {
    final service = Provider.of<GemmaModelDownloadService>(context, listen: false);
    final variant = settings.backgroundLocalModel;
    final installed = await service.isInstalled(variant);
    if (!mounted) return;
    if (installed) {
      setState(() {
        _gemmaInstalled = true;
        _checkedVariant = variant;
      });
      return;
    }
    _startGemmaDownload(variant, settings.huggingFaceAccessToken);
  }

  Widget _buildGemmaInstallTile(AppSettings settings) {
    final variant = settings.backgroundLocalModel;
    if (_checkedVariant != variant && _downloadSub == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshGemmaInstallState(variant);
      });
    }

    if (_downloadProgress != null) {
      final pct = _downloadProgress!.percent;
      return _ActionSettingsTile(
        icon: Icons.cloud_download_outlined,
        title: 'Downloading Gemma model ($pct%)',
        subtitle: _downloadProgress!.filename.isEmpty ? 'Starting…' : _downloadProgress!.filename,
        onTap: () => _cancelGemmaDownload(variant),
      );
    }

    if (_downloadError != null) {
      return _ActionSettingsTile(
        icon: Icons.error_outline,
        title: 'Download failed',
        subtitle: 'Tap to retry — ${_downloadError!}',
        onTap: () => _startGemmaDownload(variant, settings.huggingFaceAccessToken),
      );
    }

    if (_gemmaInstalled == true) {
      return _ActionSettingsTile(
        icon: Icons.check_circle_outline,
        title: 'Gemma model installed',
        subtitle: 'Ready to analyze',
        onTap: () => _confirmAndRedownload(variant, settings),
      );
    }

    return _ActionSettingsTile(
      icon: Icons.cloud_download_outlined,
      title: 'Download Gemma model',
      subtitle:
          '${AnalysisModelCatalog.formatBytes(AnalysisModelCatalog.approximateSizeBytesFor(variant))} — tap to download',
      onTap: () => _startGemmaDownload(variant, settings.huggingFaceAccessToken),
    );
  }

  Future<void> _confirmAndRedownload(BackgroundAnalysisLocalModel variant, AppSettings settings) async {
    final confirmed = await showPlatformDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Re-download model?'),
        content: const Text('This will delete the installed model and download it again.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Re-download')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _cancelGemmaDownload(variant);
    if (!mounted) return;
    _startGemmaDownload(variant, settings.huggingFaceAccessToken);
  }

  Future<void> _showHuggingFaceTokenDialog(AppSettings settings, SettingsBloc settingsBloc) async {
    final controller = TextEditingController(text: settings.huggingFaceAccessToken);
    final result = await showPlatformDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('HuggingFace access token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Required only for gated model files. Paste a token from huggingface.co/settings/tokens.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'hf_...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      settingsBloc.setHuggingFaceAccessToken(result);
    }
  }

  Future<bool> _showBackgroundAnalysisDiskCostDialog(BackgroundAnalysisLocalModel variant) async {
    final totalBytes = AnalysisModelCatalog.totalApproximateSizeBytesFor(variant);
    final totalLabel = AnalysisModelCatalog.formatBytes(totalBytes);
    final gemmaLabel = AnalysisModelCatalog.formatBytes(
      AnalysisModelCatalog.approximateSizeBytesFor(variant),
    );
    final whisperLabel = AnalysisModelCatalog.formatBytes(
      AnalysisModelCatalog.whisperApproximateSizeBytes,
    );

    final result = await showPlatformDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Download models?',
            style: Theme.of(dialogContext).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Background analysis runs Whisper and Gemma 4 fully on-device. '
                'Enabling it will download the required models the next time you '
                'charge your device:',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text('• Whisper transcription ($whisperLabel)'),
              Text('• Gemma 4 ${_backgroundLocalModelLabel(variant)} ($gemmaLabel)'),
              const SizedBox(height: 12),
              Text(
                'Total disk cost: about $totalLabel.',
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Download'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  bool _backgroundAnalysisSupported() {
    // Background Gemma 4 requires Android 8+ (SDK 26) for WorkManager + model
    // runtime. Other platforms have no background pipeline at all.
    return Platform.isAndroid;
  }

  String _backgroundAnalysisSubtitle() {
    if (Platform.isAndroid) {
      return 'Runs Whisper + Gemma 4 on-device while charging. Requires Android 8 or newer.';
    }
    return 'Background analysis is only available on Android.';
  }

  String _backgroundLocalModelLabel(BackgroundAnalysisLocalModel model) {
    switch (model) {
      case BackgroundAnalysisLocalModel.gemma4E2B:
        return 'Gemma 4 E2B (~2.4 GB) — recommended';
      case BackgroundAnalysisLocalModel.gemma4E4B:
        return 'Gemma 4 E4B (~4.3 GB) — higher quality';
    }
  }

  Future<void> _showBackgroundLocalModelDialog(AppSettings settings) async {
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    final options = <_ValueLabel<BackgroundAnalysisLocalModel>>[
      _ValueLabel(BackgroundAnalysisLocalModel.gemma4E2B, _backgroundLocalModelLabel(BackgroundAnalysisLocalModel.gemma4E2B)),
      _ValueLabel(BackgroundAnalysisLocalModel.gemma4E4B, _backgroundLocalModelLabel(BackgroundAnalysisLocalModel.gemma4E4B)),
    ];

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        var selected = settings.backgroundLocalModel;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'On-device model',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    _SelectionDialogTile(
                      title: option.label,
                      selected: selected == option.value,
                      onTap: () {
                        setDialogState(() {
                          selected = option.value;
                        });
                        settingsBloc.setBackgroundLocalModel(option.value);
                        Navigator.pop(dialogContext);
                        setState(() {});
                      },
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: ActionText(L.of(context)!.close_button_label),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAnalysisModelDialog(AppSettings settings) async {
    final provider = settings.transcriptUploadProvider;

    if (provider != TranscriptUploadProvider.gemini) {
      return;
    }

    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    final secureSecretsService = Provider.of<SecureSecretsService>(context, listen: false);
    final catalogService = EpisodeAnalysisModelCatalogService(
      secureSecretsService: secureSecretsService,
    );
    final loadModels = catalogService.listModels(provider: provider);
    final currentModel = settings.geminiAnalysisModel;

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return FutureBuilder<List<String>>(
          future: loadModels,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return AlertDialog(
                title: Text(
                  'Analysis model',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                content: const SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text(
                  'Analysis model',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                content: Text(_analysisModelErrorMessage(snapshot.error)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: ActionText(L.of(context)!.close_button_label),
                  ),
                ],
              );
            }

            final models = _mergeCurrentModel(
              snapshot.data ?? const <String>[],
              currentModel,
            );
            var selected = currentModel;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(
                    'Analysis model',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final model in models)
                            _SelectionDialogTile(
                              title: model,
                              selected: selected == model,
                              onTap: () {
                                setDialogState(() {
                                  selected = model;
                                });

                                switch (provider) {
                                  case TranscriptUploadProvider.openAi:
                                    settingsBloc.setOpenAiAnalysisModel(model);
                                    break;
                                  case TranscriptUploadProvider.grok:
                                    settingsBloc.setGrokAnalysisModel(model);
                                    break;
                                  case TranscriptUploadProvider.gemini:
                                    settingsBloc.setGeminiAnalysisModel(model);
                                    break;
                                  case TranscriptUploadProvider.disabled:
                                  case TranscriptUploadProvider.analysisBackend:
                                    break;
                                }

                                Navigator.pop(dialogContext);
                                setState(() {});
                              },
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: ActionText(L.of(context)!.close_button_label),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    catalogService.close();
  }

  Future<void> _showTranscriptionProviderDialog(AppSettings settings) async {
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    final options = <_ValueLabel<TranscriptionProvider>>[
      const _ValueLabel(TranscriptionProvider.localAi, 'On-device Whisper'),
      const _ValueLabel(TranscriptionProvider.openAi, 'OpenAI Whisper API'),
    ];

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        var selected = settings.transcriptionProvider;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Transcription provider',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    _SelectionDialogTile(
                      title: option.label,
                      selected: selected == option.value,
                      onTap: () {
                        setDialogState(() {
                          selected = option.value;
                        });
                        settingsBloc.setTranscriptionProvider(option.value);
                        Navigator.pop(dialogContext);
                        setState(() {});
                      },
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: ActionText(L.of(context)!.close_button_label),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showApiKeyDialog({
    required String title,
    required String secretKey,
    required String hintText,
  }) async {
    final secureSecretsService = Provider.of<SecureSecretsService>(context, listen: false);
    final existingKey = await secureSecretsService.read(secretKey);
    final controller = TextEditingController();

    if (!mounted) {
      return;
    }

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((existingKey?.trim().isNotEmpty ?? false))
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text('A key is already stored securely. Save a new one to replace it, or clear it below.'),
                ),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: hintText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: ActionText(L.of(context)!.cancel_button_label),
            ),
            TextButton(
              onPressed: () async {
                await secureSecretsService.delete(secretKey);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (mounted) {
                  setState(() {});
                }
              },
              child: const ActionText('Clear'),
            ),
            TextButton(
              onPressed: () async {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  await secureSecretsService.delete(secretKey);
                } else {
                  await secureSecretsService.write(
                    key: secretKey,
                    value: value,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (mounted) {
                  setState(() {});
                }
              },
              child: const ActionText('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAdSkipModeDialog(AppSettings settings) async {
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    final options = <_ValueLabel<AdSkipMode>>[
      const _ValueLabel(AdSkipMode.prompt, 'Prompt before skipping'),
      const _ValueLabel(AdSkipMode.auto, 'Skip automatically'),
      const _ValueLabel(AdSkipMode.disabled, 'Disabled'),
    ];

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        var selected = settings.adSkipMode;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Ad skip mode',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    _SelectionDialogTile(
                      title: option.label,
                      selected: selected == option.value,
                      onTap: () {
                        setDialogState(() {
                          selected = option.value;
                        });
                        settingsBloc.setAdSkipMode(option.value);
                        Navigator.pop(dialogContext);
                      },
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: ActionText(L.of(context)!.close_button_label),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _analysisModelErrorMessage(Object? error) {
    if (error is EpisodeAnalysisHttpException) {
      return 'Model list request failed with status ${error.statusCode}.';
    }

    if (error is TimeoutException) {
      return 'Loading models timed out. Try again.';
    }

    if (error is StateError || error is FormatException) {
      return error.toString().replaceFirst(RegExp(r'^(StateError|FormatException):\s*'), '');
    }

    return 'Could not load models. Try again.';
  }

  List<String> _mergeCurrentModel(List<String> models, String currentModel) {
    final merged = <String>[
      ...models,
      if (currentModel.trim().isNotEmpty && !models.contains(currentModel)) currentModel,
    ]..sort();

    return List<String>.unmodifiable(merged);
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const _SettingsCard({
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 28.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _ActionSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionSettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.0),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleSettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSettingsTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SpeedControlCard extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;

  const _SpeedControlCard({
    required this.speed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Playback Speed',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999.0),
              ),
              child: Text(
                '${speed.toStringAsFixed(1)}x',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryFixed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: speed.clamp(0.5, 2.0),
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: '${speed.toStringAsFixed(1)}x',
          onChanged: onChanged,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScaleLabel(label: '0.5x'),
              _ScaleLabel(label: '1.0x'),
              _ScaleLabel(label: '2.0x'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  final String label;

  const _ScaleLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
    );
  }
}

class _StaticPlaybackCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StaticPlaybackCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                value,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChoiceRow extends StatelessWidget {
  final String selectedTheme;
  final ValueChanged<String> onChanged;

  const _ThemeChoiceRow({
    required this.selectedTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemeCard(
            label: L.of(context)!.settings_theme_value_light,
            selected: selectedTheme == 'light',
            preview: const _ThemePreview.light(),
            onTap: () => onChanged('light'),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _ThemeCard(
            label: L.of(context)!.settings_theme_value_dark,
            selected: selectedTheme == 'dark',
            preview: const _ThemePreview.dark(),
            onTap: () => onChanged('dark'),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _ThemeCard(
            label: L.of(context)!.settings_theme_value_auto,
            selected: selectedTheme == 'system',
            preview: const _ThemePreview.system(),
            onTap: () => onChanged('system'),
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(26.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26.0),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: Column(
            children: [
              preview,
              const SizedBox(height: 10.0),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionDialogTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionDialogTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final Color left;
  final Color right;
  final bool split;

  const _ThemePreview.light()
      : left = const Color(0xfff7faf6),
        right = const Color(0xfff7faf6),
        split = false;

  const _ThemePreview.dark()
      : left = const Color(0xff2d312f),
        right = const Color(0xff2d312f),
        split = false;

  const _ThemePreview.system()
      : left = const Color(0xfff7faf6),
        right = const Color(0xff2d312f),
        split = true;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: split
            ? Row(
                children: [
                  Expanded(child: ColoredBox(color: left)),
                  Expanded(child: ColoredBox(color: right)),
                ],
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: left,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                              alpha: split
                                  ? 0.0
                                  : left.computeLuminance() > 0.5
                                      ? 0.08
                                      : 0.14),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Container(
                        width: 38.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                              alpha: split
                                  ? 0.0
                                  : left.computeLuminance() > 0.5
                                      ? 0.08
                                      : 0.14),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ValueLabel<T> {
  final T value;
  final String label;

  const _ValueLabel(this.value, this.label);
}

class _BackgroundAnalysisRunPage extends StatefulWidget {
  const _BackgroundAnalysisRunPage();

  @override
  State<_BackgroundAnalysisRunPage> createState() => _BackgroundAnalysisRunPageState();
}

class _BackgroundAnalysisRunPageState extends State<_BackgroundAnalysisRunPage> {
  final List<_LogLine> _lines = [];
  final ScrollController _scroll = ScrollController();
  StreamSubscription<LogRecord>? _logSub;
  bool _done = false;
  bool _failed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _logSub = Logger.root.onRecord.listen((r) {
      if (!_isRelevant(r.loggerName)) return;
      if (!mounted) return;
      setState(() {
        _lines.add(_LogLine(
          level: r.level,
          logger: r.loggerName,
          message: r.message,
          error: r.error?.toString(),
        ));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    });
    _run();
  }

  bool _isRelevant(String name) {
    return name.contains('Analysis') ||
        name.contains('Gemma') ||
        name.contains('Whisper') ||
        name.contains('Transcription') ||
        name.contains('Checkpoint') ||
        name.contains('Supersession') ||
        name.contains('AdSegment');
  }

  Future<void> _run() async {
    try {
      await runBackgroundAnalysisOnce();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _error = e.toString();
      });
    }
    if (!mounted) return;
    setState(() => _done = true);
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _done
        ? (_failed ? 'Failed: $_error' : 'Pass complete')
        : 'Running…';
    final statusColor = _done
        ? (_failed ? theme.colorScheme.error : theme.colorScheme.primary)
        : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background analysis (dev)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy_outlined),
            tooltip: 'Copy log to clipboard',
            onPressed: _lines.isEmpty
                ? null
                : () {
                    final text = _lines.map((l) => l.format()).join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Log copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHigh,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                if (!_done)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _failed ? Icons.error_outline : Icons.check_circle_outline,
                    color: statusColor,
                    size: 18,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.bodyMedium?.copyWith(color: statusColor),
                  ),
                ),
                Text(
                  '${_lines.length} lines',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _lines.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for log output…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _lines.length,
                    itemBuilder: (_, i) => _LogLineView(line: _lines[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogLine {
  final Level level;
  final String logger;
  final String message;
  final String? error;

  const _LogLine({
    required this.level,
    required this.logger,
    required this.message,
    this.error,
  });

  String format() {
    final base = '${level.name.padRight(7)} $logger: $message';
    return error == null ? base : '$base\n    error: $error';
  }
}

class _LogLineView extends StatelessWidget {
  final _LogLine line;

  const _LogLineView({required this.line});

  Color _colorFor(BuildContext context, Level level) {
    final scheme = Theme.of(context).colorScheme;
    if (level >= Level.SEVERE) return scheme.error;
    if (level >= Level.WARNING) return Colors.orange;
    if (level >= Level.INFO) return scheme.primary;
    return scheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorFor(context, line.level);
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier'],
      height: 1.35,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: mono,
          children: [
            TextSpan(
              text: '${line.level.name.padRight(7)} ',
              style: mono?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: '${line.logger}: ',
              style: mono?.copyWith(color: theme.colorScheme.outline),
            ),
            TextSpan(
              text: line.message,
              style: mono?.copyWith(color: theme.colorScheme.onSurface),
            ),
            if (line.error != null)
              TextSpan(
                text: '\n    ${line.error}',
                style: mono?.copyWith(color: theme.colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
