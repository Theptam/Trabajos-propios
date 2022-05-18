;Francisco Manuel Pozón Ayuso.
DATA SEGMENT 
	INICIO DB "CONECTA 4", 13, 10, "$"	;Cabecera del juego
	FILA DB " | | | | | | |",13,10," | | | | | | |",13,10," | | | | | | |",13,10," | | | | | | |",13,10," | | | | | | |",13,10," | | | | | | |",13,10,"$" ;Mapa 
	JG1 DB "Turno del jugador 1:$"	;Texto para el turno del jugador 1
	JG2 DB "Turno del jugador 2:$"	;Texto para el turno del jugador 2
	ERRO DB "Error, recuerda que el número debe estar entre 1 y 7 ambos inclusive, y que no puede introducir una ficha en una columna llena", 13,10,"$" ;Texto para un posible error en la introducción del dato
	GX DB "EL jugador 1 es el ganador$"	;JG1 gana
	GO DB "El jugador 2 es el ganador$"	;JG2 gana
	CONSTA DB 2	;La utilizo para contar las posiciones del array sin las barritas
	SALTO DB "",13,10,"$"
	JUGADA DB (?)	;Donde se guarda la jugada
DATA ENDS

EXTRA SEGMENT

EXTRA ENDS

PILA SEGMENT STACK "STACK"
	DB 40h DUP (0)
ENDS PILA

CODE SEGMENT
	ASSUME cs: CODE, ds: DATA, es: EXTRA, ss: PILA
	
	START PROC FAR
			;Inicializo segmentos
			mov ax, DATA
			mov ds, ax
		
			mov ax, PILA
			mov ss, ax
		
			mov ax, EXTRA
			mov es, ax
			
			;Imprimo la cabecera del juego
			mov ah, 9
			mov dx, OFFSET INICIO
			int 21h
			call mapa	;Llamo al procedimiento que imprime el mapa
			call juego	;Llamo al procedimiento que hace el juego
			
	START ENDP
	
	mapa PROC	;Procedimiento que imprime el mapa
			mov ah, 9
			mov dx, OFFSET SALTO
			int 21h
			mov dx, OFFSET FILA
			int 21h
			ret

	mapa ENDP
	
	juego PROC ;Procedimiento del juego
			mov di, 0
			mov bh, 0
			mov dx, OFFSET JG1	;Imprimo el turno del JG1
			int 21h
			mov ah, 0ah
			mov dx, OFFSET JUGADA	;Leo por pantalla el dato de la columna a la que se introducirá la ficha
			mov JUGADA[0], 2	;Pongo máximo un carácter a la escritura (No implementado el comando de fin)
			int 21h
			mov bl, JUGADA[2]	;Muevo el dato a bl
			sub bl, 30h		;le resto 30h para pasarlo de ASCII a decimal
			dec bl			;Le resto 1 para utilizarlo en la matriz (la matriz empieza en 0, pero las columnas en 1)
			cmp bl, 0		;Si es menor que 0 (Dato introducido menor que 1) Informa de error 
			jl info
			cmp bl, 6		;Si es mayor que 6 (Dato introducido mayor que 7) Informa de error
			jg info
			mov ax, bx	
			mul CONSTA	;Multiplico por 2 el dato para no contabilizar las posiciones que son barritas
			mov bx, ax
			cmp FILA[0][bx], ' '	;Si la fila mas arriba en esa columna del array esta ocupada informa de error
			jne info
inse:		cmp di, 80		;Mientras que haya huecos debajo libres seguirá en el bucle
			je inse1
			add di, 16	;De 16 en 16 porque son 7 espacios, 7 barritas y el salto de linea (13, 10)
			cmp FILA[di][bx], ' '
			je inse
			mov FILA[di-16][bx], 'X'	;Si encuentra una casilla ocupada inserta la ficha en la fila superior
pt:			call comprobarX		;Llama al procedimiento que comprueba si ha ganado
			mov di, 0		
			mov bh, 0
			mov dx, OFFSET JG2	;Turno del JG2
			int 21h
			mov ah, 0ah
			mov dx, OFFSET JUGADA	;Lee el dato e inserta la ficha con un proceso análogo al JG1
			mov JUGADA[0], 2
			int 21h
			mov bl, JUGADA[2]
			sub bl, 30h
			dec bl
			cmp bl, 0
			jl info
			cmp bl, 6
			jg info
			mov ax, bx
			mul CONSTA
			mov bx, ax
			cmp FILA[0][bx], ' '
			jne info
insa:		cmp di, 80
			je inse2
			add di, 16
			cmp FILA[di][bx], ' '
			je insa
			mov FILA[di-16][bx], 'O'
py:			call comprobarO		;LLamo al procedimiento que comprueba si ha ganado
			
info:		mov ah, 9
			mov dx, OFFSET ERRO	;Imprime los posibles errores por pantalla
			int 21h
			jmp juego	;Vuelve al procedimiento juego para que vuelva a pedirle el dato
			
inse1:		mov FILA[di][bx], 'X'	;Aquí entrará cuando hayamos llegado a la fila de más abajo sin encontrarnos fichas a la hora de insertar, e insertará en esta
			add di, 16
			jmp pt		;Salta donde se llama al procedimiento que comprueba si ha ganado

