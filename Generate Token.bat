@ECHO OFF 
TITLE Generate Token
ECHO Please Wait...
:: Section 1: Activate the environment.
ECHO ============================
ECHO Conda Activate
ECHO ============================
@CALL "C:\Users\Welcome\Anaconda3\Scripts\activate.bat" base
:: Section 2: Execute python script.
ECHO ============================
ECHO Python generate_token.py
ECHO ============================
python D:\Python\First_Choice_Git\xts\strategy\scripts\generate_token.py

ECHO ============================
ECHO End
ECHO ============================
PAUSE