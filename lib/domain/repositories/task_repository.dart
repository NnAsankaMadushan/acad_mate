import 'package:acad_mate/domain/entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasks(String uid);
  Future<void> saveTask(String uid, Task task);
  Future<void> deleteTask(String uid, String taskId);
}
