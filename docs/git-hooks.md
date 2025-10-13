# Git Hooks 使用指南

本项目配置了 Git pre-commit hook，用于在每次提交前自动运行代码质量检查。

## Pre-commit Hook

### 功能说明

每次执行 `git commit` 时，会自动运行 `flutter analyze` 检查代码质量：

- ✅ **允许提交**: 如果只有 warning 和 info 级别的问题
- ❌ **阻止提交**: 如果存在 error 级别的问题

### 输出示例

```bash
🔍 Running Flutter analyze...

Analyzing chat-app...

warning • The value of the field '_trayListener' isn't used
   info • Use 'const' with the constructor to improve performance

38 issues found. (ran in 1.1s)

✅ Flutter analyze passed!
   Found 3 warning(s) and 35 info message(s)
   (These won't block the commit)
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

1. 运行 `flutter analyze --no-pub`
2. 捕获输出并检查是否有 error 级别的问题
3. 统计 error、warning、info 的数量
4. 如果有 error，则阻止提交并返回错误码 1
5. 如果没有 error，允许提交并显示摘要信息

### 修改 Hook

如果需要修改 hook 行为，编辑 `.git/hooks/pre-commit` 文件。

例如，如果也想阻止 warning：

```bash
if echo "$ANALYZE_OUTPUT" | grep -q '^  error •\|^warning •'; then
    echo "❌ Flutter analyze found errors or warnings!"
    exit 1
fi
```

## 其他推荐的 Hooks

### Pre-push Hook（可选）

在推送前运行测试：

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
