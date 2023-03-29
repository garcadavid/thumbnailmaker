; ***********************************************************************
;  Data declarations
;	Note, the error message strings should NOT be changed.
;	All other variables may changed or ignored...

section	.data

; -----
;  Define standard constants.

LF		equ	10			; line feed
NULL		equ	0			; end of string
SPACE		equ	0x20			; space

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; Successful operation
NOSUCCESS	equ	1			; Unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
SYS_close	equ	3			; system call code for file close
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

O_CREAT		equ	0x40
O_TRUNC		equ	0x200
O_APPEND	equ	0x400

O_RDONLY	equ	000000q			; file permission - read only
O_WRONLY	equ	000001q			; file permission - write only
O_RDWR		equ	000002q			; file permission - read and write

S_IRUSR		equ	00400q
S_IWUSR		equ	00200q
S_IXUSR		equ	00100q

; -----
;  Define program specific constants.

MIN_FILE_LEN	equ	5

; buffer size (part A) - DO NOT CHANGE THE NEXT LINE.
BUFF_SIZE	equ 750000

; -----
;  Variables for getImageFileName() function.

eof		db	FALSE

usageMsg	db	"Usage: ./makeThumb <inputFile.bmp> "
		db	"<outputFile.bmp>", LF, NULL
errIncomplete	db	"Error, incomplete command line arguments.", LF, NULL
errExtra	db	"Error, too many command line arguments.", LF, NULL
errReadName	db	"Error, invalid source file name.  Must be '.bmp' file.", LF, NULL
errWriteName	db	"Error, invalid output file name.  Must be '.bmp' file.", LF, NULL
errReadFile	db	"Error, unable to open input file.", LF, NULL
errWriteFile	db	"Error, unable to open output file.", LF, NULL

; -----
;  Variables for setImageInfo() function.

HEADER_SIZE	equ	138

errReadHdr	db	"Error, unable to read header from source image file."
		db	LF, NULL
errFileType	db	"Error, invalid file signature.", LF, NULL
errDepth	db	"Error, unsupported color depth.  Must be 24-bit color."
		db	LF, NULL
errCompType	db	"Error, only non-compressed images are supported."
		db	LF, NULL
errSize		db	"Error, bitmap block size inconsistent.", LF, NULL
errWriteHdr	db	"Error, unable to write header to output image file.", LF,
		db	"Program terminated.", LF, NULL

; -----
;  Variables for readRow() function.

buffMax		dq	BUFF_SIZE
curr		dq	BUFF_SIZE
wasEOF		db	FALSE
pixelCount	dq	0

errRead		db	"Error, reading from source image file.", LF,
		db	"Program terminated.", LF, NULL

three  dd 3
index  dq 0

; -----
;  Variables for writeRow() function.

errWrite	db	"Error, writting to output image file.", LF,
		db	"Program terminated.", LF, NULL

pixelCount2 dq 0


; ------------------------------------------------------------------------
;  Unitialized data

section	.bss

buffer		resb	BUFF_SIZE
header		resb	HEADER_SIZE


; ***************************************************************

section	.text

; ***************************************************************
;  Routine to get image file names (from command line)
;	Verify files by atemptting to open the files (to make
;	sure they are valid and available).

;  Command Line format:
;	./makeThumb <inputFileName> <outputFileName>

; -----
;  Arguments:
;	- argc (value)
;	- argv table (address)
;	- read file descriptor (address)
;	- write file descriptor (address)
;  Returns:
;	read file descriptor (via reference)
;	write file descriptor (via reference)
;	TRUE or FALSE

