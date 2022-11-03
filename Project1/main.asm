TITLE Windows Application	(WinApp.asm)

.386
.model flat, stdcall
option casemap: none

; 系统库
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
include	 winmm.inc
includelib  winmm.lib

; 自定义库
include const.inc

;=================== CODE =========================
.code
WinMain PROC
	; Get a handle to the current process.
		INVOKE GetModuleHandle, NULL
		mov hInstance, eax
		mov MainWin.hInstance, eax

	; Load the program's icon and cursor.
		INVOKE LoadIcon, hInstance, 115
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
		cmp eax,WM_CREATE		; create window?
		je CreateWindowMessage	  
		cmp eax,WM_CLOSE		 ; close window?
		je CloseWindowMessage
		cmp eax,WM_PAINT       ; 绘图消息
		je PaintMessage
		cmp eax,WM_TIMER      ; 定时器消息
		je TimerMessage
		jmp OtherMessage		 ; other message?

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
			.IF WhichMenu == 2   ;在游戏界面设置了按键判断标志，如果长按那么只会标记1次按键，保障按一次发射一个子弹
				mov eax,attack_black  
				mul SpaceKeyHold
				mov SpaceKeyHold,eax
				mov eax,0
				mov attack_black,eax
			.ENDIF
		@nspace1:
			cmp eax,13  ;识别enter键
			jne @nenter1
			mov EnterKeyHold,1
			.IF WhichMenu == 2  ;在游戏界面设置了按键判断标志，如果长按那么只会标记1次按键，保障按一次发射一个子弹
				mov eax,attack_white
				mul EnterKeyHold
				mov EnterKeyHold,eax
				mov eax,0
				mov attack_white,eax
			.ENDIF
		@nenter1:
			cmp eax,27 ;识别esc键
			jne @nescape1
			call EscapeKeyDown
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
			.IF WhichMenu != 2
				call chooseMenu
			.ENDIF
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
			mov eax,1
			mov attack_black,eax
			mov SpaceKeyHold,0
		@nspace2:
			cmp eax,13    ;识别enter键
			jne @nenter2
			mov eax,1
			mov attack_white,eax
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

		; 开始定时器 30ms发一次定时器消息
		invoke SetTimer,hWnd,1,30,NULL

		; 获取当前程序窗口DC句柄
		invoke GetDC,hWnd
		mov hdc,eax

		; 创建并设置字体
		INVOKE CreateFontA,50,0,0,0,700,1,0,0,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FF_DECORATIVE,NULL
		mov font_50, eax
		INVOKE CreateFontA,40,0,0,0,700,1,0,0,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FF_DECORATIVE,NULL
		mov font_40, eax
		INVOKE CreateFontA,20,0,0,0,700,1,0,0,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FF_DECORATIVE,NULL
		mov font_20, eax

		; 绘制基础的黑色显示句柄、白色显示句柄、背景色显示句柄、帮助界面显示句柄
		call DrawBasicPic

		; 接下来的部分主要是显示几个提供选择的关卡图片
		INVOKE CreateCompatibleDC, hdc
		mov hdcMemMap1, eax
		INVOKE CreateCompatibleDC, hdc
		mov hdcMemMap2, eax
		INVOKE CreateCompatibleDC, hdc
		mov hdcMemMap3, eax

		; 主要图片存储进句柄
		INVOKE LoadImageA, hInstance,118,0,160,120,0
		INVOKE SelectObject, hdcMemMap1, eax
		INVOKE LoadImageA, hInstance,119,0,160,120,0
		INVOKE SelectObject, hdcMemMap2, eax
		INVOKE LoadImageA, hInstance,120,0,160,120,0
		INVOKE SelectObject, hdcMemMap3, eax

		; 释放当前窗口DC
		invoke ReleaseDC,hWnd,hdc

		jmp WinProcExit

	CloseWindowMessage:
		; 关闭信息接受
		INVOKE PostQuitMessage,0

		INVOKE DeleteObject,font_50
		INVOKE DeleteObject,font_40
		INVOKE DeleteObject,font_20

		INVOKE DeleteObject,hdcMempage

		mov ecx,20
	L1:
		push ecx
		INVOKE DeleteObject,[hdcMemColors+ecx*4-4]
		pop ecx
		loop L1

		INVOKE DeleteObject,hdcMemhelp

		INVOKE DeleteObject,hdcMemMap1
		INVOKE DeleteObject,hdcMemMap2
		INVOKE DeleteObject,hdcMemMap3

		; 关闭定时器
		invoke KillTimer,hWnd,1
		jmp WinProcExit

	PaintMessage:
		; 直接调用绘图函数
		INVOKE PaintProc, hWnd, localMsg, wParam, lParam
		jmp WinProcExit

	TimerMessage:
		; 直接调用定时器处理函数
		call TimerPROC
		; 每次接收到定时器信号后都进行重绘
		invoke RedrawWindow,hWnd,NULL,NULL,1
		jmp WinProcExit

	OtherMessage:
		INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
		jmp WinProcExit

	WinProcExit:
		ret
WinProc ENDP

EscapeKeyDown PROC
	.IF WhichMenu == 2
		.IF statusFlag == 0
			mov statusFlag, 3  ; 如果游戏处于正常对战中状态，将状态标志位修改为3，即暂停
		.ELSEIF statusFlag == 3
			mov statusFlag, 0  ; 若已经处于暂停状态，将状态恢复。
		.ENDIF
	.ELSEIF WhichMenu != 3     ; 对于除游戏中界面、游戏胜利界面之外的界面，将界面跳转回主界面
		mov WhichMenu, 0
		mov SelectMenu, 0
	.ENDIF
	ret
EscapeKeyDown ENDP

