TITLE Windows Application                   (WinApp.asm)

; This program displays a resizable application window and
; several popup message boxes.
; Thanks to Tom Joyce for creating a prototype
; from which this program was derived.
; Last update: 9/24/01
.386
.model flat, stdcall
option casemap: none

include windows.inc
include gdi32.inc
includelib gdi32.lib
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include masm32.inc
includelib masm32.lib
include msvcrt.inc
includelib msvcrt.lib
include shell32.inc
includelib shell32.lib

WNDCLASS STRUC
	style DWORD ?
	lpfnWndProc DWORD ?
	cbClsExtra DWORD ?
	cbWndExtra DWORD ?
	hInstance DWORD ?
	hIcon DWORD ?
	hCursor DWORD ?
	hbrBackground DWORD ?
	lpszMenuName DWORD ?
	lpszClassName DWORD ?
WNDCLASS ENDS

MSGStruct STRUCT
	msgWnd DWORD ?
	msgMessage DWORD ?
	msgWparam DWORD ?
	msgLparam DWORD ?
	msgTime DWORD ?
	msgPt POINT <>
MSGStruct ENDS

MAIN_WINDOW_STYLE = WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU \
+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME

;函数引入，用于后面翻译键盘输入为字符�?
TranslateMessage PROTO STDCALL :DWORD
SetTimer PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
KillTimer PROTO STDCALL :DWORD,:DWORD

GetDC PROTO STDCALL :DWORD
GetStockObject PROTO STDCALL :DWORD
ReleaseDC PROTO STDCALL :DWORD,:DWORD
LoadImageA PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
BeginPaint PROTO STDCALL :DWORD,:DWORD
EndPaint PROTO STDCALL :DWORD,:DWORD

CreateCompatibleDC PROTO STDCALL: DWORD
CreateCompatibleBitmap PROTO STDCALL :DWORD,:DWORD,:DWORD
SelectObject PROTO STDCALL :DWORD,:DWORD
BitBlt PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SetBkColor PROTO STDCALL :DWORD,:DWORD
Rectangle PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

SRCCOPY		EQU		000cc0020h
BLACK_BRUSH           EQU 4
SYSTEM_FIXED_FONT     EQU 16


;固定参数，用于后面识别键盘按下与抬起
WM_PAINT		EQU		00000000fh
WM_KEYDOWN		EQU		000000100h
WM_KEYUP		EQU		000000101h

;==================== DATA =======================
.data

AppLoadMsgTitle BYTE "Application Loaded",0
AppLoadMsgText  BYTE "This window displays when the WM_CREATE "
	            BYTE "message is received",0

PopupTitle BYTE "Popup Window",0
PopupText  BYTE "This window was activated by a "
	       BYTE "WM_LBUTTONDOWN message",0

GreetTitle BYTE "Main Window Active",0
GreetText  BYTE "This window is shown immediately after "
	       BYTE "CreateWindow and UpdateWindow are called.",0

buttonTitle BYTE "push keyboard Window",0
buttonText  BYTE "This window was activated by a"
	       BYTE "WM_KEYDOWN message.",0

CloseMsg   BYTE "WM_CLOSE message received",0

ErrorTitle  BYTE "Error",0

; 
WindowName  BYTE "ASM Windows App",0
className   BYTE "ASMWin",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?

hbitmap DWORD ?
hdcMem DWORD ?
hdcPic DWORD ?
hdc DWORD ?
holdbr DWORD ?
holdft DWORD ?
ps PAINTSTRUCT <>

WhichMenu DWORD 0			; 哪个界面，0表示开始，1表示选择游戏模式，2表示正在游戏，3表示游戏结束

; 按键是否按下的指示变量
UpKeyHold DWORD 0 
DownKeyHold DWORD 0
LeftKeyHold DWORD 0
RightKeyHold DWORD 0
WKeyHold DWORD 0
SKeyHold DWORD 0
AKeyHold DWORD 0
DKeyHold DWORD 0
SpaceKeyHold DWORD 0
EnterKeyHold DWORD 0

;=================== CODE =========================
.code
WinMain PROC
	; Get a handle to the current process.
		INVOKE GetModuleHandle, NULL
		mov hInstance, eax
		mov MainWin.hInstance, eax

	; Load the program's icon and cursor.
		INVOKE LoadIcon, NULL, IDI_APPLICATION
		mov MainWin.hIcon, eax
		INVOKE LoadCursor, NULL, IDC_ARROW
		mov MainWin.hCursor, eax

	; Register the window class.
		INVOKE RegisterClass, ADDR MainWin
		.IF eax == 0
		call ErrorHandler
		jmp Exit_Program
		.ENDIF

	; Create the application's main window.
	; Returns a handle to the main window in EAX.
		INVOKE CreateWindowEx, 0, ADDR className,
		ADDR WindowName,MAIN_WINDOW_STYLE,
		CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
		CW_USEDEFAULT,NULL,NULL,hInstance,NULL
		mov hMainWnd,eax

	; If CreateWindowEx failed, display a message & exit.
		.IF eax == 0
		call ErrorHandler
		jmp  Exit_Program
		.ENDIF

	; Show and draw the window.
		INVOKE ShowWindow, hMainWnd, SW_SHOW
		INVOKE UpdateWindow, hMainWnd

	; Display a greeting message.
	;INVOKE MessageBox, hMainWnd, ADDR GreetText,ADDR GreetTitle, MB_OK

	; Begin the program's message-handling loop.
	Message_Loop:
		; Get next message from the queue.
		INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

		; Quit if no more messages.
		.IF eax == 0
		jmp Exit_Program
		.ENDIF

		;翻译键盘消息，把键盘消息转化成字符码
		INVOKE TranslateMessage, ADDR msg
		; Relay the message to the program's WinProc.
		INVOKE DispatchMessage, ADDR msg
		jmp Message_Loop

	Exit_Program:
		INVOKE ExitProcess,0
