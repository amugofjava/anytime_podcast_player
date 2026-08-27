// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import 'mp3_converter_service.dart';

/// The real [AudioConverterRunner] backed by the ffmpeg-kit plugin.
///
/// This is the only file in the app that touches the native ffmpeg binaries,
/// so everything else stays unit-testable without ffmpeg.
class FFmpegAudioConverterRunner implements AudioConverterRunner {
  @override
  Future<bool> run(List<String> args, {void Function(int percentage)? onProgress}) async {
    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();
    return ReturnCode.isSuccess(returnCode);
  }
}