NewRound PROC  ; 进入游戏实现自动初始化
	initblock: ; 初始化黑白块初始位置
		mov ax,[black_initpos]
		mov [blackblock],ax

		mov ax,[black_initpos+2]
		mov [blackblock+2],ax

		mov [blackblock+6],1

		mov [blackblock+8],4

		mov [blackblock+10],0

		mov ax,[white_initpos]
		mov [whiteblock],ax

		mov ax,[white_initpos+2]
		mov [whiteblock+2],ax

		mov [whiteblock+6],1

		mov [whiteblock+8],4

		mov [whiteblock+10],0

	initstatusFlag: ; 还原无胜利标志
		mov statusFlag,0	

		mov ecx,300
	SetMap:  ; 用循环拷贝地图，保障原始地图可以一直使用
		.IF edx == 0
			mov ax,[roundone_map+ecx*2-2]
		.ELSEIF edx == 1
			mov ax,[roundtwo_map+ecx*2-2]
		.ELSEIF edx == 2
			mov ax,[roundthree_map+ecx*2-2]
		.ENDIF
		mov [map+ecx*2-2],ax
		loop SetMap

		ret
NewRound ENDP

chooseMenu PROC  ; 选择菜单函数
	.IF WhichMenu == 0   ;开始界面
		.IF eax == 38 || eax == 87   ; 识别向上按键和w
			.IF SelectMenu > 0
				dec SelectMenu  
				ret
			.ENDIF
		.ENDIF
		.IF eax == 40 || eax == 83  ; 识别向下按键和s
			.IF SelectMenu < 3
				inc SelectMenu
				ret
			.ENDIF
		.ENDIF
		.IF eax == 13 || eax == 32  ; 确认键为enter和space 
			.IF SelectMenu == 0
				mov WhichMenu,1
				ret
			.ELSEIF SelectMenu == 1
				;INVOKE ShellExecuteA, 
				mov WhichMenu,4
				ret
			.ELSEIF SelectMenu == 2
				mov WhichMenu,6
				mov SelectMenu,0
				mov SelectMenu2,1
				mov SelectMenu3,2
				ret
			.ELSE
				INVOKE ExitProcess,0
			.ENDIF
		.ENDIF
	.ELSEIF WhichMenu == 1  ;游戏模式选择界面
		.IF eax == 38 || eax == 87   ; 识别向上按键和w
			.IF SelectMenu > 0
				dec SelectMenu
				ret
			.ENDIF
		.ENDIF
		.IF eax == 40 || eax == 83  ; 识别向下按键和s
			.IF SelectMenu < 1
				inc SelectMenu
				ret
			.ENDIF
		.ENDIF
		.IF eax == 13 || eax == 32  ; 确认键为enter和space 
			.IF SelectMenu == 0
				mov EnterKeyHold,0
				mov SpaceKeyHold,0
				mov WhichMenu,5
				mov SelectMenu,0
				ret
			.ELSEIF SelectMenu == 1
				mov WhichMenu,0
				mov SelectMenu,0
				ret
			.ENDIF
		.ENDIF
	.ELSEIF WhichMenu == 3   ;帮助界面
		.IF eax == 82 ; 确认键为r
			mov WhichMenu,1
			ret
		.ENDIF
	.ELSEIF WhichMenu == 4   ;帮助界面
		.IF eax == 13 || eax == 32  ; 确认键为enter和space 
			mov WhichMenu,0
			ret
		.ENDIF
	.ELSEIF WhichMenu == 5   ;选关界面
		.IF eax == 38 || eax == 87   ; 识别向上按键和w
			.IF SelectMenu > 0
				dec SelectMenu  
				ret
			.ENDIF
		.ENDIF
		.IF eax == 40 || eax == 83  ; 识别向下按键和s
			.IF SelectMenu < 2
				inc SelectMenu
				ret
			.ENDIF
		.ENDIF
		.IF eax == 13 || eax == 32  ; 确认键为enter和space
			mov EnterKeyHold,0
			mov SpaceKeyHold,0
			mov WhichMenu,2
			mov edx,SelectMenu
			call NewRound    ; 每次进入游戏都会初始化游戏页面以及数据
			mov SelectMenu,0
			ret
		.ENDIF
	.ELSEIF WhichMenu == 6   ;自定义界面

		; 控制p1选择光标
		.IF eax == 87   ; 识别w按键
			sub SelectMenu,5
			mov edx,SelectMenu
			.IF edx == SelectMenu2 || edx == SelectMenu3
				sub SelectMenu,5
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					sub SelectMenu,5
				.ENDIF
			.ENDIF
			.IF SelectMenu < 0
				add SelectMenu,20
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					sub SelectMenu,5
					mov edx,SelectMenu
					.IF edx == SelectMenu2 || edx == SelectMenu3
						sub SelectMenu,5
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 83  ; 识别s按键
			add SelectMenu,5
			mov edx,SelectMenu
			.IF edx == SelectMenu2 || edx == SelectMenu3
				add SelectMenu,5
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					add SelectMenu,5
				.ENDIF
			.ENDIF
			.IF SelectMenu > 19
				sub SelectMenu,20
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					add SelectMenu,5
					mov edx,SelectMenu
					.IF edx == SelectMenu2 || edx == SelectMenu3
						add SelectMenu,5
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 65   ; 识别a按键
			sub SelectMenu,1
			mov edx,SelectMenu
			.IF edx == SelectMenu2 || edx == SelectMenu3
				sub SelectMenu,1
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					sub SelectMenu,1
				.ENDIF
			.ENDIF
			.IF SelectMenu == -1 || SelectMenu == 4 || SelectMenu == 9 || SelectMenu == 14
				add SelectMenu,5
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					sub SelectMenu,1
					mov edx,SelectMenu
					.IF edx == SelectMenu2 || edx == SelectMenu3
						sub SelectMenu,1
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 68  ; 识别d按键
			add SelectMenu,1
			mov edx,SelectMenu
			.IF edx == SelectMenu2 || edx == SelectMenu3
				add SelectMenu,1
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					add SelectMenu,1
				.ENDIF
			.ENDIF
			.IF SelectMenu == 5 || SelectMenu == 10 || SelectMenu == 15 || SelectMenu == 20
				sub SelectMenu,5
				mov edx,SelectMenu
				.IF edx == SelectMenu2 || edx == SelectMenu3
					add SelectMenu,1
					mov edx,SelectMenu
					.IF edx == SelectMenu2 || edx == SelectMenu3
						add SelectMenu,1
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF

		; 控制p2选择光标
		.IF eax == 38   ; 识别向上按键
			sub SelectMenu2,5
			mov edx,SelectMenu2
			.IF edx == SelectMenu || edx == SelectMenu3
				sub SelectMenu2,5
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					sub SelectMenu2,5
				.ENDIF
			.ENDIF
			.IF SelectMenu2 < 0
				add SelectMenu2,20
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					sub SelectMenu2,5
					mov edx,SelectMenu2
					.IF edx == SelectMenu || edx == SelectMenu3
						sub SelectMenu2,5
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 40  ; 识别向下按键
			add SelectMenu2,5
			mov edx,SelectMenu2
			.IF edx == SelectMenu || edx == SelectMenu3
				add SelectMenu2,5
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					add SelectMenu2,5
				.ENDIF
			.ENDIF
			.IF SelectMenu2 > 19
				sub SelectMenu2,20
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					add SelectMenu2,5
					mov edx,SelectMenu2
					.IF edx == SelectMenu || edx == SelectMenu3
						add SelectMenu2,5
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 37   ; 识别向左按键
			sub SelectMenu2,1
			mov edx,SelectMenu2
			.IF edx == SelectMenu || edx == SelectMenu3
				sub SelectMenu2,1
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					sub SelectMenu2,1
				.ENDIF
			.ENDIF
			.IF SelectMenu2 == -1 || SelectMenu2 == 4 || SelectMenu2 == 9 || SelectMenu2 == 14
				add SelectMenu2,5
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					sub SelectMenu2,1
					mov edx,SelectMenu2
					.IF edx == SelectMenu || edx == SelectMenu3
						sub SelectMenu2,1
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 39  ; 识别向右按键
			add SelectMenu2,1
			mov edx,SelectMenu2
			.IF edx == SelectMenu || edx == SelectMenu3
				add SelectMenu2,1
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					add SelectMenu2,1
				.ENDIF
			.ENDIF
			.IF SelectMenu2 == 5 || SelectMenu2 == 10 || SelectMenu2 == 15 || SelectMenu2 == 20
				sub SelectMenu2,5
				mov edx,SelectMenu2
				.IF edx == SelectMenu || edx == SelectMenu3
					add SelectMenu2,1
					mov edx,SelectMenu2
					.IF edx == SelectMenu || edx == SelectMenu3
						add SelectMenu2,1
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF

		; 控制背景选择光标
		.IF eax == 73   ; 识别i按键
			sub SelectMenu3,5
			mov edx,SelectMenu3
			.IF edx == SelectMenu || edx == SelectMenu2
				sub SelectMenu3,5
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					sub SelectMenu3,5
				.ENDIF
			.ENDIF
			.IF SelectMenu3 < 0
				add SelectMenu3,20
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					sub SelectMenu3,5
					mov edx,SelectMenu3
					.IF edx == SelectMenu || edx == SelectMenu2
						sub SelectMenu3,5
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 75  ; 识别k按键
			add SelectMenu3,5
			mov edx,SelectMenu3
			.IF edx == SelectMenu || edx == SelectMenu2
				add SelectMenu3,5
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					add SelectMenu3,5
				.ENDIF
			.ENDIF
			.IF SelectMenu3 > 19
				sub SelectMenu3,20
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					add SelectMenu3,5
					mov edx,SelectMenu3
					.IF edx == SelectMenu || edx == SelectMenu2
						add SelectMenu3,5
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 74   ; 识别j按键
			sub SelectMenu3,1
			mov edx,SelectMenu3
			.IF edx == SelectMenu || edx == SelectMenu2
				sub SelectMenu3,1
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					sub SelectMenu3,1
				.ENDIF
			.ENDIF
			.IF SelectMenu3 == -1 || SelectMenu3 == 4 || SelectMenu3 == 9 || SelectMenu3 == 14
				add SelectMenu3,5
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					sub SelectMenu3,1
					mov edx,SelectMenu3
					.IF edx == SelectMenu || edx == SelectMenu2
						sub SelectMenu3,1
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF
		.IF eax == 76  ; 识别l按键
			add SelectMenu3,1
			mov edx,SelectMenu3
			.IF edx == SelectMenu || edx == SelectMenu2
				add SelectMenu3,1
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					add SelectMenu3,1
				.ENDIF
			.ENDIF
			.IF SelectMenu3 == 5 || SelectMenu3 == 10 || SelectMenu3 == 15 || SelectMenu3 == 20
				sub SelectMenu3,5
				mov edx,SelectMenu3
				.IF edx == SelectMenu || edx == SelectMenu2
					add SelectMenu3,1
					mov edx,SelectMenu3
					.IF edx == SelectMenu || edx == SelectMenu2
						add SelectMenu3,1
					.ENDIF
				.ENDIF
			.ENDIF
			ret
		.ENDIF

		; 确认
		.IF eax == 13 || eax == 32  ; 确认键为enter和space
			mov EnterKeyHold,0
			mov SpaceKeyHold,0
			mov WhichMenu,0

			; 将不同颜色的句柄直接赋给三个显示用的hdcMem
			mov edx, SelectMenu
			mov eax, [hdcMemColors+edx*4]
			mov hdcMemblack, eax
			mov edx, SelectMenu2
			mov eax, [hdcMemColors+edx*4]
			mov hdcMemwhite, eax
			mov edx, SelectMenu3
			mov eax, [hdcMemColors+edx*4]
			mov hdcMembg, eax

			mov SelectMenu,0
			ret
		.ENDIF
	.ENDIF
	ret
