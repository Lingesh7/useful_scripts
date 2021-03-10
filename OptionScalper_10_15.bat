@ECHO OFF 
TITLE OptionScalper_Live
ECHO Please Wait...
:: Section 1: Activate the environment.
ECHO ============================
ECHO Conda Activate
ECHO ============================
@CALL "C:\Users\Welcome\Anaconda3\Scripts\activate.bat" base
:: Section 2: Execute python script.
ECHO ============================
ECHO Python OptionScalper_Live.py
ECHO ============================
python D:\Python\First_Choice_Git\xts\strategy\scripts\OptionScalper_Live.py -t NIFTY -st 10:15:00

ECHO ============================
ECHO End
ECHO ============================
PAUSE