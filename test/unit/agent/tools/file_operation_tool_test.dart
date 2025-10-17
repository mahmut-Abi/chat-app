import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/data/tools/file_operation_tool.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';
import 'package:path/path.dart' as path;

void main() {
  group('FileOperationTool', () {
    late FileOperationTool fileOp;
    late AgentTool tool;
    late Directory tempDir;
    late String testFilePath;
    late String testDirPath;

    setUp(() async {
      fileOp = FileOperationTool();
      tool = AgentTool(
        id: 'file_op_1',
        name: '文件操作',
        description: '执行文件操作',
        type: AgentToolType.fileOperation,
      );

      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('file_op_test_');
      testFilePath = path.join(tempDir.path, 'test_file.txt');
      testDirPath = path.join(tempDir.path, 'test_dir');
      await Directory(testDirPath).create();
    });

    tearDown(() async {
      // 清理临时文件
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('应该正确返回工具类型', () {
      // Assert
      expect(fileOp.type, AgentToolType.fileOperation);
    });

    group('参数验证', () {
      test('应该在缺少 operation 参数时返回错误', () async {
        // Arrange
        final input = {'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('缺少必要参数'));
      });

      test('应该在缺少 path 参数时返回错误', () async {
        // Arrange
        final input = {'operation': 'read'};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('缺少必要参数'));
      });

      test('应该在不支持的操作时返回错误', () async {
        // Arrange
        final input = {'operation': 'delete', 'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('不支持的操作'));
      });
    });

    group('读取文件', () {
      test('应该成功读取存在的文件', () async {
        // Arrange
        final testContent = 'Hello, World!';
        await File(testFilePath).writeAsString(testContent);
        final input = {'operation': 'read', 'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains(testContent));
        expect(result.metadata?['path'], testFilePath);
        expect(result.metadata?['size'], testContent.length);
      });

      test('应该在读取不存在的文件时返回错误', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.txt');
        final input = {'operation': 'read', 'path': nonExistentPath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('文件不存在'));
      });

      test('应该正确读取多行内容', () async {
        // Arrange
        final testContent = 'Line 1\nLine 2\nLine 3';
        await File(testFilePath).writeAsString(testContent);
        final input = {'operation': 'read', 'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('Line 1'));
        expect(result.result, contains('Line 2'));
        expect(result.result, contains('Line 3'));
      });

      test('应该正确读取空文件', () async {
        // Arrange
        await File(testFilePath).writeAsString('');
        final input = {'operation': 'read', 'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.metadata?['size'], 0);
      });
    });

    group('写入文件', () {
      test('应该成功写入文件', () async {
        // Arrange
        final testContent = 'Test content';
        final input = {
          'operation': 'write',
          'path': testFilePath,
          'content': testContent,
        };

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('写入成功'));
        expect(result.metadata?['path'], testFilePath);
        expect(result.metadata?['size'], testContent.length);

        // 验证文件确实被写入
        final content = await File(testFilePath).readAsString();
        expect(content, testContent);
      });

      test('应该在缺少 content 参数时返回错误', () async {
        // Arrange
        final input = {'operation': 'write', 'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('需要 content 参数'));
      });

      test('应该覆盖已存在的文件', () async {
        // Arrange
        await File(testFilePath).writeAsString('Old content');
        final newContent = 'New content';
        final input = {
          'operation': 'write',
          'path': testFilePath,
          'content': newContent,
        };

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        final content = await File(testFilePath).readAsString();
        expect(content, newContent);
        expect(content, isNot(contains('Old content')));
      });

      test('应该正确写入多行内容', () async {
        // Arrange
        final testContent = 'Line 1\nLine 2\nLine 3';
        final input = {
          'operation': 'write',
          'path': testFilePath,
          'content': testContent,
        };

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        final content = await File(testFilePath).readAsString();
        expect(content, testContent);
      });

      test('应该正确写入空内容', () async {
        // Arrange
        final input = {
          'operation': 'write',
          'path': testFilePath,
          'content': '',
        };

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        final content = await File(testFilePath).readAsString();
        expect(content, isEmpty);
      });
    });

    group('列出目录', () {
      test('应该成功列出目录内容', () async {
        // Arrange
        // 创建测试文件
        await File(path.join(testDirPath, 'file1.txt')).writeAsString('test');
        await File(path.join(testDirPath, 'file2.txt')).writeAsString('test');
        await Directory(path.join(testDirPath, 'subdir')).create();

        final input = {'operation': 'list', 'path': testDirPath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('file1.txt'));
        expect(result.result, contains('file2.txt'));
        expect(result.result, contains('subdir'));
        expect(result.metadata?['count'], 3);
      });

      test('应该在目录不存在时返回错误', () async {
        // Arrange
        final nonExistentDir = path.join(tempDir.path, 'non_existent_dir');
        final input = {'operation': 'list', 'path': nonExistentDir};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('目录不存在'));
      });

      test('应该正确列出空目录', () async {
        // Arrange
        final emptyDir = path.join(tempDir.path, 'empty_dir');
        await Directory(emptyDir).create();
        final input = {'operation': 'list', 'path': emptyDir};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.metadata?['count'], 0);
      });

      test('应该区分文件和目录', () async {
        // Arrange
        await File(path.join(testDirPath, 'file.txt')).writeAsString('test');
        await Directory(path.join(testDirPath, 'dir')).create();
        final input = {'operation': 'list', 'path': testDirPath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('📄')); // 文件图标
        expect(result.result, contains('📁')); // 目录图标
      });
    });

    group('获取文件信息', () {
      test('应该成功获取文件信息', () async {
        // Arrange
        final testContent = 'Test content for info';
        await File(testFilePath).writeAsString(testContent);
        final input = {'operation': 'info', 'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('路径'));
        expect(result.result, contains('大小'));
        expect(result.result, contains('修改时间'));
        expect(result.metadata?['path'], testFilePath);
        expect(result.metadata?['size'], testContent.length);
      });

      test('应该在文件不存在时返回错误', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.txt');
        final input = {'operation': 'info', 'path': nonExistentPath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('文件不存在'));
      });

      test('应该正确获取目录信息', () async {
        // Arrange
        final input = {'operation': 'info', 'path': testDirPath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('路径'));
        expect(result.metadata?['path'], testDirPath);
      });
    });

    group('操作大小写不敏感', () {
      test('应该支持大写的 READ', () async {
        // Arrange
        await File(testFilePath).writeAsString('test');
        final input = {'operation': 'READ', 'path': testFilePath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
      });

      test('应该支持大写的 WRITE', () async {
        // Arrange
        final input = {
          'operation': 'WRITE',
          'path': testFilePath,
          'content': 'test',
        };

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
      });

      test('应该支持混合大小写', () async {
        // Arrange
        final input = {'operation': 'LiSt', 'path': testDirPath};

        // Act
        final result = await fileOp.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
      });
    });
  });
}
