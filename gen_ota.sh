#!/bin/bash
set -e  # 發生錯誤就退出

REPO="git@github.com:twentyfouri/ac-100-issue.git"
DIR="ac-100-issue"

if [ -z "$1" ]; then
    echo "用法: $0 <tag>"
    exit 1
fi

TAG=$1

# 如果資料夾已存在，先刪掉
if [ -d "$DIR" ]; then
    echo "移除舊的 $DIR"
    rm -rf "$DIR"
fi

# 下載 repo
echo "Cloning $REPO ..."
git clone "$REPO"

cd "$DIR"

# 取得所有 tag
git fetch --tags

# 切換到指定 tag
echo "Checkout tag $TAG ..."
git checkout "tags/$TAG" -b "$TAG-branch"

echo "完成！"

