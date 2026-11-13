import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../dashboard/dashboard_layout.dart';

class AddEditEventScreen extends StatefulWidget {
  final EventModel? event; // Null if Adding, non-null if Editing

  const AddEditEventScreen({super.key, this.event});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late bool _isEditMode;
  
  final _nameController = TextEditingController();
  final _picController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedStatus = 'Aktif';
  String _selectedCategory = 'Organisasi';

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.event != null;
    
    if (_isEditMode) {
      final e = widget.event!;
      _nameController.text = e.name;
      _picController.text = e.pic;
      _locationController.text = e.location;
      _descriptionController.text = e.description;
      _selectedDate = e.date;
      _selectedStatus = e.status;
      _selectedCategory = e.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _picController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryIndigo,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimeOfDayPicker();
    
    if (pickedTime == null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<TimeOfDay?> showTimeOfDayPicker() {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryIndigo,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? AppTheme.accentPink : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      if (_isEditMode) {
        // UPDATE CRUD
        await appState.updateEvent(
          id: widget.event!.id,
          name: _nameController.text.trim(),
          pic: _picController.text.trim(),
          date: _selectedDate,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          category: _selectedCategory,
          createdAt: widget.event!.createdAt,
        );
        _showSnackbar('Event berhasil diperbarui!', isError: false);
      } else {
        // CREATE CRUD
        await appState.addEvent(
          name: _nameController.text.trim(),
          pic: _picController.text.trim(),
          date: _selectedDate,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          category: _selectedCategory,
        );
        _showSnackbar('Event baru berhasil ditambahkan!', isError: false);
      }

      if (!mounted) return;

      // Handle redirect depending on how this screen was opened
      if (Navigator.canPop(context)) {
        // If it was pushed on navigation stack (e.g. editing via Edit button)
        Navigator.pop(context);
      } else {
        // If opened as a bottom navigation tab (Adding new event)
        // Reset form inputs
        _nameController.clear();
        _picController.clear();
        _locationController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedDate = DateTime.now().add(const Duration(days: 1));
          _selectedStatus = 'Aktif';
          _selectedCategory = 'Organisasi';
        });

        // Switch bottom tab index to Daftar Event (index 1)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardLayout(initialTab: 1)),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Gagal menyimpan event: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormatted = DateFormat('EEEE, dd MMMM yyyy - HH:mm').format(_selectedDate);
    final categories = ['Akademik', 'Organisasi', 'Lomba', 'Seminar'];
    final statuses = ['Aktif', 'Selesai'];

    final body = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions/Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEditMode 
                    ? AppTheme.primaryIndigo.withOpacity(0.08)
                    : AppTheme.successGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isEditMode 
                      ? AppTheme.primaryIndigo.withOpacity(0.2)
                      : AppTheme.successGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                    color: _isEditMode ? AppTheme.primaryIndigo : AppTheme.successGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditMode 
                          ? 'Perbarui formulir di bawah ini untuk mengubah data kegiatan kampus.'
                          : 'Lengkapi formulir untuk mempublikasikan event atau kegiatan baru.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isEditMode ? AppTheme.primaryIndigo : AppTheme.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Event Name
            CustomTextField(
              controller: _nameController,
              labelText: 'Nama Event / Kegiatan',
              hintText: 'Masukkan nama kegiatan',
              prefixIcon: Icons.title_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama event tidak boleh kosong';
                }
                return null;
              },
            ),

            // 2. PIC / Penanggung Jawab
            CustomTextField(
              controller: _picController,
              labelText: 'Penanggung Jawab (PIC)',
              hintText: 'Nama lengkap PIC event',
              prefixIcon: Icons.person_pin_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama penanggung jawab wajib diisi';
                }
                return null;
              },
            ),

            // 3. Date Selection Row (Date Picker field)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard.withOpacity(0.4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.1) : Colors.indigo.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.indigo.withOpacity(0.03),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          color: isDark ? AppTheme.secondaryIndigo : AppTheme.primaryIndigo,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal & Waktu Event',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormatted,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_right_rounded,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Location input
            CustomTextField(
              controller: _locationController,
              labelText: 'Lokasi Event',
              hintText: 'Nama gedung, ruangan, zoom link...',
              prefixIcon: Icons.map_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Lokasi event tidak boleh kosong';
                }
                return null;
              },
            ),

            // 5. Category Dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard.withOpacity(0.4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.1) : Colors.indigo.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Kategori Event',
                  labelStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.category_rounded,
                    color: isDark ? AppTheme.secondaryIndigo : AppTheme.primaryIndigo,
                    size: 22,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.indigo.withOpacity(0.03),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryIndigo,
                      width: 1.5,
                    ),
                  ),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
            ),

            // 6. Status Dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard.withOpacity(0.4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.1) : Colors.indigo.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Status Event',
                  labelStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.check_circle_rounded,
                    color: isDark ? AppTheme.secondaryIndigo : AppTheme.primaryIndigo,
                    size: 22,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.indigo.withOpacity(0.03),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryIndigo,
                      width: 1.5,
                    ),
                  ),
                ),
                items: statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatus = val;
                    });
                  }
                },
              ),
            ),

            // 7. Description TextField
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Deskripsi Event',
              hintText: 'Tuliskan deskripsi detail event...',
              prefixIcon: Icons.description_rounded,
              maxLines: 4,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Deskripsi event wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Submit Button
            Consumer<AppState>(
              builder: (context, appState, _) {
                return CustomButton(
                  text: _isEditMode ? 'Simpan Perubahan' : 'Publikasikan Event',
                  onPressed: _handleSave,
                  isLoading: appState.isLoading,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (Navigator.canPop(context)) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_isEditMode ? 'Edit Data Event' : 'Tambah Event Baru'),
          centerTitle: true,
        ),
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Event Baru'),
        centerTitle: true,
      ),
      body: body,
    );
  }
}
