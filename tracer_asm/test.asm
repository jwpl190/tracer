%include "WIN32N.INC"

bits  32


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
push 	byte 0
call 	GetModuleHandleA
mov 	[handle],eax

push 	seh1
push 	dword [fs:0]
mov	dword [fs:0],esp 

;int	3
;nop
;nop
;int	3
;nop
;nop
;int	3
xor	eax,eax
pushf
or	dword [esp],0x100
;popf
int 3


push 	0
push 	Title
push 	Finish
push 	0
call 	MessageBoxA

pop		dword [fs:0]
add		esp,4h

push 	dword [handle]
call 	ExitProcess
ret



seh1:
%define pExcept		ebp+8
%define pFrame		ebp+0Ch
%define pContext	ebp+10h
%define pDispatch	ebp+14h

push	ebp
mov		ebp,esp

mov	eax,[pExcept]
cmp 	dword[eax+EXCEPTION_RECORD.ExceptionCode],STATUS_BREAKPOINT
jnz 	.set_trace
mov	eax,[pContext]
;add 	dword [eax+CONTEXT.regEip],1

.set_trace:
mov	eax,[pContext]
;or	dword [eax+CONTEXT.regFlag],0x100
mov	eax,EXCEPTION_CONTINUABLE

pushad
;mov	edx,[fs:018h]
;mov	edx,dword [edx+024h]
push	eax
mov	eax,[pExcept]
push	dword[eax+EXCEPTION_RECORD.ExceptionCode]
mov	eax,[pContext]
push	dword [eax+CONTEXT.regEip]
push	MessageSEH1
push	txtbuf
call	wsprintfA

add	esp,4*5

push 	0
push 	Title
push 	txtbuf
push 	0
call 	MessageBoxA
popad

pop	ebp
ret












%if 0
seh2:
push	ebp
mov		ebp,esp

pushad

mov	edx,[fs:018h]
mov	edx,dword [edx+024h]

push	edx
push	MessageSEH2
push	txtbuf
call	wsprintfA

add	esp,4*3

push 	0
push 	Title
push 	txtbuf
push 	0
call 	MessageBoxA

popad

mov	eax,[pExcept]
cmp 	dword[eax+EXCEPTION_RECORD.ExceptionCode],STATUS_BREAKPOINT
jnz 	.set_trace
mov	eax,[pContext]
;add 	dword [eax+CONTEXT.regEip],1

.set_trace:
mov	eax,[pContext]
;or	dword [eax+CONTEXT.regFlag],0x100
mov	eax,EXCEPTION_CONTINUABLE

pop	ebp
ret
%endif


[segment data public]
Title 				db 'Alien patch',0

ntdll_hit			db '0x%X: NumberParameters[%X] ExceptionAddress[%X] pExceptionRecord[%X] ExceptionFlags[%X] ExceptionCode[%X]',13,10,0

handle 	 			dd 0
Finish				db 'Finished',0
MessageSEH1			db 'Inside first  seh %X %X %X',0
MessageSEH2			db 'Inside second seh %X',0

section  .bss  use32
txtbuf      		resb     1024