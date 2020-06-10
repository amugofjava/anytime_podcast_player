// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The BLoCs in this application share common states, such as loading, error
/// or populated. Rather than having a separate selection of state classes, we
/// create this generic one.
enum BlocErrorType { unknown, connectivity, timeout }

abstract class BlocState<T> {}

class BlocDefaultState<T> extends BlocState<T> {}

class BlocLoadingState<T> extends BlocState<T> {}

class BlocSuccessfulState<T> extends BlocState<T> {}

class BlocEmptyState<T> extends BlocState<T> {}

class BlocErrorState<T> extends BlocState<T> {
  final BlocErrorType error;

  BlocErrorState({
    this.error = BlocErrorType.unknown,
  });
}

class BlocNoInputState<T> extends BlocState<T> {}

class BlocPopulatedState<T> extends BlocState<T> {
  final T results;

  BlocPopulatedState(this.results);
}
