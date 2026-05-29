import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../widgets/app_shell_layout.dart';
import '../controllers/profile_controller.dart';
import '../data/profile_age_band.dart';
import '../data/profile_avatars.dart';
import '../widgets/profile_avatar_picker.dart';
import '../widgets/profile_avatar_widget.dart';

/// Editar perfil: nome, idade e avatar.
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  ProfileController? _profileCtrl;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedAvatarId = 'girl1';
  String _previewImageUrl = kProfileAvatars.first.pngUrl;
  bool _customPhotoSelected = false;
  var _saving = false;
  var _uploadingPhoto = false;

  ProfileController get profileCtrl {
    _profileCtrl ??= Get.find<ProfileController>();
    return _profileCtrl!;
  }

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    final c = profileCtrl;
    _nameController.text = c.userName.value;
    _ageController.text = '${c.userAge.value}';
    _selectedAvatarId = c.avatarId.value;

    final icone = c.icone.value;
    final fromUrl = profileAvatarIdFromUrl(icone);
    if (icone.isNotEmpty && fromUrl == null) {
      _customPhotoSelected = true;
      _previewImageUrl = icone;
    } else {
      _customPhotoSelected = false;
      _previewImageUrl =
          findProfileAvatar(_selectedAvatarId)?.pngUrl ?? kProfileAvatars.first.pngUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onAvatarSelected(ProfileAvatarOption avatar) {
    setState(() {
      _selectedAvatarId = avatar.id;
      _previewImageUrl = avatar.pngUrl;
      _customPhotoSelected = false;
    });
  }

  Future<void> _save() async {
    if (_saving || _uploadingPhoto) return;

    // Lê os campos ANTES de qualquer await/setState que possa invalidar o controller.
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final avatarId = _selectedAvatarId;

    if (name.isEmpty) {
      AppMessenger.info('Informe o nome.');
      return;
    }
    final age = int.tryParse(ageText) ?? profileCtrl.userAge.value;

    if (!mounted) return;
    setState(() => _saving = true);

    var ok = false;
    try {
      ok = await profileCtrl.updateProfile(
        name: name,
        age: age.clamp(1, 99),
        selectedAvatarId: avatarId,
      );
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    if (ok) {
      if (mounted) Navigator.of(context).pop();
      AppMessenger.success('Perfil atualizado com sucesso');
      return;
    }

    if (profileCtrl.error.value.isNotEmpty) {
      AppMessenger.error(profileCtrl.error.value);
    }
    setState(() => _saving = false);
  }

  Future<void> _uploadPhoto() async {
    if (_saving || _uploadingPhoto) return;

    if (!mounted) return;
    setState(() => _uploadingPhoto = true);

    var ok = false;
    try {
      ok = await profileCtrl.pickAndUploadProfileImage(context);
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    if (ok) {
      AppMessenger.success('Foto de perfil atualizada');
      setState(() {
        _customPhotoSelected = true;
        _previewImageUrl = profileCtrl.icone.value;
      });
    } else if (profileCtrl.error.value.isNotEmpty) {
      AppMessenger.error(profileCtrl.error.value);
    }

    setState(() => _uploadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellLayout(
      body: Container(
        color: AppLayoutTokens.scaffoldBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                child: Row(
                  children: [
                    _roundButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '✏️ Editar Perfil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppLayoutTokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _saving || _uploadingPhoto,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _labeledField(
                              label: 'Nome',
                              child: TextField(
                                controller: _nameController,
                                decoration: _inputDecoration(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeledField(
                              label: 'Idade',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ProfileAgeBand.forAge(
                                      int.tryParse(_ageController.text.trim()) ??
                                          profileCtrl.userAge.value,
                                    ).display,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppLayoutTokens.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: AppLayoutTokens.primary, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Avatar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppLayoutTokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: ProfileAvatarWidget(
                                imageUrl: _previewImageUrl,
                                avatarId: _customPhotoSelected ? null : _selectedAvatarId,
                                radius: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ProfileAvatarPicker(
                              selectedId: _selectedAvatarId,
                              customUrlSelected: _customPhotoSelected,
                              onSelected: _onAvatarSelected,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _uploadPhoto,
                              icon: _uploadingPhoto
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppLayoutTokens.primary,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                              label: Text(
                                _uploadingPhoto
                                    ? 'Enviando foto…'
                                    : 'Enviar foto personalizada',
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                foregroundColor: AppLayoutTokens.primary,
                                side: BorderSide(color: AppLayoutTokens.subtleBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Material(
                        elevation: 4,
                        shadowColor: AppLayoutTokens.primary.withAlpha(80),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _save,
                          child: Ink(
                            decoration: BoxDecoration(
                              color: AppLayoutTokens.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: _saving
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Salvar Alterações',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppLayoutTokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppLayoutTokens.primary.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppLayoutTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppLayoutTokens.scaffoldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppLayoutTokens.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppLayoutTokens.primary, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppLayoutTokens.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppLayoutTokens.cardBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppLayoutTokens.textPrimary),
        ),
      ),
    );
  }
}
