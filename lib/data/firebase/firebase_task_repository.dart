import 'package:acad_mate/domain/entities/task.dart';
import 'package:acad_mate/domain/repositories/task_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTaskRepository implements TaskRepository {
  FirebaseTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  @override
  Stream<List<Task>> watchTasks(String uid) {
    return _tasksRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    Task.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  @override
  Future<void> saveTask(String uid, Task task) async {
    final Map<String, dynamic> data = task.toMap();
    final DocumentReference<Map<String, dynamic>> ref =
        _tasksRef(uid).doc(task.id);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    if (!snap.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteTask(String uid, String taskId) =>
      _tasksRef(uid).doc(taskId).delete();
}
