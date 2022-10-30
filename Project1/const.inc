; 结构创建区域
; 窗口结构数组
WNDCLASS STRUCT
	style				DWORD ?
	lpfnWndProc			DWORD ?
	cbClsExtra			DWORD ?
	cbWndExtra			DWORD ?
	hInstance			DWORD ?
	hIcon				DWORD ?
	hCursor				DWORD ?
	hbrBackground		DWORD ?
	lpszMenuName		DWORD ?
	lpszClassName		DWORD ?
WNDCLASS ENDS

;消息结构数组
MSGStruct STRUCT
	msgWnd				DWORD ?
	msgMessage			DWORD ?
	msgWparam			DWORD ?
	msgLparam			DWORD ?
	msgTime				DWORD ?
	msgPt				POINT <>
MSGStruct ENDS

;子弹数组定义
BULLET STRUCT
	xCoor				SWORD ? ;单位：像素
	yCoor				SWORD ? ;单位：像素
	color				WORD ? ;1代表黑方射出的子弹（黑色），2代表白方，0代表不合法子弹
	heading				WORD ? ;子弹的朝向，1代表上，2代表下，3代表左，4代表右
BULLET ENDS


; 特有变量声明区域
; 窗口变量样式定义
MAIN_WINDOW_STYLE = WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU \
+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME

; 黑色笔刷
BLACK_BRUSH				EQU		4
; 窗口长宽
WINDOW_WIDTH			EQU		640
WINDOW_HEIGHT			EQU		480

; 消息固定参数
WM_PAINT				EQU		00000000fh
WM_KEYDOWN				EQU		000000100h
WM_KEYUP				EQU		000000101h


; 函数声明区域
; 消息部分
; 消息转换用于后面翻译键盘输入为字符码
TranslateMessage		PROTO STDCALL :DWORD

; 定时器部分
; 定时器设置
SetTimer				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
; 定时器删除
KillTimer				PROTO STDCALL :DWORD,:DWORD

; 绘图部分
; 获取程序显示DC句柄
GetDC					PROTO STDCALL :DWORD
; 释放DC窗口句柄
ReleaseDC				PROTO STDCALL :DWORD,:DWORD
; 图片加载函数 
LoadImageA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 开始绘画函数
BeginPaint				PROTO STDCALL :DWORD,:DWORD
; 结束绘画函数
EndPaint				PROTO STDCALL :DWORD,:DWORD
; 创造与指定DC兼容的存储DC
CreateCompatibleDC		PROTO STDCALL: DWORD
; 创造与指定DC兼容的位图句柄
CreateCompatibleBitmap	PROTO STDCALL :DWORD,:DWORD,:DWORD
; 用选定的DC填充目标DC
SelectObject			PROTO STDCALL :DWORD,:DWORD
; 将指定的DC链接到目标DC的某一个区域上，是一个显示图片的函数
BitBlt					PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 设置背景颜色
SetBkColor				PROTO STDCALL :DWORD,:DWORD
; 将字符串链接到目标DC的某一个区域上，是一个显示数字的函数
TextOutA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; 创建指定的字体
CreateFontA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

; 自定义函数声明区域
PaintProc				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
emitBullet				PROTO STDCALL :WORD,:WORD,:WORD,:WORD

;==================== DATA =======================
.data

; 字符串定义区域
WindowName				BYTE	"INVERSUS ASM",0     ; 窗口名
className				BYTE	"ASMWin",0              ; 窗口类名

ErrorTitle				BYTE	"Error",0                  ; 错误警告弹窗标题

blackWinMsg			   BYTE	"Black Win",0               ; 黑方胜利提示   
whiteWinMsg            BYTE "White Win",0              ; 白方胜利提示   
endbacktip1                BYTE "press enter or space",0 ; 结束页面提示语言
endbacktip2                BYTE "to comeback",0 ; 结束页面提示语言

