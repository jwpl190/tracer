%include "WIN32N.INC"

bits  32

%macro get_displacement 1
; this way is probably better than usual call $+5 pop xxx since that way the processor keeps its ret stack synchronized
call	%%get_eip
%%addr_return:
jmp		%%get_eip2
%%get_eip:
mov		%1,[esp]
ret

%%get_eip2:
sub		%1,%%addr_return
%endmacro

%macro	push_displacement 3
lea		%2,[%3+%1]
push	%2
%endmacro

%macro call_restore_displacement 2
call	[%1+%2]
mov		%2,[esp]
%endmacro



start_of_alien:

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Prepare process and install hooks in NTDLL!
;
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
prepare_ntdll_hook:
pushad

get_displacement esi
push_displacement dll,eax,esi
call [esi+_LoadLibraryA]

popad
ret


;dll 			db 'Y:\\Reverse\\Tracer\\release\\pumt.dll',0
dll 			db 'Z:\\Work\\Tracer\\release\\pumt.dll',0
Title			db 'Alien',0
Message			db 'Finished insertion',0
_LoadLibraryA		dd 07C801D77h
_MessageBoxA		dd 07E3D058Ah

