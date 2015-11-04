' PDF2Parts
' Version 1.1
' November 4, 2015
' Copyright 2012 - 2015 by Jamal Mazrui
' GNU Lesser General Public License (LGPL)

#INCLUDE "C:\pdf2parts\Private.inc"
' #INCLUDE "C:\pdf2parts\pdf2parts.inc"
#INCLUDE "Win32API.inc"
#INCLUDE "C:\pdf2parts\EOIni.inc"

Global bDebugMode As Long
GLOBAL sExe,    sIni AS STRING

FUNCTION GetCommandArgCount() AS LONG
    LOCAL i AS LONG
    FOR i = 1 TO 100
IF COMMAND$(i) = "" THEN EXIT FOR
NEXT
i = i - 1
FUNCTION = i
END FUNCTION

        FUNCTION GetImageFormatFromString(BYVAL sFormat AS STRING, BYREF sExt AS STRING) AS LONG
LOCAL iReturn AS LONG

iReturn = -1
sFormat = LCase$(sFormat)
sFormat = LTrim$(sFormat, Any ".")
IF sFormat = "bmp" THEN iReturn = 0
IF sFormat = "jpg" THEN iReturn = 1
IF sFormat = "wmf" THEN iReturn = 2
IF sFormat = "emf" THEN iReturn = 3
IF sFormat = "eps" THEN iReturn = 4
IF sFormat = "png" THEN iReturn = 5
IF sFormat = "gif" THEN iReturn = 6
IF sFormat = "tif" Or sFormat = "tiff" THEN iReturn = 7
IF sFormat = "emf+" THEN
iReturn = 8
sExt = ".emf"
ElseIf sFormat = "tiff" Then
sExt = ".tif"
ELSE
sExt = "." & sFormat
END IF
FUNCTION = iReturn
END FUNCTION

FUNCTION LogError(sText AS STRING) AS LONG
LOCAL s AS STRING

IF ISFALSE bDebugMode THEN EXIT FUNCTION
CLIPBOARD GET TEXT TO s
s = s & $CRLF & sText
CLIPBOARD SET TEXT s
END FUNCTION

FUNCTION AnalyzePDF(ByRef oLib AS iDispatch, BYVAL sPDF AS STRING, BYREF iPageCount AS LONG) AS STRING
LOCAL hDoc, hInfo AS LONG
LOCAL iError, iResult, iKey AS LONG
' LOCAL sError, sPassword, sKey, sValue, sReturn AS STRING
' LOCAL sError, sPassword, sKey, sValue, sReturn AS STRING
Local sReturn as String
LOCAL sError, sPassword, sKey, sValue AS WSTRING
Local vPdf, vPassword As Variant

vPdf = sPdf
vPassword = sPassword

Object Call oLib.AnalyseFile(vPDF, vPassword) To hInfo
IF hInfo THEN
FOR iKey = 0 TO 31
IF iKey > 9 AND iKey < 31 THEN ITERATE
Object Call oLib.GetAnalysisInfo(hInfo, iKey) To sValue
IF LEN(sValue) = 0 OR LEN(sValue) = 255 THEN ITERATE
sKey = Ini_GetKey(sIni, "Analysis", FORMAT$(iKey), "")
sReturn = sReturn + sKey
sReturn = sReturn + " = " + sValue + $CRLF + $CrLf
' DialogShow(sKey, FORMAT$(LEN(sValue)))
NEXT
' DialogShow("sReturn", sReturn)

FOR iKey = 20 TO 30
Object Call oLib.GetAnalysisInfo(hInfo, iKey) To sValue
IF LEN(sValue) <= 0 OR TRIM$(sValue) = "0" OR TRIM$(sValue) = "" THEN ITERATE
sReturn = sReturn + Ini_GetKey(sIni, "Analysis", FORMAT$(iKey), "")
sReturn = sReturn + " = " + Ini_GetKey(sIni, "Security Values", sValue, "") + $CRLF + $CrLf
NEXT
Object Call oLib.DeleteAnalysis(hInfo) To iResult
'sReturn = Trim$(sReturn, Any $CrLf)
' DialogShow("sReturn", sReturn)
ELSE
Object Call oLib.LastErrorCode() to iError
sError = Format$(iError)
sReturn = ini_GetKey(sIni, "Error Codes", sError, "")
'DeleteAnalysis(hLib, hInfo)
END IF

