import '../models/diary_entry.dart';

/// Contrato de acesso ao diário de cuidados.
abstract class DiaryRepository {
  /// Registros de uma planta, do mais recente para o mais antigo.
  Future<List<DiaryEntry>> getByPlant(String plantId, {int? limit});
  Future<List<DiaryEntry>> getAll();
  Future<void> add(DiaryEntry entry);
  Future<void> delete(String entryId);
  Future<void> deleteByPlant(String plantId);
}