chooseMenu ENDP

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

DrawBasicPic PROC USES ebx
	; 布局页面的句柄以及其显示的句柄创建设置
	invoke CreateCompatibleDC,hdc
	mov hdcMempage,eax
	invoke CreateCompatibleBitmap,hdc,WINDOW_WIDTH,WINDOW_HEIGHT
	invoke SelectObject,hdcMempage,eax
	
	; 绘制20种颜色并存在hdcMemColors
	mov ecx,20
L1:
	push ecx
	mov ebx,ecx
	INVOKE CreateCompatibleDC, hdc
	mov [hdcMemColors+ebx*4-4], eax
	invoke CreateCompatibleBitmap,hdcMempage,WINDOW_WIDTH,WINDOW_HEIGHT
	invoke SelectObject,[hdcMemColors+ebx*4-4],eax
	invoke CreateSolidBrush, [Colors+ebx*4-4]
	invoke SelectObject, [hdcMemColors+ebx*4-4], eax
	INVOKE Rectangle,[hdcMemColors+ebx*4-4],-1,-1,1000,1000
	pop ecx
	loop L1

	; 将不同颜色的句柄直接赋给三个显示用的hdcMem
	mov eax, [hdcMemColors]
	mov hdcMemblack, eax
	mov eax, [hdcMemColors+4]
	mov hdcMemwhite, eax
	mov eax, [hdcMemColors+8]
	mov hdcMembg, eax
	
	; 绘制帮助文档并存在hdcmemhelp
	INVOKE CreateCompatibleDC, hdc
	mov hdcMemhelp, eax
	invoke CreateCompatibleBitmap,hdcMempage,WINDOW_WIDTH,WINDOW_HEIGHT
	invoke SelectObject,hdcMemhelp,eax

	invoke CreateSolidBrush, 02BA245h
	invoke SelectObject, hdcMemhelp, eax
	INVOKE Rectangle,hdcMemhelp,331,260,360,290  ; w
	INVOKE Rectangle,hdcMemhelp,300,290,330,320  ; a
	INVOKE Rectangle,hdcMemhelp,331,290,360,320  ; s
	INVOKE Rectangle,hdcMemhelp,361,290,390,320  ; d
	INVOKE Rectangle,hdcMemhelp,485,275,555,305  ; space
	INVOKE Rectangle,hdcMemhelp,341,320,400,350  ; 上
	INVOKE Rectangle,hdcMemhelp,300,350,340,380  ; 下
	INVOKE Rectangle,hdcMemhelp,341,350,400,380  ; 左
	INVOKE Rectangle,hdcMemhelp,401,350,440,380  ; 右
	INVOKE Rectangle,hdcMemhelp,535,335,605,365  ; enter
	INVOKE Rectangle,hdcMemhelp,431,380,460,410  ; I
	INVOKE Rectangle,hdcMemhelp,400,410,430,440  ; J
	INVOKE Rectangle,hdcMemhelp,431,410,460,440  ; K
	INVOKE Rectangle,hdcMemhelp,461,410,490,440  ; L

	INVOKE SetTextColor,hdcMemhelp,00FFFFFFh
	INVOKE SetBkColor,hdcMemhelp,0
	INVOKE SelectObject,hdcMemhelp, font_40
	INVOKE TextOutA,hdcMemhelp,0,0,offset helptext_title1,14
	INVOKE TextOutA,hdcMemhelp,0,220,offset helptext_title2,17
	INVOKE SelectObject,hdcMemhelp, font_20
	INVOKE TextOutA,hdcMemhelp,0,40,offset helptext_hang1,53
	INVOKE TextOutA,hdcMemhelp,0,60,offset helptext_hang2,54
	INVOKE TextOutA,hdcMemhelp,0,80,offset helptext_hang3,55
	INVOKE TextOutA,hdcMemhelp,0,100,offset helptext_hang4,32
	INVOKE TextOutA,hdcMemhelp,0,120,offset helptext_hang5,55
	INVOKE TextOutA,hdcMemhelp,0,140,offset helptext_hang6,54
	INVOKE TextOutA,hdcMemhelp,0,160,offset helptext_hang7,52
	INVOKE TextOutA,hdcMemhelp,0,180,offset helptext_hang8,52
	INVOKE TextOutA,hdcMemhelp,0,200,offset helptext_hang9,18
	INVOKE TextOutA,hdcMemhelp,0,280,offset helptext_hang10_1,27
	INVOKE TextOutA,hdcMemhelp,390,280,offset helptext_hang10_6,8
	INVOKE TextOutA,hdcMemhelp,0,340,offset helptext_hang11_1,27
	INVOKE TextOutA,hdcMemhelp,440,340,offset helptext_hang11_6,8
	INVOKE TextOutA,hdcMemhelp,0,400,offset helptext_hang12_1,35
	INVOKE TextOutA,hdcMemhelp,490,400,offset helptext_hang12_6,12
	INVOKE TextOutA,hdcMemhelp,0,440,offset helptext_hang13,53
	INVOKE TextOutA,hdcMemhelp,0,460,offset helptext_hang14,58

	INVOKE SetBkColor,hdcMemhelp,02BA245h
	INVOKE TextOutA,hdcMemhelp,336,265,offset helptext_hang10_2,1
	INVOKE TextOutA,hdcMemhelp,336,295,offset helptext_hang10_3,1
	INVOKE TextOutA,hdcMemhelp,305,295,offset helptext_hang10_4,1
	INVOKE TextOutA,hdcMemhelp,366,295,offset helptext_hang10_5,1
	INVOKE TextOutA,hdcMemhelp,490,280,offset helptext_hang10_7,5
	INVOKE TextOutA,hdcMemhelp,355,325,offset helptext_hang11_2,2
	INVOKE TextOutA,hdcMemhelp,346,355,offset helptext_hang11_3,4
	INVOKE TextOutA,hdcMemhelp,305,355,offset helptext_hang11_4,2
	INVOKE TextOutA,hdcMemhelp,406,355,offset helptext_hang11_5,2
	INVOKE TextOutA,hdcMemhelp,540,340,offset helptext_hang11_7,5
	INVOKE TextOutA,hdcMemhelp,436,385,offset helptext_hang12_2,1
	INVOKE TextOutA,hdcMemhelp,436,415,offset helptext_hang12_3,1
	INVOKE TextOutA,hdcMemhelp,405,415,offset helptext_hang12_4,1
	INVOKE TextOutA,hdcMemhelp,466,415,offset helptext_hang12_5,1

	ret
