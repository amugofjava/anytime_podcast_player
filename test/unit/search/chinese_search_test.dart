// 一次性验证：用项目实际使用的 podcast_search 库测试中文搜索（网络测试）
import 'package:flutter_test/flutter_test.dart';
import 'package:podcast_search/podcast_search.dart';

void main() {
  test('iTunes 中文搜索能返回国内播客', () async {
    final search = Search(searchProvider: const ITunesProvider());
    final result = await search.search(
      '科技',
      country: Country.china,
      language: 'zh_cn',
      limit: 10,
    );

    expect(result.items, isNotEmpty);
    expect(result.items.first.collectionName, isNotEmpty);
    // ignore: avoid_print
    print('中文搜索「科技」返回 ${result.items.length} 个结果:');
    for (final item in result.items.take(5)) {
      // ignore: avoid_print
      print('  - ${item.collectionName}');
    }
  });

  test('iTunes 能搜到小宇宙独占节目（声东击西）', () async {
    final search = Search(searchProvider: const ITunesProvider());
    final result = await search.search(
      '声东击西',
      limit: 5,
    );

    expect(result.items, isNotEmpty);
    // ignore: avoid_print
    print('搜索「声东击西」: ${result.items.map((e) => e.collectionName).toList()}');
  });
}
