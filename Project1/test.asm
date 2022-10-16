TITLE Windows Application                   (WinApp.asm)

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

;函数引入，用于后面翻译键盘输入为字符码
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
TextOutA PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

PaintProc PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD

BLACK_BRUSH           EQU 4
SYSTEM_FIXED_FONT     EQU 16

WINDOW_WIDTH	EQU		640
WINDOW_HEIGHT	EQU		480

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

startText BYTE "start",0
helpText BYTE "help",0
exitText BYTE "exit",0

IDB_PNG1_PATH BYTE "..\Project1\image\black.jpg",0  ;暂时写成这样便于测试
IDB_PNG2_PATH BYTE "..\Project1\image\white.jpg",0
IDR_BG1_PATH BYTE "..\Project1\image\background.jpg",0

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
SelectMenu DWORD 0			; 正在选择的菜单项

;地图数组，20*15，0代表该格为空，1代表黑格，2代表白格
map		WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,1,1,1,2,2,2,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,1,1,1,2,2,2,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,1,1,1,2,2,2,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,1,1,1,2,2,2,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,1,1,1,2,2,2,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,1,1,1,2,2,2,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,0
		WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

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
	INVOKE CreateWindowEx, WS_EX_CLIENTEDGE, ADDR className,
	ADDR WindowName,WS_OVERLAPPEDWINDOW-WS_THICKFRAME-WS_MAXIMIZEBOX,100,100,
	WINDOW_WIDTH+20,WINDOW_HEIGHT+43,NULL,NULL,hInstance,NULL
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
		cmp eax,WM_PAINT
		je PaintMessage
		cmp eax,WM_TIMER
		je TimerMessage
		jmp OtherMessage			; other message?

	KeyDownMessage:
			mov eax,[localMsg+4] ;将按键的值转给eax

			cmp eax,38  ;识别向上方向键
			jne @nup1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov UpKeyHold,1
		@nup1:
			cmp eax,40  ;识别向下方向键
			jne @ndown1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov DownKeyHold,1
		@ndown1:
			cmp eax,37  ;识别向左方向键
			jne @nleft1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov LeftKeyHold,1
		@nleft1:
			cmp eax,39   ;识别向右方向键
			jne @nright1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov RightKeyHold,1
		@nright1:
			cmp eax,32  ;识别空格键
			jne @nspace1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov SpaceKeyHold,1
		@nspace1:
			cmp eax,13  ;识别enter键
			jne @nenter1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov EnterKeyHold,1
		@nenter1:
			cmp eax,27 ;识别esc键
			jne @nescape1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
		@nescape1: 
			cmp eax,65 ;识别a键
			jne @na1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov AKeyHold,1
		@na1:
			cmp eax,68 ;识别d键
			jne @nd1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov DKeyHold,1
		@nd1:
			cmp eax,83 ;识别s键
			jne @ns1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov SKeyHold,1
		@ns1:
			cmp eax,87 ;识别w键
			jne @nw1
			INVOKE MessageBox, hWnd, ADDR buttonText, ADDR buttonTitle, MB_OK  ;消息弹窗
			mov WKeyHold,1
		@nw1:		
			jmp WinProcExit

	KeyUpMessage:
			mov eax,[localMsg+4]  ;将按键的值转给eax
	
			cmp eax,38    ;识别向上方向键
			jne @nup2
			mov UpKeyHold,0
		@nup2:
			cmp eax,40   ;识别向下方向键
			jne @ndown2
			mov DownKeyHold,0
		@ndown2:
			cmp eax,37   ;识别向左方向键
			jne @nleft2
			mov LeftKeyHold,0
		@nleft2:
			cmp eax,39   ;识别向右方向键
			jne @nright2
			mov RightKeyHold,0
		@nright2:
			cmp eax,32   ;识别空格键
			jne @nspace2
			mov SpaceKeyHold,0
		@nspace2:
			cmp eax,13    ;识别enter键
			jne @nenter2
			mov EnterKeyHold,0
		@nenter2:
			cmp eax,65    ;识别a键
			jne @na2
			mov AKeyHold,0
		@na2:
			cmp eax,68   ;识别d键
			jne @nd2
			mov DKeyHold,0
		@nd2:
			cmp eax,83   ;识别s键
			jne @ns2
			mov SKeyHold,0
		@ns2:
			cmp eax,87   ;识别w键
			jne @nw2
			mov WKeyHold,0
		@nw2:
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

		invoke CreateCompatibleBitmap,hdc,WINDOW_WIDTH,WINDOW_HEIGHT
		mov hbitmap,eax

		invoke SelectObject,hdcMem,hbitmap

		invoke SetTextColor,hdcMem,00FFFFFFh

		invoke SetBkColor,hdcMem,0

		invoke ReleaseDC,hWnd,hdc

		jmp WinProcExit

	CloseWindowMessage:
		INVOKE PostQuitMessage,0

		invoke KillTimer,hWnd,1
		jmp WinProcExit

	PaintMessage:
		INVOKE PaintProc, hWnd, localMsg, wParam, lParam
		jmp WinProcExit

	TimerMessage:
	
		;call TimerTick

		;invoke RedrawWindow,hWnd,NULL,NULL,1

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

