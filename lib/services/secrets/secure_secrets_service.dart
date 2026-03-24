// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const openAiApiKeySecret = 'openai_api_key';

abstract class SecureSecretsService {
  Future<String?> read(String key);

  Future<void> write({
    required String key,
    required String value,
  });

  Future<void> delete(String key);
}
