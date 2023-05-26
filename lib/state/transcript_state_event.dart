// Copyright 2020-2022 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.9

import 'package:anytime/entities/transcript.dart';
import 'package:flutter/material.dart';

/// Events
abstract class TranscriptEvent {}

class TranscriptClearEvent extends TranscriptEvent {}

class TranscriptFilterEvent extends TranscriptEvent {
  final String search;

  TranscriptFilterEvent({@required this.search});
}

/// State
abstract class TranscriptState {
  final Transcript transcript;
  final bool isFiltered;

  TranscriptState({
    @required this.transcript,
    this.isFiltered = false,
  });
}

class TranscriptUnavailableState extends TranscriptState {}

class TranscriptLoadingState extends TranscriptState {}

class TranscriptUpdateState extends TranscriptState {
  TranscriptUpdateState({@required Transcript transcript}) : super(transcript: transcript);
}
