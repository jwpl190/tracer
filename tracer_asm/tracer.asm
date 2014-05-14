%include "WIN32N.INC"

bits  32

STRUC _PUSHAD
.regEdi RESD 1
.regEsi RESD 1
.regEbp RESD 1
.regEsp RESD 1
.regEbx RESD 1
.regEdx RESD 1
.regEcx RESD 1
.regEax RESD 1
ENDSTRUC

[extern MessageBoxA]
[extern GetModuleHandleA]
[extern ExitProcess]
[extern wsprintfA]

[extern VirtualProtect]
[extern CreateFileA]
[extern CloseHandle]
[extern WriteFile]


PAGE_EXECUTE_READWRITE 	equ 0x40

[segment code public use32 class='CODE']

..start:
enter 	0,0
push 	byte 0
call 	GetModuleHandleA
mov 	[handle],eax


push	0
push	0
push	CREATE_ALWAYS
push	0
push	0
push	GENERIC_WRITE
push	filename_seh
call	CreateFileA
mov		dword [handle_seh],eax

push 	seh1
push 	dword [fs:0]
mov		dword [fs:0],esp 

call 	prepare_ntdll_hook

mov 	ebx,01234567h
mov 	ecx,11111111h
mov 	edx,22222222h
mov 	esi,33333333h
mov 	edi,44444444h

int 	3 ; Exception not handled by our Handler, to init tracing!

pushf
or 		dword [esp],0x100
popf


push	 0
push 	Title
push 	Message3
push 	0
call 	MessageBoxA


pop		dword [fs:0]
add		esp,4h

push 	dword [handle_seh]
call 	CloseHandle

call 	remove_ntdll_hook

push 	dword [handle]
call 	ExitProcess
leave
ret



seh1:
%define pExcept		ebp+8
%define pFrame		ebp+0Ch
%define pContext	ebp+10h
%define pDispatch	ebp+14h

push	ebp
mov		ebp,esp

pushad



%if 1
mov	eax,[pContext]
push 	dword[eax+CONTEXT.regEip]
push 	Message_Thread_SEH
push 	txtbuf
call 	wsprintfA
add		esp,0Ch

push 	0
push 	Title
push 	txtbuf
push 	0
call 	MessageBoxA
%endif

mov		eax,[pContext]
mov		ebx,[pExcept]
mov		edx,dword [handle_seh]
call 	trace

popad

mov		eax,[pExcept]
cmp 	dword[eax+EXCEPTION_RECORD.ExceptionCode],STATUS_BREAKPOINT
jnz 	.set_trace
mov		eax,[pContext]
add 	dword [eax+CONTEXT.regEip],1

.set_trace:
mov		eax,[pContext]
or		dword [eax+CONTEXT.regFlag],0x100
mov		eax,EXCEPTION_CONTINUABLE


pop		ebp
ret




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
push	esi
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
;Importing API needed...
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov		dword [esi+_CreateFileA],CreateFileA
mov		dword [esi+_VirtualProtect],VirtualProtect
mov		dword [esi+_MessageBoxA],MessageBoxA
mov		dword [esi+_WriteFile],WriteFile
mov		dword [esi+_CloseHandle],CloseHandle
mov		dword [esi+_wsprintfA],wsprintfA



;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Creating file in current context...
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------

push	0
push	0
push	CREATE_ALWAYS
push	0
push	0
push	GENERIC_WRITE
push_displacement	filename_ntdll,eax,esi
call_restore_displacement	_CreateFileA,esi

mov		dword [esi+handle_ntdll],eax

;-----------------------------------------------------------------
;virtual protect to allowing writing in ntdll
;-----------------------------------------------------------------
push_displacement	OldProtect,eax,esi
push 	PAGE_EXECUTE_READWRITE
push 	6
push 	dword [esi+patch_offset]
call_restore_displacement _VirtualProtect,esi

