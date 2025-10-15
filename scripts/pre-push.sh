#!/bin/bash

# Pre-push hook - 运行测试

set -e

echo "\n🧪 运行测试..."

# 运行测试
flutter test --timeout 60s

if [ $? -eq 0 ]; then
  echo "\n✅ 所有测试通过！"
else
  echo "\n❌ 测试失败，请修复后重试"
  exit 1
fi

exit 0
