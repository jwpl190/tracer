// pumt.cpp : Defines the entry point for the DLL application.
//

#include "stdafx.h"
#include "pumt.h"
#include <string>
#include "winternl.h"

#define _CRT_SECURE_NO_WARNINGS

#ifdef _MANAGED
#pragma managed(push, off)
#endif

HANDLE		TraceHandle;
DWORD		TribIndex;
FARPROC		ExceptionDispatcher;
LONG		uid;


#define		KiUserExceptionDispatcher_start	0x7C91EAF0
#define		KiUserExceptionDispatcher_end	0x7C91EB35


#define MAX_REENTRANT	10
typedef struct	_TRIB
{
	BYTE ProcessNextInterrupt;
	BYTE SkipHook;
}TRIB,* PTRIB;



TRIB trib[MAX_REENTRANT];

typedef BOOLEAN (NTAPI *PrototypeRtlDispatchException)(PEXCEPTION_RECORD ExceptionRecord,PCONTEXT Context);
PrototypeRtlDispatchException		OldRtlDispatchException;

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
					 )
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		InstallHook();
		break;
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		break;
	case DLL_PROCESS_DETACH:
		RemoveHook();
		break;
	}
    return TRUE;
}

#ifdef _MANAGED
#pragma managed(pop)
#endif

// This is an example of an exported variable
PUMT_API int npumt=0;

int RemoveHook(void)
{
	CloseHandle(TraceHandle);
	return 0;
}

int InstallHook(void)
{
	HINSTANCE	ntdll;
	DWORD		OldProtect;
	CHAR		buffer[1024];

	//
	// Patch: Get function addr
	//
	ntdll=LoadLibrary("ntdll.dll");
	if( NULL == ntdll)
	{
		return FALSE;
	}

	ExceptionDispatcher=GetProcAddress(ntdll,"KiUserExceptionDispatcher");
	if( NULL == ExceptionDispatcher)
	{
		return FALSE;
	}
	FreeLibrary(ntdll);

	if( (FARPROC) 0x7C91EAEC != ExceptionDispatcher)
	{
		MessageBox(0,"ExceptionDispatcher not at current know address","Error",MB_OK);
		return 1;
	}
	
	VirtualProtect(ExceptionDispatcher,40,PAGE_EXECUTE_READWRITE,&OldProtect);

	//
	// TODO find to the first "call" met in ExceptionDispatcher !
	//

	OldRtlDispatchException = (PrototypeRtlDispatchException)0x7C9477C1;
	*((DWORD*)0x07C91EAF6) = (DWORD)&_RtlDispatchException - (DWORD)0x07C91EAF5 - 5 ;

	VirtualProtect(ExceptionDispatcher,40,OldProtect,&OldProtect);

	//
	//	Create File
	//
	GetModuleFileName(NULL,buffer,255);
	strcat(buffer,".pul");

	TraceHandle = CreateFile(buffer,GENERIC_WRITE,NULL,NULL,CREATE_ALWAYS,NULL,NULL);
	if( NULL == TraceHandle)
	{
		return 1;
	}	

	LogInformation("##################################\n");
	LogInformation("######Pulsar Usermode Tracer######\n");
	LogInformation("##################################\n");
	sprintf(buffer,"#_RtlDispatchException at: [%X]]\n",(DWORD)InstallHook);
	LogInformation(buffer);
	LogInformation("#FileName: [");
	GetModuleFileName(NULL,buffer,255);
	LogInformation(buffer);
	LogInformation("]\n");

	if(IDYES == MessageBox(NULL,"Let process handle first interrupt?","Pumt",MB_YESNO))
		trib[0].ProcessNextInterrupt=1;
	else
		trib[0].ProcessNextInterrupt=0;
	sprintf(buffer,"#Let process handle first interrupt?: [%X]\n",trib[0].ProcessNextInterrupt);
	LogInformation(buffer);

	trib[0].SkipHook=0;
	TribIndex=0;
	uid=0;
}

void LogInformation(CHAR* str)
{
	DWORD nb_written;
	WriteFile(TraceHandle,str,strlen(str),&nb_written,0);
}

BOOLEAN
NTAPI
HitFilter(IN PEXCEPTION_RECORD	ExceptionRecord,
					  IN PCONTEXT  	Context)
{
	if(Context->Eip > 0x400000 && Context->Eip < 0x70000000)
		return TRUE;
	else
		return FALSE;
}