;modify ntdll
;lea		eax,[onbp+esi]
;mov		ebx,dword [esi+patch_point]
;call 		create_jmp

;modify ntdll
lea		eax,[esi+test_bp]
mov		ebx,dword [esi+patch_offset]
call 		change_call

mov		esi,[esp]

;-----------------------------------------------------------------
;virtual protect to restore
;-----------------------------------------------------------------
push_displacement	OldProtect,eax,esi
push 	dword [esi+OldProtect]
push 	6
push 	dword [esi+patch_offset]
call_restore_displacement _VirtualProtect,esi

push 	0
push_displacement	Title,eax,esi
push_displacement	Message1,eax,esi
push 	0
call_restore_displacement _MessageBoxA,esi
pop		esi
popad
ret

change_call:
push		eax
push		ebx
sub		eax,ebx
sub		eax,5
inc		ebx
mov		dword [ebx],eax
pop		ebx
pop		eax
ret

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Restore NTDLL
;
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
remove_ntdll_hook:
pushad
get_displacement esi
push	esi

;-----------------------------------------------------------------
;virtual protect to allowing writing in ntdll
;-----------------------------------------------------------------
push_displacement	OldProtect,eax,esi
push 	PAGE_EXECUTE_READWRITE
push 	6
push 	dword [esi+patch_point]
call_restore_displacement _VirtualProtect,esi

;TODO restore bytes...

;-----------------------------------------------------------------
;virtual protect to restore
;-----------------------------------------------------------------
push_displacement	OldProtect,eax,esi
push 	dword [esi+OldProtect]
push 	6
push 	dword [esi+patch_point]
call_restore_displacement _VirtualProtect,esi

push 	0
push_displacement	Title,eax,esi
push_displacement	Message2,eax,esi
push 	0
call_restore_displacement _MessageBoxA,esi

;push 	dword [esi+handle_ntdll]
;call_restore_displacement _CloseHandle,esi // If i do that...crash :p

pop	esi
popad

ret

test_bp:
push	dword [esp+8]
push	dword [esp+8]
call	dword [to_call]
ret

onbp:
mov		ecx,[ebp+18h]
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Test after SEH.... do we have to actually mark the exception
; as OK?
;
; if the thread set itself the TFlag, we should let it handle it!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
pushad
get_displacement esi
push	esi
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Exception here isn't a int1, and apparently the process did not set an int1 before...So it's probably ours :p
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------

%if 0
mov		ebx,[pExcept]
push	dword [ebx+EXCEPTION_RECORD.ExceptionCode]
mov		eax,[pContext]
push 	dword[eax+CONTEXT.regEip]
push 	Message_Seh
push 	txtbuf
call 	[_wsprintfA]
add		esp,10h

push 	0
push 	Title
push 	txtbuf
push 	0
call 	[_MessageBoxA]
%endif

mov		eax,[pContext]
mov		ebx,[pExcept]
mov		edx,dword [esi+handle_ntdll]
call 	trace
mov		esi,[esp]

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Thread did set itself TFlag? (popf)
; Then let it handle exception itself!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov		ebx,[pContext]
mov 	eax,[ebx+CONTEXT.regFlag]
and		eax,0x100					
jnz		.exception_handled

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Exception was int1?
; Let it handle itself!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Exception = SingleStep?
; no -> Let it handle itself!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov		ebx,[pExcept]
cmp		dword[ebx+EXCEPTION_RECORD.ExceptionCode],STATUS_SINGLE_STEP
jnz		.exception_handled

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Did the thread set TFlag previously?
; yes -> Let it handle int!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov		eax,dword [esi+int1_enabled]
mov		dword [esi+int1_enabled],0 ; reset flag
test	eax,eax
jnz		.exception_handled

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
;The exception came from our own trap flag -> Process it!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov		dword [esp+_PUSHAD.regEax],EXCEPTION_CONTINUABLE

pop	esi
popad
jmp		.activate_trap_flag


