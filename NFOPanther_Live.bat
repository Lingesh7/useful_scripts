@ECHO OFF 
TITLE NFOPanther_Live
ECHO Please Wait...
:: Section 1: Activate the environment.
ECHO ============================
ECHO Conda Activate
ECHO ============================
@CALL "C:\Users\Welcome\Anaconda3\Scripts\activate.bat" base
:: Section 2: Execute python script.
ECHO ============================
ECHO Python NFOPanther_Live.py
ECHO ============================
python D:\Python\First_Choice_Git\xts\strategy\scripts\NFOPanther_Live.py

ECHO ============================
ECHO End
ECHO ============================
PAUSE