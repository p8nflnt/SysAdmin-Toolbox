<#
.SYNOPSIS
    Capture text from all single-page .PDF documents in target directory via OCR
    Uses open-source Ghostscript (https://www.ghostscript.com/index.html)
    Uses open-source Tesseract-OCR (https://github.com/tesseract-ocr/tesseract)

.NOTES
    Name: Get-PdfOcrText
    Author: Payton Flint
    Version: 1.0
    DateCreated: 2023-Sep

.LINK
    https://paytonflint.com/powershell-extract-text-from-pdf-files/
    https://github.com/p8nflnt/SysAdmin-Toolbox/blob/main/Get-PdfOcrText.ps1
#>

Function Get-PdfOcrText {
    param (
        $pdfFileStore
    )

    # identify location of script
    #$PSScriptRoot = Split-Path ($MyInvocation.MyCommand.Path) -Parent

    # Update-EnvironmentVariables Function
    Function Update-EnvironmentVariables {
        # Clear nullified environment variables
        $machineValues = [Environment]::GetEnvironmentVariables('Machine')
        $userValues    = [Environment]::GetEnvironmentVariables('User')
        $processValues = [Environment]::GetEnvironmentVariables('Process')
        # Identify the entire list of environment variable names first
        $envVarNames = ($machineValues.Keys + $userValues.Keys + 'PSModulePath') | Sort-Object | Select-Object -Unique
        # Lastly remove the environment variables that no longer exist
        ForEach ($envVarName in $processValues.Keys | Where-Object {$envVarNames -like $null}) {
        Remove-Item -LiteralPath "env:${envVarName}" -Force
        }
        # Update variables
        foreach($level in "Machine","User","Process") {
        [Environment]::GetEnvironmentVariables($level)
        }
    } # End of Update-EnvironmentVariables Function

    # specify path to tesseract.exe (TesseractOCR)
    $tesseractPath = "$env:SystemDrive\Program Files\Tesseract-OCR\tesseract.exe"

    # install TesseractOCR if it is not present
    # https://github.com/UB-Mannheim/tesseract/wiki
    If (!(Test-Path -Path $tesseractPath)){
        Write-Host -ForegroundColor Red "`'tesseract.exe`' not present @ $tesseractPath."
        Write-host -ForegroundColor Red "Please install Tesseract or specify new location."

        # specify Tesseract source URL
        $tesseractURL = "https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-5.3.1.20230401.exe"

        # derive file name from url
        $tesseractFileName = $tesseractURL -split '/'
        $tesseractFileName = $tesseractFileName[-1]

        # build destination path
        $tesseractInstallPath = Join-Path $PSScriptRoot $tesseractFileName

        # download .exe from url to script root
        Invoke-WebRequest -Uri $tesseractURL -OutFile $tesseractInstallPath

        # run .exe installer
        Start-Process -FilePath $tesseractInstallPath -Wait

        # remove file when done
        Remove-Item -Path "$tesseractInstallPath"
    }

    # specify path to gswin64c.exe (GhostScript)
    $ghostScriptPath = 'C:\Program Files\gs\gs10.02.0\bin\gswin64c.exe'

    # install GhostScript if it is not present
    # https://ghostscript.readthedocs.io/en/latest/?utm_content=cta-header-link&utm_medium=website&utm_source=ghostscript
    If (!(Test-Path -Path $ghostScriptPath)) {
        $ghostScriptUrl = 'https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10020/gs10020w64.exe'

        # derive file name from url
        $ghostScriptFileName = $ghostScriptUrl -split '/'
        $ghostScriptFileName = $ghostScriptFileName[-1]

        # build destination path
        $ghostScriptInstallPath = Join-Path $PSScriptRoot $ghostScriptFileName

        # download .exe from url to script root
        Invoke-WebRequest -Uri $ghostScriptUrl -OutFile $ghostScriptInstallPath

        # run .exe installer
        Start-Process -FilePath $ghostScriptInstallPath -Wait

        # Update Environment Variables - gswin64 path is written to $env:PATH on install
        Update-EnvironmentVariables

        # remove file when done
        Remove-Item -Path "$ghostScriptInstallPath"
    }

    # specify ghostscript input file extension
    $gsInFileExt = '.pdf'

    # add wildcard to file extension to get all files of that type
    $gsInFileExt = '*' + $gsInFileExt

    # get all .pdf files from input file store
    $gsInFiles = $pdfFileStore | Get-ChildItem -Filter $gsInFileExt

    # specify ghostscript output file extension
    $gsOutFileExt = '.png'

    # specify tesseract output file extension
    $tessOutFileExt = '.txt'

    # specify language abbreviation for TesseractOCR 
    # refer to Tesseract documentation
    $tessOCRLang = 'eng' # eng = english

    # set working directory to pdf source path
    Set-Location $pdfFileStore

    # initialize PDF OCR text array
    $pdfOcrText = @()

    $gsInFiles | ForEach-Object {
    
        # specify input .pdf file name for GhostScript
        $gsInFile =  $_.Name

        # specify output .png file name for GhostScript
        $gsOutFile = $_.BaseName + $gsOutFileExt
    
        # convert .pdf input file to temp .png output file via GhostScript
        Start-Process -FilePath 'gswin64c.exe' -ArgumentList "-sDEVICE=pngalpha -o $gsOutFile -r144 $gsInFile " -Wait

        # specify temp .png input file name for TesseractOCR
        $tessInFile =  Join-Path $pdfFileStore $gsOutFile

        # specify temp .txt output file basename for TesseractOCR
        $tessOutFile = Join-Path $pdfFileStore $_.BaseName

        # convert temp .png input file to temp .txt output file via TesseractOCR
        Start-Process -FilePath $tesseractPath -ArgumentList "-l $tessOCRLang `"$tessInFile`" `"$tessOutFile`" txt" -Wait
    
        # specify temp .txt output file full name w/ extension
        $tessOutFile = $tessOutFile + $tessOutFileExt
    
        # remove temp .png file
        Remove-Item -Path $tessInFile -Force
    
        # get content from temp .txt file
        $pdfOcrText += Get-Content -Path $tessOutFile
    
        # remove temp .txt file
        Remove-Item -Path $tessOutFile -Force
    }
    $pdfOcrText
} # End Function Get-PdfOcrText

$pdfFileStore = "<DIRECTORY PATH>"

$text = Get-PdfOcrText $pdfFileStore

$text
