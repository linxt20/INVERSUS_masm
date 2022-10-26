WNDCLASS STRUC
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

MSGStruct STRUCT
	msgWnd				DWORD ?
	msgMessage			DWORD ?
	msgWparam			DWORD ?
	msgLparam			DWORD ?
	msgTime				DWORD ?
	msgPt				POINT <>
MSGStruct ENDS

MAIN_WINDOW_STYLE = WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU \
+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME

; �������룬���ں��淭���������Ϊ�ַ���
TranslateMessage		PROTO STDCALL :DWORD
SetTimer				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
KillTimer				PROTO STDCALL :DWORD,:DWORD

GetDC					PROTO STDCALL :DWORD
GetStockObject			PROTO STDCALL :DWORD
ReleaseDC				PROTO STDCALL :DWORD,:DWORD
LoadImageA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
BeginPaint				PROTO STDCALL :DWORD,:DWORD
EndPaint				PROTO STDCALL :DWORD,:DWORD

CreateCompatibleDC		PROTO STDCALL: DWORD
CreateCompatibleBitmap	PROTO STDCALL :DWORD,:DWORD,:DWORD
SelectObject			PROTO STDCALL :DWORD,:DWORD
BitBlt					PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SetBkColor				PROTO STDCALL :DWORD,:DWORD
Rectangle				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
TextOutA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
CreateFontA				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

PaintProc				PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD

BLACK_BRUSH				EQU		4

WINDOW_WIDTH			EQU		640
WINDOW_HEIGHT			EQU		480

;�̶����������ں���ʶ����̰�����̧��
WM_PAINT				EQU		00000000fh
WM_KEYDOWN				EQU		000000100h
WM_KEYUP				EQU		000000101h

;==================== DATA =======================
.data

ErrorTitle				BYTE	"Error",0

WindowName				BYTE	"INVERSUS ASM",0
className				BYTE	"ASMWin",0

startText				BYTE	"start",0
helpText				BYTE	"help",0
exitText				BYTE	"exit",0
PVPText					BYTE	"P V P",0
PVEText					BYTE	"P V E",0
BackText				BYTE	"<-back",0

IDB_PNG1_PATH			BYTE	"..\Project1\image\black.jpg",0
IDB_PNG2_PATH			BYTE	"..\Project1\image\white.jpg",0
IDR_BG1_PATH			BYTE	"..\Project1\image\background.jpg",0
IDR_HELP_PATH			BYTE	"..\Project1\image\help.jpg",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg						MSGStruct <>
winRect					RECT <>
hMainWnd				DWORD ?
hInstance				DWORD ?
whitePicBitmap			DWORD ?
blackPicBitmap			DWORD ? 
bgPicBitmap				DWORD ?
helpPicBitmap			DWORD ?
hbitmap					DWORD ?
hdc						DWORD ?
holdbr					DWORD ?
holdft					DWORD ?
ps						PAINTSTRUCT	<>
hdcMem					DWORD ?
hdcMem2					DWORD ?

WhichMenu				DWORD 0			; �ĸ����棬0��ʾ��ʼ��1��ʾѡ����Ϸģʽ��2��ʾ������Ϸ��3��ʾ��Ϸ������4������������
SelectMenu				DWORD 0			; ����ѡ��Ĳ˵���

blackblock				WORD 164,164,24
whiteblock				WORD 452,292,24

;��ͼ���飬20*15��0�����ø�Ϊ�գ�1�����ڸ�2�����׸�
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

; �����Ƿ��µ�ָʾ����
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