DrawBasicPic ENDP

PaintProc PROC USES ebx esi,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
	local bulletheight:word,bulletwidth:word
	invoke BeginPaint, hWnd, addr ps ; 开始绘画
	mov hdc, eax                    ; 绘画页面句柄

	; 设置字体
	INVOKE SelectObject,hdcMempage, font_50

	; 画上黑色背景
	invoke BitBlt,hdcMempage,0,0,WINDOW_WIDTH,WINDOW_HEIGHT,[hdcMemColors],0,0,SRCCOPY
	
	; 设置布局页面的背景颜色和字的颜色
	INVOKE SetTextColor,hdcMempage,00FFFFFFh
	INVOKE SetBkColor,hdcMempage,0

	.IF WhichMenu == 0 ;开始界面
		INVOKE TextOutA,hdcMempage,253,188,offset startText,5  ;640/2-67=253
		INVOKE TextOutA,hdcMempage,266,248,offset helpText,4   ;640/2-54=266
		INVOKE TextOutA,hdcMempage,240,308,offset customText,6 ;640/2-80=240
		INVOKE TextOutA,hdcMempage,267,368,offset exitText,4   ;640/2-53=267

		INVOKE SetTextColor,hdcMempage,0
		INVOKE SetBkColor,hdcMempage,00FFFFFFh
		; 给选中的菜单设置相反的背景与字色
		.IF SelectMenu == 0
			INVOKE TextOutA,hdcMempage,253,188,offset startText,5  ;640/2-67=253
		.ELSEIF SelectMenu == 1
			INVOKE TextOutA,hdcMempage,266,248,offset helpText,4   ;640/2-54=266
		.ELSEIF SelectMenu == 2
			INVOKE TextOutA,hdcMempage,240,308,offset customText,6 ;640/2-80=240
		.ELSEIF SelectMenu == 3
			INVOKE TextOutA,hdcMempage,267,368,offset exitText,4   ;640/2-53=267
		.ENDIF

	.ELSEIF WhichMenu == 1  ;游戏模式选择界面

		INVOKE TextOutA,hdcMempage,251,208,offset PVPText,5   ;640/2-69=251
		INVOKE TextOutA,hdcMempage,240,368,offset BackText,6  ;640/2-80=240	

		INVOKE SetTextColor,hdcMempage,0
		INVOKE SetBkColor,hdcMempage,00FFFFFFh
		; 给选中的菜单设置相反的背景与字色
		.IF SelectMenu == 0
			INVOKE TextOutA,hdcMempage,251,208,offset PVPText,5  ;640/2-69=251
		.ELSEIF SelectMenu == 1
			INVOKE TextOutA,hdcMempage,240,368,offset BackText,6  ;640/2-80=240
		.ENDIF

	.ELSEIF WhichMenu == 2                    ;游戏界面
		
		; 把背景图绘制在布局页面上
		INVOKE BitBlt, hdcMempage, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMembg, 0, 0, SRCCOPY

		; 这部分两层循环实现根据地图块上的数字实现给布局页面对应位置画上不同的色块
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
			INVOKE BitBlt, hdcMempage, ax, bx, 31, 31, hdcMemblack, 0, 0, SRCCOPY
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
			INVOKE BitBlt, hdcMempage, ax, bx, 31, 31, hdcMemwhite, 0, 0, SRCCOPY
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

		; 在布局页面是画上两个主角
		INVOKE BitBlt, hdcMempage, [blackblock], [blackblock+2], [blackblock+4], [blackblock+4], hdcMemblack, 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, [whiteblock], [whiteblock+2], [whiteblock+4], [whiteblock+4], hdcMemwhite, 0, 0, SRCCOPY

		.IF [blackblock+8] >= 1
			mov ax,[blackblock]
			add ax,4
			mov dx,[blackblock+2]
			add dx,4
			INVOKE BitBlt, hdcMempage, ax, dx,4,4, hdcMemwhite, 0, 0, SRCCOPY
		.ENDIF
		.IF [blackblock+8] >= 2
			mov ax,[blackblock]
			add ax,4
			mov dx,[blackblock+2]
			add dx,15
			INVOKE BitBlt, hdcMempage, ax, dx,4,4, hdcMemwhite, 0, 0, SRCCOPY
		.ENDIF
		.IF [blackblock+8] >= 3
			mov ax,[blackblock]
			add ax,15
			mov dx,[blackblock+2]
			add dx,15
			INVOKE BitBlt, hdcMempage, ax, dx,4,4, hdcMemwhite, 0, 0, SRCCOPY
		.ENDIF
		.IF [blackblock+8] >= 4
			mov ax,[blackblock]
			add ax,15
			mov dx,[blackblock+2]
			add dx,4
			INVOKE BitBlt, hdcMempage, ax, dx,4,4, hdcMemwhite, 0, 0, SRCCOPY
		.ENDIF
		.IF [whiteblock+8] >= 1
			mov ax,[whiteblock]
			add ax,4
			mov dx,[whiteblock+2]
			add dx,4
			INVOKE BitBlt, hdcMempage, ax, dx, 4, 4, hdcMemblack, 0, 0, SRCCOPY
		.ENDIF
		.IF [whiteblock+8] >= 2
			mov ax,[whiteblock]
			add ax,4
			mov dx,[whiteblock+2]
			add dx,15
			INVOKE BitBlt, hdcMempage, ax, dx, 4, 4, hdcMemblack, 0, 0, SRCCOPY
		.ENDIF
		.IF [whiteblock+8] >= 3
			mov ax,[whiteblock]
			add ax,15
			mov dx,[whiteblock+2]
			add dx,15
			INVOKE BitBlt, hdcMempage, ax, dx, 4, 4, hdcMemblack, 0, 0, SRCCOPY
		.ENDIF
		.IF [whiteblock+8] >= 4
			mov ax,[whiteblock]
			add ax,15
			mov dx,[whiteblock+2]
			add dx,4
			INVOKE BitBlt, hdcMempage, ax, dx, 4, 4, hdcMemblack, 0, 0, SRCCOPY
		.ENDIF

			mov ecx,10
		L1:                     ; 循环画子弹
			push ecx
			mov esi,offset bullets
			mov eax,ecx
			dec ax
			sal ax,3
			add esi,eax

			mov ax,WORD PTR [esi+6]
			.IF ax == 1 || ax == 2
				mov bx,[esi]         ; 子弹目前是正方形，为了使其中心就是之前的子弹点，因此正方形的起始点需要是(-10,-10),目前正方形子弹的大小为20*20像素
				sub bx,2
				mov dx,[esi+2]
				sub dx,10
				mov cx,5
				mov bulletheight,cx
				mov cx,20
				mov bulletwidth,cx
			.ELSEIF ax == 3 || ax == 4
				mov bx,[esi]         ; 子弹目前是正方形，为了使其中心就是之前的子弹点，因此正方形的起始点需要是(-10,-10),目前正方形子弹的大小为20*20像素
				sub bx,10
				mov dx,[esi+2]
				sub dx,2
				mov cx,20
				mov bulletheight,cx
				mov cx,5
				mov bulletwidth,cx
			.ENDIF
			mov ax,WORD PTR [esi+4]
			.IF ax == 1  
				INVOKE BitBlt, hdcMempage, bx, dx, bulletheight, bulletwidth, hdcMemblack, 0, 0, SRCCOPY
			.ELSEIF ax==2
				INVOKE BitBlt, hdcMempage, bx, dx, bulletheight, bulletwidth, hdcMemwhite, 0, 0, SRCCOPY
			.ENDIF
			pop ecx
			dec ecx
			jne L1

			.IF statusFlag == 3  ; 如果暂停
				INVOKE SelectObject,hdcMempage, font_40
				INVOKE TextOutA,hdcMempage,0,220,offset pauseText,31  ; 绘制暂停中提示
			.ENDIF


	.ELSEIF WhichMenu == 3   ;结束界面
		.IF statusFlag == 1
			INVOKE TextOutA,hdcMempage,200,170,offset P1WinMsg,6  ; 绘制P1胜利结束页面语言
		.ELSE 
			INVOKE TextOutA,hdcMempage,200,170,offset P2WinMsg,6 ; 绘制P2胜利结束页面语言
		.ENDIF
		INVOKE TextOutA,hdcMempage,60,320,offset endbacktip,19  ; press r to comeback

	.ELSEIF WhichMenu == 4   ;帮助界面
		INVOKE BitBlt, hdcMempage, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMemhelp, 0, 0, SRCCOPY

	.ELSEIF WhichMenu == 5   ;选关界面
		; 将三张地图图片绘制到屏幕
		INVOKE BitBlt, hdcMempage, 240, 30, 160, 120, hdcMemMap1, 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 240, 180, 160, 120, hdcMemMap2, 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 240, 330, 160, 120, hdcMemMap3, 0, 0, SRCCOPY
		; 分别绘制箭头在不同的位置
		.IF SelectMenu == 0
			INVOKE TextOutA,hdcMempage,170,60,offset arrowText,2
		.ELSEIF SelectMenu == 1
			INVOKE TextOutA,hdcMempage,170,210,offset arrowText,2
		.ELSEIF SelectMenu == 2
			INVOKE TextOutA,hdcMempage,170,360,offset arrowText,2
		.ENDIF
	.ELSEIF WhichMenu == 6
		; 画20种颜色。太懒不想写循环。两重循环的码量不一定比20行少。
		INVOKE BitBlt, hdcMempage, 40, 20, 80, 80, [hdcMemColors], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 160, 20, 80, 80, [hdcMemColors+4], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 280, 20, 80, 80, [hdcMemColors+8], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 400, 20, 80, 80, [hdcMemColors+12], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 520, 20, 80, 80, [hdcMemColors+16], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 40, 140, 80, 80, [hdcMemColors+20], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 160, 140, 80, 80, [hdcMemColors+24], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 280, 140, 80, 80, [hdcMemColors+28], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 400, 140, 80, 80, [hdcMemColors+32], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 520, 140, 80, 80, [hdcMemColors+36], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 40, 260, 80, 80, [hdcMemColors+40], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 160, 260, 80, 80, [hdcMemColors+44], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 280, 260, 80, 80, [hdcMemColors+48], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 400, 260, 80, 80, [hdcMemColors+52], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 520, 260, 80, 80, [hdcMemColors+56], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 40, 380, 80, 80, [hdcMemColors+60], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 160, 380, 80, 80, [hdcMemColors+64], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 280, 380, 80, 80, [hdcMemColors+68], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 400, 380, 80, 80, [hdcMemColors+72], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 520, 380, 80, 80, [hdcMemColors+76], 0, 0, SRCCOPY

		; 为避免第一种颜色（黑色）与背景融为一体，将其周围画白框
		INVOKE BitBlt, hdcMempage, 40, 20, 80, 1, [hdcMemColors+4], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 40, 20, 1, 80, [hdcMemColors+4], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 120, 20, 1, 80, [hdcMemColors+4], 0, 0, SRCCOPY
		INVOKE BitBlt, hdcMempage, 40, 100, 80, 1, [hdcMemColors+4], 0, 0, SRCCOPY

		INVOKE SelectObject,hdcMempage, font_20
		; 绘制p1选择光标
		mov eax, SelectMenu
		mov bx, 5
		div bx
		mov bl, 120
		mul bl
		add ax, 50
		push eax

		mov ax,dx
		mul bl
		add ax, 20
		pop edx

		INVOKE TextOutA,hdcMempage,eax,edx,offset p1ChooseText,10

		; 绘制p2选择光标
		mov eax, SelectMenu2
		mov bx, 5
		div bx
		mov bl, 120
		mul bl
		add ax, 50
		push eax

		mov ax,dx
		mul bl
		add ax, 20
		pop edx

		INVOKE TextOutA,hdcMempage,eax,edx,offset p2ChooseText,10

		; 绘制背景选择光标
		mov eax, SelectMenu3
		mov bx, 5
		div bx
		mov bl, 120
		mul bl
		add ax, 50
		push eax

		mov ax,dx
		mul bl
		add ax, 20
		pop edx

		INVOKE TextOutA,hdcMempage,eax,edx,offset bgChooseText,10
	.ENDIF

	; 最后把准备好的布局页面一次画到显示窗口上
	INVOKE BitBlt, hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMempage, 0, 0, SRCCOPY

	invoke EndPaint, hWnd, addr ps
	ret
