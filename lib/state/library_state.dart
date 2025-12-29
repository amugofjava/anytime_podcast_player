// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class LibraryState {}

class LibraryRefreshingState extends LibraryState {}

class LibraryReadyState extends LibraryState {}

class LibraryUpdatedState extends LibraryState {}
