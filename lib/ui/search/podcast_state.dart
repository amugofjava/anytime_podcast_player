// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class PodcastState {}

class MarkAllPlayedState extends PodcastState {}

class ClearAllPlayedState extends PodcastState {}
