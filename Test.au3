#include <_HttpRequest.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Test", 257, 182, 192, 124)
GUISetFont(12, 400, 0, "Times New Roman")
$Text = GUICtrlCreateLabel("", 32, 8, 184, 42)
GUICtrlSetFont(-1, 20, 400, 0, "Comic Sans MS")
$Username = GUICtrlCreateInput("", 8, 56, 241, 27)
$Password = GUICtrlCreateInput("", 8, 96, 241, 27, $ES_PASSWORD)
$Edit1 = GUICtrlCreateEdit("", 88, 120, 433, 153,$ES_AUTOVSCROLL + $WS_VSCROLL)
GUICtrlSetState($Edit1, $GUI_HIDE)
GUICtrlSetData(-1, "")
$Login = GUICtrlCreateButton("Login", 32, 136, 89, 33)
$Exit = GUICtrlCreateButton("Exit", 136, 136, 89, 33)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $Login
			_Login(GUICtrlRead($Username), GUICtrlRead($Password))
		Case $Exit
			Exit
	EndSwitch
WEnd
Func FB_Post($Handle, $Content, $Pri = 0, $UID = False)
	Local $Post_pri[3] = ["300645083384735", "291667064279714", "286958161406148"], $data, $UserID = ($UID ? $UID : $Handle[1]), $Post_body, $Get_id
	If not IsArray($Handle) then Return SetError(1, 0, False)
	If $Pri < 0 Or $Pri > 2 or (not IsNumber($Pri)) Then $Pri = 0
	$data = "privacyx=" & ($UID ? "" : $Post_pri[$Pri]) & "&xhpc_targetid=" & $UserID &"&xhpc_message=" & _URIEncode($Content) & "&fb_dtsg=" & $Handle[2]
	$Post_body = _HttpRequest(2, "https://www.facebook.com/ajax/updatestatus.php",$data, $Handle[0], "https://www.facebook.com/profile.php?id=" & ($UID ? $UID :$Handle[1]))
	$Get_id = StringRegExp($Post_body, "top_level_post_id&quot;:&quot;(.*?)&quot;",3)
	If @error then Return SetError(2, 0, True)
	Return $Get_id[0]
EndFunc
Func _Login($Username, $Password, $iRememberCookie = 1, $sPathSaveCookie = @ScriptDir & "\Cookie.ini")
	If Not FileExists($sPathSaveCookie) Then FileOpen($sPathSaveCookie, 2 + 8 + 32)
	Local $sCookie, $FB_dtsg, $UserID
	$g_SectionINI = ___MyB64Encode(_Crypt_HashData($Username & $Password, $CALG_MD5))
	If $iRememberCookie Then
		$sCookie = IniRead($sPathSaveCookie, $g_SectionINI, 'Cookie', '')
		$FB_dtsg = IniRead($sPathSaveCookie, $g_SectionINI, 'DTSG', '')
		If Not $sCookie Or Not $FB_dtsg Or ___TimeStampNow() - IniRead($sPathSaveCookie, $g_SectionINI, 'Timestamp', 0) > 2000000 Then
			Return _Login($Username, $Password, 0, $sPathSaveCookie)
		EndIf
		Local $encrt_UserID = StringRegExp($sCookie, "c_user=(.*?);", 1)[0]
		$UserID = BinaryToString(_Crypt_DecryptData(___MyB64Decode($encrt_UserID), $Password, $CALG_AES_256))
		$sCookie = StringReplace($sCookie, 'c_user=' & $encrt_UserID, 'c_user=' & $UserID, 1, 1)
		Local $aRet = [$sCookie, $UserID, $FB_dtsg]
	Else
		Local $Request = _HttpRequest(1, "https://m.facebook.com/login.php", "email=" & _URIEncode($Username) & "&pass=" & _URIEncode($Password))
		$sCookie = _GetCookie($Request)
		If @error Then Return SetError(1, 0, False)
		Local $UserID = StringRegExp($sCookie, "c_user=(.*?);", 1)
		If @error Then Return SetError(2, 0, False)
		$FB_dtsg = StringRegExp(_HttpRequest(2, 'https://m.facebook.com/home.php', '', $sCookie), '\Q"fb_dtsg" value="\E(.*?)\"', 1)
		If @error Or $FB_dtsg[0] = '' Then Return SetError(3, 0, False)
		Local $aRet[3] = [$sCookie, $UserID[0], $FB_dtsg[0]]
		Local $encrt_UserID = ___MyB64Encode(_Crypt_EncryptData($UserID[0], $Password, $CALG_AES_256))
		$sCookie = StringReplace($sCookie, 'c_user=' & $UserID[0], 'c_user=' & $encrt_UserID, 1, 1)
		IniWrite($sPathSaveCookie, $g_SectionINI, "Cookie", $sCookie)
		IniWrite($sPathSaveCookie, $g_SectionINI, "DTSG", $aRet[2])
		IniWrite($sPathSaveCookie, $g_SectionINI, "ID", $UserID[0])
		IniWrite($sPathSaveCookie, $g_SectionINI, "Timestamp", ___TimeStampNow())
	EndIf
	Return $aRet
EndFunc
 ;============================================
Func ___MyB64Encode($binaryData, $iLinebreak = 0)
	Local $aChr = StringSplit('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-', '', 2)
	Local $lenData = StringLen($binaryData) - 2, $iOdd = Mod($lenData, 3), $spDec = '', $base64Data = '', $iCounter = 0
	For $i = 3 To $lenData - $iOdd Step 3
		$spDec = Dec(StringMid($binaryData, $i, 3))
		$base64Data &= $aChr[$spDec / 64] & $aChr[Mod($spDec, 64)]
	Next
	If $iOdd Then
		$spDec = BitShift(Dec(StringMid($binaryData, $i, 3)), -8 / $iOdd)
		$base64Data &= $aChr[$spDec / 64] & ($iOdd = 2 ? $aChr[Mod($spDec, 64)] & '==' : '=')
	EndIf
	If $iLinebreak Then $base64Data = StringRegExpReplace($base64Data, '(.{' & $iLinebreak & '})', '${1}' & @LF) & @LF
	Return $base64Data
EndFunc
Func ___MyB64Decode($base64Data)
	$base64Data = StringStripWS($base64Data, 8)
	Local $sChr64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-'
	Local $aData = StringSplit($base64Data, ''), $binaryData = '0x', $iOdd = 0 * StringReplace($base64Data, '=', '') + @extended
	For $i = 1 To $aData[0] - $iOdd * 2 Step 2
		$binaryData &= Hex((StringInStr($sChr64, $aData[$i], 1, 1) - 1) * 64 + StringInStr($sChr64, $aData[$i + 1], 1, 1) - 1, 3)
	Next
	If $iOdd Then $binaryData &= Hex(BitShift((StringInStr($sChr64, $aData[$i], 1, 1) - 1) * 64 + ($iOdd - 1) * (StringInStr($sChr64, $aData[$i + 1], 1, 1) - 1), 8 / $iOdd), $iOdd)
	Return $binaryData
EndFunc
 ;============================================
Func ___TimeStampNow()
	Local $nYear = @YEAR - (@MON < 3 ? 1 : 0)
	Return (Int(Int($nYear / 100) / 4) - Int($nYear / 100) + @MDAY + Int(365.25 * ($nYear + 4716)) + Int(30.6 * ((@MON < 3 ? @MON + 12 : @MON) + 1)) - 2442110) * 86400 + (@HOUR * 3600 + @MIN * 60 + @SEC)
EndFunc