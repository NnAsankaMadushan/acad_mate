import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/domain/entities/task.dart';
import 'package:acad_mate/domain/repositories/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksController extends AsyncNotifier<List<Task>> {
  late TaskRepository _repo;
  late String _uid;

  @override
  Future<List<Task>> build() async {
    _repo = ref.watch(taskRepositoryProvider);
    final String? uid = ref.watch(authStateProvider).value?.uid;
    if (uid == null) return <Task>[];
    _uid = uid;

    final List<Task> initial = await _repo.watchTasks(uid).first;

    // Keep state in sync with Firestore stream and cancel on dispose.
    final subscription = _repo.watchTasks(uid).listen(
      (List<Task> tasks) => state = AsyncData<List<Task>>(tasks),
    );
    ref.onDispose(subscription.cancel);

    return initial;
  }

  Future<void> add(Task task) => _repo.saveTask(_uid, task);

  Future<void> toggle(String id) async {
    final List<Task> current = state.asData?.value ?? <Task>[];
    final Task? task = current.where((Task t) => t.id == id).firstOrNull;
    if (task == null) return;
    await _repo.saveTask(_uid, task.copyWith(isDone: !task.isDone));
  }

  Future<void> edit(Task updated) => _repo.saveTask(_uid, updated);

  Future<void> remove(String id) => _repo.deleteTask(_uid, id);
}