PaintProc ENDP

TimerPROC PROC USES ebx

	.IF WhichMenu == 2   ;游戏界面
		.IF statusFlag == 0
			call updateBullets

			.IF WORD PTR [whiteblock+8] < 4
				inc WORD PTR [whiteblock+10]
				.IF WORD PTR [whiteblock+10] == 100
					mov WORD PTR [whiteblock+10],0
					inc WORD PTR [whiteblock+8]
				.ENDIF
			.ENDIF

			.IF WORD PTR [blackblock+8] < 4
				inc WORD PTR [blackblock+10]
				.IF WORD PTR [blackblock+10] == 100
					mov WORD PTR [blackblock+10],0
					inc WORD PTR [blackblock+8]
				.ENDIF
			.ENDIF

			cmp UpKeyHold,1
			jne TT@1
			mov [whiteblock+6],1
			mov ax,[whiteblock+2]
			sub ax,4
			mov bx,[whiteblock]
			call calCoordinate
			.IF [map+ax] == 1
				mov ax,[whiteblock+2]
				sub ax,4
				mov bx,[whiteblock]
				add bx,23
				call calCoordinate
				.IF [map+ax] == 1
					sub [whiteblock+2],4
				.ENDIF
			.ENDIF

		TT@1:
			cmp DownKeyHold,1
			jne TT@2
			mov [whiteblock+6],2
			mov ax,[whiteblock+2]
			add ax,27
			mov bx,[whiteblock]
			call calCoordinate
			.IF [map+ax] == 1
				mov ax,[whiteblock+2]
				add ax,27
				mov bx,[whiteblock]
				add bx,23
				call calCoordinate
				.IF [map+ax] == 1
					add [whiteblock+2],4
				.ENDIF
			.ENDIF
		
		TT@2:
			cmp LeftKeyHold,1
			jne TT@3
			mov [whiteblock+6],3
			mov ax,[whiteblock+2]
			mov bx,[whiteblock]
			sub bx,4
			call calCoordinate
			.IF [map+ax] == 1
				mov ax,[whiteblock+2]
				mov bx,[whiteblock]
				sub bx,4
				add ax,23
				call calCoordinate
				.IF [map+ax] == 1
					sub [whiteblock],4
				.ENDIF
			.ENDIF
		
		TT@3:
			cmp RightKeyHold,1
			jne TT@4
			mov [whiteblock+6],4
			mov ax,[whiteblock+2]
			add ax,23
			mov bx,[whiteblock]
			add bx,27
			call calCoordinate
			.IF [map+ax] == 1
				mov ax,[whiteblock+2]
				mov bx,[whiteblock]
				add bx,27
				call calCoordinate
				.IF [map+ax] == 1
					add [whiteblock],4
				.ENDIF
			.ENDIF
		
		TT@4:
			cmp EnterKeyHold,1
			jne TT@5
			.IF WORD PTR [whiteblock+8] > 0
				dec WORD PTR [whiteblock+8]
				invoke emitBullet,[whiteblock],[whiteblock+2],2,[whiteblock+6]
			.ENDIF
			mov EnterKeyHold,0

		TT@5:
			cmp WKeyHold,1
			jne TT@6
			mov [blackblock+6],1
			mov ax,[blackblock+2]
			sub ax,4
			mov bx,[blackblock]
			call calCoordinate
			.IF [map+ax] == 2
				mov ax,[blackblock+2]
				sub ax,4
				mov bx,[blackblock]
				add bx,23
				call calCoordinate
				.IF [map+ax] == 2
					sub [blackblock+2],4
				.ENDIF
			.ENDIF
		
		TT@6:
			cmp SKeyHold,1
			jne TT@7
			mov [blackblock+6],2
			mov ax,[blackblock+2]
			add ax,27
			mov bx,[blackblock]
			call calCoordinate
			.IF [map+ax] == 2
				mov ax,[blackblock+2]
				add ax,27
				mov bx,[blackblock]
				add bx,23
				call calCoordinate
				.IF [map+ax] == 2
					add [blackblock+2],4
				.ENDIF
			.ENDIF

		TT@7:
			cmp AKeyHold,1
			jne TT@8
			mov [blackblock+6],3
			mov ax,[blackblock+2]
			mov bx,[blackblock]
			sub bx,4
			call calCoordinate
			.IF [map+ax] == 2
				mov ax,[blackblock+2]
				mov bx,[blackblock]
				sub bx,4
				add ax,23
				call calCoordinate
				.IF [map+ax] == 2
					sub [blackblock],4
				.ENDIF
			.ENDIF

		TT@8:
			cmp DKeyHold,1
			jne TT@9
			mov [blackblock+6],4
			mov ax,[blackblock+2]
			add ax,23
			mov bx,[blackblock]
			add bx,27
			call calCoordinate
			.IF [map+ax] == 2
				mov ax,[blackblock+2]
				mov bx,[blackblock]
				add bx,27
				call calCoordinate
				.IF [map+ax] == 2
					add [blackblock],4
				.ENDIF
			.ENDIF
		
		TT@9:
			cmp SpaceKeyHold,1
			jne TimerTickReturn
			.IF WORD PTR [blackblock+8] > 0
				dec WORD PTR [blackblock+8]
				invoke emitBullet,[blackblock],[blackblock+2],1,[blackblock+6]
			.ENDIF
			mov SpaceKeyHold,0
		.ENDIF
	.ENDIF

	TimerTickReturn:
		ret
		
