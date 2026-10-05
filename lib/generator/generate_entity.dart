import 'dart:io';
import 'package:path/path.dart' as p;

class ClassInfo {
  final String name;
  final List<FieldInfo> fields;
  ClassInfo(this.name, this.fields);
}

class FieldInfo {
  final String type;
  final String name;
  final bool hasAnnotation;
  FieldInfo(this.type, this.name, this.hasAnnotation);
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run lib/generator/generate_entity.dart <path_to_model_file.dart>');
    return;
  }

  var filePath = args[0];
  var file = File(filePath);
  
  if (!file.existsSync()) {
    // Try to find the file smartly by scanning the lib directory
    final libDir = Directory('lib');
    if (libDir.existsSync()) {
      final searchParts = filePath.replaceAll(r'\', '/').split('/').where((p) => p.isNotEmpty).toList();
      final targetBasename = searchParts.isNotEmpty ? searchParts.last : '';
      
      final entities = libDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final normalizedPath = entity.path.replaceAll(r'\', '/');
          if (p.basename(normalizedPath) == targetBasename) {
            bool matches = true;
            for (final part in searchParts) {
              if (!normalizedPath.contains(part)) {
                matches = false;
                break;
              }
            }
            if (matches) {
              filePath = entity.path;
              file = File(filePath);
              print('Auto-resolved path to: $filePath');
              break;
            }
          }
        }
      }
    }
  }

  if (!file.existsSync()) {
    print('File not found: ${args[0]}');
    return;
  }

  final content = file.readAsStringSync();
  final allClasses = _parseClasses(content);
  final classes = _filterEntityClasses(allClasses);

  if (classes.isEmpty) {
    print('No classes with @EntityField or @entityField annotations found.');
    return;
  }

  final entityFilename = _getEntityFilename(p.basename(filePath));
  
  String targetDir = p.dirname(filePath);
  // Check if it's in a standard Clean Architecture path structure
  if (targetDir.contains('/data/models') || targetDir.contains(r'\data\models')) {
    targetDir = targetDir.replaceAll(RegExp(r'[/\\]data[/\\]models'), '/domain/entities');
    final dir = Directory(targetDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  final entityFilePath = p.join(targetDir, entityFilename);

  _generateEntityFile(entityFilePath, classes);
  _injectExtensionToModel(file, content, classes, entityFilePath);
}

List<ClassInfo> _parseClasses(String content) {
  final lines = content.split('\n');
  final classes = <ClassInfo>[];
  
  bool insideClass = false;
  int braceCount = 0;
  String? currentClassName;
  List<FieldInfo> currentFields = [];
  bool pendingAnnotation = false;

  final classRegex = RegExp(r'class\s+([A-Za-z0-9_]+)');
  final fieldRegex = RegExp(r'(?:final\s+|const\s+|var\s+|late\s+)?([A-Za-z0-9_<>?]+)\s+([A-Za-z0-9_]+)\s*;');

  for (var line in lines) {
    var trimmed = line.trim();

    if (!insideClass) {
      final match = classRegex.firstMatch(line);
      if (match != null) {
        insideClass = true;
        currentClassName = match.group(1);
        currentFields = [];
        braceCount = 0;
        if (line.contains('{')) braceCount++;
      }
    } else {
      if (trimmed.contains('{')) braceCount += '{'.allMatches(trimmed).length;
      if (trimmed.contains('}')) braceCount -= '}'.allMatches(trimmed).length;

      bool isAnnotation = trimmed.startsWith('@EntityField') || trimmed.startsWith('@entityField');
      if (isAnnotation) {
        pendingAnnotation = true;
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('//')) {
        final match = fieldRegex.firstMatch(trimmed);
        if (match != null) {
          currentFields.add(FieldInfo(match.group(1)!, match.group(2)!, pendingAnnotation));
          pendingAnnotation = false;
        } else if (trimmed.contains('(')) {
          pendingAnnotation = false;
        }
      }

      if (braceCount <= 0 && insideClass) {
        if (currentFields.isNotEmpty && currentClassName != null) {
          classes.add(ClassInfo(currentClassName, currentFields));
        }
        insideClass = false;
      }
    }
  }

  return classes;
}

List<ClassInfo> _filterEntityClasses(List<ClassInfo> classes) {
  final entityClasses = <ClassInfo>[];
  
  for (final cls in classes) {
    final validFields = <FieldInfo>[];
    for (final field in cls.fields) {
      final cleanType = field.type.replaceAll('?', '').replaceAll(RegExp(r'List<|>'), '');
      final isNestedEntity = classes.any((c) => c.name == cleanType && c.fields.any((f) => f.hasAnnotation));
      
      if (field.hasAnnotation || isNestedEntity) {
        validFields.add(field);
      }
    }
    
    if (validFields.isNotEmpty) {
      entityClasses.add(ClassInfo(cls.name, validFields));
    }
  }
  
  return entityClasses;
}

String _getEntityFilename(String modelFilename) {
  return '${modelFilename
      .replaceAll('model_', '')
      .replaceAll('_model', '')
      .replaceAll('dto_', '')
      .replaceAll('_dto', '')
      .replaceAll('.dart', '')}_entity.dart';
}

