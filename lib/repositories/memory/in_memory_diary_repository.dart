import '../../models/diary_entry.dart';
import '../diary_repository.dart';

class InMemoryDiaryRepository implements DiaryRepository {
  final List<DiaryEntry> _entries = [];

  List<DiaryEntry> get _sorted =>
      [..._entries]..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<List<DiaryEntry>> getByPlant(String plantId, {int? limit}) async {
    final list = _sorted.where((e) => e.plantId == plantId);
    return (limit == null ? list : list.take(limit)).toList();
  }

  @override
  Future<List<DiaryEntry>> getAll() async => _sorted;

  @override
  Future<void> add(DiaryEntry entry) async => _entries.add(entry);

  @override
  Future<void> delete(String entryId) async =>
      _entries.removeWhere((e) => e.id == entryId);

  @override
  Future<void> deleteByPlant(String plantId) async =>
      _entries.removeWhere((e) => e.plantId == plantId);
}