TimerPROC ENDP

;--------------------------------------------------------------
calCoordinate PROC
;用于计算黑白角色在地图中的位置，便于判断是否是合法移动
;也可以用来计算子弹所处的位置，用于碰撞判断
;参数：ax：需要计算的物体的纵坐标，bx：横坐标
;返回值：ax，存储当前位置在map数组中的偏移量。（已乘WORD的长度）
;（即，使用方法：[map+ax]的值为被计算坐标的物体所在的格子）
;--------------------------------------------------------------
	push bx
	sar ax,5
	mov bx,20
	mul bx
	pop bx
	sar bx,5
	add ax,bx
	mov bx,2
	mul bx
	ret
calCoordinate ENDP

playmusic PROC
	INVOKE PlaySound,124,hInstance,SND_RESOURCE
	ret
playmusic ENDP

emitBullet PROC USES esi,xCoor:WORD,yCoor:WORD,color:WORD,heading:WORD

	invoke CreateThread,NULL,NULL,addr playmusic,NULL,0,NULL 
    invoke CloseHandle,eax 
	add xCoor,12
	add yCoor,12
	mov esi,offset bullets
	mov eax,0
	mov ax,currentBullet
	sal ax,3
	add esi,eax
	mov ax,xCoor
	mov WORD PTR [esi],ax

	mov ax,yCoor
	mov WORD PTR [esi+2],ax

	mov ax,color
	mov WORD PTR [esi+4],ax

	mov ax,heading
	mov WORD PTR [esi+6],ax

	inc currentBullet
	.IF currentBullet == 10
		mov currentBullet,0
	.ENDIF
	ret