startText				BYTE	"start",0                  ; 开始游戏标签     
helpText				BYTE	"help",0                  ; 控制帮助文档标签
exitText				BYTE	"exit",0                   ; 退出游戏标签
PVPText					BYTE	"P V P",0               ; 双人小游戏模式标签
PVEText					BYTE	"P V E",0               ; 单机模式标签     unused
BackText				BYTE	"<-back",0                ; 返回上一级目录标签

IDB_PNG1_PATH			BYTE	"..\Project1\image\black.jpg",0     ; 黑色块路径
IDB_PNG2_PATH			BYTE	"..\Project1\image\white.jpg",0     ; 白色块路径
IDR_BG1_PATH			BYTE	"..\Project1\image\background.jpg",0 ; 背景块路径
IDR_HELP_PATH			BYTE	"..\Project1\image\help.jpg",0      ; 控制帮助图片路径


; 结构变量定义区域
; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, COLOR_WINDOW,NULL,className>
; 消息结构变量定义
msg					MSGStruct <>
; 画笔结构变量定义
ps					 PAINTSTRUCT	<>

; 普通变量定义区域
; 句柄变量
hMainWnd			 DWORD ?    ;总窗口句柄
hInstance				DWORD ?   ; 用于创建调用进程的文件的句柄
whitePicBitmap			DWORD ?    ; 用于存放白色块图片的句柄
blackPicBitmap			DWORD ?    ;用于存放黑色块图片的句柄
bgPicBitmap				DWORD ?    ; 用于存放背景图的句柄
helpPicBitmap			DWORD ?     ; 用户存放控制帮助图片的句柄
hbitmap					DWORD ?    ; 用于布局页面句柄
hdc						DWORD ?    ; 程序窗口的句柄
hdcMempage				DWORD ?   ; 布局页面显示句柄
hdcMemwhite				DWORD ?   ; 白色块显示句柄
hdcMemblack				DWORD ?   ; 黑色块显示句柄
hdcMembg                DWORD ?    ; 背景块显示句柄
hdcMemhelp                DWORD ?    ; 帮助图显示句柄

; 菜单选项变量
WhichMenu				DWORD 0		; 哪个界面，0表示开始，1表示选择游戏模式，2表示正在游戏，3表示游戏结束，4代表帮助界面
SelectMenu				DWORD 0		  ; 正在选择的菜单项 0表示第一项

; 方块状态变量  前两位是位置，第三位是大小，第四位是朝向(heading)，指示子弹发射的方向
blackblock				WORD 164,164,23,1
whiteblock				WORD 452,292,23,1

; 每一轮黑白块的初始位置 第一个数是横向的刻度，第二个数是纵向的刻度
roundone_black_initpos   WORD 164,164
roundone_white_initpos   WORD 452,292

; 字体变量
font                   DWORD ?

; 每一轮地图数组，20*15，0代表该格为空，1代表黑格，2代表白格
roundone_map WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
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

; 游戏中使用的临时地图数组，主要拷贝地图数组的内容，使地图数组能够反复利用
map WORD 300 DUP(?)

;子弹数组，储存地图中的每颗子弹，在计时器中令所有子弹向指定方向移动一段距离
bullets					BULLET 10 DUP(< -1,-1,0,0 >)  
;假定地图中同时最多有10颗子弹，采取队列的思想，每次从currentBullet插入，并令currentBullets加一（并模10）
currentBullet			WORD 0

; 状态变量
WinFlag				WORD 0 ;是否胜利flag，0代表未胜利，游戏正常进行，1代表胜利，玩家无法继续操作

; 按键是否按下的指示变量
UpKeyHold				DWORD 0 
DownKeyHold				DWORD 0
LeftKeyHold				DWORD 0
RightKeyHold			DWORD 0
WKeyHold				DWORD 0
SKeyHold				DWORD 0
AKeyHold				DWORD 0
DKeyHold				DWORD 0
SpaceKeyHold			DWORD 0
EnterKeyHold			DWORD 0