Object Call oLib.LoadFromFile(vPdf, vPassword) To iResult
' Object call oLib.LastPageError() To iResult
' Object Call oLib.SelectedDocument() To hDoc
sKey = "Image Only"
Object Call oLib.HasFontResources() To iResult
sValue = "No"
IF ISFALSE iResult THEN sValue = "Yes"
sReturn = sReturn + sKey + " = " + sValue + $CRLF + $CrLf

sKey = "Tagged"
Object Call oLib.IsTaggedPDF() To iResult
' DialogShow("Tagged", Format$(iResult))
sValue = "No"
IF ISTrue iResult THEN sValue = "Yes"
sReturn = sReturn + sKey + " = " + sValue + $CRLF + $CrLf

Object Call oLib.PageCount() To iPageCount

If %False Then
Local sKeys as wstring
Local iType as Long
iType = 2
' Object Call oLib.GetCustomKeys(iType) to sKeys
' Object Call oLib.GetDocumentMetadata() to sKeys
' Clipboard Set Text sKeys
Local sTemp as string
sTemp = sKeys
End If ' custom keys

Object Call oLib.RemoveDocument(hDoc) To iResult

If %False Then
' Shell ENVIRON$("COMSPEC") + " /C DIR *.* > filename.txt"
Local sPdfInfo, sTempFile as String
sPdfInfo = EXE.PATH$ & "pdfinfo.exe"
sTempFile = PATHNAME$(PATH, sPdf) & "temp.tmp"
Shell Environ$("COMSPEC") + " /c " + sPdfInfo + " " + sPdf + " >" + sTempFile
' Shell sPdfInfo + " " + sPdf + " >" + sTempFile
sTemp = FileToString(sTempFile)
Kill sTempFile
Local iIndex as Long
iIndex = InStr(sTemp, Chr$(10) + "Tagged:")
sTemp = Right$(sTemp, Len(sTemp) - iIndex)
iIndex = InStr(sTemp, Chr$(10))
sTemp = Left$(sTemp, iIndex - 1)
Local iLen As Long
While %True
iLen = Len(sTemp)
Replace " " with "" In sTemp
If Len(sTemp) = iLen Then Exit Loop
WEnd
Replace ":" With " = " in sTemp
sReturn = sReturn + sTemp + $CrLf
End If ' get tagged status from pdfinfo

sReturn = Trim$(sReturn, ANY " " + $Crlf) + $CrLf
FUNCTION = sReturn
END FUNCTION

FUNCTION FileToString(BYVAL s_file AS ASCIIZ * 256) AS STRING
LOCAL i_size AS LONG, h_file AS LONG, s_return AS STRING

IF LEN(DIR$(s_file, 7)) =0 THEN
s_return =""
ELSE
h_file =FREEFILE
OPEN s_file FOR BINARY AS h_file
i_size =LOF(h_file)
GET$ h_file, i_size, s_return
CLOSE h_file
END IF
FUNCTION =s_return
END FUNCTION

FUNCTION StringToFile(BYVAL s_text AS STRING, BYVAL s_file AS ASCIIZ * 256) AS LONG
LOCAL i_size AS LONG, h_file AS LONG, i_return AS LONG

IF ISTRUE ISFILE(s_file) THEN KILL s_File
'msgbox format$(len(s_text))
IF LEN(s_text) =0 THEN
'If IsFalse Then
i_return =0
ELSE
h_file =FREEFILE
OPEN s_file FOR BINARY AS h_file
i_size =LEN(s_text)
PUT$ h_file, s_text
CLOSE h_file
i_return =1
END IF
FUNCTION =i_return
END FUNCTION

FUNCTION PrintLine(Z AS STRING) AS LONG
 ' returns TRUE (non-zero) on success
   LOCAL hStdOut AS LONG, nCharsWritten AS LONG
   LOCAL w AS STRING
   STATIC CSInitialized AS LONG, CS AS CRITICAL_SECTION
   IF ISFALSE CSInitialized THEN
       InitializeCriticalSection CS
       CSInitialized  =  1
   END IF
   EntercriticalSection Cs
   hStdOut      = GetStdHandle (%STD_OUTPUT_HANDLE)
   IF hSTdOut   = -1& OR hStdOut = 0&   THEN     ' invalid handle value, coded in line to avoid
                                                 ' casting differences in Win32API.INC
                                                 ' test for %NULL added 8.26.04 for Win/XP
     AllocConsole
     hStdOut  = GetStdHandle (%STD_OUTPUT_HANDLE)
   END IF
   LeaveCriticalSection CS
   w = Z & $CRLF
   FUNCTION = WriteFile(hStdOut, BYVAL STRPTR(W), LEN(W),  nCharsWritten, BYVAL %NULL)
 END FUNCTION

