#!/bin/bash

# 全平台测试脚本
# 用于测试 Flutter 应用在所有平台上的运行状况

set -e

echo "=========================================="
echo "Flutter Chat App - 全平台测试"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}错误: Flutter 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter 已安装${NC}"
flutter --version
echo ""

# 1. 代码分析
echo "=========================================="
echo "1. 运行代码分析"
echo "=========================================="
if flutter analyze; then
    echo -e "${GREEN}✓ 代码分析通过${NC}"
else
    echo -e "${RED}✗ 代码分析失败${NC}"
    exit 1
fi
echo ""

# 2. 运行测试
echo "=========================================="
echo "2. 运行单元测试"
echo "=========================================="
if flutter test; then
    echo -e "${GREEN}✓ 测试通过${NC}"
else
    echo -e "${RED}✗ 测试失败${NC}"
    exit 1
fi
echo ""

# 3. 生成测试覆盖率报告
echo "=========================================="
echo "3. 生成测试覆盖率报告"
echo "=========================================="
if flutter test --coverage; then
    echo -e "${GREEN}✓ 覆盖率报告已生成${NC}"
    echo "覆盖率文件: coverage/lcov.info"
    
    # 如果安装了 lcov，生成 HTML 报告
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}✓ HTML 报告已生成: coverage/html/index.html${NC}"
    else
        echo -e "${YELLOW}提示: 安装 lcov 以生成 HTML 报告${NC}"
    fi
else
    echo -e "${RED}✗ 覆盖率报告生成失败${NC}"
fi
echo ""

# 4. 检查可用设备
echo "=========================================="
echo "4. 检查可用设备"
echo "=========================================="
flutter devices
echo ""

# 5. Web 构建测试
echo "=========================================="
echo "5. Web 构建测试"
echo "=========================================="
if flutter build web --release; then
    echo -e "${GREEN}✓ Web 构建成功${NC}"
else
    echo -e "${YELLOW}⚠ Web 构建失败${NC}"
fi
echo ""

# 6. macOS 构建测试 (如果在 macOS 上)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "=========================================="
    echo "6. macOS 构建测试"
    echo "=========================================="
    if flutter build macos --release; then
        echo -e "${GREEN}✓ macOS 构建成功${NC}"
    else
        echo -e "${YELLOW}⚠ macOS 构建失败${NC}"
    fi
    echo ""
    
    # iOS 构建测试
    echo "=========================================="
    echo "7. iOS 构建测试"
    echo "=========================================="
    if flutter build ios --release --no-codesign; then
        echo -e "${GREEN}✓ iOS 构建成功${NC}"
    else
        echo -e "${YELLOW}⚠ iOS 构建失败${NC}"
    fi
    echo ""
fi

# 7. Android 构建测试 (如果 Android SDK 可用)
if [ -d "$ANDROID_HOME" ] || [ -d "$ANDROID_SDK_ROOT" ]; then
    echo "=========================================="
    echo "8. Android 构建测试"
    echo "=========================================="
    if flutter build apk --release; then
        echo -e "${GREEN}✓ Android APK 构建成功${NC}"
        
        # 显示 APK 大小
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        if [ -f "$APK_PATH" ]; then
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            echo "APK 大小: $APK_SIZE"
        fi
    else
        echo -e "${YELLOW}⚠ Android 构建失败${NC}"
    fi
    echo ""
fi

# 8. Windows 构建测试 (如果在 Windows 上)
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "=========================================="
    echo "9. Windows 构建测试"
    echo "=========================================="
    if flutter build windows --release; then
        echo -e "${GREEN}✓ Windows 构建成功${NC}"
    else
        echo -e "${YELLOW}⚠ Windows 构建失败${NC}"
    fi
    echo ""
fi

# 9. Linux 构建测试 (如果在 Linux 上)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "=========================================="
    echo "10. Linux 构建测试"
    echo "=========================================="
    if flutter build linux --release; then
        echo -e "${GREEN}✓ Linux 构建成功${NC}"
    else
        echo -e "${YELLOW}⚠ Linux 构建失败${NC}"
    fi
    echo ""
fi

# 总结
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo -e "${GREEN}所有测试已完成！${NC}"
echo ""
echo "下一步："
echo "1. 查看测试覆盖率报告: coverage/html/index.html"
echo "2. 修复任何失败的构建"
echo "3. 在真机上测试应用"
echo ""