inse2:		mov FILA[di][bx], 'O'	;Análogo a inse1 pero con el JG2
			add di, 16
			jmp py
			
			
			
			
	juego ENDP
	
	comprobarX PROC	;Procedimiento que comprueba si el JG1 es ganador
			mov ax, 0
			jmp h
sum1:		inc si	;Se ha encontrado a la izquieda, incrementamos contador y pasamos a comprbar la casilla de su izquierda
			sub bx, 2
			jmp comp_hi
sum2:		inc si	;Se ha encontrado a la derecha, incrementamos contador y pasamos a comprbar la casilla de su derecha
			add bx, 2
			jmp comp_hd
sum3:		sub di, 16	;Se ha encontrado arriba, incrementamos contador y pasamos a comprbar la casilla de arriba
			inc si
			jmp comp_va
sum4:		add di, 16	;Se ha encontrado abajo, incrementamos contador y pasamos a comprbar la casilla de abajo
			inc si
			jmp comp_vb
h:			mov dx, bx	;Guardamos el dato de la columna en dx
			mov si, 0	;Esta variable será la que me diga si ha ganado o no
			sub di, 16	
			mov cx, di	;Guardamos la fila en cx
comp_hi:	cmp si, 3	;Comprobamos la horizontal por la izquierda 
			jne m	;Si no es 3 si (4 en raya, las 3 más la que se ha insertado) salta
			call mapa	;Si es ganador imprime el mapa con la ficha nueva y llama al procedimiento que le proclama vencedor
			call ganadorX
			ret
m:			cmp bx, 0	;si estamos a la izquierda no puede haber fichas a nuestra izquierda asi que no comprobamos
			je term1
			cmp FILA[di][bx-2], 'X'	;Comprobamos si la casilla de nuestra izquierda tiene una ficha nuestra
			je sum1	;Si es así saltamos
term1:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov di, cx
comp_hd:	cmp si, 3	;Comprobamos por la derecha
			je ganaX	
			cmp bx, 14	;Si estamos a la derecha del todo salta
			je term2
			cmp FILA[di][bx+2], 'X'	;Comprobamos si la casilla de nuestra derecha tiene una ficha nuestra
			je sum2	;Si es así saltamos
term2:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov si, 0	;Reseteamos si porque la linea horizontal no tiene 4 seguidas
			mov di, cx	
comp_va:	cmp si, 3	;Comprobamos hacia arriba
			je ganaX
			cmp di, 0	;Si estamos arriba saltamos
			je term3
			cmp FILA[di-16][bx], 'X'	;Comprobamos si la casilla de arriba tiene una ficha nuestra
			je sum3	;Si es así saltamos
term3:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov di, cx
comp_vb:	cmp si, 3	;Comprobamos hacia abajo
			je ganaX
			cmp di, 80	;Si estamos abajo saltamos
			je term4
			cmp FILA[di+16][bx], 'X'	;Comprobamos si la casilla de abajo tiene una ficha nuestra
			je sum4	;Si es así saltamos
term4:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov si, 0	;Reseteamos si porque la linea vertical no tiene 4 seguidas
			mov di, cx
comp_dai:	cmp si, 3	;Comprobamos diagonal arriba izquierda
			je ganaX
			cmp di, 0	;Si estamos arriba o a la izquierda saltamos
			je term5
			cmp bx, 0
			je term5
			cmp FILA[di-16][bx-2], 'X'	;Comprobamos si la casilla de arriba a la izquierda tiene una ficha nuestra
			je sum5	;Si es así saltamos
term5:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov di, cx
comp_dabi:	cmp si, 3	;Comprobamos diagonal abajo izquierda
			je ganaX
			cmp di, 80	;Si estamos abajo o a la izquierda salta
			je term6
			cmp bx, 0
			je term6
			cmp FILA[di+16][bx-2], 'X'	;Comprobamos si la casilla de abajo a la izquierda tiene una ficha nuestra
			je sum6	;Si es así saltamos
term6:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov si, 0	;Reseteamos si porque la linea diagonal ascendente de izquierda a derecha no tiene 4 seguidas
			mov di, cx
comp_dad:	cmp si, 3	;Comprobamos la diagonal arriba a la derecha
			jne l		;Si no es ganador salta
ganaX:		call mapa	;Si es ganador imprime el mapa y salta al procedimiento que le proclama como ganador
			call ganadorX
			ret
l:			cmp di, 0	;Si estamos arriba o a la derecha salta
			je term7	
			cmp bx, 14
			je term7
			cmp FILA[di-16][bx+2], 'X'	;Comprobamos si la casilla de arriba a la derecha tiene una ficha nuestra
			je sum7	;Si es así saltamos
term7:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov di, cx
comp_dabd:	cmp si, 3	;Comprobamos diagonal abajo a la derecha
			je ganaX
			cmp di, 80	;Si estamos a la derecha o abajo salta
			je term8
			cmp bx, 14
			je term8
			cmp FILA[di+16][bx+2],'X'	;Comprobamos si la casilla de abajo a la derecha tiene una ficha nuestra
			je sum8	;Si es así saltamos	
