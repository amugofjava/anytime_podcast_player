// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/entities/ad_segment.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/transcript.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Episode serialization', () {
    test('round-trips analysis metadata and ad segments', () {
      final publicationDate = DateTime(2025, 1, 2, 3, 4, 5);
      final lastUpdated = DateTime(2025, 1, 2, 4, 5, 6);
      final analysisUpdatedAt = DateTime(2025, 1, 2, 5, 6, 7);

      final episode = Episode(
        id: 42,
        guid: 'EP-ANALYSIS-1',
        pguid: 'POD-1',
        podcast: 'Podcast 1',
        title: 'Episode 1',
        publicationDate: publicationDate,
        lastUpdated: lastUpdated,
        analysisStatus: 'completed',
        analysisJobId: 'job-123',
        analysisError: null,
        analysisUpdatedAt: analysisUpdatedAt,
        adSegments: const <AdSegment>[
          AdSegment(
            startMs: 1000,
            endMs: 30000,
            reason: 'midroll',
            confidence: 0.92,
            flags: <String>['music_bed', 'host_read'],
          ),
          AdSegment(
            startMs: 61000,
            endMs: 90000,
            reason: 'preroll',
            confidence: 0.64,
            flags: <String>[],
          ),
        ],
      );

      final restored = Episode.fromMap(episode.id, episode.toMap());

      expect(restored, episode);
      expect(restored.analysisStatus, 'completed');
      expect(restored.analysisJobId, 'job-123');
      expect(restored.analysisUpdatedAt, analysisUpdatedAt);
      expect(restored.adSegments, episode.adSegments);
    });

    test('loads legacy persisted episodes without analysis fields', () {
      final publicationDate = DateTime(2025, 2, 3, 4, 5, 6);
      final lastUpdated = DateTime(2025, 2, 3, 5, 6, 7);

      final legacyMap = Episode(
        id: 7,
        guid: 'EP-LEGACY-1',
        pguid: 'POD-LEGACY',
        podcast: 'Legacy Podcast',
        title: 'Legacy Episode',
        publicationDate: publicationDate,
        lastUpdated: lastUpdated,
      ).toMap()
        ..remove('analysisStatus')
        ..remove('analysisJobId')
        ..remove('analysisError')
        ..remove('analysisUpdatedAt')
        ..remove('adSegments');

      final restored = Episode.fromMap(7, legacyMap);

      expect(restored.guid, 'EP-LEGACY-1');
      expect(restored.analysisStatus, isNull);
      expect(restored.analysisJobId, isNull);
      expect(restored.analysisError, isNull);
      expect(restored.analysisUpdatedAt, isNull);
      expect(restored.adSegments, isEmpty);
    });
  });

  group('Transcript serialization', () {
    test('round-trips transcript provenance metadata', () {
      final transcript = Transcript(
        id: 9,
        guid: 'EP-TRANSCRIPT-1',
        provenance: TranscriptProvenance.localAi,
        provider: 'whisper',
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 2),
            data: 'Hello',
          ),
        ],
      );

      final restored = Transcript.fromMap(transcript.id, transcript.toMap());

      expect(restored, transcript);
      expect(restored.provenance, TranscriptProvenance.localAi);
      expect(restored.provider, 'whisper');
    });

    test('defaults legacy transcript records to feed provenance', () {
      final legacyMap = Transcript(
        id: 10,
        guid: 'EP-TRANSCRIPT-LEGACY',
        subtitles: <Subtitle>[
          Subtitle(
            index: 1,
            start: Duration.zero,
            end: const Duration(seconds: 1),
            data: 'Legacy',
          ),
        ],
      ).toMap()
        ..remove('provenance')
        ..remove('provider');

      final restored = Transcript.fromMap(10, legacyMap);

      expect(restored.provenance, TranscriptProvenance.feed);
      expect(restored.provider, isNull);
    });
  });
}
