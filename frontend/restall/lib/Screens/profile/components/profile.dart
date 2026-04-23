import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restall/API/PhotoPic/photoPic.dart';
import 'package:restall/components/top_rounded_container.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/UserProfile.dart';
import 'package:restall/providers/Profile/profile_provider.dart';
import 'package:restall/widget/date_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'dart:convert';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final bool isUpdating = provider.state == ProfileState.loading &&
            provider.userProfile != null;

        return Stack(
          children: [
            _buildContent(context, provider),
            if (isUpdating)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aggiornamento in corso...',
                        style: TextStyle(
                          color: white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ProfileProvider provider) {
    switch (provider.state) {
      case ProfileState.loading:
        return provider.userProfile == null
            ? const _ProfileSkeleton()
            : _ProfileForm(userProfile: provider.userProfile!);
      case ProfileState.error:
        return _ProfileError(
          message: provider.errorMessage ?? 'Si è verificato un errore.',
          onRetry: () => provider.fetchProfile(forceRefresh: true),
        );
      case ProfileState.idle:
        if (provider.userProfile != null) {
          return _ProfileForm(userProfile: provider.userProfile!);
        }
        return _ProfileError(
          message: 'Impossibile caricare i dati del profilo.',
          onRetry: () => provider.fetchProfile(forceRefresh: true),
        );
    }
  }
}

class _ProfileForm extends StatefulWidget {
  final UserProfile userProfile;
  const _ProfileForm({required this.userProfile});

  @override
  __ProfileFormState createState() => __ProfileFormState();
}

class __ProfileFormState extends State<_ProfileForm>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _cfController;
  late TextEditingController _numTelController;
  late TextEditingController _dateController;
  late TextEditingController _refController;
  late TextEditingController _parentIdController;

  // Image handling
  XFile? _pickedFile;
  CroppedFile? _croppedFile;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  // Animations
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers(widget.userProfile);
    _loadProfileImage();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void didUpdateWidget(covariant _ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProfile != oldWidget.userProfile) {
      _initializeControllers(widget.userProfile);
    }
  }

  void _initializeControllers(UserProfile profile) {
    _firstNameController = TextEditingController(text: profile.nome);
    _lastNameController = TextEditingController(text: profile.cognome);
    _cfController = TextEditingController(text: profile.codFiscale ?? '');
    _numTelController = TextEditingController(text: profile.numTel ?? '');
    _dateController = TextEditingController(text: profile.dataNascita ?? '');
    _refController = TextEditingController(text: profile.referral ?? '');
    _parentIdController = TextEditingController(text: profile.parentId ?? '');
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cfController.dispose();
    _numTelController.dispose();
    _dateController.dispose();
    _refController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }

  // Image handling methods
  Future<void> _loadProfileImage() async {
    try {
      final response = await PhotoPicApi().getPhotoPic();
      if (response != null && response.statusCode == 200) {
        final body = json.decode(response.body);
        final img = body['file'];
        if (img != null && img['location'] != null && mounted) {
          setState(() {
            _profileImageUrl = img['location'];
          });
        }
      }
    } catch (e) {
      // Silent fallback to default image
      print('Errore caricamento immagine profilo: $e');
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarColor: secondaryColor,
            toolbarWidgetColor: white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            backgroundColor: Colors.black,
          ),
          IOSUiSettings(
            aspectRatioLockEnabled: true,
            doneButtonTitle: 'Fatto',
            cancelButtonTitle: 'Annulla',
            aspectRatioPickerButtonHidden: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _croppedFile = croppedFile;
          _isUploadingImage = true;
        });

        try {
          final response =
              await PhotoPicApi().uploadPhotoPic(_croppedFile!.path);

          if (mounted) {
            setState(() {
              _isUploadingImage = false;
            });

            if (response?.statusCode == 200) {
              await _loadProfileImage();
              _showSuccessSnackBar('Foto profilo aggiornata con successo!');
            } else {
              _showErrorSnackBar('Errore durante l\'upload dell\'immagine');
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isUploadingImage = false;
            });
            _showErrorSnackBar('Errore durante l\'upload dell\'immagine');
          }
        }
      }
    }
  }

  ImageProvider _getProfileImageProvider() {
    if (_croppedFile != null) {
      return FileImage(File(_croppedFile!.path));
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    } else {
      return const AssetImage("assets/images/logo.png");
    }
  }

  // Form handling methods
  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      final updatedProfile = widget.userProfile.copyWith(
        nome: _firstNameController.text.trim(),
        cognome: _lastNameController.text.trim(),
        codFiscale: _cfController.text.trim(),
        numTel: _numTelController.text.trim(),
        dataNascita: _dateController.text.trim(),
        parentId: _parentIdController.text.trim(),
      );

      final success = await provider.updateProfile(updatedProfile);
      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
          });
          _showSuccessSnackBar('Profilo aggiornato con successo!');
        } else {
          _showErrorSnackBar('Aggiornamento fallito: ${provider.errorMessage}');
        }
      }
    }
  }

  void _onCancel() {
    _initializeControllers(widget.userProfile);
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked =
        await datePickProfile(context, _dateController.text);
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // UI Helper methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Section
                _buildAvatarSection(),
                const SizedBox(height: 32),

                // Referral Section
                if (widget.userProfile.referral != null)
                  _buildReferralSection(),

                // Personal Data Section
                _buildSectionHeader(
                  "Dati Personali",
                  icon: Icons.person_rounded,
                  showEditIcon: true,
                  isEditing: _isEditing,
                  onEdit: () => setState(() => _isEditing = true),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  "Nome",
                  _firstNameController,
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Il nome è obbligatorio';
                    }
                    return null;
                  },
                ),

                _buildTextField(
                  "Cognome",
                  _lastNameController,
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Il cognome è obbligatorio';
                    }
                    return null;
                  },
                ),

                _buildTextField(
                  "Codice Fiscale / P.IVA",
                  _cfController,
                  icon: Icons.credit_card_rounded,
                  textCapitalization: TextCapitalization.characters,
                ),

                _buildTextField(
                  "Numero di Telefono",
                  _numTelController,
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),

                _buildDateField(),

                // Action Buttons
                if (_isEditing) _buildActionButtons(),

                const SizedBox(height: 10),

                // Delete Section
                _buildDeleteSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          // Main Avatar Container
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [primaryColor, accentCanvasColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: white,
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[50],
                backgroundImage: _getProfileImageProvider(),
              ),
            ),
          ),

          // Loading Overlay
          if (_isUploadingImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.7),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),

          // Camera Icon - ALWAYS VISIBLE
          if (!_isUploadingImage)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryColor,
                  border: Border.all(color: white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await _uploadImage();
                      if (_pickedFile != null) {
                        await _cropImage();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReferralSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: secondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Il tuo codice referral',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.userProfile.referral ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.userProfile.referral ?? ''));
                    _showSuccessSnackBar('Codice copiato negli appunti!');
                  },
                  icon: const Icon(Icons.copy_rounded),
                  color: secondaryColor,
                ),
                IconButton(
                  onPressed: () {
                    Share.share(
                        'Usa il mio codice referral: ${widget.userProfile.referral}');
                  },
                  icon: const Icon(Icons.share_rounded),
                  color: secondaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required IconData icon,
    bool showEditIcon = false,
    bool isEditing = false,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: secondaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ),
          if (showEditIcon && !isEditing)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              color: secondaryColor,
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        cursorColor: kPrimaryColor,
        decoration: InputDecoration(
          labelText: label,
          hintText: "Inserisci $label",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: icon != null
              ? Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Icon(icon),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: TextFormField(
        controller: _dateController,
        enabled: _isEditing,
        readOnly: true,
        onTap: _isEditing ? () => _selectDate(context) : null,
        cursorColor: kPrimaryColor,
        // 🛡️ VALIDAZIONE MIGLIORATA CON CONTROLLO ETÀ
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'La data di nascita è obbligatoria';
          }

          try {
            DateTime birthDate;

            // Prova diversi formati di data
            try {
              birthDate = DateFormat('dd/MM/yyyy').parse(value);
            } catch (e) {
              birthDate = DateFormat('yyyy-MM-dd').parse(value);
            }

            final now = DateTime.now();
            final age = now.year -
                birthDate.year -
                ((now.month > birthDate.month ||
                        (now.month == birthDate.month &&
                            now.day >= birthDate.day))
                    ? 0
                    : 1);

            // ✅ CONTROLLO ETÀ RIGOROSO
            if (age < 18) {
              return 'Devi avere almeno 18 anni per utilizzare il servizio';
            }

            // 🔍 CONTROLLO RAGIONEVOLEZZA (non più di 120 anni)
            if (age > 120) {
              return 'Data di nascita non valida';
            }

            return null;
          } catch (e) {
            return 'Formato data non valido';
          }
        },
        decoration: InputDecoration(
          labelText: 'Data di Nascita',
          hintText: 'Inserisci la tua data di nascita',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: const Padding(
            padding: EdgeInsets.all(defaultPadding),
            child: Icon(Icons.calendar_month_rounded),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[700],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Salva',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteSection() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: errorColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Zona Pericolosa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Eliminando il tuo account perderai permanentemente tutti i tuoi dati, ordini e cronologia. Questa azione non può essere annullata.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDeleteConfirmDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_forever_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Elimina Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: errorColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Conferma Eliminazione',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Sei sicuro di voler eliminare il tuo account? Tutti i tuoi dati verranno persi permanentemente. Questa azione non può essere annullata.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final provider =
                    Provider.of<ProfileProvider>(context, listen: false);
                final success = await provider.deleteProfile();
                if (!success && mounted) {
                  _showErrorSnackBar(
                      'Eliminazione fallita: ${provider.errorMessage}');
                }
              },
              child: const Text(
                'Elimina',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar skeleton
            const CircleAvatar(radius: 60, backgroundColor: Colors.white),
            const SizedBox(height: 40),

            // Section header skeleton
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form fields skeleton
            ...List.generate(
                5,
                (index) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: errorColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Qualcosa è andato storto',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Riprova',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
