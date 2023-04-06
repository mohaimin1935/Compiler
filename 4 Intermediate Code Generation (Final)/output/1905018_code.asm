.MODEL SMALL
.STACK 1000H
.DATA
	CR EQU 0DH
	LF EQU 0AH
	NUMBER DB "00000$"
	w DW 0
	TEN DW 10
.CODE

main PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH BP
	MOV BP, SP
; var_declaration: line-3
	SUB SP, 2
	SUB SP, 20
; assignment: line-4
	MOV AX, 0
	MOV BX, AX
	SHL BX, 1
	ADD BX, 0
	NEG BX
	ADD BX, w
	MOV AX, 2
	NEG AX
	MOV [BX], AX
; assignment: line-5
	MOV AX, 0
	MOV BX, AX
	SHL BX, 1
	ADD BX, 4
	NEG BX
	ADD BX, BP
	MOV AX, 0
	MOV BX, AX
	SHL BX, 1
	ADD BX, 0
	NEG BX
	ADD BX, w
	MOV AX, [BX]
	MOV [BX], AX
; assignment: line-6
	MOV AX, 0
	MOV BX, AX
	SHL BX, 1
	ADD BX, 4
	NEG BX
	ADD BX, BP
	MOV AX, [BX]
	MOV [BP-2], AX
; print: line-7
	MOV AX, [BP-2]
	CALL print_output
	CALL new_line
; assignment: line-8
	MOV AX, 1
	MOV BX, AX
	SHL BX, 1
	ADD BX, 4
	NEG BX
	ADD BX, BP
	MOV AX, 0
	MOV BX, AX
	SHL BX, 1
	ADD BX, 0
	NEG BX
	ADD BX, w
	INC [BX]
	MOV [BX], AX
; assignment: line-9
	MOV AX, 1
	MOV BX, AX
	SHL BX, 1
	ADD BX, 4
	NEG BX
	ADD BX, BP
	MOV AX, [BX]
	MOV [BP-2], AX
; print: line-10
	MOV AX, [BP-2]
	CALL print_output
	CALL new_line
; assignment: line-11
	MOV AX, 0
	MOV BX, AX
	SHL BX, 1
	ADD BX, 0
	NEG BX
	ADD BX, w
	MOV AX, [BX]
	MOV [BP-2], AX
; print: line-12
	MOV AX, [BP-2]
	CALL print_output
	CALL new_line
; assignment: line-14
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 0
	MOV DX, AX
	POP AX
	ADD AX, DX
	MOV [BP-2], AX
; assignment: line-15
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 0
	MOV DX, AX
	POP AX
	SUB AX, DX
	MOV [BP-2], AX
; assignment: line-16
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 1
	MOV CX, AX
	POP AX
	CWD
	MUL CX
	MOV [BP-2], AX
; print: line-17
	MOV AX, [BP-2]
	CALL print_output
	CALL new_line
; if logic evaluation: line-19
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 0
	MOV DX, AX
	POP AX
	CMP AX, DX
	JG L13
	JMP L14
L13:
	MOV AX, 1
	JMP L15
L14:
	MOV AX, 0
L15:
	CMP AX, 0
	JE L11
L9:
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 10
	MOV DX, AX
	POP AX
	CMP AX, DX
	JL L16
	JMP L17
L16:
	MOV AX, 1
	JMP L18
L17:
	MOV AX, 0
L18:
	CMP AX, 0
	JNE L10
	JMP L11
L10:
	MOV AX, 1
	JMP L12
L11:
	MOV AX, 0
L12:
	CMP AX, 0
	JNE L6
L5:
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 0
	MOV DX, AX
	POP AX
	CMP AX, DX
	JL L23
	JMP L24
L23:
	MOV AX, 1
	JMP L25
L24:
	MOV AX, 0
L25:
	CMP AX, 0
	JE L21
L19:
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 10
	NEG AX
	MOV DX, AX
	POP AX
	CMP AX, DX
	JG L26
	JMP L27
L26:
	MOV AX, 1
	JMP L28
L27:
	MOV AX, 0
L28:
	CMP AX, 0
	JNE L20
	JMP L21
L20:
	MOV AX, 1
	JMP L22
L21:
	MOV AX, 0
L22:
	CMP AX, 0
	JNE L6
	JMP L7
L6:
	MOV AX, 1
	JMP L8
L7:
	MOV AX, 0
L8:
	CMP AX, 0
	JE L3
; if statement: line-19
L2:
; assignment: line-20
	MOV AX, 100
	MOV [BP-2], AX
	JMP L4
; else statement: line-19
L3:
; assignment: line-22
	MOV AX, 200
	MOV [BP-2], AX
L4:
; print: line-23
	MOV AX, [BP-2]
	CALL print_output
	CALL new_line
	MOV AX, 0
	JMP L1
L1:
	ADD SP, 22
	POP BP
	MOV AX, 4CH
	INT 21H
main ENDP
new_line PROC
	PUSH AX
	PUSH DX
	MOV AH, 2
	MOV DL, CR
	INT 21H
	MOV AH, 2
	MOV DL, LF
	INT 21H
	POP DX
	POP AX
	RET
new_line ENDP
print_output PROC
	PUSH AX
	PUSH CX
	PUSH DX
	PUSH SI
	LEA SI,NUMBER
	ADD SI,4
	CMP AX,0
	JNGE NEGATE
PRINT:
	XOR DX,DX
	DIV TEN
	MOV [SI],DL
	ADD [SI],'0'
	DEC SI
	CMP AX,0
	JNE PRINT
	INC SI
	LEA DX,SI
	MOV AH,9
	INT 21H
	POP SI
	POP DX
	POP CX
	POP AX
	RET
NEGATE:
	PUSH AX
	MOV AH,02H
	MOV DL,'-'
	INT 21H
	POP AX
	NEG AX
	JMP PRINT
print_output ENDP
END main
