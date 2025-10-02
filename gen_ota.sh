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


PREFIX=${TAG:0:10}   # 取前 10 個字元
TARGET_DIR="$(pwd)/$PREFIX"

# 建立目錄
mkdir -p "$TARGET_DIR"

echo "已建立目錄: $TARGET_DIR"

# 檔案名稱
FILENAME="ac100-${PREFIX}.tar.xz"

# 建立 list.txt
cat > "$TARGET_DIR/list.txt" <<EOF
{ "version":"${PREFIX}",
  "auto" : false,
  "whitelist": [],
  "rootfs" : "",
  "model":"",
  "file": "${FILENAME}"
}
EOF

echo "已建立 $TARGET_DIR/list.txt"
