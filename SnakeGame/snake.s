.data
# Reservar suficiente espacio para el bitmap
bitmap: 	.space 	0x20000

# Mismo color pero diferentes direcciones por propositos de comparacion y control
snkUp:		.word	0x00F4B402	
snkDn:		.word	0x01F4B402	
snkLf:		.word	0x02F4B402	
snkRt:		.word	0x03F4B402	

# Coordenadas cartesianas inciales de la cabeza de la serpiente. Tomando el origen como la esquina superior izquierda
xPosi:		.word	27
yPosi:		.word	25

# Posicion literal de la cola
snkTail:	.word	3564

# Coordenadas cartesianas de la manzana
appX:		.word	13		
appY:		.word	24

# Cuaantos bloques y hacia donde se debe mover la serpiente
xSpd:			.word	0
ySpd:			.word	0





.text
start:
# Dibujar fondo
	la 	$t0, bitmap		# cargar en $t0 el bitmap
	li 	$t1, 1024		# $t1 = (512/8 * 256/8) = 2048 = i
	li 	$t2, 0x0080C3DF		# cargar color
bLoop:
	sw   	$t2, 0($t0)		# carga en la posicion correspondiente el color de fondo
	addi 	$t0, $t0, 4 		
	addi 	$t1, $t1, -1		
	bne 	$t1, 0, bLoop
	
	
	
# Dibujar marco
	li 	$t9, 0x00000000		# color de borde

	# borde superior
	la	$t0, bitmap
	li	$t1, 32			# $t1 = 512/8 = 64 = i 

drawTopBorder:
	sw	$t9, 0($t0)		
	addi	$t0, $t0, 4
	addi	$t1, $t1, -1
	bne	$t1, 0, drawTopBorder
	
	# borde derecho
	la	$t0, bitmap
	addi	$t0, $t0, 124		# Se suma 508 para que salte a la ultima unidad de cada fila (total - 4) => (512 - 4)
	li	$t1, 32			# $t1 = 256/8 = 32 = i

drawRightBorder:
	sw	$t9, 0($t0)		
	addi	$t0, $t0, 128		
	addi	$t1, $t1, -1	 
	bne	$t1, 0, drawRightBorder
		
	# borde inferior
	la	$t0, bitmap	
	addi	$t0, $t0, 3968		# Se suma 7936 para que salte a la ultima fila (total - 64 * 4) => (8192 - 256) = 7936
	li	$t1, 32			# $t1 = 512/8 = 64 = i

	drawBottomBorder:
	sw	$t9, 0($t0)		
	addi	$t0, $t0, 4
	addi	$t1, $t1, -1
	bne	$t1, 0, drawBottomBorder
	
	# borde izquierdo
	la	$t0, bitmap	
	li	$t1, 32 		# $t1 = 256/8 = 32 = i

drawLeftBorder:
	sw	$t9, 0($t0)		
	addi	$t0, $t0, 128		
	addi	$t1, $t1, -1		
	bne	$t1, 0, drawLeftBorder	
	
	
	
	
	
# Dibujar serpiente inicial
	la	$t0, bitmap	
	lw	$s1, snkTail		# cargar en $s1 la posicion de la cola
	lw	$s2, snkUp		# cargar en $s2 la direccion de la serpiente hacia arriba (que en realidad es un color)
	
	add	$t1, $s1, $t0		# $t1 = direccion base + direccion de la cola = direccion de la cola
	sw	$s2, 0($t1)		# dibujar la cola
	addi	$t1, $t1, -128		# $t1 = direccion cola - (64 * 4) = direccion de la cabeza cabeza
	sw	$s2, 0($t1)		# dibujar la cabeza
	
	
	
	
	
# Dibujar manzana inicial
	jal 	drawApple
	
	
	
	
	
gLoop:
	lw	$t9, 0xffff0004		# obtener keyboard input (ASCII)
	
	li	$a0, 100		# tiempo del delay en ms. = 100ms
	li	$v0, 32			# syscall code para sleep
	syscall
	
	# ASCII table
	# 119 -> w => arriba
	# 100 -> d => derecha
	# 115 -> s => abajo
	# 97  -> a => izquierda
	beq	$t9, 119, up
	beq	$t9, 100, right
	beq	$t9, 115, down
	beq	$t9, 97, left
	
	beq	$t9, 0, up		# Cuando el programa se prende por defecto va para arriba