FUNCTION StringPlural(sText AS STRING, iCount AS LONG) AS STRING
LOCAL sReturn AS STRING

sReturn = sText
IF iCount <> 1 THEN sReturn = sReturn & "s"
FUNCTION = sReturn
END FUNCTION

FUNCTION GetWidth(iNum AS LONG) AS LONG
LOCAL iResult, iLoop, iPower AS LONG

iLoop = 1
WHILE iLoop > 0
iResult = iNum \ (10^iPower)
IF (iResult = 0) OR (iLoop = 100) THEN
iLoop = -1 * iLoop
ELSE
iPower = iPower + 1
END IF
WEND

IF iLoop = -100 THEN
DialogShow("reached 100 for width", "")
GetWidth = 5
ELSE
GetWidth = iPower
END IF
END FUNCTION

FUNCTION DialogInput(sTitle AS STRING, sMessage AS STRING, sValue AS STRING) AS STRING
FUNCTION = INPUTBOX$(sMessage, sTitle, sValue)
END FUNCTION

FUNCTION DialogShow(sTitle AS STRING, sMessage AS STRING) AS LONG
' show a standard message box

DIM iFlags AS LONG

DialogShow = %True
iFlags = %MB_ICONINFORMATION OR %MB_SYSTEMMODAL
IF sTitle = "" THEN sTitle = "Show"
MSGBOX sMessage, iFlags, sTitle
END FUNCTION

FUNCTION StringQuote(BYVAL s$) AS STRING
FUNCTION = CHR$(34) & s$ & CHR$(34)
END FUNCTION

FUNCTION DialogConfirm(sTitle AS STRING, sMessage AS STRING, sDefault AS STRING) AS STRING
' Get choice from a standard Yes, No, or Cancel message box

DIM iFlags AS LONG, iChoice AS LONG

DialogConfirm = ""
iFlags = %MB_YESNOCANCEL
iFlags = iFlags OR %MB_ICONQUESTION     ' 32 query icon
iFlags = iFlags OR %MB_SYSTEMMODAL ' 4096   System modal
IF sTitle = "" THEN sTitle = "Confirm"
IF sDefault = "N" THEN iFlags = iFlags OR %MB_DEFBUTTON2
iChoice = MSGBOX(sMessage, iFlags, sTitle)
IF iChoice = %IDCANCEL THEN EXIT FUNCTION

IF iChoice = %IDYES THEN
DialogConfirm = "Y"
ELSE
DialogConfirm = "N"
END IF
END FUNCTION

FUNCTION Say(sText AS STRING) AS LONG
DIM sExe AS STRING
sExe = appPath$ & "SayLine.exe"
SHELL(StringQuote(sExe) & sText, 0)
END FUNCTION

FUNCTION pdf2urls() AS LONG
LOCAL hLib, hDoc, hPdf, hPage, hGraphics, hGraphic, hOutline AS LONG
LOCAL iCount, iFormat, iOptions, iDPI, iResult, iPage, iPageCount, iPageWidth, iType, iProperty, iGraphic, iImageCount, iImageWidth, iAnnot, iAnnotCount, iAnnotWidth, iOutline, iOutlineCount AS LONG
Local oLib As IDispatch
' LOCAL sRange, sLib, sProgId, sClsId, sUnlockKey, sPage, sDPI, sFormat, sText, sPdf, sPassword, sImage, sGraphic, sBody, sTxt, sSuffix, sPath, sBase, sRoot, sExt, sAnnot, sName, sContents, sURL AS STRING
LOCAL sRange, sLib, sProgId, sClsId, sUnlockKey, sPage, sDPI, sFormat, sText, sPdf, sPassword, sImage, sGraphic, sBody, sTxt, sSuffix, sPath, sBase, sRoot, sExt, sAnnot, sName, sContents, sURL AS WSTRING
Local vRange, vPassword, vGraphic, vPdf, vPage, vTxt, vImage, vUnlockKey, vAnnot, vName, vContents, vURL  As Variant

