TITLE Windows Application	(WinApp.asm)

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

include const.inc

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
		mov UpKeyHold,1
	@nup1:
		cmp eax,40  ;识别向下方向键
		jne @ndown1
		mov DownKeyHold,1
	@ndown1:
		cmp eax,37  ;识别向左方向键
		jne @nleft1
		mov LeftKeyHold,1
	@nleft1:
		cmp eax,39   ;识别向右方向键
		jne @nright1
		mov RightKeyHold,1
	@nright1:
		cmp eax,32  ;识别空格键
		jne @nspace1
		mov SpaceKeyHold,1
	@nspace1:
		cmp eax,13  ;识别enter键
		jne @nenter1
		mov EnterKeyHold,1
	@nenter1:
		cmp eax,27 ;识别esc键
		jne @nescape1
	@nescape1: 
		cmp eax,65 ;识别a键
		jne @na1
		mov AKeyHold,1
	@na1:
		cmp eax,68 ;识别d键
		jne @nd1
		mov DKeyHold,1
	@nd1:
		cmp eax,83 ;识别s键
		jne @ns1
		mov SKeyHold,1
	@ns1:
		cmp eax,87 ;识别w键
		jne @nw1
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

CreateWindowMessage:
	mov eax,[localMsg-4]
	mov hWnd,eax

	invoke SetTimer,hWnd,1,100,NULL

	invoke GetDC,hWnd
	mov hdc,eax

	invoke LoadImageA,hInstance,1001,0,0,0,0
	mov hbitmap,eax

	invoke CreateCompatibleDC,hdc
	mov hdcMem,eax

	invoke CreateCompatibleBitmap,hdc,WINDOW_WIDTH,WINDOW_HEIGHT
	mov hbitmap,eax

	invoke SelectObject,hdcMem,hbitmap

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
	call TimerPROC
	invoke RedrawWindow,hWnd,NULL,NULL,1
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
	local font: DWORD

	invoke  BeginPaint, hWnd, addr ps
	mov hdc, eax

	.IF WhichMenu == 0 ;开始界面

		invoke GetStockObject,BLACK_BRUSH
		invoke SelectObject,hdcMem,eax
		mov holdbr,eax

		invoke Rectangle,hdcMem,0,0,WINDOW_WIDTH,WINDOW_HEIGHT
		invoke SelectObject,hdcMem,holdbr

		invoke BitBlt,hdc,0,0,WINDOW_WIDTH,WINDOW_HEIGHT,hdcMem,0,0,SRCCOPY

		INVOKE CreateFontA,50,0,0,0,700,1,0,0,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FF_DECORATIVE,NULL
		mov font, eax
		INVOKE SelectObject,hdc, eax

		INVOKE SetTextColor,hdc,00FFFFFFh
		INVOKE SetBkColor,hdc,0

		;根据选择菜单，分别绘制不同样式的菜单项
		.IF SelectMenu == 0
			INVOKE TextOutA,hdc,266,288,offset helpText,4  ;640/2-54=266
			INVOKE TextOutA,hdc,267,368,offset exitText,4  ;640/2-53=267
			INVOKE SetTextColor,hdc,0
			INVOKE SetBkColor,hdc,00FFFFFFh
			INVOKE TextOutA,hdc,253,208,offset startText,5  ;640/2-67=253
		.ELSEIF SelectMenu == 1
			INVOKE TextOutA,hdc,253,208,offset startText,5  ;640/2-67=253
			INVOKE TextOutA,hdc,267,368,offset exitText,4  ;640/2-53=267
			INVOKE SetTextColor,hdc,0
			INVOKE SetBkColor,hdc,00FFFFFFh
			INVOKE TextOutA,hdc,266,288,offset helpText,4  ;640/2-54=266
		.ELSEIF SelectMenu == 2
			INVOKE TextOutA,hdc,253,208,offset startText,5  ;640/2-67=253
			INVOKE TextOutA,hdc,266,288,offset helpText,4  ;640/2-54=266
			INVOKE SetTextColor,hdc,0
			INVOKE SetBkColor,hdc,00FFFFFFh
			INVOKE TextOutA,hdc,267,368,offset exitText,4  ;640/2-53=267
		.ENDIF

		INVOKE DeleteObject,font

	.ELSEIF WhichMenu == 1  ;游戏模式选择界面

		invoke GetStockObject,BLACK_BRUSH
		invoke SelectObject,hdcMem,eax
		mov holdbr,eax

		invoke Rectangle,hdcMem,0,0,WINDOW_WIDTH,WINDOW_HEIGHT
		invoke SelectObject,hdcMem,holdbr

		invoke BitBlt,hdc,0,0,WINDOW_WIDTH,WINDOW_HEIGHT,hdcMem,0,0,SRCCOPY

		INVOKE CreateFontA,50,0,0,0,700,1,0,0,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FF_DECORATIVE,NULL
		mov font, eax
		INVOKE SelectObject,hdc, eax

		INVOKE SetTextColor,hdc,00FFFFFFh
		INVOKE SetBkColor,hdc,0

		;根据选择菜单，分别绘制不同样式的菜单项
		.IF SelectMenu == 0
			INVOKE TextOutA,hdc,240,368,offset BackText,6  ;640/2-80=240
			INVOKE SetTextColor,hdc,0
			INVOKE SetBkColor,hdc,00FFFFFFh
			INVOKE TextOutA,hdc,251,208,offset PVPText,5  ;640/2-69=251
		.ELSEIF SelectMenu == 1
			INVOKE TextOutA,hdc,251,208,offset PVPText,5  ;640/2-69=251
			INVOKE SetTextColor,hdc,0
			INVOKE SetBkColor,hdc,00FFFFFFh
			INVOKE TextOutA,hdc,240,368,offset BackText,6  ;640/2-80=240
		.ENDIF

		INVOKE DeleteObject,font

	.ELSEIF WhichMenu == 2                    ;游戏界面
		INVOKE CreateCompatibleDC, hdc
		mov hdcMem, eax
		INVOKE CreateCompatibleDC, hdc
		mov hdcMem2, eax 

		INVOKE LoadImageA, NULL, offset IDB_PNG1_PATH, 0, 32, 32, LR_LOADFROMFILE
		mov blackPicBitmap, eax
		INVOKE LoadImageA, NULL, offset IDB_PNG2_PATH, 0, 32, 32, LR_LOADFROMFILE
		mov whitePicBitmap, eax
		INVOKE LoadImageA, NULL, offset IDR_BG1_PATH, 0, WINDOW_WIDTH, WINDOW_HEIGHT, LR_LOADFROMFILE
		mov bgPicBitmap, eax

		INVOKE SelectObject, hdcMem, bgPicBitmap
		INVOKE BitBlt, hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMem, 0, 0, SRCCOPY  ; 这里借用了黑格的hdcmem用来显示背景（但没有影响）

		INVOKE SelectObject, hdcMem, blackPicBitmap
		INVOKE SelectObject, hdcMem2, whitePicBitmap

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
			INVOKE BitBlt, hdc, ax, bx, 31, 31, hdcMem, 0, 0, SRCCOPY
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
			INVOKE BitBlt, hdc, ax, bx, 31, 31, hdcMem2, 0, 0, SRCCOPY
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

		INVOKE BitBlt, hdc, [blackblock], [blackblock+2], [blackblock+4], [blackblock+4], hdcMem, 0, 0, SRCCOPY
		INVOKE BitBlt, hdc, [whiteblock], [whiteblock+2], [whiteblock+4], [whiteblock+4], hdcMem2, 0, 0, SRCCOPY

		invoke DeleteDC, hdcMem
		invoke DeleteDC, hdcMem2
	.ELSEIF WhichMenu == 3   ;结束界面
	.ELSEIF WhichMenu == 4   ;帮助界面
		INVOKE CreateCompatibleDC, hdc
		mov hdcMem, eax

		INVOKE LoadImageA, NULL, offset IDR_HELP_PATH, 0, 640, 384, LR_LOADFROMFILE
		mov helpPicBitmap, eax

		INVOKE SelectObject, hdcMem, helpPicBitmap
		INVOKE BitBlt, hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMem, 0, 0, SRCCOPY
	.ENDIF

	invoke EndPaint, hWnd, addr ps
	ret
