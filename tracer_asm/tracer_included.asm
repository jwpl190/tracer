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

PAGE_EXECUTE_READWRITE 	equ 0x40

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
;mov		dword [esi+_CreateFileA],CreateFileA
;mov		dword [esi+_VirtualProtect],VirtualProtect
;mov		dword [esi+_MessageBoxA],MessageBoxA
;mov		dword [esi+_WriteFile],WriteFile
;mov		dword [esi+_CloseHandle],CloseHandle
;mov		dword [esi+_wsprintfA],wsprintfA



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
lea		eax,[esi+_KiUserExceptionDispatcher]
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

%if 0
push	0
push_displacement	Title,ebx,esi
push_displacement	Message1,ebx,esi
push	0
call	[esi+_MessageBoxA]
%endif

pop		esi
popad
ret



;%define pExcept		ebp+8
;%define pFrame		ebp+0Ch
;%define pContext	ebp+10h
;%define pDispatch	ebp+14h

%define pExcept		ebp+8
%define pContext	ebp+0Ch

%macro test 0
get_displacement esi
push	dword [pContext]
push	dword [pExcept]
call	dword [esi+old_offset]
mov	dword [esp+_PUSHAD.regEax],eax

popad
pop	ebp
ret	8
%endmacro

_KiUserExceptionDispatcher:

;----------------------
; OK that's working!
;----------------------
;get_displacement eax
;jmp	[eax+old_offset]

push	ebp
mov	ebp,esp
pushad
;call	_TraceException

call	_HandleException ; 1 means that the thread can handle it
or	al,al
jz	.skip_handlers

get_displacement esi
mov	dword [ esi + seh_done],1
call	_TraceException

push	dword [pContext]
push	dword [pExcept]
call	dword [esi+old_offset]

mov	dword [esp+_PUSHAD.regEax],eax
jmp	.set_trap_flag

.skip_handlers:
get_displacement esi
mov	dword [ esi + seh_done],0
mov	dword [esp+_PUSHAD.regEax],1 ; !!! It's not 0 but 1 to return to call ZWContinue!
call	_TraceException


.set_trap_flag:
call	_SetTrapFlag
popad
pop	ebp
ret	8





;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
;Activate trap flag now
;
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
_SetTrapFlag:
get_displacement esi
mov		dword [esi+int1_enabled],0 ; reset flag
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Activate Trap Flag
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov		ebx,[pContext]
mov 	eax,[ebx+CONTEXT.regFlag]
and		eax,0x100
jz		.int1_not_enabled
mov		dword [esi + int1_enabled],1 ; remember that the int1 is coming from the proggy itself!
or 		dword [ebx+CONTEXT.regFlag],0x100
jmp		.end_trap_flag



.int1_not_enabled:
or 		dword [ebx+CONTEXT.regFlag],0x100

mov		eax,[pExcept]
cmp		dword[eax+EXCEPTION_RECORD.ExceptionCode],STATUS_SINGLE_STEP
jnz		.end_trap_flag

mov		ecx,dword [ebx+CONTEXT.regEip]
mov		cl,byte [ecx] ; OUCH here!
cmp		cl,0xF1 ; icebp
jnz		.end_trap_flag
mov		dword [esi + int1_enabled],1

.end_trap_flag:
ret



_TraceException:
get_displacement esi
mov		eax,[pContext]
mov		ebx,[pExcept]
mov		edx,dword [esi+handle_ntdll]
call 		trace
ret

_HandleException:
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Test after SEH.... do we have to actually mark the exception
; as OK?
;
; if the thread set itself the TFlag, we should let it handle it!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
get_displacement esi

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Exception here isn't a int1, and apparently the process did not set an int1 before...So it's probably ours :p
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Thread did set itself TFlag? (popf)
; Then let it handle exception itself!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------

mov		ebx,[pContext]
mov 		eax,[ebx+CONTEXT.regFlag]
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
test		eax,eax
jnz		.exception_handled

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
;The exception came from our own trap flag -> Process it!
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
mov	eax,0
ret

.exception_handled:
mov	eax,1
ret

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
; eax=pContext
; ebx=pExcept
; edx=handle
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------
trace:
pushad

get_displacement esi
push	esi

%if 1
push	edx
push	dword [esi+seh_done]
push	dword [ebx+EXCEPTION_RECORD.ExceptionCode]
push	dword [ebx+EXCEPTION_RECORD.ExceptionFlags]
push	dword [ebx+EXCEPTION_RECORD.pExceptionRecord]
push	dword [ebx+EXCEPTION_RECORD.ExceptionAddress]
push	dword [ebx+EXCEPTION_RECORD.NumberParameters]
push 	dword [eax+CONTEXT.regEip]

push_displacement	ntdll_hit,ebx,esi
push_displacement	txtbuf,ebx,esi
call 	[esi+_wsprintfA]
add		esp,9*04

mov		esi,[esp+4]

sub		ecx, ecx
lea		edi, [esi+txtbuf]
not		ecx
sub		al, al
cld
repne	scasb
not		ecx
lea		eax, [ecx-1]
pop		edx

push			0
push_displacement	bytes_written,ebx,esi
push			eax
push_displacement	txtbuf,ebx,esi
push			edx
call			[esi+_WriteFile]


%endif

%if 0
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

display_dword:
pushad
get_displacement esi
push		esi

push		eax
push_displacement	msg_dword,ebx,esi
push_displacement	txtbuf,ebx,esi
call 		[esi+_wsprintfA]
add		esp,3*04
mov		esi,[esp]

push	0
push_displacement	Title,ebx,esi
push_displacement	txtbuf,ebx,esi
push	0
call	[esi+_MessageBoxA]
pop	esi
popad
ret


patch_offset		dd 0x07C91EAF5
old_offset			dd 0x07C9477C1

handle_ntdll 		dd 0
bytes_written 		dd 0
int1_enabled 		dd 0
OldProtect		dd 0
seh_done		dd 0
Title 			db 'Alien patch',0
Message1 		db 'NtDll modified!',0
Message2 		db 'NtDll restored',0
filename_ntdll 		db 'ntdll.hex',0
no_seh			db 'We do NOT pass this exception to thread! [%X]',0
do_seh			db 'We DO pass this exception to thread! [%X]',0
ntdll_hit		db '0x%X: NumberParameters[%X] ExceptionAddress[%X] pExceptionRecord[%X] ExceptionFlags[%X] ExceptionCode[%X] seh[%X]',13,10,0
msg_dword		db 'Value of dword is %X',0


_VirtualProtect		dd 07C801AD0h
_CloseHandle		dd 07C809B47h
_WriteFile		dd 07C810D87h
_CreateFileA		dd 07C801A24h
_MessageBoxA		dd 07E3D058Ah
_wsprintfA		dd 07E39A8ADh
txtbuf      		resb     1024