PaintProc PROC USES ecx eax ebx esi,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD

	local @ps: PAINTSTRUCT, @hdcMem: DWORD, @hdcMem2: DWORD; 创建两个句柄分别用来指向两张图（通常hdcmem是黑格，hdcmem2是白格）
	local whitePicBitmap: DWORD, blackPicBitmap: DWORD, bgPicBitmap: DWORD
	invoke  BeginPaint, hWnd, addr @ps
	mov hdc, eax

	.IF WhichMenu == 0
		invoke GetStockObject,BLACK_BRUSH
		
		invoke SelectObject,hdcMem,eax
		mov holdbr,eax
		
		invoke GetStockObject,SYSTEM_FIXED_FONT
		
		invoke SelectObject,hdcMem,eax
		mov holdft,eax

		invoke Rectangle,hdcMem,0,0,WINDOW_WIDTH,WINDOW_HEIGHT

		;invoke DrawLine,4,256,160,0Ch,0Dh,0Eh,0Fh

		;invoke DrawLine,4,256,192,2Ch,2Dh,0Eh,0Fh

		;jmp DrawMenuSelect
		
		invoke SelectObject,hdcMem,holdbr

		invoke SelectObject,hdcMem,holdft

		invoke BitBlt,hdc,0,0,WINDOW_WIDTH,WINDOW_HEIGHT,hdcMem,0,0,SRCCOPY

		INVOKE TextOutA,hdc,298,208,offset startText,5  ;640/2-22=298,480/2-12-20=208
		INVOKE TextOutA,hdc,298,228,offset helpText,4  ;640/2-22=298,480/2-12=228
		INVOKE TextOutA,hdc,298,248,offset exitText,4  ;640/2-22=298,480/2-12+20=228

	.ELSEIF WhichMenu == 2
		INVOKE CreateCompatibleDC, hdc
		mov @hdcMem, eax
		INVOKE CreateCompatibleDC, hdc
		mov @hdcMem2, eax 

		INVOKE LoadImageA, NULL, offset IDB_PNG1_PATH, 0, 32, 32, LR_LOADFROMFILE
		mov blackPicBitmap, eax
		INVOKE LoadImageA, NULL, offset IDB_PNG2_PATH, 0, 32, 32, LR_LOADFROMFILE
		mov whitePicBitmap, eax
		INVOKE LoadImageA, NULL, offset IDR_BG1_PATH, 0, WINDOW_WIDTH, WINDOW_HEIGHT, LR_LOADFROMFILE
		mov bgPicBitmap, eax

		INVOKE SelectObject, @hdcMem, bgPicBitmap
		INVOKE BitBlt, hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, @hdcMem, 0, 0, SRCCOPY  ; 这里借用了黑格的hdcmem用来显示背景（但没有影响）

		INVOKE SelectObject, @hdcMem, blackPicBitmap
		INVOKE SelectObject, @hdcMem2, whitePicBitmap

		mov	esi, offset map
		mov ecx, 15
	Lx: ;按行loop
		push ecx
		mov ecx, 20
	Ly: ;按列loop
		mov ax, [esi]
		.IF ax == 1
			mov eax, ecx  ;此时内层循环下标为20-eax，也即20-al(更高位都为0)
			sub ah, al
			mov al, ah
			mov ah, 0
			add al, 20
			sal ax, 5
			pop ebx
			push ebx  ;将外层循环的ecx给ebx
			sub bh, bl
			mov bl, bh
			mov bh, 0
			add bl, 15
			sal bx, 5
			push ecx
			INVOKE BitBlt, hdc, ax, bx, 31, 31, @hdcMem, 0, 0, SRCCOPY
			pop ecx
		.ELSEIF ax == 2
			mov eax, ecx  ;此时内层循环下标为20-eax，也即20-al(更高位都为0)
			sub ah, al
			mov al, ah
			mov ah, 0
			add al, 20
			sal ax, 5
			pop ebx
			push ebx  ;将外层循环的ecx给ebx
			sub bh, bl
			mov bl, bh
			mov bh, 0
			add bl, 15
			sal bx, 5
			push ecx
			INVOKE BitBlt, hdc, ax, bx, 31, 31, @hdcMem2, 0, 0, SRCCOPY
			pop ecx
		.ENDIF
		add esi, type map
		dec ecx
		cmp ecx, 0
		jne Ly
		pop ecx
		dec ecx
		cmp ecx, 0
		jne Lx

		invoke DeleteDC, @hdcMem
		invoke DeleteDC, @hdcMem2
	.ENDIF

	invoke EndPaint, hWnd, addr @ps
	ret
PaintProc ENDP

END WinMain