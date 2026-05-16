import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';
import '../editor_screen.dart';
import 'tutorials_page.dart';
import 'assets_library_screen.dart';
import '../profile/profile_screen.dart';
import '../video_player/video_player_screen.dart';
import '../../config/app_config.dart';

import 'package:intl/intl.dart';
import '../../services/project_service.dart';
import '../../models/editor_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final projects = ProjectService.getAllProjects();
    final editorProvider = context.watch<EditorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Typo Edit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (AppConfig.showHomeProfile)
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (AppConfig.showHomeNewProject) ...[
              _buildActionCard(
                context,
                title: 'New Project',
                subtitle: 'Create a new typography video',
                icon: Icons.add_rounded,
                onTap: () {
                  editorProvider.createNewProject();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
                },
                primary: true,
              ),
              const SizedBox(height: 20),
              if (AppConfig.showHomeAssetsLibrary) ...[
                _buildActionCard(
                  context,
                  title: 'Asset Library',
                  subtitle: 'Manage your overlays and sounds',
                  icon: Icons.auto_awesome_motion_rounded,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetsLibraryScreen()));
                  },
                ),
                const SizedBox(height: 20),
              ],
              if (AppConfig.showImportProjectButton) ...[
                _buildActionCard(
                  context,
                  title: 'Import Project',
                  subtitle: 'Load project from device storage',
                  icon: Icons.file_download_outlined,
                  onTap: () async {
                    final success = await ProjectService.importProject();
                    if (success) {
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Project imported successfully')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ],
            if (AppConfig.showHomeTutorials) ...[
              _buildActionCard(
                context,
                title: 'Tutorials',
                subtitle: 'Learn how to use the editor',
                icon: Icons.play_circle_outline_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialsPage()));
                },
              ),
              const SizedBox(height: 20),
            ],
            if (AppConfig.showHomeNativePlayer) ...[
              _buildActionCard(
                context,
                title: 'Native Player',
                subtitle: 'Play videos with native engine',
                icon: Icons.video_collection_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoPlayerScreen()));
                },
              ),
            ],
            const SizedBox(height: 40),
            const Text(
              'RECENT PROJECTS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            if (projects.isEmpty)
              _buildEmptyProjectsState()
            else
              _buildRecentProjectsList(context, projects, editorProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProjectsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.movie_filter_rounded, size: 64, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 16),
            const Text(
              'No projects yet.\nCreate one to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: primary ? Colors.black : Colors.white,
              size: 28,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primary ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primary ? Colors.black.withOpacity(0.6) : Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: primary ? Colors.black.withOpacity(0.3) : Colors.white10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjectsList(BuildContext context, List<Project> projects, EditorProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final timeStr = DateFormat('MMM d, HH:mm').format(project.lastModified);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              await provider.loadProject(project.id);
              if (mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.movie_outlined, color: Colors.white24, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Modified $timeStr',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white10),
                    color: const Color(0xFF252525),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Rename', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        onTap: () {
                          // Use a delayed future to show dialog after menu closes
                          Future.delayed(Duration.zero, () => _showRenameDialog(context, project));
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Duplicate', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        onTap: () async {
                          await ProjectService.duplicateProject(project.id);
                          setState(() {});
                        },
                      ),
                      if (AppConfig.showExportProjectButton)
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.share_outlined, size: 16, color: Colors.white70),
                              SizedBox(width: 8),
                              Text('Export', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          onTap: () async {
                            await ProjectService.exportProject(project);
                          },
                        ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                          ],
                        ),
                        onTap: () async {
                          await ProjectService.deleteProject(project.id);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, Project project) {
    final controller = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('Rename Project', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Project Name',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final updated = project.copyWith(name: controller.text);
                await ProjectService.saveProject(updated);
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('RENAME', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