.exception_handled
pop	esi
popad
call	ecx

.activate_trap_flag
pushad
get_displacement esi
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Activate Trap Flag
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov		ebx,[pContext]
mov 	eax,[ebx+CONTEXT.regFlag]
and		eax,0x100
jz		.int1_not_enabled
mov		dword [esi + int1_enabled],1 ; remember that the int1 is coming from the proggy itself!
.int1_not_enabled:
or 		dword [ebx+CONTEXT.regFlag],0x100
popad

get_displacement ecx

jmp 	dword [ecx+patch_point_return] ; return to ntdll...

;-----------------------------------------------------------------
; ebx = offset to insert jmp // eax = offset to jump to 
;-----------------------------------------------------------------
create_jmp:
push	eax
push	ebx
sub		eax,ebx
sub		eax,5
mov		byte [ebx],0xE9
inc		ebx
mov		dword [ebx],eax
pop		ebx
pop		eax
ret

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; eax=pContext
; ebx=pExcept
; edx=handle
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
trace:
pushad

get_displacement esi
push	esi

%if 0
push	edx
push	dword [ebx+EXCEPTION_RECORD.ExceptionCode]
push	dword [ebx+EXCEPTION_RECORD.ExceptionFlags]
push	dword [ebx+EXCEPTION_RECORD.pExceptionRecord]
push	dword [ebx+EXCEPTION_RECORD.ExceptionAddress]
push	dword [ebx+EXCEPTION_RECORD.NumberParameters]
push 	dword [eax+CONTEXT.regEip]

push 	dword [esi+ntdll_hit]
push_displacement	txtbuf,ebx,esi
call 	[esi+_wsprintfA]
add		esp,8*04
mov		esi,[esp]

sub		ecx, ecx
lea		edi, [esi+txtbuf]
not		ecx
sub		al, al
cld
repne	scasb
not		ecx
lea		eax, [ecx-1]

pop		edx
push	0
push_displacement	bytes_written,ebx,esi
push	eax
push_displacement	txtbuf,ebx,esi
push	edx
call	[esi+_WriteFile]
%endif

%if 1
lea		eax,[eax+CONTEXT.regEip]
push	0
push_displacement	bytes_written,ebx,esi
push	4
push	eax
push	edx
call	[esi+_WriteFile]
%endif
pop		esi
popad
ret



[segment data public]
patch_point		dd 07C9137BAh
patch_point_return 	dd 07C9137BFh
patch_offset		dd 0x07C91EAF5
to_call			dd 0x7C9477C1
handle_ntdll 		dd 0
bytes_written 		dd 0
int1_enabled 		dd 0
OldProtect 			dd 0
Title 				db 'Alien patch',0
Message1 			db 'NtDll modified!',0
Message2 			db 'NtDll restored',0
filename_ntdll 		db 'ntdll.hex',0
Message_Thread_SEH 	db 'Thread SEH at EIP[%X]',0
ntdll_hit			db '0x%X: NumberParameters[%X] ExceptionAddress[%X] pExceptionRecord[%X] ExceptionFlags[%X] ExceptionCode[%X]',13,10,0

_VirtualProtect		dd 07C801AD0h
_CloseHandle		dd 07C809B47h
_WriteFile			dd 07C810D87h
_CreateFileA		dd 07C801A24h
_MessageBoxA		dd 07E3D058Ah
_wsprintfA			dd 07E39A8ADh


handle 	 			dd 0
handle_seh 	 		dd 0

Message3 			db 'Fin d execution',0
Message4 			db 'Message dans le SEH!',0
Message5 			db 'Inserted SEH has to set eax to EXCEPTION_CONTINUABLE!',0
Message_Seh 		db 'Inserted SEH has to set eax to EXCEPTION_CONTINUABLE! EIP=%X Code=%X',0
filename_seh 		db 'seh.hex',0



section  .bss  use32
txtbuf      		resb     1024