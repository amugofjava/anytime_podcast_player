import 'package:anytime/repository/repository.dart';
import 'package:flutter/foundation.dart';

abstract class SettingsService {
  final Repository repository;

  SettingsService({
    @required this.repository,
  });

  bool get markDeletedEpisodesAsPlayed;
  set markDeletedEpisodesAsPlayed(bool value);

  bool get storeDownloadsSDCard;
  set storeDownloadsSDCard(bool value);
}