global getfilename
getfilename:

	push rbp
	mov rbp, rsp

	mov rbx, rdi 

	check_errUsage:
		cmp rbx, 1
		je is_errUsage

	check_errIncomplete:
		cmp rbx, 3
		jb is_errIncomplete

	check_errExtra:
		cmp rbx, 3
		ja is_errExtra

	check_errReadName:
		mov r10, qword[rsi+8] 
		cmp byte[r10], "."
		je is_errUsage              ; check if the file is only .bmp and no name

		ignore1:
			inc r10
			cmp byte[r10], "."
			jne ignore1

		inc r10						; check if file contains bmp
		cmp byte[r10], "b"
		jne is_errReadName
			inc r10
			cmp byte[r10], "m"
			jne is_errReadName
				inc r10
				cmp byte[r10], "p"
				jne is_errReadName
					inc r10
					cmp byte[r10], NULL
					jne is_errReadName

	check_errWriteName:
		mov r10, qword[rsi+16]
		cmp byte[r10], "."
		je is_errUsage              ; check if the file is only .bmp and no name

		ignore2:
			inc r10
			cmp byte[r10], "."
			jne ignore2

		inc r10						; check if file contains bmp
		cmp byte[r10], "b"
		jne is_errWriteName
			inc r10
			cmp byte[r10], "m"
			jne is_errWriteName
				inc r10
				cmp byte[r10], "p"
				jne is_errWriteName
					inc r10
					cmp byte[r10], NULL
					jne is_errWriteName


	mov r10, rsi
	check_errReadFile:
		mov rax, SYS_open
		mov rdi, qword[r10+8]
		push rcx					; I pushed it because I noticed that
		mov rsi, O_RDONLY           ; rcx changes when read only
		syscall

		cmp rax, 0
		jl is_errReadFile

		mov qword[rdx], rax

	check_errWriteFile:
		mov rax, SYS_creat
		mov rdi, qword[r10+16]
		mov rsi, S_IRUSR | S_IWUSR
		syscall

		cmp rax, 0
		jl is_errWriteFile
		
		pop rcx
		mov qword[rcx], rax
	
	is_SUCCESS:
		mov rax, TRUE
		jmp doReturn

	is_errUsage:
		lea rdi, byte[usageMsg]
		call printString
		mov rax, FALSE
		jmp doReturn

	is_errIncomplete:
		lea rdi, byte[errIncomplete]
		call printString
		mov rax, FALSE
		jmp doReturn

	is_errExtra:
		lea rdi, byte[errExtra]
		call printString
		mov rax, FALSE
		jmp doReturn

	is_errReadName:
		lea rdi, byte[errReadName]
		call printString
		mov rax, FALSE
		jmp doReturn
	
	is_errWriteName:
		lea rdi, byte[errWriteName]
		call printString
		mov rax, FALSE
		jmp doReturn

	is_errReadFile:
		lea rdi, byte[errReadFile]
		call printString
		mov rax, FALSE
		jmp doReturn
	
	is_errWriteFile:
		lea rdi, byte[errWriteFile]
		call printString
		mov rax, FALSE
		jmp doReturn

	doReturn:
		mov rax, rax

	mov rsp, rbp
	pop rbp
ret


; ***************************************************************
;  Read, verify, and set header information

;  HLL Call:
;	bool = setImageInfo(readFileDesc, writeFileDesc,
;		&picWidth, &picHeight, thumbWidth, thumbHeight)

;  If correct, also modifies header information and writes modified
;  header information to output file (i.e., thumbnail file).

; -----
;  2 -> BM				(+0)
;  4 file size				(+2)
;  4 skip				(+6)
;  4 header size			(+10)
;  4 skip				(+14)
;  4 width				(+18)
;  4 height				(+22)
;  2 skip				(+26)
;  2 depth (16/24/32)			(+28)
;  4 compression method code		(+30)
;  4 bytes of pixel data		(+34)
;  skip remaing header entries

; -----
;   Arguments:
;	- read file descriptor (value)
;	- write file descriptor (value)
;	- old image width (address)
;	- old image height (address)
;	- new image width (value)
;	- new image height (value)

;  Returns:
;	old image width (via reference)
;	old image height (via reference)
;	TRUE or FALSE

