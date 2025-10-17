# Git Hooks 使用指南

本项目配置了 Git pre-commit hook，用于在每次提交前自动运行代码格式、质量检查和测试。

## Pre-commit Hook

### 功能说明

每次执行 `git commit` 时，会自动运行以下检查：

#### 1. Dart 代码格式检查

- ✅ **允许提交**: 如果所有暂存的 Dart 文件都已格式化
- ❌ **阻止提交**: 如果有未格式化的 Dart 文件
- 只检查暂存（staged）的 `.dart` 文件

如果格式检查失败，会提示运行：
```bash
flutter format .
# 或格式化具体文件
dart format path/to/file.dart
```

#### 2. Flutter Analyze 代码质量检查

- ✅ **允许提交**: 如果只有 warning 和 info 级别的问题
- ❌ **阻止提交**: 如果存在 error 级别的问题

#### 3. Flutter Test 测试和覆盖率

- ✅ **允许提交**: 如果所有测试通过
- ❌ **阻止提交**: 如果有测试失败
- 自动生成代码覆盖率报告到 `coverage/lcov.info`

### 输出示例

**正常情况（所有检查通过）：**

```bash
🎨 Checking Dart formatting...

✅ All Dart files are formatted!

🔍 Running Flutter analyze...

Analyzing chat-app...

warning • The value of the field '_trayListener' isn't used
   info • Use 'const' with the constructor to improve performance

38 issues found. (ran in 1.1s)

✅ Flutter analyze passed!
   Found 3 warning(s) and 35 info message(s)
   (These won't block the commit)

🧪 Running Flutter tests with coverage...

00:02 +125: All tests passed!

✅ All tests passed!

📊 Coverage report generated at: coverage/lcov.info

✅ All checks passed! Ready to commit.
```

**异常情况（测试失败）：**

```bash
🧪 Running Flutter tests with coverage...

00:05 +98 -2: Some tests failed.

❌ Tests failed!
Please fix failing tests before committing.
```

### Hook 安装位置

```
.git/hooks/pre-commit
```

### 如何跳过 Hook

如果在紧急情况下需要跳过 hook 检查，可以使用 `--no-verify` 参数：

```bash
git commit --no-verify -m "commit message"
```

⚠️ **注意**: 不建议经常跳过检查，这可能导致代码质量问题进入代码库。

### Hook 代码说明

Hook 会执行以下步骤：

1. 获取所有暂存的 `.dart` 文件列表
2. 运行 `dart format --output=none --set-exit-if-changed` 检查格式
3. 如果有未格式化的文件，阻止提交
4. 运行 `flutter analyze --no-pub` 检查代码质量
5. 捕获输出并检查是否有 error 级别的问题
6. 统计 error、warning、info 的数量
7. 如果有 error，则阻止提交
8. 运行 `flutter test --coverage` 执行所有测试
9. 如果测试失败，阻止提交
10. 生成代码覆盖率报告
11. 如果所有检查通过，允许提交

### 修改 Hook

如果需要修改 hook 行为，编辑 `.git/hooks/pre-commit` 文件。

**示例 1**: 如果也想阻止 warning：

```bash
if echo "$ANALYZE_OUTPUT" | grep -q '^ error •\|^warning •'; then
    echo "❌ Flutter analyze found errors or warnings!"
    exit 1
fi
```

**示例 2**: 如果只想运行特定测试：

```bash
# 只运行单元测试
flutter test test/unit/ --coverage

# 跳过集成测试
flutter test --exclude-tags=integration --coverage
```

**示例 3**: 如果想自动修复格式问题而不是阻止提交：

```bash
if [ -n "$STAGED_DART_FILES" ]; then
    echo "🎨 Auto-formatting Dart files..."
    dart format $STAGED_DART_FILES
    git add $STAGED_DART_FILES
fi
```

## 其他推荐的 Hooks

### Pre-push Hook（可选）

在推送前运行额外的检查：

```bash
#!/bin/sh
echo "🧪 Running tests before push..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed!"
    exit 1
fi
echo "✅ Tests passed!"
```

保存到 `.git/hooks/pre-push` 并执行 `chmod +x .git/hooks/pre-push`

### Commit-msg Hook（可选）

检查 commit message 格式（遵循 Conventional Commits）：

```bash
#!/bin/sh
COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat $COMMIT_MSG_FILE)

if ! echo "$COMMIT_MSG" | grep -qE "^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+"; then
    echo "❌ Commit message format is invalid!"
    echo "Expected format: type(scope): subject"
    echo "Example: feat(聊天): 添加消息发送功能"
    exit 1
fi
```

保存到 `.git/hooks/commit-msg` 并执行 `chmod +x .git/hooks/commit-msg`

## 团队协作

由于 `.git/hooks/` 目录不会被 Git 跟踪，团队成员需要手动配置 hooks。

可以在项目中创建 `scripts/setup-hooks.sh` 脚本来自动化安装：

```bash
#!/bin/bash
echo "Installing Git hooks..."
cp scripts/hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
echo "✅ Git hooks installed!"
```

新成员克隆仓库后运行：

```bash
./scripts/setup-hooks.sh
```

## 性能优化建议

### 跳过测试（开发阶段）

如果测试运行时间较长，影响开发体验，可以临时注释掉测试部分：

编辑 `.git/hooks/pre-commit`，注释掉测试相关代码：

```bash
# echo "🧪 Running Flutter tests with coverage..."
# echo ""
# TEST_OUTPUT=$(flutter test --coverage 2>&1)
# ...
```

### 只运行受影响的测试（高级）

可以根据修改的文件智能运行相关测试：

```bash
# 获取修改的文件
CHANGED_FILES=$(git diff --cached --name-only | grep 'lib/.*\.dart$')

# 根据修改的文件找到对应的测试
for file in $CHANGED_FILES; do
    TEST_FILE=$(echo $file | sed 's|lib/|test/|; s|\.dart$|_test.dart|)')
    if [ -f "$TEST_FILE" ]; then
        flutter test $TEST_FILE
    fi
done
```

## CI/CD 集成

GitHub Actions 也已配置了相同的检查逻辑：

- ✅ 只有 error 会导致 CI 失败
- ✅ warning 和 info 不会阻止构建
- ✅ 运行所有测试并生成覆盖率报告
- ✅ 显示详细的问题统计

查看 `.github/workflows/flutter_test.yml` 了解详细配置。

这确保了本地和 CI 环境的代码质量检查标准保持一致。

## 故障排查

### Hook 不执行

1. 检查文件权限：`ls -la .git/hooks/pre-commit`
2. 确保有可执行权限：`chmod +x .git/hooks/pre-commit`
3. 检查文件第一行是否为 `#!/bin/sh`

### 测试运行时间过长

1. 考虑只运行单元测试：`flutter test test/unit/ --coverage`
2. 或者在开发阶段临时禁用测试检查
3. 使用 `--no-verify` 跳过检查（不推荐频繁使用）

### Flutter 命令找不到

确保 Flutter 已添加到 PATH：

```bash
export PATH="$PATH:`pwd`/flutter/bin"
```