emitBullet ENDP

updateBullets PROC USES ebx esi
	LOCAL bulletPosition:WORD
	
	mov ecx,10
L1:
	mov esi,offset bullets
	mov eax,ecx
	dec ax
	sal ax,3
	add esi,eax  ;现在esi里存的就是当前所需要更新的子弹结构体的地址了，使用[esi]、[esi + 2]...等可以访问具体的属性值
	
	mov ax,WORD PTR [esi+4]
	.IF ax == 0  ;子弹的颜色为0代表子弹不合法（即不存在），直接找下一个子弹
		loop L1
		ret
	.ENDIF

	mov ax,WORD PTR [esi+6]   ;子弹合法，更新子弹位置
	.IF ax == 1
		sub WORD PTR [esi+2],16
	.ELSEIF ax == 2
		add WORD PTR [esi+2],16
	.ELSEIF ax == 3
		sub WORD PTR [esi],16
	.ELSEIF ax == 4
		add WORD PTR [esi],16
	.ENDIF

	; 如果子弹位置更新后超出地图，则将子弹颜色置为0，视为不合法
	mov ax,SWORD PTR [esi]
	mov dx,SWORD PTR [esi+2]
	.IF (ax < 0)||(ax > 640)
		mov WORD PTR [esi+4],0
		dec ecx
		cmp ecx, 0
		jne L1
		ret
	.ELSEIF (dx < 0)||(dx > 480)
		mov WORD PTR [esi+4],0
		dec ecx
		cmp ecx, 0
		jne L1
		ret
	.ENDIF

	;如果子弹位置更新后未超出地图，检测其是否与其他子弹对冲而抵消
	mov ax,WORD PTR [esi+2]
	mov bx,WORD PTR [esi]
	call calCoordinate
	mov bulletPosition,ax
	push ecx
	mov ecx,10
	mov edx,offset bullets
