@echo off
chcp 65001 >nul
title VSD-AI-Toolkit: Trình Cài Đặt Tích Hợp Nhanh (Junction)

echo ========================================================
echo ⚡ VSD-AI-TOOLKIT: TRÌNH TÍCH HỢP NHANH (NTFS JUNCTION)
echo ========================================================
echo.
echo Tùy chọn:
echo  - Nhập đường dẫn thư mục dự án đích (hoặc kéo thả vào đây)
echo  - Nhập 'global' (hoặc 'self') để tích hợp toàn cục cho Antigravity IDE
echo.

set "TARGET_DIR=%~1"

if "%TARGET_DIR%"=="" (
    set /p "TARGET_DIR=Đường dẫn hoặc 'global': "
)

rem Bỏ dấu ngoặc kép thừa nếu có
set "TARGET_DIR=%TARGET_DIR:"=%"

if "%TARGET_DIR%"=="" (
    echo [LỖI] Đường dẫn không được để trống.
    pause
    exit /b 1
)

echo.
echo Đang chạy script tích hợp PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-junction.ps1" -TargetPath "%TARGET_DIR%"

echo.
pause