global setheader
setheader:

	push rbp
	mov rbp, rsp

	push rdi
	push rsi
	push rdx
	push rcx						; im also pushing rcx because it changes for some reason

	check_errReadHdr:
		mov rax, SYS_read
		mov rdi, rdi
		mov rsi, header
		mov rdx, HEADER_SIZE		; read header size much
		syscall

		cmp rax, 0
		jl is_errReadHdr
	
		cmp rax, HEADER_SIZE
		jne is_errReadHdr

	pop rcx
	pop rdx
	pop rsi
	pop rdi

	check_errFileType:
		mov rbx, header
		cmp word[rbx], "BM"
		jne is_errFileType

	check_errDepth:
		mov rbx, header
		cmp word[rbx+28], 24
		jne is_errDepth
		
	check_errCompType:
		mov rbx, header
		cmp dword[rbx+30], 0
		jne is_errCompType

	check_errSize:
		mov rbx, header

		mov eax, dword[rbx+34]      ; size of image
		add eax, dword[rbx+10]		; size of header

		cmp eax, dword[rbx+2]
		jne is_errSize

	updateHeader:
		mov rax, 0
		mov rbx, header

		mov eax, dword[rbx+18]   	; save original width
		mov dword[rdx], eax

		mov eax, dword[rbx+22]  	; save original height
		mov dword[rcx], eax

		mov rax, r8					; update new width
		mov dword[rbx+18], eax

		mov rax, r9					; update new height
		mov dword[rbx+22], eax

		push rdx					
		mov eax, dword[rbx+18]     	; update file size
		mov edx, dword[rbx+22]
		mul edx
		mul dword[three]
		add rax, HEADER_SIZE
		mov qword[rbx+2], rax
		pop rdx


	push rdi
	push rsi
	push rdx
	push rcx

	check_errWriteHdr:
		mov rax, SYS_write
		mov rdi, rsi
		mov rsi, header
		mov rdx, HEADER_SIZE
		syscall

		cmp rax, 0
		jl is_errWriteHdr

	pop rcx
	pop rdx
	pop rsi
	pop rdi

	is_SUCCESS_2:
		mov rax, TRUE
		jmp doReturn2

	is_errReadHdr:
		lea rdi, byte[errReadHdr]
		call printString
		mov rax, FALSE
		jmp doReturn2

	is_errFileType:
		lea rdi, byte[errFileType]
		call printString
		mov rax, FALSE
		jmp doReturn2

	is_errDepth:
		lea rdi, byte[errDepth]
		call printString
		mov rax, FALSE
		jmp doReturn2
	
	is_errCompType:
		lea rdi, byte[errCompType]
		call printString
		mov rax, FALSE
		jmp doReturn2

	is_errSize:
		lea rdi, byte[errSize]
		call printString
		mov rax, FALSE
		jmp doReturn2

	is_errWriteHdr:
		lea rdi, byte[errWriteHdr]
		call printString
		mov rax, FALSE
		jmp doReturn2

	doReturn2:
		mov rax, rax


	mov rsp, rbp
	pop rbp

ret


; ***************************************************************
;  Return a row from read buffer
;	This routine performs all buffer management

; ----
;  HLL Call:
;	bool = readRow(readFileDesc, picWidth, rowBuffer[]);

;   Arguments:
;	- rdi read file descriptor (value)
;	- rsi image width (value)
;	- rdx row buffer (address)
;  Returns:
;	TRUE or FALSE

; -----
;  This routine returns TRUE when row has been returned
;	and returns FALSE if there is no more data to
;	return (i.e., all data has been read) or if there
;	is an error on read (which would not normally occur).

;  The read buffer itself and some misc. variables are used
;  ONLY by this routine and as such are not passed.

