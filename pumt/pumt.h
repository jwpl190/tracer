// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the PUMT_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// PUMT_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef PUMT_EXPORTS
#define PUMT_API __declspec(dllexport)
#else
#define PUMT_API __declspec(dllimport)
#endif

extern PUMT_API int npumt;



PUMT_API int nada(void);
BOOLEAN NTAPI _RtlDispatchException	(IN PEXCEPTION_RECORD	ExceptionRecord, IN PCONTEXT  	Context);

// private
int RemoveHook(void);
int InstallHook(void);
void LogInformation(CHAR* str);