' bDebugMode = %True
bDebugMode = %False

sExe = EXE.FULL$
sLib = EXE.PATH$ & "pdf2parts.dll"
sIni = EXE.PATH$ & "pdf2parts.ini"

iDPI = 150

iCount = GetCommandArgCount()
IF iCount = 0 THEN
PrintLine("Syntax:")
PrintLine("pdf2urlcs.exe FileName")
PrintLine("FileName is the PDF")
EXIT FUNCTION
END IF

IF iCount > 0 THEN
sPdf = COMMAND$(1)
IF ISFALSE ISFILE(sPdf) THEN
PrintLine("Cannot find file" & sPdf)
EXIT FUNCTION
END IF
END IF

vPdf = sPdf
vPassword = sPassword

IF iCount > 1 THEN
sDPI = COMMAND$(2)
iDPI = VAL(sDPI)
END IF

PrintLine("Converting to URLs")

' Version 10
' sClsId = Guid$("{379ADE06-ECA2-458E-A46F-9A7690F930B1}")
sClsId = GUID$("{2E75DB15-9312-4902-8DA0-EAC34A6DD40C}")
oLib = NewCom ClsId sClsId Lib sLib
sUnlockKey = $QuickPDF_UnlockKey
vUnlockKey = sUnlockKey
Object Call oLib.UnlockKey(vUnlockKey) To iResult

sPath = PATHNAME$(PATH, sPdf)
sRoot = PATHNAME$(NAME, sPdf)
sSuffix = "_urls"
sBase = PATHNAME$(NAMEX, sPdf)
sExt = ".txt"
sTxt = SPath & sRoot & sSuffix & sExt

' Object Call oLib.DAOpenFileReadOnly(vPdf, vPassword) To hPdf
' Object Call oLib.OpenFileReadOnly(vPdf, vPassword) To hPdf
Object Call oLib.LoadFromFile(vPdf, vPassword) To hPdf
Object Call oLib.PageCount() To iPageCount
iPageWidth = GetWidth(iPageCount)
PrintLine(sBase & " = " & FORMAT$(iPageCount) & " " & StringPlural("page", iPageCount))

FOR iPage = 1 TO iPageCount
' Object Call oLib.FindPage(hPdf, iPage) To hPage
Object Call oLib.SelectPage(iPage) To hPage

' Dim iAnnotCount as Long
Dim vAnnotCount as Variant
Object Call oLib.AnnotationCount() To vAnnotCount
iAnnotCount = Variant#(vAnnotCount)
iAnnotWidth = GetWidth(iAnnotCount)
IF iAnnotCount > 0 THEN PrintLine("Page " & FORMAT$(iPage) & " = " & FORMAT$(iAnnotCount) & " " & StringPlural("URL", iAnnotCount))

FOR iAnnot = 1 TO iAnnotCount
sSuffix = "_" & RSET$(FORMAT$(iPage), iPageWidth USING "0") & "-" & RSET$(FORMAT$(iGraphic), iAnnotWidth USING "0")
sAnnot = SPath & sRoot & sSuffix & sExt
vAnnot = sAnnot
' Object Call oLib.DAGetAnnotActionID(hPdf, iAnnot) To hAnnot
iProperty = 102
Object Call oLib.GetAnnotStrProperty(iAnnot, iProperty) To sContents

iProperty = 103
Object Call oLib.GetAnnotStrProperty(iAnnot, iProperty) To sName

iProperty = 111
Object Call oLib.GetAnnotStrProperty(iAnnot, iProperty) To sURL

' If Len(sURL) Then PrintLine(sURL)
If Len(sURL) Then sText = sText + sURL + $CrLf + $CrLf
NEXT
NEXT

If %False Then
Object Call oLib.OutlineCount() To iOutlineCount
PrintLine(FORMAT$(iOutlineCount) & " " & StringPlural("Outline", iOutlineCount))
' sText = sText + "Outlines" + $CrLf