PaintProc ENDP

TimerPROC PROC

	.IF WhichMenu == 0   ;开始界面
		.IF UpKeyHold == 1
			.IF SelectMenu > 0
				dec SelectMenu
			.ENDIF
		.ENDIF
		.IF DownKeyHold == 1
			.IF SelectMenu < 2
				inc SelectMenu
			.ENDIF
		.ENDIF
		.IF EnterKeyHold == 1
			.IF SelectMenu == 0
				inc WhichMenu
				jmp TimerTickReturn
			.ELSEIF SelectMenu == 1
				mov WhichMenu,4
				jmp TimerTickReturn
			.ELSE
				INVOKE ExitProcess,0
			.ENDIF
		.ENDIF
	.ELSEIF WhichMenu == 1  ;游戏模式选择界面
		.IF UpKeyHold == 1
			.IF SelectMenu > 0
				dec SelectMenu
			.ENDIF
		.ENDIF
		.IF DownKeyHold == 1
			.IF SelectMenu < 1
				inc SelectMenu
			.ENDIF
		.ENDIF
		.IF EnterKeyHold == 1
			.IF SelectMenu == 0
				inc WhichMenu
				jmp TimerTickReturn
			.ELSEIF SelectMenu == 1
				dec WhichMenu
				dec SelectMenu
				jmp TimerTickReturn
			.ENDIF
		.ENDIF
	.ELSEIF WhichMenu == 4   ;帮助界面
		.IF EnterKeyHold == 1
			mov WhichMenu,0
			jmp TimerTickReturn
		.ENDIF
	.ELSEIF WhichMenu == 2

			cmp UpKeyHold,1
			jne TT@1
			sub [whiteblock+2],2

		TT@1:
			cmp DownKeyHold,1
			jne TT@2
			add [whiteblock+2],2
		
		TT@2:
			cmp LeftKeyHold,1
			jne TT@3
			sub [whiteblock],2
		
		TT@3:
			cmp RightKeyHold,1
			jne TT@4
			add [whiteblock],2
		
		TT@4:
			cmp EnterKeyHold,1
			jne TT@5

		TT@5:
			cmp WKeyHold,1
			jne TT@6
			sub [blackblock+2],2
		
		TT@6:
			cmp SKeyHold,1
			jne TT@7
			add [blackblock+2],2

		TT@7:
			cmp AKeyHold,1
			jne TT@8
			sub [blackblock],2

		TT@8:
			cmp DKeyHold,1
			jne TT@9
			add [blackblock],2
		
		TT@9:
			cmp SpaceKeyHold,1
			jne TimerTickReturn

	.ENDIF

TimerTickReturn:
	ret

TimerPROC ENDP

END WinMain