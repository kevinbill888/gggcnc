<%
' 滑动验证码组件
Class SliderCaptcha
    Private captcha_id, captcha_value, captcha_session
    
    Private Sub Class_Initialize()
        Randomize
        captcha_id = "captcha_" & Timer & "_" & Int(Rnd() * 10000)
        captcha_value = Int(Rnd() * 90000) + 10000
        captcha_session = "slider_" & captcha_id
        Session(captcha_session) = captcha_value
    End Sub
    
    Public Function GenerateHTML()
        Dim html
        html = "<div class='slider-captcha' id='" & captcha_id & "'>"
        html = html & "<div class='captcha-track'>"
        html = html & "<div class='captcha-thumb' id='thumb_" & captcha_id & "'>"
        html = html & "<span class='thumb-icon'>→</span>"
        html = html & "</div>"
        html = html & "<div class='captcha-text'>向右滑动验证</div>"
        html = html & "</div>"
        html = html & "<input type='hidden' id='input_" & captcha_id & "' value=''>"
        html = html & "<input type='hidden' id='session_" & captcha_id & "' value='" & captcha_session & "'>"
        html = html & "</div>"
        GenerateHTML = html
    End Function
    
    Public Function Validate(value)
        Validate = (CStr(value) = CStr(Session(captcha_session)))
        If Validate Then
            Session(captcha_session) = ""
        End If
    End Function
    
    Public Function GetID()
        GetID = captcha_id
    End Function
End Class
%>