String _cleanClassName(String name) {
  return name
      .replaceAll(RegExp(r'^Model'), '')
      .replaceAll(RegExp(r'Model$'), '')
      .replaceAll(RegExp(r'^Dto'), '')
      .replaceAll(RegExp(r'Dto$'), '');
}

void _generateEntityFile(String path, List<ClassInfo> classes) {
  final buffer = StringBuffer();
  // Ensure we do not overwrite other imports if needed, but for simple entity it just needs types.

  for (final classInfo in classes) {
    final entityName = '${_cleanClassName(classInfo.name)}Entity';
    buffer.writeln('class $entityName {');
    for (final field in classInfo.fields) {
      String newType = field.type;
      final cleanType = field.type.replaceAll('?', '').replaceAll(RegExp(r'List<|>'), '');
      final isNestedEntity = classes.any((c) => c.name == cleanType);
      
      if (isNestedEntity) {
        final nestedEntityName = '${_cleanClassName(cleanType)}Entity';
        newType = newType.replaceAll(cleanType, nestedEntityName);
      }
      buffer.writeln('  final $newType ${field.name};');
    }
    buffer.writeln();
    buffer.writeln('  const $entityName({');
    for (final field in classInfo.fields) {
      if (field.type.endsWith('?')) {
        buffer.writeln('    this.${field.name},');
      } else {
        buffer.writeln('    required this.${field.name},');
      }
    }
    buffer.writeln('  });');
    buffer.writeln('}');
    buffer.writeln();
  }

  File(path).writeAsStringSync(buffer.toString());
  print('Generated $path');
}

void _injectExtensionToModel(File file, String content, List<ClassInfo> classes, String entityFilePath) {
  var newContent = content;

  // Ensure import of entity file is present
  final relativePath = p.relative(entityFilePath, from: p.dirname(file.path)).replaceAll(r'\', '/');
  final importStatement = "import '$relativePath';";
  if (!newContent.contains(importStatement)) {
    // Find the last import
    final importRegex = RegExp(r'^import\s+.*;', multiLine: true);
    final matches = importRegex.allMatches(newContent);
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      newContent = newContent.replaceRange(lastMatch.end, lastMatch.end, '\n$importStatement');
    } else {
      newContent = '$importStatement\n\n' + newContent;
    }
  }

  // Inject extensions
  for (final classInfo in classes) {
    final entityName = '${_cleanClassName(classInfo.name)}Entity';
    final extensionName = '${entityName}Extension';
    
    // Check if extension already exists (assuming exactly one nested method)
    final extensionRegex = RegExp(r'extension\s+' + extensionName + r'\s+on\s+' + classInfo.name + r'\s*\{[\s\S]*?\}\s*\}');
    
    final extensionCode = StringBuffer();
    extensionCode.writeln('extension $extensionName on ${classInfo.name} {');
    extensionCode.writeln('  $entityName toEntity() {');
    extensionCode.writeln('    return $entityName(');
    for (final field in classInfo.fields) {
      final cleanType = field.type.replaceAll('?', '').replaceAll(RegExp(r'List<|>'), '');
      final isNestedEntity = classes.any((c) => c.name == cleanType);
      
      if (isNestedEntity) {
        final isNullable = field.type.endsWith('?');
        final q = isNullable ? '?' : '';
        if (field.type.contains('List<')) {
          extensionCode.writeln('      ${field.name}: ${field.name}$q.map((e) => e.toEntity()).toList(),');
        } else {
          extensionCode.writeln('      ${field.name}: ${field.name}$q.toEntity(),');
        }
      } else {
        extensionCode.writeln('      ${field.name}: ${field.name},');
      }
    }
    extensionCode.writeln('    );');
    extensionCode.writeln('  }');
    extensionCode.writeln('}');

    if (extensionRegex.hasMatch(newContent)) {
      newContent = newContent.replaceAll(extensionRegex, extensionCode.toString().trim());
    } else {
      newContent += '\n' + extensionCode.toString();
    }
  }

  file.writeAsStringSync(newContent);
  print('Updated ${file.path} with toEntity extension');
}