If iOutlineCount then PrintLine("Outlines")
FOR iOutline = 1 TO iOutlineCount
Object Call oLib.GetOutlineID(iOutline) To hOutline
Object Call oLib.GetOutlineWebLink(hOutline) To sURL
' If Len(sURL) Then PrintLine(sURL)
Local sTemp as string
sTemp = sURL
' PrintLine(sTemp)
If Len(sTemp) Then sText = sText + sTemp + $CrLf + $CrLf
' If Len(sTemp) Then PrintLine("a web link")
Next
End If ' Outlines
sText = Trim$(sText, ANY " " + $Crlf) + $CrLf
StringToFile(sText, sTxt)
PrintLine("Done")
AbortFunction:
Object Call oLib.DACloseFile(hPdf) To iResult
Object Call oLib.ReleaseLibrary() To iResult
EXIT FUNCTION

ErrorTrap:
SELECT CASE ERRCLEAR
CASE %ERR_NOERROR: LogError "ERR_NOERROR= 0"
CASE %ERR_ILLEGALFUNCTIONCALL: LogError "ERR_ILLEGALFUNCTIONCALL= 5"
CASE %ERR_OVERFLOW: LogError "ERR_OVERFLOW = 6 (reserved)"
CASE %ERR_OUTOFMEMORY: LogError "ERR_OUTOFMEMORY= 7"
CASE %ERR_SUBSCRIPTPOINTEROUTOFRANGE: LogError "ERR_SUBSCRIPTPOINTEROUTOFRANGE= 9"
CASE %ERR_DIVISIONBYZERO: LogError "ERR_DIVISIONBYZERO = 11 (reserved)"
CASE %ERR_DEVICETIMEOUT: LogError "ERR_DEVICETIMEOUT= 24"
CASE %ERR_INTERNALERROR: LogError "ERR_INTERNALERROR= 51"
CASE %ERR_BADFILENAMEORNUMBER: LogError "ERR_BADFILENAMEORNUMBER= 52"
CASE %ERR_FILENOTFOUND: LogError "ERR_FILENOTFOUND= 53"
CASE %ERR_BADFILEMODE: LogError "ERR_BADFILEMODE= 54"
CASE %ERR_FILEISOPEN: LogError "ERR_FILEISOPEN= 55"
CASE %ERR_DEVICEIOERROR: LogError "ERR_DEVICEIOERROR= 57"
CASE %ERR_FILEALREADYEXISTS: LogError "ERR_FILEALREADYEXISTS= 58"
CASE %ERR_DISKFULL: LogError "ERR_DISKFULL= 61"
CASE %ERR_INPUTPASTEND: LogError "ERR_INPUTPASTEND= 62"
CASE %ERR_BADRECORDNUMBER: LogError "ERR_BADRECORDNUMBER= 63"
CASE %ERR_BADFILENAME: LogError "ERR_BADFILENAME= 64"
CASE %ERR_TOOMANYFILES: LogError "ERR_TOOMANYFILES= 67"
CASE %ERR_DEVICEUNAVAILABLE: LogError "ERR_DEVICEUNAVAILABLE= 68"
CASE %ERR_COMMERROR: LogError "ERR_COMMERROR= 69"
CASE %ERR_PERMISSIONDENIED: LogError "ERR_PERMISSIONDENIED= 70"
CASE %ERR_DISKNOTREADY: LogError "ERR_DISKNOTREADY= 71"
CASE %ERR_DISKMEDIAERROR: LogError "ERR_DISKMEDIAERROR= 72"
CASE %ERR_RENAMEACROSSDISKS: LogError "ERR_RENAMEACROSSDISKS= 74"
CASE %ERR_PATHFILEACCESSERROR: LogError "ERR_PATHFILEACCESSERROR= 75"
CASE %ERR_PATHNOTFOUND: LogError "ERR_PATHNOTFOUND= 76"
CASE %ERR_OBJECTERROR: LogError "ERR_OBJECTERROR= 99"
CASE %ERR_GLOBALMEMORYCORRUPT: LogError "ERR_GLOBALMEMORYCORRUPT= 241 (Previously %ERR_FARHEAPCORRUPT)"
CASE %ERR_STRINGSPACECORRUPT: LogError "ERR_STRINGSPACECORRUPT= 242"
CASE ELSE : LogError "Unknown error!"
END SELECT
RESUME AbortFunction
END FUNCTION

