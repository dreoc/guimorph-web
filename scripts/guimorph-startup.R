# PowerShell: & "C:\Program Files\R\R-4.6.0\bin\R.exe"
# Then paste the setwd + load_all lines below (forward slashes required).
setwd("//wsl$/Ubuntu/home/akagi/home/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
devtools::load_all(".")
GUImorph()


'''
Recompile:
cd \\wsl$\Ubuntu\home\akagi\home\GUImorph\integrated-guimorph-development_EOC\Project\tkogl2
cmake --build build-msvc --config Release
Copy-Item build-msvc\Release\tkogl2.dll `
  ..\GUImorphDevelopment\inst\libs\x64\tkogl2.dll -Force
'''
