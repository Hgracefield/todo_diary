import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_todo_list_app/model/diary.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class DiaryEditorView extends StatefulWidget {
  const DiaryEditorView({super.key, required this.date});

  final DateTime date;

  @override
  State<DiaryEditorView> createState() => _DiaryEditorViewState();
}

class _DiaryEditorViewState extends State<DiaryEditorView> {
  final db = DatabaseHandler();
  final picker = ImagePicker();
  final textController = TextEditingController();

  Diary? diary;
  List<Uint8List> images = [];
  int selectedImageIndex = 0;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadDiary() async {
    final loadedDiary = await db.getDiaryByDate(_dateKey(widget.date));
    List<Uint8List> loadedImages = [];

    if (loadedDiary != null && loadedDiary.diaryId != null) {
      loadedImages = await db.getDiaryImages(loadedDiary.diaryId!);
      if (loadedImages.isEmpty && loadedDiary.image.isNotEmpty) {
        loadedImages = [loadedDiary.image];
      }
    }

    if (!mounted) return;

    setState(() {
      diary = loadedDiary;
      images = loadedImages;
      selectedImageIndex = 0;
      textController.text = loadedDiary?.content ?? '';
      isLoading = false;
    });
  }

  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final nextImages = <Uint8List>[];
    for (final item in picked) {
      nextImages.add(await item.readAsBytes());
    }

    if (!mounted) return;

    setState(() {
      images = [...images, ...nextImages];
      if (images.isNotEmpty) {
        selectedImageIndex = 0;
      }
    });
  }

  Future<void> _saveDiary() async {
    final content = textController.text.trim();
    if (content.isEmpty && images.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      isSaving = true;
    });

    final coverImage = images.isEmpty ? Uint8List(0) : images.first;

    if (diary == null) {
      final diaryId = await db.insertDiary(
        Diary(
          diaryDate: _dateKey(widget.date),
          content: content,
          image: coverImage,
        ),
        images: images,
      );

      diary = Diary(
        diaryId: diaryId,
        diaryDate: _dateKey(widget.date),
        content: content,
        image: coverImage,
      );
    } else {
      await db.updateDiary(
        diary!.diaryId!,
        content,
        images,
        diaryDate: _dateKey(widget.date),
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _removeImage(int index) {
    setState(() {
      images.removeAt(index);
      if (images.isEmpty) {
        selectedImageIndex = 0;
      } else if (selectedImageIndex >= images.length) {
        selectedImageIndex = images.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${widget.date.year}.${widget.date.month.toString().padLeft(2, '0')}.${widget.date.day.toString().padLeft(2, '0')}';
    final previewImage = images.isEmpty ? null : images[selectedImageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.close,
                          onTap: () => Navigator.pop(context, false),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Dcolor.defaultText,
                              ),
                            ),
                          ),
                        ),
                        _CircleIconButton(
                          icon: Icons.edit_outlined,
                          onTap: _pickImages,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (previewImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          previewImage,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 34,
                                color: Dcolor.textColorGrey,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '사진을 등록하세요.',
                                style: TextStyle(color: Dcolor.textColorGrey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 68,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final isSelected = index == selectedImageIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImageIndex = index;
                                });
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2D9CFF)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.memory(
                                      images[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemCount: images.length,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        maxLines: null,
                        expands: true,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: '소중한 당신의 일상을 펼쳐보세요.',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Dcolor.defaultText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveDiary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Dcolor.defaultText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(isSaving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Dcolor.defaultText),
        ),
      ),
    );
  }
}
