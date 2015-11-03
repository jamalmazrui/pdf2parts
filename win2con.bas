#Compile Exe "Win2Con.exe"' Turn a windows program into a console one, ' USAGE Win2Con <FileName> or drag and drop a file onto this program

Function PBMain() As Long
Dim FilePath As String
Dim hFile As Long
Dim OffendingByte As Byte

FilePath = Command$
If FilePath = "" Then Exit Function
Replace $Dq With "" In FilePath    'remove quote marks if the file in case the file is dropped
hFile = FreeFile
OffendingByte = 3
Open FilePath For Binary As hFile
Put hfile, 221,OffendingByte    'update the byte
Close hFile
End Function