FUNCTION PBMAIN() AS LONG
LOCAL hLib, hDoc, hPdf, hPage, hGraphics, hGraphic AS LONG
LOCAL iCount, iFormat, iOptions, iDPI, iResult, iPage, iPageCount, iPageWidth, iType, iProperty, iGraphic, iImageCount, iImageWidth AS LONG
Local oLib As IDispatch
LOCAL sRange, sLib, sProgId, sClsId, sUnlockKey, sPage, sDPI, sFormat, sText, sPdf, sPassword, sImage, sGraphic, sBody, sTxt, sSuffix, sPath, sBase, sRoot, sExt AS STRING
Local vRange, vPassword, vGraphic, vPdf, vPage, vTxt, vImage, vUnlockKey As Variant

' bDebugMode = %True
bDebugMode = %False

sExe = EXE.FULL$
sLib = EXE.PATH$ & "pdf2parts.dll"
sIni = EXE.PATH$ & "pdf2parts.ini"

iDPI = 150
sFormat = "tiff"
sExt = ".tif"
iFormat = 7

iCount = GetCommandArgCount()
IF iCount = 0 THEN
PrintLine("Syntax:")
PrintLine("pdf2parts.exe FileName DPI Format")
PrintLine("FileName is the PDF, DPI is the Dots Per Inch, and Format is the image format")
EXIT FUNCTION
END IF

IF iCount > 0 THEN
sPdf = COMMAND$(1)
IF ISFALSE ISFILE(sPdf) THEN
PrintLine("Cannot find file" & sPdf)
EXIT FUNCTION
END IF
END IF

vPdf = sPdf
vPassword = sPassword

IF iCount > 1 THEN
sDPI = COMMAND$(2)
iDPI = VAL(sDPI)
END IF

IF iCount > 2 THEN
sFormat = COMMAND$(3)
iFormat = GetImageFormatFromString(sFormat, sExt)

IF iFormat = -1 THEN
PrintLine("Invalid image format")
EXIT FUNCTION
END IF
END IF

PrintLine("Converting to images and graphics at " & Format$(iDPI) & " DPI")

' Version 10
' sClsId = Guid$("{379ADE06-ECA2-458E-A46F-9A7690F930B1}")
sClsId = GUID$("{2E75DB15-9312-4902-8DA0-EAC34A6DD40C}")
oLib = NewCom ClsId sClsId Lib sLib
sUnlockKey = $QuickPDF_UnlockKey
vUnlockKey = sUnlockKey
' MsgBox sUnlockKey
Object Call oLib.UnlockKey(vUnlockKey) To iResult
' msgbox Format$(iResult)

sPath = PATHNAME$(PATH, sPdf)
sRoot = PATHNAME$(NAME, sPdf)
sBase = PATHNAME$(NAMEX, sPdf)

sText = AnalyzePDF(oLib, sPdf, iPageCount)
iPageWidth = GetWidth(iPageCount)
iPage = 0
'sSuffix = "_" & RSET$(FORMAT$(iPage), iPageWidth USING "0")
sSuffix = "_meta"
sExt = ".txt"
sTxt = SPath & sRoot & sSuffix & sExt
StringToFile(sText, sTxt)

Object Call oLib.DAOpenFileReadOnly(vPdf, vPassword) To hPdf
Object Call oLib.DAGetPageCount(hPdf) To iPageCount
iPageWidth = GetWidth(iPageCount)
PrintLine(sBase & " = " & FORMAT$(iPageCount) & " " & StringPlural("page", iPageCount))

FOR iPage = 1 TO iPageCount
Object Call oLib.DAFindPage(hPdf, iPage) To hPage
sSuffix = "_" & RSET$(FORMAT$(iPage), iPageWidth USING "0")

sExt = ".pdf"
sPage = SPath & sRoot & sSuffix & sExt
vPage = sPage
sRange = Format$(iPage)
vRange = sRange
Object Call oLib.ExtractFilePages(vPdf, vPage, vRange) To iResult

iFormat = GetImageFormatFromString(sFormat, sExt)
sImage = SPath & sRoot & sSuffix & sExt
vImage = sImage
Object Call oLib.DARenderPageToFile(hPdf, hPage, iFormat, iDpi, vImage) To iResult

