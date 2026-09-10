import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/models/trash_entry.dart';
import '../../gallery/providers/gallery_providers.dart';
import '../data/trash_repository.dart';

class TrashNotifier extends StateNotifier<List<TrashEntry>> {
  TrashNotifier(this._repo) : super(_repo.listAll());

  final TrashRepository _repo;

  void refresh() => state = _repo.listAll();

  Future<void> restore(TrashEntry entry) async {
    await _repo.restore(entry);
    refresh();
  }

  Future<void> permanentlyDelete(TrashEntry entry) async {
    await _repo.permanentlyDelete(entry);
    refresh();
  }

  Future<void> purgeExpired() async {
    await _repo.purgeExpired();
    refresh();
  }
}

final trashProvider = StateNotifierProvider<TrashNotifier, List<TrashEntry>>(
  (ref) => TrashNotifier(ref.watch(trashRepositoryProvider)),
);
