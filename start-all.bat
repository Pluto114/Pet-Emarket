@echo off
echo ============================================
echo   Pet-Emarket 一键启动
echo ============================================
echo.

set BASE=%~dp0

echo [1/3] 启动后端 API (端口 8080)...
start "Backend-API" cmd /c "cd /d %BASE%backend\api-server && node src/server.js"

echo [2/3] 启动管理后台 Flutter Web (端口 4000)...
start "Admin-App" cmd /c "cd /d %BASE%frontend\admin-app && flutter run -d chrome --web-port=4000"

echo [3/3] 启动用户端 Flutter Web (端口 3000)...
start "User-App" cmd /c "cd /d %BASE%frontend\user-app && flutter run -d chrome --web-port=3000"

echo.
echo ============================================
echo   启动完成！请等待各窗口就绪后访问：
echo.
echo   管理后台(Flutter) : http://localhost:4000
echo   用户端(Flutter)   : http://localhost:3000
echo   后端 API : http://localhost:8080
echo.
echo   管理员账号: admin / Admin@123456
echo ============================================
echo.
pause
