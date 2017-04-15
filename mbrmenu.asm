; Boot mananager for x86, which resides entirely in the MBR.
;
; To assemble:
; nasm mbrmenu.asm
; 
; To install:
; The 430 bytes file mbrmenu should be written to the first 430 bytes of a
; disk containing an MBR partition table. Sector size 512 bytes is assumed.
; The Linux dd program can be used for installation.
; Note that installation may not be for novices, and that you should have
; the skills to recover from errors you may make.
;
; This version was made to match a previous MASM version.
; Som commands however assemble to different encodings using NASM compared
; to MASM, for example "or eax, eax". 
;
; Written by Svend Olaf Mikkelsen.
; SHA1 of program: affe70bd2248d8bc3abfa4d2b4c7446d10f33403
; Verify that the SHA1 hash is correct before installing.
; Date of this source code version: April 15, 2017.
;
; The boot manager boots the active partition. If key 1, 2, 3 or 4 is pressed
; when a number sign prompt # is printed to the screen, the active partition is
; first changed to correspond to the value of key pressed. The prompt is
; present for 5 seconds.

    bits 16

struc entry
    .bootflag        resb 1
    .beginhead       resb 1
    .beginsector     resb 1
    .begincylinder   resb 1
    .systemid        resb 1
    .endhead         resb 1
    .endsector       resb 1
    .endcylinder     resb 1
    .relsector       resd 1
    .numsectors      resd 1
endstruc

struc mbr
    .code            resb 446
    .part1           resb 16
    .part2           resb 16
    .part3           resb 16
    .part4           resb 16
    .signature       resb 2
endstruc

    ; cs start       7900h       0h
    ; code location  7A00h     100h
    ; data location  7B00h     200h
    ; active sector  7C00h     300h
    ; program cs:    8000h     700h
    ; program code   8100h     800h
    ; data           8300h     A00h


section .text

    org 100h

    ; loaded at 0:7C00
    ; move to 0:7A00

    ; move code to 7A00h

%ifndef com
    cli
    mov ax, 790h
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0FFFEh
    mov si, 300h
    mov di, 100h
    mov cx, 512
    cld
    rep movsb
    sti
    ;jmp 0790:011F
    db 0EAh,1Fh,01h,90h,07h
%endif

    ; This is where we jump to, 0790:011F.
    ; We read the MBR again. The origin of this behaviour is that
    ; when debugging by running the boot manager as a DOS com
    ; program, the MBR should be read after program load
    ; in order to get the partition table.

    mov ax, 0201h ; Read the MBR to buffer.
    mov cx, 1     ; cylinder, sector
    mov dx, 80h
    mov bx, buffer
    int 13h

    mov si, errorinvalid
    jc error

    ; We do not detect if there is more than one active partition.

    ; Print a "#" prompt on the screen:
    mov si, prompt
    call biosprint

starttimer:
    mov ah, 0
    int 1Ah  ; high 16 bits in cx  cx:dx
    mov [beginticks], dx  ; begin ticks

testforkeypress:
    mov ah, 01h
    int 16h
    jnz  keypress
.l1:
    mov ah, 0
    int 1Ah
    cmp dx, [beginticks]
    jae .l1a
    mov bx, dx
    jmp .l1
.l1a:
    sub dx, [beginticks]
    cmp dx, 91
    jbe .l7

    ; Load address of active boot sector to eax:

    cmp byte [buffer + mbr.part1 + entry.bootflag], 80h
    jne .l2
    mov eax, [buffer + mbr.part1 + entry.relsector]
    jmp .l6
.l2:
    cmp byte [buffer + mbr.part2 + entry.bootflag], 80h
    jne .l3
    mov eax, [buffer + mbr.part2 + entry.relsector]
    jmp .l6
.l3:
    cmp byte [buffer + mbr.part3 + entry.bootflag], 80h
    jne .l4
    mov eax, [buffer + mbr.part3 + entry.relsector]
    jmp .l6
.l4:
    cmp byte [buffer + mbr.part4 + entry.bootflag], 80h
    jne .l5
    mov eax, [buffer + mbr.part4 + entry.relsector]
    jmp .l6
.l5:
    ; No active partition.
    mov si, errorinvalid
    jmp error
.l6:
    jmp doboot
.l7:
    jmp testforkeypress

keypress:
    mov ax, 00h
    int 16h

    cmp ax, 0231h
    jne .l2
    mov ebx, buffer + mbr.part1 + entry.bootflag
    mov eax, [buffer + mbr.part1 + entry.relsector]
    jmp .l6
.l2:
    cmp ax, 0332h
    jne .l3
    mov ebx, buffer + mbr.part2 + entry.bootflag
    mov eax, [buffer + mbr.part2 + entry.relsector]
    jmp .l6
.l3:
    cmp ax, 0433h
    jne .l4
    mov ebx, buffer + mbr.part3 + entry.bootflag
    mov eax, [buffer + mbr.part3 + entry.relsector]
    jmp .l6
.l4:
    cmp ax, 0534h
    jne .l5 
    mov ebx, buffer + mbr.part4 + entry.bootflag
    mov eax, [buffer + mbr.part4 + entry.relsector]
    jmp .l6
.l5:
    jmp starttimer
.l6:

    ; If entry chosen is empty then retry
    or eax, eax
    jne .l7
    jmp starttimer
.l7:
    mov byte [buffer + mbr.part1 + entry.bootflag], 0
    mov byte [buffer + mbr.part2 + entry.bootflag], 0
    mov byte [buffer + mbr.part3 + entry.bootflag], 0
    mov byte [buffer + mbr.part4 + entry.bootflag], 0
    mov byte [ebx], 80h
    push eax

    ; Write buffer to MBR
    mov ax, 0301h
    mov cx, 1
    mov dx, 80h
    mov bx, buffer
    int 13h
    pop eax


doboot:
    mov word [packetsize], 16
    mov word [numberofblocks], 1
    mov word [bufferoffset], 300h
    mov [buffersegment], es
    mov [blocknumberlow], eax
    xor edx, edx
    mov [blocknumberhigh], edx
    mov ah, 42h
    mov dl, 80h
    mov si, packetsize
    int 13h

    mov si, errorload
    jc error
    cmp word [500h-2h],0AA55h
    mov si, errorsig
    jne error

%ifndef com
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax      ; Is cli sti handled correctly? It works.
    mov sp, 7C00h
    ;jmp 0000:7C00
    db 0EAh,00,7Ch,00,00
%else
    mov ah,0Eh
    mov al,65
    xor bx,bx
    int 10h
    mov ah, 4ch
    int 21h
%endif

error:
    call biosprint

%ifndef com
halted:
    jmp halted
%else
    mov ah, 4ch
    int 21h
%endif

biosprint:
    ; si contains offset of 0 terminated string
    pusha
.l1:     lodsb
    or al, al
    je .l2
    mov ah,0Eh
    xor bx,bx
    int 10h
    jmp .l1
.l2:
    popa
    ret

section .data

errorinvalid:   db 'Invalid table', 13, 10, 0
errorload:      db 'Error loading OS', 13, 10, 0
errorsig:       db 'Missing OS', 13, 10, 0
prompt:         db  '#',0

section .bss

reserved         resb 2558 ; 0x9fe

buffer           resb 512

packetsize:      resw 1
numberofblocks:  resw 1
bufferoffset:    resw 1
buffersegment:   resw 1
blocknumberlow:  resd 1
blocknumberhigh: resd 1
beginticks:      resd 1