DWORD 
FilterSelfExceptionHandler(	IN PEXCEPTION_POINTERS ExceptionPointers,DWORD * trib_index) 
{ 
	CHAR buffer[30];
	if(	*trib_index == TribIndex 
		&& ExceptionPointers->ExceptionRecord->ExceptionCode == STATUS_SINGLE_STEP) // We are dispatching our own exception!
	{
		TribIndex--;
		//sprintf(buffer,"Previous TribIndex :%X",*trib_index);
		//LogInformation(buffer);
		(*trib_index)--;
		//sprintf(buffer,":%X\n",*trib_index);
		//LogInformation(buffer);

		trib[*trib_index].ProcessNextInterrupt=0;
	}
	//else
	//{
	//	LogInformation("Another SEH\n");
	//}
	return EXCEPTION_EXECUTE_HANDLER;
} 

BOOLEAN
NTAPI
_RtlDispatchException(IN PEXCEPTION_RECORD	ExceptionRecord,
					  IN PCONTEXT  	Context)
{
	CHAR	buffer[512];
	CHAR	buffer2[255];
	PTEB	teb;
	BOOLEAN result;
	DWORD	index; // Use Local copy, or that would hurt us in case of reentrancy!

	uid++;

	index = TribIndex;
	sprintf(buffer,"%X:%X:%X:%X:",uid,TribIndex,trib[index].SkipHook,trib[index].ProcessNextInterrupt);

	// If the process doesnt single step itself it's SEH, dont do it! That may cause problems!
	if((Context->Eip == KiUserExceptionDispatcher_start ) && ExceptionRecord->ExceptionCode == STATUS_SINGLE_STEP )
	{
		memcpy(&trib[index+1],&trib[index],sizeof(TRIB));
		index=++TribIndex;

		if(index >= MAX_REENTRANT)
		{
			strcat(buffer,"ERROR: Cannot trace with rentrance lvl > MAX_REENTRANT\n");
			LogInformation(buffer);
			return OldRtlDispatchException(ExceptionRecord,Context);
		}
	}

	if(trib[index].SkipHook)
	{

		//sprintf(buffer2,"skipping hook %X\n",index);
		//strcat(buffer,buffer2);
		//LogInformation(buffer);
		return OldRtlDispatchException(ExceptionRecord,Context);
	}

	//teb=NtCurrentTeb();

	if( trib[index].ProcessNextInterrupt || ExceptionRecord->ExceptionCode != STATUS_SINGLE_STEP )
	{
		if(HitFilter(ExceptionRecord,Context))
		{
			sprintf(buffer2,"%X:%X:%X:%X:Y\n",Context->Eip,ExceptionRecord->ExceptionCode,trib[index].SkipHook,index);
			strcat(buffer,buffer2);
		}
		result=OldRtlDispatchException(ExceptionRecord,Context);
	}
	else
	{
		result=1; // Exception Handled!
		if(HitFilter(ExceptionRecord,Context))
		{
			sprintf(buffer2,"%X:%X:%X:%X:N\n",Context->Eip,ExceptionRecord->ExceptionCode,trib[index].SkipHook,index);
			strcat(buffer,buffer2);
		}
	}

	trib[index].ProcessNextInterrupt=0;

	__try
	{
		trib[index].SkipHook=1; // Disable interrupts

		if( (ExceptionRecord->ExceptionCode==STATUS_SINGLE_STEP) && (*(BYTE*)Context->Eip) == 0xF1 )
			trib[index].ProcessNextInterrupt=1;
	}
	__except (FilterSelfExceptionHandler(GetExceptionInformation(),&index)) 
	{
		//sprintf(buffer,"in our own seh %X %X\n",trib[index].SkipHook,index);
		//LogInformation(buffer);
	}

	if(Context->EFlags & 0x100)
	{
		//sprintf(buffer2,"NI->Y for %X",index);
		//strcat(buffer,buffer2);	
		trib[index].ProcessNextInterrupt=1;
	}
	//strcat(buffer,"\n");
	LogInformation(buffer);

	trib[index].SkipHook=0; //Enable interrupts

	Context->EFlags |= 0x100;
	
	return result;
}

PUMT_API int nada(void)
{
	return 0;
}