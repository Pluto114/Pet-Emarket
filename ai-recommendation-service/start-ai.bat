@echo off
setlocal

set "BASE=%~dp0"
cd /d "%BASE%"

if exist "%BASE%..\.env" (
  for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%BASE%..\.env") do (
    if not "%%A"=="" set "%%A=%%B"
  )
)

if exist "%BASE%.env" (
  for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%BASE%.env") do (
    if not "%%A"=="" set "%%A=%%B"
  )
)

if "%PORT%"=="" set "PORT=8001"

if "%LLM_API_KEY%"=="" (
  echo [WARN] LLM_API_KEY is not configured. RAG chat will return LLM_API_KEY_MISSING until it is set.
)

set "PY_CMD="

if exist "%BASE%.venv-ai-win\Scripts\python.exe" (
  "%BASE%.venv-ai-win\Scripts\python.exe" -c "import uvicorn" >nul 2>nul
  if not errorlevel 1 set "PY_CMD="%BASE%.venv-ai-win\Scripts\python.exe""
)

if exist "%BASE%.venv-ai\Scripts\python.exe" (
  "%BASE%.venv-ai\Scripts\python.exe" -c "import uvicorn" >nul 2>nul
  if not errorlevel 1 set "PY_CMD="%BASE%.venv-ai\Scripts\python.exe""
)

if exist "%BASE%.venv-ai\bin\python.exe" (
  "%BASE%.venv-ai\bin\python.exe" -c "import uvicorn" >nul 2>nul
  if not errorlevel 1 set "PY_CMD="%BASE%.venv-ai\bin\python.exe""
)

if exist "%BASE%.venv\Scripts\python.exe" (
  "%BASE%.venv\Scripts\python.exe" -c "import uvicorn" >nul 2>nul
  if not errorlevel 1 set "PY_CMD="%BASE%.venv\Scripts\python.exe""
)

if not defined PY_CMD (
  python -c "import uvicorn" >nul 2>nul
  if not errorlevel 1 set "PY_CMD=python"
)

if not defined PY_CMD (
  py -3 -c "import uvicorn" >nul 2>nul
  if not errorlevel 1 set "PY_CMD=py -3"
)

if not defined PY_CMD (
  echo [ERROR] No usable Python environment with uvicorn was found.
  echo.
  echo Fix it with:
  echo   cd /d "%BASE%"
  echo   py -3.13 -m venv .venv-ai
  echo   .venv-ai\Scripts\python -m pip install -r requirements.txt
  echo   或使用 .venv-ai\bin\python -m pip install -r requirements.txt
  echo.
  exit /b 1
)

echo Starting AI Recommendation Service on http://localhost:%PORT%
%PY_CMD% -m uvicorn app.main:app --host 0.0.0.0 --port %PORT%
exit /b %errorlevel%
