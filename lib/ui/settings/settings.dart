// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/opml_bloc.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/core/environment.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/l10n/L.dart';
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
                const _SectionLabel(label: 'AI'),
                _SettingsCard(
                  children: [
                    _ActionSettingsTile(
                      icon: Icons.subtitles_outlined,
                      title: 'Transcription provider',
                      subtitle: _transcriptionProviderLabel(settings.transcriptionProvider),
                      onTap: () => _showTranscriptionProviderDialog(settings),
                    ),
                    _ActionSettingsTile(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Ad analysis provider',
                      subtitle: _analysisProviderLabel(settings.transcriptUploadProvider),
                      onTap: () => _showAnalysisProviderDialog(settings),
                    ),
                    if (_supportsAnalysisModelSelection(settings.transcriptUploadProvider))
                      _ActionSettingsTile(
                        icon: Icons.tune_outlined,
                        title: 'Analysis model',
                        subtitle: _analysisModelLabel(settings),
                        onTap: () => _showAnalysisModelDialog(settings),
                      ),
                    if (settings.transcriptUploadProvider == TranscriptUploadProvider.openAi ||
                        settings.transcriptionProvider == TranscriptionProvider.openAi)
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
                    if (settings.transcriptUploadProvider == TranscriptUploadProvider.grok)
                      FutureBuilder<String?>(
                        future: Provider.of<SecureSecretsService>(context, listen: false).read(grokApiKeySecret),
                        builder: (context, snapshot) {
                          return _ActionSettingsTile(
                            icon: Icons.vpn_key_outlined,
                            title: 'Grok API key',
                            subtitle: _apiKeyLabel(snapshot.data),
                            onTap: () => _showApiKeyDialog(
                              title: 'Grok API key',
                              secretKey: grokApiKeySecret,
                              hintText: 'xai-...',
                            ),
                          );
                        },
                      ),
                    if (settings.transcriptUploadProvider == TranscriptUploadProvider.gemini)
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
                  child: Text(
                    'Version ${Environment.projectVersion}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      letterSpacing: 1.0,
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

  String _analysisProviderLabel(TranscriptUploadProvider provider) {
    switch (provider) {
      case TranscriptUploadProvider.disabled:
        return 'Disabled';
      case TranscriptUploadProvider.openAi:
        return 'OpenAI';
      case TranscriptUploadProvider.grok:
        return 'Grok';
      case TranscriptUploadProvider.gemini:
        return 'Gemini (audio-direct)';
      case TranscriptUploadProvider.analysisBackend:
        return 'Private backend';
    }
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

  bool _supportsAnalysisModelSelection(TranscriptUploadProvider provider) {
    return provider == TranscriptUploadProvider.openAi ||
        provider == TranscriptUploadProvider.grok ||
        provider == TranscriptUploadProvider.gemini;
  }

  String _analysisModelLabel(AppSettings settings) {
    switch (settings.transcriptUploadProvider) {
      case TranscriptUploadProvider.openAi:
        return settings.openAiAnalysisModel;
      case TranscriptUploadProvider.grok:
        return settings.grokAnalysisModel;
      case TranscriptUploadProvider.gemini:
        return settings.geminiAnalysisModel;
      case TranscriptUploadProvider.disabled:
      case TranscriptUploadProvider.analysisBackend:
        return 'Not available';
    }
  }

  Future<void> _showAnalysisProviderDialog(AppSettings settings) async {
    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    final options = <_ValueLabel<TranscriptUploadProvider>>[
      const _ValueLabel(TranscriptUploadProvider.disabled, 'Disabled'),
      const _ValueLabel(TranscriptUploadProvider.openAi, 'OpenAI'),
      const _ValueLabel(TranscriptUploadProvider.grok, 'Grok'),
      const _ValueLabel(TranscriptUploadProvider.gemini, 'Gemini (audio-direct)'),
      if (Environment.hasAnalysisBackend)
        const _ValueLabel(TranscriptUploadProvider.analysisBackend, 'Private backend'),
    ];

    await showPlatformDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        var selected = settings.transcriptUploadProvider;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Ad analysis provider',
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
                        settingsBloc.setTranscriptUploadProvider(option.value);
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

    if (!_supportsAnalysisModelSelection(provider)) {
      return;
    }

    final settingsBloc = Provider.of<SettingsBloc>(context, listen: false);
    final secureSecretsService = Provider.of<SecureSecretsService>(context, listen: false);
    final catalogService = EpisodeAnalysisModelCatalogService(
      secureSecretsService: secureSecretsService,
    );
    final loadModels = catalogService.listModels(provider: provider);
    final currentModel = _analysisModelLabel(settings);

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
