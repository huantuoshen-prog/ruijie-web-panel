#!/bin/bash
# ========================================
# Web Panel 测试入口
# 用法: bash tests/run_tests.sh
# ========================================

set -e

TEST_DIR="$(cd "$(dirname "${0}")" && pwd)"

for test_file in "${TEST_DIR}"/test_*.sh; do
    [ -f "$test_file" ] || continue
    bash "$test_file"
done