up:
	lw	$s1, snkUp
	move	$a0, $s1
	jal	reRenderSnake
	
	# move the snake
	jal 	reRenderSnakeHeadPosition
	
	j	stopMove
right:
	lw	$s1, snkRt	
	move	$a0, $s1
	jal	reRenderSnake
	
	# move the snake
	jal 	reRenderSnakeHeadPosition

	j	stopMove	
down:
	lw	$s1, snkDn	
	move	$a0, $s1
	jal	reRenderSnake
	
	# move the snake
	jal 	reRenderSnakeHeadPosition
	
	j	stopMove
left:
	lw	$s1, snkLf
	move	$a0, $s1
	jal	reRenderSnake
	
	# move the snake
	jal 	reRenderSnakeHeadPosition
	
	j	stopMove 	

stopMove:
	j 	gLoop		# loop back to beginning
	
	
	
	
	
reRenderSnake:
	sw 	$ra, 0($sp)	# 4($sp) = $ra (donde debe devolverse despues del llamado reRenderSnake)
	
# Dibujar cabeza
	lw	$t0, xPosi		
	lw	$t1, yPosi		
	li	$t2, 32
	mul	$t3, $t1, $t2	
	add	$t3, $t3, $t0
	li	$t2, 4		
	mul	$t0, $t3, $t2
	
	la 	$t1, bitmap
	add	$t0, $t1, $t0		# $t0 = direccion base + direccion rel cabeza = direccion abs cabeza 
	lw	$t4, 0($t0)		# guardar en $t4 para comparar posteriormente (aqui se ve el proposito de por que tener 4 direcciones diferentes con el mismo color, es para posteriormente ver de que color era el bit de la cabeza antes de colorearlo para saber si choco con una manzana, el cuerpo o el borde)
	sw	$a0, 0($t0)		# cambiar el color de la cabeza (antes era o color del fondo, serpiente o borde)
	
# Settear velocidad
	# arriba?
	lw	$t2, snkUp			
	beq	$a0, $t2, setVelocityUp	
	# derecha?
	lw	$t2, snkRt			
	beq	$a0, $t2, setVelocityRight
	# abajo?
	lw	$t2, snkDn			
	beq	$a0, $t2, setVelocityDown	
	# izquierda?
	lw	$t2, snkLf			
	beq	$a0, $t2, setVelocityLeft	
	
setVelocityUp:
	li	$t5, -1
	sw	$zero, xSpd
	sw	$t5, ySpd
	j exitVelocitySet

setVelocityRight:
	li	$t5, 1		
	sw	$t5, xSpd
	sw	$zero, ySpd
	j exitVelocitySet
	
setVelocityDown:
	li	$t5, 1
	sw	$zero, xSpd
	sw	$t5, ySpd
	j exitVelocitySet
	
setVelocityLeft:
	li	$t5, -1
	sw	$t5, xSpd
	sw	$zero, ySpd
	j exitVelocitySet
	
exitVelocitySet:
# checkear color de cabeza
	li 	$t2, 0x00FFC0CB			# cargar color de manzana
	bne	$t2, $t4, headNotApple		# si el color de cabeza y el color de manzana no son iguales entonces no comio una manzana
	
	jal 	generateAppleCoordinates	# generar nuevas coordenadas de manzana
	jal	drawApple			# dibujar nueva manazana
	j	exitReRenderSnake
	
headNotApple:
	li	$t2, 0x0080C3DF			# cargar color de fondo
	beq	$t2, $t4, validHead	# si el color de cabeza es igual al color de fondo significa que no choco con el borde ni comio una manzana
	
	
	
	
	li 	$v0, 10				# Si choco con el borde pierde por lo que se acaba la ejecucion del programa
	syscall
	