sExt = ".txt"
sTxt = SPath & sRoot & sSuffix & sExt
vTxt = sTxt
' iFormat = 8 ' human readable withoutlayout
' iFormat = 7 ' human readable
iFormat = 0 ' original
' Causes crash over time
Object Call oLib.DAExtractPageText(hPdf, hPage, iFormat) To sText
StringToFile(sText, sTxt)

IF sBody <> "" THEN sBody = sBody & CHR$(12) & CHR$(13) & CHR$(10)
sBody = sBody & sText

Object Call oLib.DAGetPageImageList(hPdf, hPage) To hGraphics
Object Call oLib.DAGetImageListCount(hPdf, hGraphics) To iImageCount
iImageWidth = GetWidth(iImageCount)
IF iImageCount > 0 THEN PrintLine("Page " & FORMAT$(iPage) & " = " & FORMAT$(iImageCount) & " " & StringPlural("graphic", iImageCount))


FOR iGraphic = 1 TO iImageCount
iProperty = 400 ' image type
Object Call oLib.DAGetImageIntProperty(hPdf,   hGraphics, iGraphic, iProperty) To iType

IF iType = 0 THEN
sExt = ".bin"
ELSEIF iType = 1 THEN
sExt = ".jpg"
ELSEIF iType = 2 THEN
sExt = ".bmp"
ELSEIF iType = 3 THEN
sExt = ".tif"
END IF

sSuffix = "_" & RSET$(FORMAT$(iPage), iPageWidth USING "0") & "-" & RSET$(FORMAT$(iGraphic), iImageWidth USING "0")
sGraphic = SPath & sRoot & sSuffix & sExt
vGraphic = sGraphic
Object Call oLib.DASaveImageDataToFile(hPdf, hGraphics, iGraphic, vGraphic) To iResult
NEXT
NEXT

sExt = ".txt"
sTxt = sPath & sRoot & sExt
vTxt = sTxt
StringToFile(sBody, sTxt)

' pdf2urls
sPath = PATHNAME$(PATH, sPdf)
sRoot = PATHNAME$(NAME, sPdf)
sSuffix = "_urls"
sBase = PATHNAME$(NAMEX, sPdf)
sExt = ".txt"
sTxt = SPath & sRoot & sSuffix & sExt

' Object Call oLib.DAOpenFileReadOnly(vPdf, vPassword) To hPdf
' Object Call oLib.OpenFileReadOnly(vPdf, vPassword) To hPdf
Object Call oLib.LoadFromFile(vPdf, vPassword) To hPdf
Object Call oLib.PageCount() To iPageCount
iPageWidth = GetWidth(iPageCount)
PrintLine(sBase & " = " & FORMAT$(iPageCount) & " " & StringPlural("page", iPageCount))

FOR iPage = 1 TO iPageCount
' Object Call oLib.FindPage(hPdf, iPage) To hPage
Object Call oLib.SelectPage(iPage) To hPage

Dim vAnnotCount as Variant
Object Call oLib.AnnotationCount() To vAnnotCount
Dim iAnnotCount as Long
Dim iAnnotWidth as Long
Dim iAnnot as Long
iAnnotCount = Variant#(vAnnotCount)
' iAnnotCount = oLib.AnnotationCount() 
iAnnotWidth = GetWidth(iAnnotCount)
IF iAnnotCount > 0 THEN PrintLine("Page " & FORMAT$(iPage) & " = " & FORMAT$(iAnnotCount) & " " & StringPlural("URL", iAnnotCount))

FOR iAnnot = 1 TO iAnnotCount
sSuffix = "_" & RSET$(FORMAT$(iPage), iPageWidth USING "0") & "-" & RSET$(FORMAT$(iGraphic), iAnnotWidth USING "0")
Dim sAnnot as WString
sAnnot = SPath & sRoot & sSuffix & sExt
Dim vAnnot as Variant
vAnnot = sAnnot
' Object Call oLib.DAGetAnnotActionID(hPdf, iAnnot) To hAnnot
iProperty = 102
Dim sContents as WString
Dim vContents as Variant
Object Call oLib.GetAnnotStrProperty(iAnnot, iProperty) To vContents
sContents = Variant$(vContents)

iProperty = 103
Dim sName as WString
Dim VName as Variant
Object Call oLib.GetAnnotStrProperty(iAnnot, iProperty) To vName
sName = Variant$(vName)

