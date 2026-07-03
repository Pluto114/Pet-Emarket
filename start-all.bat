@echo off
echo ============================================
echo   Pet-Emarket 一键启动
echo ============================================
echo.

set BASE=%~dp0

if exist "%BASE%.env" (
  for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%BASE%.env") do (
    if not "%%A"=="" set "%%A=%%B"
  )
)

if exist "%BASE%.tools\apache-maven-3.9.9\bin\mvn.cmd" (
  set "MVN=%BASE%.tools\apache-maven-3.9.9\bin\mvn.cmd"
) else (
  set "MVN=mvn.cmd"
)

echo [1/4] 启动 AI 推荐服务 (端口 8001)...
start "AI-Service" cmd /k "call ""%BASE%ai-recommendation-service\start-ai.bat"""

echo [2/4] 启动后端 API (端口 8080)...
start "Backend-API" cmd /c "cd /d %BASE%backend\pet-emarket-server && call %MVN% spring-boot:run"
echo   后端默认连接 MySQL：%DB_HOST%:%DB_PORT%/%DB_NAME%

echo [3/4] 启动管理后台 Flutter Web (端口 4000，可选)...
if exist "%BASE%frontend\admin-app" (
  start "Admin-App" cmd /c "cd /d %BASE%frontend\admin-app && flutter run -d chrome --web-port=4000"
) else (
  echo   跳过：未找到 frontend\admin-app
)

echo [4/4] 启动用户端 Flutter Web (端口 3000)...
if exist "%BASE%frontend\pet-emarket-app" (
  start "User-App" cmd /c "cd /d %BASE%frontend\pet-emarket-app && flutter run -d chrome --web-port=3000"
) else (
  start "User-App" cmd /c "cd /d %BASE%frontend\user-app && flutter run -d chrome --web-port=3000"
)

echo.
echo ============================================
echo   启动完成！请等待各窗口就绪后访问：
echo.
echo   管理后台(Flutter) : http://localhost:4000
echo   用户端(Flutter)   : http://localhost:3000
echo   后端 API : http://localhost:8080
echo   AI 服务 : http://localhost:8001/health
echo.
echo   管理员账号: admin / Admin@123456
echo ============================================
echo.
pause
