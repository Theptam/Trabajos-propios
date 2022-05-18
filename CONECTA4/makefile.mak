all:	conecta.exe

conecta.exe: conecta.obj
	tlink /v conecta.obj
conecta.obj: conecta.asm
	tasm /zi conecta.asm