iProperty = 111
Dim sUrl as WString
Dim vUrl as Variant
Object Call oLib.GetAnnotStrProperty(iAnnot, iProperty) To vURL
sUrl = Variant$(sUrl)

' If Len(sURL) Then PrintLine(sURL)
If Len(sURL) Then sText = sText + sURL + $CrLf + $CrLf
NEXT
NEXT

sText = Trim$(sText, ANY " " + $Crlf) + $CrLf
StringToFile(sText, sTxt)

pdf2urls()

PrintLine("Done")
AbortFunction:
Object Call oLib.DACloseFile(hPdf) To iResult
Object Call oLib.ReleaseLibrary() To iResult
EXIT FUNCTION

ErrorTrap:
SELECT CASE ERRCLEAR
CASE %ERR_NOERROR: LogError "ERR_NOERROR= 0"
CASE %ERR_ILLEGALFUNCTIONCALL: LogError "ERR_ILLEGALFUNCTIONCALL= 5"
CASE %ERR_OVERFLOW: LogError "ERR_OVERFLOW = 6 (reserved)"
CASE %ERR_OUTOFMEMORY: LogError "ERR_OUTOFMEMORY= 7"
CASE %ERR_SUBSCRIPTPOINTEROUTOFRANGE: LogError "ERR_SUBSCRIPTPOINTEROUTOFRANGE= 9"
CASE %ERR_DIVISIONBYZERO: LogError "ERR_DIVISIONBYZERO = 11 (reserved)"
CASE %ERR_DEVICETIMEOUT: LogError "ERR_DEVICETIMEOUT= 24"
CASE %ERR_INTERNALERROR: LogError "ERR_INTERNALERROR= 51"
CASE %ERR_BADFILENAMEORNUMBER: LogError "ERR_BADFILENAMEORNUMBER= 52"
CASE %ERR_FILENOTFOUND: LogError "ERR_FILENOTFOUND= 53"
CASE %ERR_BADFILEMODE: LogError "ERR_BADFILEMODE= 54"
CASE %ERR_FILEISOPEN: LogError "ERR_FILEISOPEN= 55"
CASE %ERR_DEVICEIOERROR: LogError "ERR_DEVICEIOERROR= 57"
CASE %ERR_FILEALREADYEXISTS: LogError "ERR_FILEALREADYEXISTS= 58"
CASE %ERR_DISKFULL: LogError "ERR_DISKFULL= 61"
CASE %ERR_INPUTPASTEND: LogError "ERR_INPUTPASTEND= 62"
CASE %ERR_BADRECORDNUMBER: LogError "ERR_BADRECORDNUMBER= 63"
CASE %ERR_BADFILENAME: LogError "ERR_BADFILENAME= 64"
CASE %ERR_TOOMANYFILES: LogError "ERR_TOOMANYFILES= 67"
CASE %ERR_DEVICEUNAVAILABLE: LogError "ERR_DEVICEUNAVAILABLE= 68"
CASE %ERR_COMMERROR: LogError "ERR_COMMERROR= 69"
CASE %ERR_PERMISSIONDENIED: LogError "ERR_PERMISSIONDENIED= 70"
CASE %ERR_DISKNOTREADY: LogError "ERR_DISKNOTREADY= 71"
CASE %ERR_DISKMEDIAERROR: LogError "ERR_DISKMEDIAERROR= 72"
CASE %ERR_RENAMEACROSSDISKS: LogError "ERR_RENAMEACROSSDISKS= 74"
CASE %ERR_PATHFILEACCESSERROR: LogError "ERR_PATHFILEACCESSERROR= 75"
CASE %ERR_PATHNOTFOUND: LogError "ERR_PATHNOTFOUND= 76"
CASE %ERR_OBJECTERROR: LogError "ERR_OBJECTERROR= 99"
CASE %ERR_GLOBALMEMORYCORRUPT: LogError "ERR_GLOBALMEMORYCORRUPT= 241 (Previously %ERR_FARHEAPCORRUPT)"
CASE %ERR_STRINGSPACECORRUPT: LogError "ERR_STRINGSPACECORRUPT= 242"
CASE ELSE : LogError "Unknown error!"
END SELECT
RESUME AbortFunction
END FUNCTION
