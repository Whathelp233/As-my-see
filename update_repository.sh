#!/bin/bash

# 知识库更新脚本

set -e

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
LOG_FILE="$REPO_DIR/update.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始更新知识库..." | tee -a "$LOG_FILE"

# 1. 更新文档结构
echo "更新文档结构..."
if [ -f "$REPO_DIR/enhance_documents.sh" ]; then
    "$REPO_DIR/enhance_documents.sh" >> "$LOG_FILE" 2>&1
fi

# 2. 更新知识扩展
echo "更新知识扩展..."
if [ -f "$REPO_DIR/knowledge_expansion.sh" ]; then
    "$REPO_DIR/knowledge_expansion.sh" >> "$LOG_FILE" 2>&1
fi

# 3. Git 提交
echo "提交到 Git..."
cd "$REPO_DIR"
git add .
git commit -m "docs: 自动更新 - $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>&1

# 4. 推送到远程
echo "推送到远程仓库..."
git push origin master >> "$LOG_FILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 知识库更新完成" | tee -a "$LOG_FILE"
echo "更新日志: $LOG_FILE"
