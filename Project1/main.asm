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
		@nspace1:
			cmp eax,13  ;识别enter键
			jne @nenter1
			mov EnterKeyHold,1
		@nenter1:
			cmp eax,27 ;识别esc键
			jne @nescape1
			; call EscapeInMenu
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

		; 开始定时器 30ms发一次定时器消息
		invoke SetTimer,hWnd,1,30,NULL

		; 获取当前程序窗口DC句柄
		invoke GetDC,hWnd
		mov hdc,eax

		; 布局页面的句柄以及其显示的句柄创建设置
		invoke CreateCompatibleDC,hdc
		mov hdcMempage,eax
		invoke CreateCompatibleBitmap,hdc,WINDOW_WIDTH,WINDOW_HEIGHT
		mov hbitmap,eax
		invoke SelectObject,hdcMempage,hbitmap

		; 四个主要图片的显示句柄
		INVOKE CreateCompatibleDC, hdc
		mov hdcMemblack, eax
		INVOKE CreateCompatibleDC, hdc
		mov hdcMemwhite, eax 
		INVOKE CreateCompatibleDC, hdc
		mov hdcMembg, eax
		INVOKE CreateCompatibleDC, hdc
		mov hdcMemhelp, eax

		; 四个主要图片的存储句柄
		INVOKE LoadImageA, hdc, offset IDB_PNG1_PATH, 0, 0, 0, LR_LOADFROMFILE
		mov blackPicBitmap, eax
		INVOKE LoadImageA, hdc, offset IDB_PNG2_PATH, 0, 0, 0, LR_LOADFROMFILE
		mov whitePicBitmap, eax
		INVOKE LoadImageA, hdc, offset IDR_BG1_PATH, 0, WINDOW_WIDTH, WINDOW_HEIGHT, LR_LOADFROMFILE
		mov bgPicBitmap, eax
		INVOKE LoadImageA, hdc, offset IDR_HELP_PATH, 0, 0, 0, LR_LOADFROMFILE
		mov helpPicBitmap, eax

		; 存储句柄与显示句柄之间的链接绑定
		INVOKE SelectObject, hdcMembg, bgPicBitmap
		INVOKE SelectObject, hdcMemblack, blackPicBitmap
		INVOKE SelectObject, hdcMemwhite, whitePicBitmap
		INVOKE SelectObject, hdcMemhelp, helpPicBitmap

		INVOKE CreateFontA,50,0,0,0,700,1,0,0,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FF_DECORATIVE,NULL
		mov font, eax
		INVOKE SelectObject,hdcMempage, eax

		; 释放当前窗口DC
		invoke ReleaseDC,hWnd,hdc

		jmp WinProcExit

	CloseWindowMessage:
		; 关闭信息接受
		INVOKE PostQuitMessage,0

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

NewRound PROC  ; 进入游戏实现自动初始化
	initblock: ; 初始化黑白块初始位置
		mov ax,[roundone_black_initpos]
		mov [blackblock],ax

		mov ax,[roundone_black_initpos+2]
		mov [blackblock+2],ax

		mov [blackblock+6],1

		mov ax,[roundone_white_initpos]
		mov [whiteblock],ax

		mov ax,[roundone_white_initpos+2]
		mov [whiteblock+2],ax

		mov [whiteblock+6],1

	initwinflag: ; 还原无胜利标志
		mov WinFlag,0	

		mov ecx,300
	SetMap:  ; 用循环拷贝地图，保障原始地图可以一直使用
		mov ax,[roundone_map+ecx*2-2]
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
			.IF SelectMenu < 2
				inc SelectMenu
				ret
			.ENDIF
		.ENDIF
		.IF eax == 13 || eax == 32  ; 确认键为enter和space 
			.IF SelectMenu == 0
				mov WhichMenu,1
				ret
			.ELSEIF SelectMenu == 1
				mov WhichMenu,4
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
				mov WhichMenu,2
				call NewRound    ; 每次进入游戏都会初始化游戏页面以及数据
				ret
			.ELSEIF SelectMenu == 1
				mov WhichMenu,0
				mov SelectMenu,0
				ret
			.ENDIF
		.ENDIF
	.ELSEIF WhichMenu == 3   ;帮助界面
		.IF eax == 13 || eax == 32  ; 确认键为enter和space 
			mov WhichMenu,1
			ret
		.ENDIF
	.ELSEIF WhichMenu == 4   ;帮助界面
		.IF eax == 13 || eax == 32  ; 确认键为enter和space 
			mov WhichMenu,0
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