WinMain ENDP

;-----------------------------------------------------
WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
	; The application's message handler, which handles
	; application-specific messages. All other messages
	; are forwarded to the default Windows message
	; handler.
	;-----------------------------------------------------
		mov eax, localMsg
		
		;判断是否为键盘按下操作
		cmp eax,WM_KEYDOWN
		je KeyDownMessage
		;检查按下的键盘是否抬起，抬起则恢复
		cmp eax,WM_KEYUP
		je KeyUpMessage
		cmp eax,WM_LBUTTONDOWN		; mouse button?
		je Lmousedown
		cmp eax,WM_CREATE			; create window?
		je CreateWindowMessage	  
		cmp eax,WM_CLOSE		 ; close window?
		je CloseWindowMessage
		; 参照坦克大战部分画图测试
		cmp eax,WM_PAINT
		je PaintMessage
		jmp OtherMessage			; other message?

	KeyDownMessage:
		mov eax,[localMsg+4] ;将按键的值转给eax

		cmp eax,32         ;识别空格键
		jne WinProcExit
		mov UpKeyHold,1   ;设置标识
		INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
		jmp WinProcExit

	KeyUpMessage:
		mov eax,[localMsg+4]  ;将按键的值转给eax
 
		cmp eax,32          ;识别空格键
		jne WinProcExit 
		mov UpKeyHold,0  ;取消标识
		jmp WinProcExit

	Lmousedown:
		INVOKE MessageBox, hWnd, ADDR PopupText, ADDR PopupTitle, MB_OK
		jmp WinProcExit

	CreateWindowMessage:
		mov eax,[localMsg-4]
		mov hWnd,eax

		invoke SetTimer,hWnd,1,30,NULL

		invoke GetDC,hWnd
		mov hdc,eax

		invoke CreateCompatibleDC,eax
		mov hdcPic,eax

		invoke LoadImageA,hInstance,1001,0,0,0,0
		mov hbitmap,eax

		invoke SelectObject,hdcPic,hbitmap

		invoke CreateCompatibleDC,hdc
		mov hdcMem,eax

		invoke CreateCompatibleBitmap,hdc,640,480
		mov hbitmap,eax

		invoke SelectObject,hdcMem,hbitmap

		invoke SetTextColor,hdcMem,0

		invoke SetBkColor,hdcMem,0

		invoke ReleaseDC,hWnd,hdc

		jmp WinProcExit

	CloseWindowMessage:
		INVOKE PostQuitMessage,0

		invoke KillTimer,hWnd,1
		jmp WinProcExit

	PaintMessage:
		invoke BeginPaint,hWnd,offset ps
		mov hdc,eax

		invoke GetStockObject,BLACK_BRUSH
		
		invoke SelectObject,hdcMem,eax
		mov holdbr,eax
		
		invoke GetStockObject,SYSTEM_FIXED_FONT
		
		invoke SelectObject,hdcMem,eax
		mov holdft,eax

		invoke Rectangle,hdcMem,0,0,640,480

		call DrawUI
		
		invoke SelectObject,hdcMem,holdbr

		invoke SelectObject,hdcMem,holdft

		invoke BitBlt,hdc,0,0,640,480,hdcMem,0,0,SRCCOPY
		
		invoke EndPaint,hWnd,offset ps

		jmp WinProcExit

	OtherMessage:
		INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
		jmp WinProcExit

	WinProcExit:
		ret
WinProc ENDP

;---------------------------------------------------
ErrorHandler PROC
	; Display the appropriate system error message.
	;---------------------------------------------------
	.data
	pErrorMsg  DWORD ?		; ptr to error message
	messageID  DWORD ?
	.code
		INVOKE GetLastError	; Returns message ID in EAX
		mov messageID,eax

		; Get the corresponding message string.
		INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
		FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
		ADDR pErrorMsg,NULL,NULL

		; Display the error message.
		INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
		MB_ICONERROR+MB_OK

		; Free the error message string.
		INVOKE LocalFree, pErrorMsg
		ret
ErrorHandler ENDP

END WinMain