term8:		mov bx, dx	;Si no, recuperamos el valor de bx y di
			mov si, 0	;Reseteamos si porque la linea diagonal ascendente de derecha a izquierda no tiene 4 seguidas
			mov di, cx
			call mapa	;Imprimimos el mapa y volvemos a juego
			ret

sum5:		sub di, 16	;Se ha encontrado arriba a la izquierda, incrementamos contador y pasamos a comprbar la casilla de arriba a la izquierda
			sub bx, 2
			inc si
			jmp comp_dai

sum6:		add di, 16	;Se ha encontrado abajo a la izquierda, incrementamos contador y pasamos a comprbar la casilla de abajo a la izquierda
			sub bx, 2
			inc si
			jmp comp_dabi
			
sum7:		sub di, 16	;Se ha encontrado arriba a la derecha, incrementamos contador y pasamos a comprbar la casilla de arriba a la derecha
			add bx, 2
			inc si
			jmp comp_dad

sum8:		add di, 16	;Se ha encontrado abajo a la derecha, incrementamos contador y pasamos a comprbar la casilla de abajo a la derecha
			add bx, 2
			inc si
			jmp comp_dabd
			
	comprobarX ENDP
	
	comprobarO PROC	;Procedimiento que comprueba si el jugador 2 es ganador (Sin comentar, análogo al JG1)
			mov ax, 0
			jmp p
sum1O:		inc si
			sub bx, 2
			jmp comp_hiO
sum2O:		inc si
			add bx, 2
			jmp comp_hdO
sum3O:		sub di, 16
			inc si
			jmp comp_vaO

sum4O:		add di, 16
			inc si
			jmp comp_vbO
p:			mov dx, bx
			mov si, 0
			sub di, 16
			mov cx, di
comp_hiO:	cmp si, 3
			jne n
			call mapa
			call ganadorO
			ret
n:			cmp bx, 0
			je term1O
			cmp FILA[di][bx-2], 'O'
			je sum1O
term1O:		mov bx, dx
			mov di, cx
comp_hdO:	cmp si, 3
			je ganaO
			cmp bx, 14
			je term2O
			cmp FILA[di][bx+2], 'O'
			je sum2O
term2O:		mov bx, dx
			mov si, 0
			mov di, cx
comp_vaO:	cmp si, 3
			je ganaO
			cmp di, 0
			je term3O
			cmp FILA[di-16][bx], 'O'
			je sum3O
term3O:		mov bx, dx
			mov di, cx
comp_vbO:	cmp si, 3
			je ganaO
			cmp di, 80
			je term4O
			cmp FILA[di+16][bx], 'O'
			je sum4O
term4O:		mov bx, dx
			mov si, 0
			mov di, cx
comp_daiO:	cmp si, 3
			je ganaO
			cmp di, 0
			je term5O
			cmp bx, 0
			je term5O
			cmp FILA[di-16][bx-2], 'O'
			je sum5O
term5O:		mov bx, dx
			mov di, cx
comp_dabiO:	cmp si, 3
			je ganaO
			cmp di, 80
			je term6O
			cmp bx, 14
			je term6O
			cmp FILA[di+16][bx-2], 'O'
			je sum6O
term6O:		mov bx, dx
			mov si, 0
			mov di, cx
comp_dadO:	cmp si, 3
			jne ll
ganaO:		call mapa
			call ganadorO
			ret
ll:			cmp di, 0
			je term7O
			cmp bx, 14
			je term7O
			cmp FILA[di-16][bx+2], 'O'
			je sum7O
term7O:		mov bx, dx
			mov di, cx
comp_dabdO:	cmp si, 3
			je ganaO
			cmp di, 80
			je term8O
			cmp bx, 0
			je term8O
			cmp FILA[di+16][bx+2],'O'
			je sum8O
term8O:		mov bx, dx
			mov si, 0
			mov di, cx
			call mapa	;Al terminar sin encontrar ganador se imprime el mapa y se sigue jugando
			jmp juego


sum5O:		sub di, 16
			sub bx, 2
			inc si
			jmp comp_daiO

sum6O:		add di, 16
			sub bx, 2
			inc si
			jmp comp_dabiO
			
sum7O:		sub di, 16
			add bx, 2
			inc si
			jmp comp_dadO

sum8O:		add di, 16
			add bx, 2
			inc si
			jmp comp_dabdO
			
	comprobarO ENDP
	
		ganadorX PROC 	;Procedimiento que proclama ganador al JG1
	
			mov ah, 9
			mov dx, OFFSET GX	;Imprimimos que el JG1 ganó y acaba el juego
			int 21h
			mov ax, 4c00h
			int 21h
	ganadorX ENDP
	
	ganadorO PROC	;Procedimiento que proclama ganador al JG2
	
			mov ah, 9
			mov dx, OFFSET GO	;Imprimimos que el JG2 ganó y acaba el juego
			int 21h
			mov ax, 4c00h
			int 21h
	ganadorO ENDP
	
	CODE ENDS
	END START


	mapa ENDP
			
		