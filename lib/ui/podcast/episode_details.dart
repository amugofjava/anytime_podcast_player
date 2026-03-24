// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:anytime/bloc/podcast/episode_bloc.dart';
import 'package:anytime/bloc/podcast/queue_bloc.dart';
import 'package:anytime/core/utils.dart';
import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/services/transcription/episode_transcription_service.dart';
import 'package:anytime/state/episode_state.dart';
import 'package:anytime/state/queue_event_state.dart';
import 'package:anytime/ui/podcast/person_avatar.dart';
import 'package:anytime/ui/podcast/transport_controls.dart';
import 'package:anytime/ui/widgets/action_text.dart';
import 'package:anytime/ui/widgets/episode_tile.dart';
import 'package:anytime/ui/widgets/podcast_html.dart';
import 'package:anytime/ui/widgets/tile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// This class renders the more info widget that is accessed from the 'more'
/// button on an episode.
///
/// The widget is displayed as a draggable, scrollable sheet. This contains
/// episode icon and play/pause control, below which the episode title, show
/// notes and person(s) details (if available).
class EpisodeDetails extends StatefulWidget {
  final Episode episode;

  const EpisodeDetails({
    super.key,
    required this.episode,
  });

  @override
  State<EpisodeDetails> createState() => _EpisodeDetailsState();
}

class _EpisodeDetailsState extends State<EpisodeDetails> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episode = widget.episode;

    /// Ensure we do not highlight this as a new episode
    episode.highlight = false;

    return DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExpansionTile(
                    key: const Key('episodemoreinfo'),
                    trailing: PlayControl(
                      episode: episode,
                    ),
                    leading: TileImage(
                      url: episode.thumbImageUrl ?? episode.imageUrl!,
                      size: 56.0,
                      highlight: episode.highlight,
                    ),
                    subtitle: EpisodeSubtitle(episode),
                    title: Text(
                      episode.title!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: false,
                      style: theme.textTheme.bodyMedium,
                    )),
                const Divider(),
                EpisodeToolBar(
                  episode: episode,
                ),
                const Divider(),
                EpisodeAnalysisPanel(
                  episode: episode,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      episode.title!,
                      style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (episode.persons.isNotEmpty)
                  SizedBox(
                    height: 120.0,
                    child: ListView.builder(
                      itemCount: episode.persons.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        return PersonAvatar(person: episode.persons[index]);
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: PodcastHtml(content: episode.content ?? episode.description!),
                )
              ],
            ),
          );
        });
  }
}

class EpisodeToolBar extends StatelessWidget {
  final Episode episode;

  const EpisodeToolBar({
    super.key,
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    final episodeBloc = Provider.of<EpisodeBloc>(context);
    final queueBloc = Provider.of<QueueBloc>(context);

    return StreamBuilder<EpisodeState>(
        stream: episodeBloc.episodeListener.where((e) => e.episode.guid == episode.guid),
        initialData: EpisodeUpdateState(episode),
        builder: (context, episodeSnapshot) {
          return StreamBuilder<QueueState>(
              stream: queueBloc.queue,
              initialData: QueueEmptyState(),
              builder: (context, queueSnapshot) {
                final data = queueSnapshot.data!;
                final queued = queueSnapshot.data!.queue.any((element) => element.guid == episode.guid);

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.delete_outline,
                          semanticLabel: L.of(context)!.delete_episode_button_label,
                          size: 20,
                        ),
                        onPressed: episodeSnapshot.data!.episode.downloaded
                            ? () {
                                showPlatformDialog<void>(
                                  context: context,
                                  useRootNavigator: false,

                                  /// TODO: Extract to own delete dialog for reuse
                                  builder: (_) => BasicDialogAlert(
                                    title: Text(
                                      L.of(context)!.delete_episode_title,
                                    ),
                                    content: Text(L.of(context)!.delete_episode_confirmation),
                                    actions: <Widget>[
                                      BasicDialogAction(
                                        title: ActionText(
                                          L.of(context)!.cancel_button_label,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      BasicDialogAction(
                                        title: ActionText(
                                          L.of(context)!.delete_button_label,
                                        ),
                                        iosIsDefaultAction: true,
                                        iosIsDestructiveAction: true,
                                        onPressed: () {
                                          episodeBloc.deleteDownload(episode);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          queued ? Icons.playlist_add_check_outlined : Icons.playlist_add_outlined,
                          semanticLabel: queued
                              ? L.of(context)!.semantics_remove_from_queue
                              : L.of(context)!.semantics_add_to_queue,
                          size: 20,
                        ),
                        onPressed: data.playing?.guid == episodeSnapshot.data!.episode.guid
                            ? null
                            : () {
                                if (queued) {
                                  queueBloc.queueEvent(QueueRemoveEvent(episode: episode));
                                } else {
                                  queueBloc.queueEvent(QueueAddEvent(episode: episode));
                                }
                              },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          episodeSnapshot.data!.episode.played
                              ? Icons.unpublished_outlined
                              : Icons.check_circle_outline,
                          semanticLabel: episodeSnapshot.data!.episode.played
                              ? L.of(context)!.mark_unplayed_label
                              : L.of(context)!.mark_played_label,
                          size: 20,
                        ),
                        onPressed: () {
                          episodeBloc.togglePlayed(episode);
                        },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.share_outlined,
                          semanticLabel: L.of(context)!.share_episode_option_label,
                          size: 20,
                        ),
                        onPressed: episode.guid.isEmpty
                            ? null
                            : () {
                                _shareEpisode();
                              },
                      ),
                    ],
                  ),
                );
              });
        });
  }

  void _shareEpisode() async {
    await shareEpisode(episode: episode);
  }
}

class EpisodeAnalysisPanel extends StatelessWidget {
  static final _log = Logger('EpisodeAnalysisPanel');
  final Episode episode;

