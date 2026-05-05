import 'package:hive_flutter/hive_flutter.dart';
import '../models/editor_models.dart';

class ProjectService {
  static const String _boxName = 'projects';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> saveProject(Project project) async {
    final box = Hive.box(_boxName);
    await box.put(project.id, project.toJson());
  }

  static Future<void> deleteProject(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  static List<Project> getAllProjects() {
    final box = Hive.box(_boxName);
    return box.values.map((v) => Project.fromJson(Map<String, dynamic>.from(v))).toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  static Project? getProject(String id) {
    final box = Hive.box(_boxName);
    final data = box.get(id);
    if (data == null) return null;
    return Project.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<void> duplicateProject(String id) async {
    final project = getProject(id);
    if (project != null) {
      final newProject = project.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${project.name} Copy',
        lastModified: DateTime.now(),
      );
      await saveProject(newProject);
    }
  }
}
