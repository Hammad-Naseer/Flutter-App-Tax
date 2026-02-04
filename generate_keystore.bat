@echo off
echo ========================================
echo Creating Android Keystore for Tax Bridge
echo ========================================
echo.

REM Set Java path (adjust if needed)
set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%

echo Generating keystore file...
echo.
echo Please enter the following information when prompted:
echo - Keystore password: TaxBridge@123
echo - Key password: TaxBridge@123
echo - First and last name: Secureism
echo - Organizational unit: Development
echo - Organization: Secureism Pvt Ltd
echo - City: Islamabad
echo - State: Punjab
echo - Country code: PK
echo.

keytool -genkey -v -keystore android\app\my-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass TaxBridge@123 -keypass TaxBridge@123 -dname "CN=Secureism, OU=Development, O=Secureism Pvt Ltd, L=Islamabad, ST=Punjab, C=PK"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ Keystore created successfully!
    echo ========================================
    echo Location: android\app\my-release-key.keystore
    echo.
    echo You can now run: flutter build appbundle --release
    echo.
) else (
    echo.
    echo ========================================
    echo ❌ Failed to create keystore
    echo ========================================
    echo.
    echo Please make sure Java JDK is installed.
    echo You can download it from: https://www.oracle.com/java/technologies/downloads/
    echo.
)

pause

