@rem set tools_home=Y:\Reverse\tools
set tools_home=Z:\Tools

%tools_home%\assembler\nasm\nasm-0.99.04\nasm -fobj tracer.asm
%tools_home%\linker\alink\alink -L %tools_home%\linker\alink\lib -oPE tracer win32.lib

%tools_home%\assembler\nasm\nasm-0.99.04\nasm -fobj test.asm
%tools_home%\linker\alink\alink -L %tools_home%\linker\alink\lib -oPE test win32.lib

%tools_home%\assembler\nasm\nasm-0.99.04\nasm -fbin tracer_included.asm
%tools_home%\assembler\nasm\nasm-0.99.04\nasm -fbin load_dll.asm