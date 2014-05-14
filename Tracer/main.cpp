#include <stdio.h>
#include "windows.h"
#include "winternl.h"

int backup;

//#define EOP_ADDRESS 0x0402581
#define EOP_ADDRESS 0x40D980
DWORD first_out;

void SaveInfo(HANDLE *hdl,DEBUG_EVENT *dbg)
{
	DWORD bytewritten;
	
	if(dbg->u.Exception.ExceptionRecord.ExceptionAddress<0x500000 && dbg->u.Exception.ExceptionRecord.ExceptionAddress>0x400000)
	{
		first_out=1;
		//instructions[instruction_index++]=dbg->u.Exception.ExceptionRecord.ExceptionAddress;
		WriteFile(*hdl,&(dbg->u.Exception.ExceptionRecord.ExceptionAddress),4,&bytewritten,0);
	}
	else if(first_out != 0)
	{
		//instructions[instruction_index++]=dbg->u.Exception.ExceptionRecord.ExceptionAddress;
		WriteFile(*hdl,&(dbg->u.Exception.ExceptionRecord.ExceptionAddress),4,&bytewritten,0);
		first_out=0;
	}

	//if(instruction_index == MAX_INSTRUCTION)
	//{
	//	WriteFile(*hdl,instructions,4*MAX_INSTRUCTION,&bytewritten,0);
	//	instruction_index=0;
	//	ZeroMemory(instruction_index, sizeof(instruction_index));
	//}
		
}


int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	CHAR buff[255];
	CHAR buff_mem[0x1000];
	int write;
	HANDLE hdl,hdl2;
	LPVOID temp=0,memory;
	IMAGE_NT_HEADERS32 *header;
	OPENFILENAME ofn;

	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	DEBUG_EVENT dbg_event;
	CONTEXT context;

	PLDR_MODULE ldr_module;

	/*
	TEB *teb;
	teb = NtCurrentTeb();
	ldr_module = (PLDR_MODULE) teb->Peb->LdrData->InLoadOrderModuleList.Flink;

	while( ldr_module != NULL )
	{
		sprintf(buff_mem,"%S: @:[%x] size:[%x]",ldr_module->BaseDllName.Buffer,ldr_module->BaseAddress,ldr_module->SizeOfImage);
		MessageBox(0,buff_mem,"Info",MB_OK);
		ldr_module = ldr_module->InLoadOrderModuleList.Flink;
	}*/



	ZeroMemory(&ofn, sizeof(ofn));
	ofn.lStructSize=sizeof(ofn);
	ofn.hwndOwner=NULL;
	ofn.lpstrFilter="Executable files (*.exe)\0*.exe\0All Files (*.*)\0*.*\0";
	ofn.lpstrFile = (LPSTR)buff;

	ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	//hdl=CreateFile((LPSTR)"Y:\\reverse\\list.hex",GENERIC_WRITE,0,NULL,CREATE_ALWAYS,NULL,NULL);

	ofn.lpstrFile[0] = '\0';
	ofn.nMaxFile = sizeof(buff);
	//ofn.lpstrFilter = "All\0*.*\0Text\0*.TXT\0";
	ofn.nFilterIndex = 1;
	ofn.lpstrFileTitle = NULL;
	ofn.nMaxFileTitle = 0;
	ofn.lpstrInitialDir = NULL;
	//ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;

	if(INVALID_HANDLE_VALUE==(hdl=CreateFile((LPSTR)"..\\tracer_asm\\load_dll",GENERIC_READ,0,NULL,OPEN_EXISTING,NULL,NULL)))
	{
		MessageBox(0,"Error ..\\tracer_asm\\load_dll not here","msg",MB_OK);
		return 1;
	}

	if(GetOpenFileName(&ofn)==TRUE)
	{
		GetStartupInfo(&si);
		if(! /*CreateProcess( (LPSTR)buff, 00, 00, 00, FALSE
							, DEBUG_PROCESS+DEBUG_ONLY_THIS_PROCESS
							, 00, 00, &si, &pi))*/
			 CreateProcess( (LPSTR)buff, 00, 00, 00, FALSE
							, CREATE_SUSPENDED
							, 00, 00, &si, &pi))
			MessageBox(NULL,"Error Creating the process\n","Info",MB_OK);
		else
		{
			int	size;
			size=GetFileSize(hdl,0);

			// Insert Alien
			memory=VirtualAllocEx(pi.hProcess,0,size+10,MEM_COMMIT | MEM_RESERVE,PAGE_EXECUTE_READWRITE);
			ReadFile(hdl,buff_mem,size,&write,0);
			WriteProcessMemory(pi.hProcess,memory,buff_mem,size,&write);
			CloseHandle(hdl);

			// CreateRemoteThread
			CreateRemoteThread(pi.hProcess,0,0,memory,NULL,0,0);
			Sleep(1000); // Let remotethread the time to install itself correctly :p
			if(IDOK == MessageBox(NULL,"Yes -> Trace ASAP\nNo  -> Trace after first exception","Info",MB_OKCANCEL))
			{
				context.ContextFlags=CONTEXT_CONTROL;
				GetThreadContext(pi.hThread,&context);
				context.EFlags|=0x100;
				SetThreadContext(pi.hThread,&context);
			}
			

			// Resume :)
			ResumeThread(pi.hThread);
			// Exit
			return 0;



















			first_out=1;
			while(1)
			{
				

				WaitForDebugEvent(&dbg_event,INFINITE);
				switch(dbg_event.dwDebugEventCode)
				{
					case EXIT_PROCESS_DEBUG_EVENT:
						MessageBox(0,"End of process","Info",MB_OK);
						return 0;
						break;
					case EXCEPTION_DEBUG_EVENT:
						SaveInfo(&hdl,&dbg_event);
						context.ContextFlags=CONTEXT_CONTROL;
						if(dbg_event.u.Exception.ExceptionRecord.ExceptionCode == EXCEPTION_BREAKPOINT)
						{
							if(dbg_event.u.Exception.ExceptionRecord.ExceptionAddress >= 0x7C000000)
							{
								// First event...
								// Create Memory + Insert alien + CreateRemoteThread on it!
								// Then detach from process!

								ReadProcessMemory(pi.hProcess,EOP_ADDRESS,&backup,4,&hdl2);
								write=0xCCCCCCCC;
								WriteProcessMemory(pi.hProcess,EOP_ADDRESS,&write,4,&hdl2);
							}
							else
							{
								WriteProcessMemory(pi.hProcess,EOP_ADDRESS,&backup,4,&hdl2);

								GetThreadContext(pi.hThread,&context);
								context.EFlags|=0x100;
								context.Eip-=1;
								SetThreadContext(pi.hThread,&context);
							}
						}

						if(dbg_event.u.Exception.ExceptionRecord.ExceptionCode == EXCEPTION_SINGLE_STEP )
						{
							GetThreadContext(pi.hThread,&context);
							context.EFlags|=0x100;
							SetThreadContext(pi.hThread,&context);
						}
						ContinueDebugEvent(dbg_event.dwProcessId,dbg_event.dwThreadId,DBG_CONTINUE);
						break;
					default:
						ContinueDebugEvent(dbg_event.dwProcessId,dbg_event.dwThreadId,DBG_EXCEPTION_NOT_HANDLED);
				}

			}
		}
		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);
	}
CloseHandle(hdl);	
}


