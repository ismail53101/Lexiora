import 'package:lexiora/features/home/data/current_affairs_api_client.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';

abstract class CurrentAffairsRepository {
  Future<CurrentAffairsFeed> fetchLatest();
}

class CurrentAffairsRepositoryImpl implements CurrentAffairsRepository {
  const CurrentAffairsRepositoryImpl(this._client);

  final CurrentAffairsApiClient _client;

  @override
  Future<CurrentAffairsFeed> fetchLatest() => _client.fetchLatest();
}
