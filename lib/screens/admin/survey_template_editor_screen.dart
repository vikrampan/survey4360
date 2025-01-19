// lib/screens/admin/survey_template_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:survey_app/models/survey_template_model.dart';
import 'package:survey_app/utils/survey_template_generator.dart';

class SurveyTemplateEditorScreen extends StatefulWidget {
  final SurveyTemplate template;

  const SurveyTemplateEditorScreen({
    Key? key,
    required this.template,
  }) : super(key: key);

  @override
  _SurveyTemplateEditorScreenState createState() => _SurveyTemplateEditorScreenState();
}

class _SurveyTemplateEditorScreenState extends State<SurveyTemplateEditorScreen> {
  late List<SurveySection> sections;

  @override
  void initState() {
    super.initState();
    sections = List.from(widget.template.sections);
  }

  void _addQuestion(int sectionIndex) {
    showDialog(
      context: context,
      builder: (context) => AddQuestionDialog(
        onAdd: (question) {
          setState(() {
            sections[sectionIndex].questions.add(question);
          });
        },
      ),
    );
  }

  void _editQuestion(int sectionIndex, int questionIndex) {
    final question = sections[sectionIndex].questions[questionIndex];
    showDialog(
      context: context,
      builder: (context) => EditQuestionDialog(
        question: question,
        onUpdate: (updatedQuestion) {
          setState(() {
            sections[sectionIndex].questions[questionIndex] = updatedQuestion;
          });
        },
      ),
    );
  }

  void _deleteQuestion(int sectionIndex, int questionIndex) {
    setState(() {
      sections[sectionIndex].questions.removeAt(questionIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Survey Template'),
        actions: [
          TextButton(
            onPressed: () {
              // Return modified template
              final modifiedTemplate = SurveyTemplate(
                id: widget.template.id,
                type: widget.template.type,
                sections: sections,
                isActive: widget.template.isActive,
              );
              Navigator.pop(context, modifiedTemplate);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          final section = sections[sectionIndex];
          return ExpansionTile(
            title: Text(section.title),
            subtitle: Text(section.description ?? ''),
            children: [
              ...List.generate(
                section.questions.length,
                (questionIndex) {
                  final question = section.questions[questionIndex];
                  return ListTile(
                    title: Text(question.question),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${question.type}'),
                        Text('Category: ${question.category}'),
                        if (question.subCategory != null)
                          Text('Sub-category: ${question.subCategory}'),
                        Text(
                          'Requires: ${question.requiresPhoto ? 'Photo, ' : ''}${question.requiresRemark ? 'Remark' : ''}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editQuestion(sectionIndex, questionIndex),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteQuestion(sectionIndex, questionIndex),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _addQuestion(sectionIndex),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AddQuestionDialog extends StatefulWidget {
  final Function(SurveyQuestion) onAdd;

  const AddQuestionDialog({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  _AddQuestionDialogState createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  String _selectedType = 'YES_NO';
  bool _requiresPhoto = false;
  bool _requiresRemark = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Question'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a question' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['YES_NO', 'TEXT', 'NUMERIC']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a category' : null,
              ),
              TextFormField(
                controller: _subCategoryController,
                decoration: const InputDecoration(labelText: 'Sub-category (Optional)'),
              ),
              CheckboxListTile(
                title: const Text('Requires Photo'),
                value: _requiresPhoto,
                onChanged: (value) {
                  setState(() {
                    _requiresPhoto = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Requires Remark'),
                value: _requiresRemark,
                onChanged: (value) {
                  setState(() {
                    _requiresRemark = value ?? true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onAdd(
                SurveyQuestion(
                  id: 'Q_${DateTime.now().millisecondsSinceEpoch}',
                  question: _questionController.text,
                  type: _selectedType,
                  requiresPhoto: _requiresPhoto,
                  requiresRemark: _requiresRemark,
                  category: _categoryController.text,
                  subCategory: _subCategoryController.text.isEmpty
                      ? null
                      : _subCategoryController.text,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }
}

class EditQuestionDialog extends StatefulWidget {
  final SurveyQuestion question;
  final Function(SurveyQuestion) onUpdate;

  const EditQuestionDialog({
    Key? key,
    required this.question,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EditQuestionDialogState createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _subCategoryController;
  late String _selectedType;
  late bool _requiresPhoto;
  late bool _requiresRemark;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.question);
    _categoryController = TextEditingController(text: widget.question.category);
    _subCategoryController =
        TextEditingController(text: widget.question.subCategory ?? '');
    _selectedType = widget.question.type;
    _requiresPhoto = widget.question.requiresPhoto;
    _requiresRemark = widget.question.requiresRemark;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Question'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a question' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['YES_NO', 'TEXT', 'NUMERIC']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a category' : null,
              ),
              TextFormField(
                controller: _subCategoryController,
                decoration: const InputDecoration(labelText: 'Sub-category (Optional)'),
              ),
              CheckboxListTile(
                title: const Text('Requires Photo'),
                value: _requiresPhoto,
                onChanged: (value) {
                  setState(() {
                    _requiresPhoto = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Requires Remark'),
                value: _requiresRemark,
                onChanged: (value) {
                  setState(() {
                    _requiresRemark = value ?? true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onUpdate(
                SurveyQuestion(
                  id: widget.question.id,
                  question: _questionController.text,
                  type: _selectedType,
                  requiresPhoto: _requiresPhoto,
                  requiresRemark: _requiresRemark,
                  category: _categoryController.text,
                  subCategory: _subCategoryController.text.isEmpty
                      ? null
                      : _subCategoryController.text,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }
}