PaintProc PROC USES ecx eax ebx esi,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD

	invoke  BeginPaint, hWnd, addr ps ; 开始绘画
	mov hdc, eax                    ; 绘画页面句柄

	; 创建并设置字体
	

	; 画上黑色背景
	invoke BitBlt,hdcMempage,0,0,WINDOW_WIDTH,WINDOW_HEIGHT,hdcMemblack,0,0,SRCCOPY
	
	; 设置布局页面的背景颜色和字的颜色
	INVOKE SetTextColor,hdcMempage,00FFFFFFh
	INVOKE SetBkColor,hdcMempage,0

	.IF WhichMenu == 0 ;开始界面
		INVOKE TextOutA,hdcMempage,253,208,offset startText,5  ;640/2-67=253
		INVOKE TextOutA,hdcMempage,266,288,offset helpText,4  ;640/2-54=266
		INVOKE TextOutA,hdcMempage,267,368,offset exitText,4  ;640/2-53=267

		INVOKE SetTextColor,hdcMempage,0
		INVOKE SetBkColor,hdcMempage,00FFFFFFh
		; 给选中的菜单设置相反的背景与字色
		.IF SelectMenu == 0
			INVOKE TextOutA,hdcMempage,253,208,offset startText,5  ;640/2-67=253
		.ELSEIF SelectMenu == 1
			INVOKE TextOutA,hdcMempage,266,288,offset helpText,4  ;640/2-54=266
		.ELSEIF SelectMenu == 2
			INVOKE TextOutA,hdcMempage,267,368,offset exitText,4  ;640/2-53=267
		.ENDIF

	.ELSEIF WhichMenu == 1  ;游戏模式选择界面

		INVOKE TextOutA,hdcMempage,251,208,offset PVPText,5  ;640/2-69=251
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
		INVOKE BitBlt, hdcMempage, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMembg, 0, 0, SRCCOPY  ; 这里借用了黑格的hdcmem用来显示背景（但没有影响）

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

	.ELSEIF WhichMenu == 3   ;结束界面
		.IF WinFlag == 1
			INVOKE TextOutA,hdcMempage,200,170,offset blackWinMsg,9  ; 绘制黑方胜利结束页面语言
		.ELSE 
			INVOKE TextOutA,hdcMempage,200,170,offset whiteWinMsg,9 ; 绘制白方胜利结束页面语言
		.ENDIF
		INVOKE TextOutA,hdcMempage,60,300,offset endbacktip1,20  ; press enter or space
		INVOKE TextOutA,hdcMempage,170,350,offset endbacktip2,11  ; to comeback
	.ELSEIF WhichMenu == 4   ;帮助界面
		INVOKE BitBlt, hdcMempage, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMemhelp, 0, 0, SRCCOPY
	.ENDIF

	; 最后把准备好的布局页面一次画到显示窗口上
	INVOKE BitBlt, hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdcMempage, 0, 0, SRCCOPY

	invoke EndPaint, hWnd, addr ps
	ret
PaintProc ENDP

TimerPROC PROC

	.IF WhichMenu == 2   ;游戏界面
		.IF WinFlag == 0
			call updateBullets

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
			invoke emitBullet,[whiteblock],[whiteblock+2],2,[whiteblock+6]

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
			invoke emitBullet,[blackblock],[blackblock+2],1,[blackblock+6]
		.ENDIF
	.ENDIF

TimerTickReturn:
	ret

TimerPROC ENDP

;--------------------------------------------------------------
calCoordinate PROC USES edx
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

emitBullet PROC USES esi,xCoor:WORD,yCoor:WORD,color:WORD,heading:WORD
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

updateBullets PROC
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
		sub WORD PTR [esi+2],32
	.ELSEIF ax == 2
		add WORD PTR [esi+2],32
	.ELSEIF ax == 3
		sub WORD PTR [esi],32
	.ELSEIF ax == 4
		add WORD PTR [esi],32
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
	call calCoordinate
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
				call someOneDead
			.ENDIF

			mov ax,[whiteblock+2]   ;检测白方的左下角是否在变色路径上
			add ax,23
			mov bx,[whiteblock]
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,2
				call someOneDead
			.ENDIF

			mov ax,[whiteblock+2]   ;检测白方的右上角是否在变色路径上
			mov bx,[whiteblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,2
				call someOneDead
			.ENDIF

			mov ax,[whiteblock+2]   ;检测白方的右下角是否在变色路径上
			add ax,23
			mov bx,[whiteblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,2
				call someOneDead
			.ENDIF


		.ELSEIF [map+ax] == 2      ;白方发的子弹
			mov [map+ax],1

			mov ax,[blackblock+2]   ;检测黑方的左上角是否在变色路径上
			mov bx,[blackblock]
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				call someOneDead
			.ENDIF

			mov ax,[blackblock+2]   ;检测黑方的左下角是否在变色路径上
			add ax,23
			mov bx,[blackblock]
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				call someOneDead
			.ENDIF

			mov ax,[blackblock+2]   ;检测白方的右上角是否在变色路径上
			mov bx,[blackblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				call someOneDead
			.ENDIF

			mov ax,[blackblock+2]   ;检测白方的右下角是否在变色路径上
			add ax,23
			mov bx,[blackblock]
			add bx,23
			call calCoordinate
			.IF ax == bulletPosition
				mov ax,1
				call someOneDead
			.ENDIF
		.ENDIF
	.ENDIF

	dec ecx
	cmp ecx, 0
	jne L1

	ret
updateBullets ENDP

;-----------------------------------
isBulletsHit PROC 
;检查是否有子弹对冲而需要抵消
;输入参数：ax：当前的子弹（）
;----------------------------------

isBulletsHit ENDP

;------------------------------------
someOneDead PROC USES ecx edx
;输入参数：ax，指被击中方的color(1/2)
;------------------------------------
	
	.IF ax == 1 ; 如果被击中的是黑色，那么白色胜利
		mov WinFlag,2  ;将胜利标志位置2
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
		mov WinFlag,1  ;将胜利标志位置1
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
