# PowerShell: & "C:\Program Files\R\R-4.6.0\bin\R.exe"
# Then paste the setwd + load_all lines below (forward slashes required).

setwd("//wsl$/Ubuntu/home/akagi/home/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
devtools::load_all(".")
GUImorph()


'''
Recompile (PowerShell; build-msvc/ is gitignored — configure once, then build):
cd \\wsl$\Ubuntu\home\akagi\home\GUImorph\integrated-guimorph-development_EOC\Project\tkogl2
cmake -B build-msvc -G "Visual Studio 17 2022" -A x64
cmake --build build-msvc --config Release
# or from repo root: powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1
Copy-Item build-msvc\Release\tkogl2.dll `
  ..\GUImorphDevelopment\inst\libs\x64\tkogl2.dll -Force
'''