  const EpisodeAnalysisPanel({
    super.key,
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    final episodeBloc = Provider.of<EpisodeBloc>(context, listen: false);
    final theme = Theme.of(context);

    return StreamBuilder<EpisodeState>(
      stream: episodeBloc.episodeListener.where((event) => event.episode.guid == episode.guid),
      initialData: EpisodeUpdateState(episode),
      builder: (context, snapshot) {
        final currentEpisode = snapshot.data!.episode;
        final isAnalyzing = _isAnalyzing(currentEpisode);
        final statusText = _statusText(currentEpisode);
        final transcriptionProvider = episodeBloc.settingsService.transcriptionProvider;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  icon: const Icon(Icons.subtitles_outlined),
                  label: const Text('Generate AI Transcript'),
                  onPressed: currentEpisode.downloaded
                      ? () async {
                          final confirmed = await showPlatformDialog<bool>(
                            context: context,
                            useRootNavigator: false,
                            builder: (_) => BasicDialogAlert(
                              title: Text(_generateTranscriptTitle(transcriptionProvider)),
                              content: Text(_generateTranscriptConfirmationText(transcriptionProvider)),
                              actions: <Widget>[
                                BasicDialogAction(
                                  title: const ActionText('Cancel'),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                BasicDialogAction(
                                  title: const ActionText('Continue'),
                                  iosIsDefaultAction: true,
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) {
                            return;
                          }

                          if (!context.mounted) {
                            return;
                          }

                          await _generateTranscript(
                            context,
                            episodeBloc: episodeBloc,
                            episode: currentEpisode,
                          );
                        }
                      : null,
                ),
                if (_transcriptStatusText(currentEpisode) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _transcriptStatusText(currentEpisode)!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8.0),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  icon: isAnalyzing
                      ? const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Analyze Ads'),
                  onPressed: isAnalyzing || !_canAnalyze(currentEpisode)
                      ? null
                      : () async {
                          final consent = await showPlatformDialog<bool>(
                            context: context,
                            useRootNavigator: false,
                            builder: (_) => BasicDialogAlert(
                              title: const Text('Upload Transcript?'),
                              content: const Text(
                                'This uploads only this episode transcript to the configured external provider for ad analysis. Nothing is uploaded automatically after transcription. Continue?',
                              ),
                              actions: <Widget>[
                                BasicDialogAction(
                                  title: const ActionText('Cancel'),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                BasicDialogAction(
                                  title: const ActionText('Upload'),
                                  iosIsDefaultAction: true,
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (consent != true) {
                            return;
                          }

                          try {
                            await episodeBloc.analyzeAds(
                              currentEpisode,
                              consentToUpload: true,
                            );
                          } catch (error) {
                            if (context.mounted) {
                              final message =
                                  error is EpisodeAnalysisFailedException ? error.message : 'Ad analysis failed.';

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                            }
                          }
                        },
                ),
                if (statusText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      statusText,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (currentEpisode.adSegments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _AdSegmentDiagnostics(
                      adSegments: currentEpisode.adSegments,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isAnalyzing(Episode episode) {
    return episode.analysisStatus == 'queued' || episode.analysisStatus == 'processing';
  }

  Future<void> _generateTranscript(
    BuildContext context, {
    required EpisodeBloc episodeBloc,
    required Episode episode,
  }) async {
    _log.fine('Starting transcript generation for ${episode.guid}');
    BuildContext? dialogContext;
    final progress = ValueNotifier<EpisodeTranscriptionProgress>(
      const EpisodeTranscriptionProgress(
        stage: EpisodeTranscriptionStage.preparing,
        message: 'Preparing local audio...',
      ),
    );

    final dialogClosed = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogBuildContext) {
        dialogContext = dialogBuildContext;
        return _TranscriptionProgressDialog(progress: progress);
      },
    );

    try {
      _setTranscriptionWakelock(true);

      await episodeBloc.generateLocalTranscript(
        episode,
        onProgress: (update) {
          _log.fine(
            'Transcript progress for ${episode.guid}: ${update.stage.name} '
            '${update.progress == null ? '' : '(${(update.progress! * 100).toStringAsFixed(0)}%) '}'
            '${update.message}',
          );
          progress.value = update;
        },
      );

      _log.fine('Transcript generation completed for ${episode.guid}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI transcript ready.')),
        );
      }
    } catch (error, stackTrace) {
      _log.warning('Transcript generation failed for ${episode.guid}', error, stackTrace);
      if (context.mounted) {
        final message = error is EpisodeTranscriptionException ? error.message : 'Transcript generation failed.';

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      _log.fine('Closing transcript dialog for ${episode.guid}');
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      await dialogClosed;
      _setTranscriptionWakelock(false);
      progress.dispose();
    }
  }

  void _setTranscriptionWakelock(bool enabled) {
    final operation = enabled ? WakelockPlus.enable() : WakelockPlus.disable();

    unawaited(operation.catchError((error) {
      // Ignore wakelock failures so transcript generation can still proceed.
      if (error is MissingPluginException || error is PlatformException) {
        return;
      }
    }));
  }

  bool _canAnalyze(Episode episode) {
    final transcript = episode.transcript;

    return transcript != null && transcript.transcriptAvailable && transcript.isAppGeneratedAiTranscript;
  }

  String _generateTranscriptTitle(TranscriptionProvider provider) {
    switch (provider) {
      case TranscriptionProvider.localAi:
        return 'Generate On-Device Transcript?';
      case TranscriptionProvider.openAi:
        return 'Generate OpenAI Transcript?';
    }
  }

  String _generateTranscriptConfirmationText(TranscriptionProvider provider) {
    switch (provider) {
      case TranscriptionProvider.localAi:
        return 'This downloads a Whisper model to your device if needed and transcribes this downloaded episode on this device. Audio stays on this device during transcription.';
      case TranscriptionProvider.openAi:
        return 'This uploads the downloaded audio file for this episode to the OpenAI Whisper API to generate a transcript. Continue only if you want this audio processed by OpenAI.';
    }
  }

  String? _transcriptStatusText(Episode episode) {
    final transcript = episode.transcript;

    if (transcript == null || !transcript.transcriptAvailable) {
      return episode.downloaded ? 'No AI transcript yet.' : 'Download this episode to generate an AI transcript.';
    }

    switch (transcript.provenance) {
      case TranscriptProvenance.localAi:
        return 'On-device AI transcript ready.';
      case TranscriptProvenance.openAi:
        return 'OpenAI transcript ready.';
      case TranscriptProvenance.analysisBackend:
        return 'Analysis transcript stored, but ad skip requires an AI transcript generated in the app.';
      case TranscriptProvenance.feed:
        return 'Feed transcript available. Ad analysis requires an AI transcript generated in the app.';
    }
  }

  String? _statusText(Episode episode) {
    switch (episode.analysisStatus) {
      case 'queued':
      case 'processing':
        return 'Analyzing ads...';
      case 'completed':
        final count = episode.adSegments.length;

        if (count > 0) {
          return 'Analysis complete - $count ${count == 1 ? 'ad segment' : 'ad segments'}';
        }

        return 'Analysis complete';
      case 'failed':
        if (episode.analysisError != null && episode.analysisError!.isNotEmpty) {
          return 'Analysis failed - ${episode.analysisError}';
        }

        return 'Analysis failed';
      default:
        return null;
    }
  }
}

class _AdSegmentDiagnostics extends StatelessWidget {
  const _AdSegmentDiagnostics({
    required this.adSegments,
  });

  final List<AdSegment> adSegments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected ad segments',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8.0),
          ...adSegments.map((segment) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: _AdSegmentDiagnosticsRow(segment: segment),
              )),
        ],
      ),
    );
  }
}

class _AdSegmentDiagnosticsRow extends StatelessWidget {
  const _AdSegmentDiagnosticsRow({
    required this.segment,
  });

  final AdSegment segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = Duration(milliseconds: segment.endMs - segment.startMs);
    final confidence = segment.confidence == null ? null : '${(segment.confidence! * 100).toStringAsFixed(0)}%';
    final flags = segment.flags.where((flag) => flag.trim().isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          '${_formatTimestamp(segment.startMs)} - ${_formatTimestamp(segment.endMs)} '
          '(${_formatDuration(duration)})',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (segment.reason != null && segment.reason!.trim().isNotEmpty)
          Text(
            'Reason: ${segment.reason}',
            style: theme.textTheme.bodySmall,
          ),
        if (confidence != null)
          Text(
            'Confidence: $confidence',
            style: theme.textTheme.bodySmall,
          ),
        if (flags.isNotEmpty)
          Text(
            'Flags: $flags',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  String _formatTimestamp(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (duration.inHours > 0) {
      final hours = duration.inHours;
      return '${hours}h ${minutes % 60}m ${seconds.toString().padLeft(2, '0')}s';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }

    return '${seconds}s';
  }
}

class _TranscriptionProgressDialog extends StatelessWidget {
  final ValueNotifier<EpisodeTranscriptionProgress> progress;

  const _TranscriptionProgressDialog({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: _TranscriptionProgressBody(progress: progress),
    );
  }
}

class _TranscriptionProgressBody extends StatefulWidget {
  final ValueNotifier<EpisodeTranscriptionProgress> progress;

  const _TranscriptionProgressBody({
    required this.progress,
  });

  @override
  State<_TranscriptionProgressBody> createState() => _TranscriptionProgressBodyState();
}

class _TranscriptionProgressBodyState extends State<_TranscriptionProgressBody> {
  late EpisodeTranscriptionStage _stage;
  late DateTime _stageStartedAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _stage = widget.progress.value.stage;
    _stageStartedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EpisodeTranscriptionProgress>(
      valueListenable: widget.progress,
      builder: (context, state, _) {
        if (state.stage != _stage) {
          _stage = state.stage;
          _stageStartedAt = DateTime.now();
        }

        final elapsed = DateTime.now().difference(_stageStartedAt);
        final eta = _estimateRemaining(
          elapsed: elapsed,
          progress: state.progress,
        );

        return AlertDialog(
          title: const Text('Generating AI Transcript'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 12.0),
              if (!state.isIndeterminate)
                Text(
                  '${(state.progress! * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8.0),
              Text(state.message),
              const SizedBox(height: 10.0),
              Text(
                _timingText(
                  stage: state.stage,
                  elapsed: elapsed,
                  eta: eta,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Duration? _estimateRemaining({
    required Duration elapsed,
    required double? progress,
  }) {
    if (progress == null || progress <= 0 || progress >= 1) {
      return null;
    }

    final remainingMilliseconds = (elapsed.inMilliseconds * (1 - progress) / progress).round();
    return Duration(milliseconds: remainingMilliseconds);
  }

  String _timingText({
    required EpisodeTranscriptionStage stage,
    required Duration elapsed,
    required Duration? eta,
  }) {
    final elapsedLabel = _formatDuration(elapsed);

    if (eta != null) {
      return 'Elapsed $elapsedLabel • About ${_formatDuration(eta)} left';
    }

    switch (stage) {
      case EpisodeTranscriptionStage.downloadingModel:
      case EpisodeTranscriptionStage.uploading:
        return 'Elapsed $elapsedLabel • Estimating time remaining...';
      case EpisodeTranscriptionStage.transcribing:
        return 'Elapsed $elapsedLabel • Time remaining depends on device speed.';
      case EpisodeTranscriptionStage.preparing:
        return 'Elapsed $elapsedLabel';
      case EpisodeTranscriptionStage.completed:
        return 'Finishing up...';
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes <= 0) {
      return '${seconds}s';
    }

    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}
