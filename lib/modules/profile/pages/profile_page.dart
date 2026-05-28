import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../widgets/app_shell_layout.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showEditNameDialog(BuildContext context, ProfileController controller) {
    final TextEditingController nameController = TextEditingController(
      text: controller.userName.value,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.updateProfile(name: nameController.text.trim());
                Get.back();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    return AppShellLayout(
      appBar: AppBar(
        backgroundColor: AppLayoutTokens.scaffoldBackground,
        foregroundColor: AppLayoutTokens.textPrimary,
        elevation: 0,
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                )
                : null,
        title: const Text('Meu perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.signOut,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.error.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    // Avatar com botão de edição
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              controller.icone.value.isNotEmpty
                                  ? NetworkImage(controller.icone.value)
                                  : null,
                          child:
                              controller.icone.value.isEmpty
                                  ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => controller.pickAndUploadProfileImage(
                                    context,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Nome do usuário com botão de edição
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.userName.value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed:
                              () => _showEditNameDialog(context, controller),
                        ),
                      ],
                    ),
                    // Função do usuário
                    Text(
                      controller.role.value.toUpperCase(),
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    // Formulário de edição
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estatísticas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  'Livros Lidos',
                                  controller.booksRead.value.toString(),
                                  Icons.book,
                                ),
                                _buildStatCard(
                                  'Favoritos',
                                  controller.favorites.value.toString(),
                                  Icons.favorite,
                                ),
                                _buildStatCard(
                                  'Progresso',
                                  controller.booksInProgress.value.toString(),
                                  Icons.trending_up,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final controller = Get.find<ProfileController>();
    return GestureDetector(
      onTap:
          title == 'Livros Lidos'
              ? () async {
                final books = await controller.fetchBooksReadHistory();
                Get.dialog(
                  AlertDialog(
                    title: const Text('Histórico de Livros Lidos'),
                    content: SizedBox(
                      width: 400,
                      child:
                          books.isEmpty
                              ? const Text('Nenhum livro lido ainda.')
                              : ListView.builder(
                                shrinkWrap: true,
                                itemCount: books.length,
                                itemBuilder: (context, index) {
                                  final book = books[index];
                                  return ListTile(
                                    leading:
                                        book['cover_image'] != null
                                            ? Image.network(
                                              book['cover_image'],
                                              width: 40,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            )
                                            : const Icon(Icons.book),
                                    title: Text(book['title'] ?? 'Sem título'),
                                    subtitle: Text(
                                      book['author'] ?? 'Autor desconhecido',
                                    ),
                                  );
                                },
                              ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              }
              : null,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