validHead:
# Quitar la cola para simular el avance
	lw	$t0, snkTail
	la 	$t1, bitmap
	add	$t2, $t0, $t1		# t2 = direccion de base + direccion rel de snkTail = direccion abs snkTail
	li 	$t3, 0x0080C3DF		# cargar color de fondo
	lw	$t4, 0($t2)		# guardar que habia en snkTail antes de cambiar el color (en este caso es util para saber la direccion)
	sw	$t3, 0($t2)		# colorear la snkTail de color del fondo
	
# update new Tail
	# arriba?
	lw	$t5, snkUp			
	beq	$t5, $t4, setNextTailUp
	# derecha?
	lw	$t5, snkRt		
	beq	$t5, $t4, setNextTailRight
	# abajo?
	lw	$t5, snkDn		
	beq	$t5, $t4, setNextTailDown
	# izquierda?
	lw	$t5, snkLf		
	beq	$t5, $t4, setNextTailLeft
	
# el proposito de actualizarlo con el mismo color es porque lo que puede cambiar es la direccion 
setNextTailUp:
	addi	$t0, $t0, -128		
	sw	$t0, snkTail		
	j exitReRenderSnake
	
setNextTailRight:
	addi	$t0, $t0, 4
	sw	$t0, snkTail
	j exitReRenderSnake
	
setNextTailDown:
	addi	$t0, $t0, 128
	sw	$t0, snkTail
	j exitReRenderSnake
	
setNextTailLeft:
	addi	$t0, $t0, -4	
	sw	$t0, snkTail
	j exitReRenderSnake
	
exitReRenderSnake:
	lw 	$ra, 0($sp)	
	jr 	$ra
	
reRenderSnakeHeadPosition:
	sw 	$ra, ($sp)
	
	lw	$t3, xSpd	
	lw	$t4, ySpd	
	lw	$t5, xPosi	
	lw	$t6, yPosi	
	add	$t5, $t5, $t3	# calcular nueva posicion en x
	add	$t6, $t6, $t4	# calcular nueva posicion en y
	sw	$t5, xPosi
	sw	$t6, yPosi
	
	lw 	$ra, 0($sp)	
	jr 	$ra		

drawApple:
	li	$t9, 0x00FFC0CB
	
	lw	$t0, appX		
	lw	$t1, appY		
	li	$t2, 32
	mul	$t3, $t1, $t2		# Es un array por lo que bajar Y unidades en realidad es Y*64 debido a que debe recorrer 64 unidades (length de la row) para bajar de fila
	add	$t3, $t3, $t0		# Como ya bajo Y unidades, ahora solo hace falta sumarle X unidades para obtener las coordenadas deseadas
	li	$t2, 4
	mul	$t0, $t3, $t2		# Se debe multiplicar por 4 porque en arrays para ir al siguiente elemento se suman 4 en vez de 1
	
	la 	$t1, bitmap	
	add	$t0, $t0, $t1	
	sw	$t9, 0($t0)	
	
	jr 	$ra	

generateAppleCoordinates:
	addiu 	$sp, $sp, -8	
	sw 	$ra, 4($sp)	
	
reCalcRanNum:		
	li	$a1, 31		# el numero generado va a estar en el intervalo [0, 63[
	li	$v0, 42		# random number syscall code 
	syscall
	move	$t1, $a0	# coordenada en x random
	
	li	$a1, 31		# el numero generado va a estar en el intervalo [0, 31[
	li	$v0, 42	 
	syscall
	move	$t2, $a0	# coordenada en y random
	
	li	$t3, 31	
	mul	$t4, $t2, $t3
	add	$t4, $t4, $t1
	li	$t3, 4
	mul	$t4, $t3, $t4
	
	la 	$t0, bitmap	
	add	$t0, $t4, $t0	
	lw	$t5, 0($t0)
	
	li	$t6, 0x0080C3DF		# cargar color de fondo
	beq	$t5, $t6, validApple	# esto se hace para confi
	j reCalcRanNum

validApple:
	sw	$t1, appX
	sw	$t2, appY

	lw 	$ra, 4($sp)	
	addiu 	$sp, $sp, 8	
	jr 	$ra