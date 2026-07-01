import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';

class MemoFormDialog extends StatefulWidget {
  const MemoFormDialog({
    super.key,
    required this.initialDate,
    required this.onSave,
  });

  final DateTime initialDate;
  final Future<void> Function(
    String text,
    DateTime selectedDate,
    TimeOfDay selectedTime,
    int selectedCategoryId,
  )
  onSave;

  @override
  State<MemoFormDialog> createState() => _MemoFormDialogState();
}

class _MemoFormDialogState extends State<MemoFormDialog> {
  final textController = TextEditingController();

  late DateTime selectedDate;
  TimeOfDay selectedTime = TimeOfDay.now();
  int selectedCategoryId = 1;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  String _timeKey(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      constraints: const BoxConstraints(maxWidth: 360),
      contentPadding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "메모 입력",
              style: TextStyle(
                color: Dcolor.defaultText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.calendar_today_outlined,
                    label: '${selectedDate.month}월 ${selectedDate.day}일',
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2022, 1, 1),
                        lastDate: DateTime(2100, 12, 31),
                      );

                      if (pickedDate == null) return;
                      setState(() => selectedDate = pickedDate);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.access_time,
                    label: _timeKey(selectedTime),
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );

                      if (pickedTime == null) return;
                      setState(() => selectedTime = pickedTime);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: todoCategoryConfigs.map((category) {
                final isSelected = selectedCategoryId == category.id;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: category == todoCategoryConfigs.last ? 0 : 8,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => selectedCategoryId = category.id);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.accentColor
                              : Colors.white,
                          border: Border.all(color: category.accentColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : category.accentColor,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: TextField(
                controller: textController,
                maxLength: 100,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "메모 입력",
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Dcolor.defaultWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text("취소", style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;

                  final navigator = Navigator.of(context);
                  await widget.onSave(
                    text,
                    selectedDate,
                    selectedTime,
                    selectedCategoryId,
                  );
                  navigator.pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Dcolor.stickerGreen,
                  foregroundColor: Dcolor.defaultWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text("저장", style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF666666)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ],
        ),
      ),
    );
  }
}
