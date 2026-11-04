#!/bin/bash
set -e

# j87-astro public directories for Flutter embedding
ASTRO_PUBLIC_DIR="$(pwd)/j87-astro/public"

echo "======== [1/3] 清理舊資料 ========"
rm -rf "$ASTRO_PUBLIC_DIR/travel/fullscreen"
rm -rf "$ASTRO_PUBLIC_DIR/mountain/fullscreen"
mkdir -p "$ASTRO_PUBLIC_DIR/travel/fullscreen"
mkdir -p "$ASTRO_PUBLIC_DIR/mountain/fullscreen"

echo "======== [2/3] 編編譯 Trivep App (Travel) ========"
# We are already in trivep_app, no need to cd
flutter clean
flutter build web --base-href "/travel/fullscreen/"

echo ">>> 正在將編譯結果移動至 Astro 靜態資料夾..."
cp -R build/web/* "$ASTRO_PUBLIC_DIR/travel/fullscreen/"

echo "======== [3/3] 嘗試編譯 Mountain Hiking App ========"
if [ -d "mountain_suite_monorepo/apps/mountain_hiking_app" ]; then
    cd mountain_suite_monorepo/apps/mountain_hiking_app
    flutter clean
    flutter build web --base-href "/mountain/fullscreen/"
    echo ">>> 正在將編譯結果移動至 Astro 靜態資料夾..."
    cp -R build/web/* "$ASTRO_PUBLIC_DIR/mountain/fullscreen/"
    cd ../../../
else
    echo "⚠️ 找不到 mountain_suite_monorepo/apps/mountain_hiking_app。跳過編譯。"
fi

echo "======== 🎉 完全整合成功 ========"
echo "請啟動您的 npm run dev 並前往："
echo "旅遊功能：http://localhost:4321/travel/app"
echo "山系功能：http://localhost:4321/mountain/app"
