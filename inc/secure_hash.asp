<% 
' ===== 安全升级：MD5改为SHA256加盐（2025-10-07）=====
Function GenerateSalt()
    Dim salt : salt = ""
    Randomize
    For i = 1 To 16
        salt = salt & Chr(Int(Rnd() * 74) + 48)  ' 生成16位随机盐
    Next
    GenerateSalt = salt
End Function

Function SecureHash(password, salt)
    Set hasher = Server.CreateObject("System.Security.Cryptography.SHA256Managed")
    Dim input : input = salt & password & salt  ' 盐值包裹增强安全性
    hasher.ComputeHash_2(ToUTF8(input))
    SecureHash = ByteToHex(hasher.Hash)
End Function
%>