global readRow
readRow:					 

	mov qword[index], 0
	mov rbx, rdx								; save row address
	
	mov qword[pixelCount], 0 					; calculate pixel count
	mov rax, rsi					
	mul dword[three]
	mov qword[pixelCount], rax

	readInput:								
		mov r10, qword[curr]					; fill buffer if current passed max
		cmp r10, qword[buffMax]
		jae fillBuffer			 
		jmp populateRow

			fillBuffer:
			mov rax, SYS_read
			mov rdi, rdi
			mov rsi, buffer
			mov rdx, BUFF_SIZE
			syscall

			cmp rax, 0
			jl is_errRead

			mov qword[curr], 0             		; reset pointers
			mov qword[buffMax], BUFF_SIZE
			
			cmp rax, BUFF_SIZE					; if less character than the max size
			jae populateRow						
				mov qword[buffMax], rax			; then point the max to input size
				mov byte[wasEOF], TRUE			; mark the buffer as not full

	populateRow:								
		mov r10, buffer							; move buffer address to r10
		add r10, qword[curr]					; offaset it by curr much
												
		mov al, byte[r10]						; take taht value
		mov r12, qword[index]
		mov byte[rbx+r12], al					; move it to current index

		inc qword[curr]
		inc qword[index]

		mov r10, qword[buffMax]					; if buffmax = curr
		cmp r10, qword[curr]					; check if its EOF
		je checkRow
		
		mov r10, qword[pixelCount]				; if row is filled
		cmp r10, qword[index]			
		je returnRow							; then return otherwise
			jmp populateRow						; keep populating row

		checkRow:
		mov al, byte[wasEOF]
		cmp al, TRUE
		je buffernotFull

		mov r10, qword[pixelCount]
		cmp r10, qword[index]
		je returnRow
			jmp readInput

		buffernotFull:
		mov r10, qword[pixelCount]
		cmp r10, qword[index]
		je returnRow
			jmp noData

	noData:
		mov rax, FALSE
		jmp doReturn3

	returnRow:
		mov rax, TRUE
		jmp doReturn3

	is_errRead:
		lea rdi, byte[errRead]
		call printString
		mov rax, FALSE
		jmp doReturn3

	doReturn3:
		mov rax, rax

ret

; ***************************************************************
;  Write image row to output file.
;	Writes exactly (width*3) bytes to file.
;	No requirement to buffer here.

; -----
;  HLL Call:
;	bool = writeRow(writeFileDesc, picWidth, rowBuffer);

;  Arguments are:
;	- rdi write file descriptor (value)
;	- rsi image width (value)
;	- rdx row buffer (address)

;  Returns:
;	N/A

; -----
;  This routine returns TRUE when row has been written
;	and returns FALSE only if there is an
;	error on write (which would not normally occur).

;  The read buffer itself and some misc. variables are used
;  ONLY by this routine and as such are not passed.

global writeRow
writeRow:

	push rbp
	mov rbp, rsp

	push rdx								; calculate amount to write
	mov rax, rsi
	mul dword[three]
	mov qword[pixelCount2], rax 
	pop rdx

	check_errWrite:
		mov rax, SYS_write
		mov rdi, rdi						; write file descriptor
		mov rsi, rdx						; row buffer address
		mov rdx, qword[pixelCount2]			; amount to write
		syscall

		cmp rax, 0
		jl is_errWrite

	is_writeSuccess:
		mov rax, TRUE
		jmp doReturn4

	is_errWrite:
		lea rdi, byte[errWrite]
		call printString
		mov rax, FALSE
		jmp doReturn4

	doReturn4:
		mov rax, rax

	mov rsp, rbp
	pop rbp

ret

; ******************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.
;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

;  Arguments:
;	1) address, string
;  Returns:
;	nothing

global	printString
printString:
	push	rbx

; -----
;  Count characters in string.

	mov	rbx, rdi			; str addr
	mov	rdx, 0
strCountLoop:
	cmp	byte [rbx], NULL
	je	strCountDone
	inc	rbx
	inc	rdx
	jmp	strCountLoop
strCountDone:

	cmp	rdx, 0
	je	prtDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of characters to write
	mov	rdi, STDOUT			; file descriptor for standard in
						; EDX=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

prtDone:
	pop	rbx
	ret

; ******************************************************************