L2:
	mov ax,WORD PTR [edx+4]
	.IF ax == WORD PTR [esi+4]  ;如果要判断的两个子弹颜色相等就直接跳过
		add edx,8
		loop L2
		jmp LoopExit
	.ENDIF
	mov ax,WORD PTR [edx+2]
	mov bx,WORD PTR [edx]
	push edx
	call calCoordinate
	pop edx
	.IF ax == bulletPosition  ;子弹颜色不等且位置相同，对冲抵消
		mov WORD PTR [edx+4],0
		mov SWORD PTR [edx+2],-1
		mov SWORD PTR [edx],-1
		mov WORD PTR [esi+4],0
		mov SWORD PTR [esi+2],-1
		mov SWORD PTR [esi],-1
		pop ecx
		dec ecx
		cmp ecx, 0
		jne L1
		ret
	.ENDIF
	add edx,8
	loop L2
LoopExit:
	pop ecx
	
	; 如果子弹没有因对冲而抵消，将路径变色，并检测是否击中敌方
	mov ax,WORD PTR [esi+2]
	mov bx,WORD PTR [esi]
	call calCoordinate
	mov bulletPosition,ax
	mov dx,[map+ax]
	.IF dx == [esi+4]
		.IF [map+ax] == 1  ;黑方发的子弹
			mov [map+ax],2

			mov ax,[whiteblock+2]   ;检测白方的左上角是否在变色路径上
			mov bx,[whiteblock]
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,2
				push ecx
				call someOneDead
				pop ecx
			.ENDIF

			mov ax,[whiteblock+2]   ;检测白方的左下角是否在变色路径上
			add ax,23
			mov bx,[whiteblock]
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,2
				push ecx
				call someOneDead
				pop ecx
			.ENDIF

			mov ax,[whiteblock+2]   ;检测白方的右上角是否在变色路径上
			mov bx,[whiteblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,2
				push ecx
				call someOneDead
				pop ecx
			.ENDIF

			mov ax,[whiteblock+2]   ;检测白方的右下角是否在变色路径上
			add ax,23
			mov bx,[whiteblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,2
				push ecx
				call someOneDead
				pop ecx
			.ENDIF


		.ELSEIF [map+ax] == 2      ;白方发的子弹
			mov [map+ax],1

			mov ax,[blackblock+2]   ;检测黑方的左上角是否在变色路径上
			mov bx,[blackblock]
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				push ecx
				call someOneDead
				pop ecx
			.ENDIF

			mov ax,[blackblock+2]   ;检测黑方的左下角是否在变色路径上
			add ax,23
			mov bx,[blackblock]
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				push ecx
				call someOneDead
				pop ecx
			.ENDIF

			mov ax,[blackblock+2]   ;检测白方的右上角是否在变色路径上
			mov bx,[blackblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				push ecx
				call someOneDead
				pop ecx
			.ENDIF

			mov ax,[blackblock+2]   ;检测白方的右下角是否在变色路径上
			add ax,23
			mov bx,[blackblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				push ecx
				call someOneDead
				pop ecx
			.ENDIF
		.ENDIF
	.ENDIF

	dec ecx
	cmp ecx, 0
	jne L1

	ret
updateBullets ENDP

;------------------------------------
someOneDead PROC
;输入参数：ax，指被击中方的color(1/2)
;------------------------------------
	
	.IF ax == 1 ; 如果被击中的是黑色，那么白色胜利
		mov statusFlag,2  ;将胜利标志位置2
		mov [blackblock],999
		mov [blackblock+2],999
		mov ecx,300
	L1:
		mov ax,cx
		dec ax
		sal ax,1
		mov [map+ax],1
		loop L1
	.ELSE  ; 如果被击中的是白色，黑色胜利
		mov statusFlag,1  ;将胜利标志位置1
		mov [whiteblock],999
		mov [whiteblock+2],999
		mov ecx,300
	L2:
		mov ax,cx
		dec ax
		sal ax,1
		mov [map+ax],2
		loop L2
	.ENDIF
	mov ecx,10
	mov edx,offset bullets
L3:          ;清除所有子弹
	mov SWORD PTR [edx],-1
	mov SWORD PTR [edx+2],-1
	mov WORD PTR [edx+4],0
	mov WORD PTR [edx+6],0
	add edx,8
	loop L3

	mov WhichMenu,3

	ret
someOneDead ENDP

END WinMain
