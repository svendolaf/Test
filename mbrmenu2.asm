; Boot manager for x86, which resides entirely in the MBR.
;
; This version was not very much tested.
;
; To assemble:
; nasm mbrmenu2.asm
; 
; To install:
; The 412 bytes file mbrmenu2 should be written to the first 412 bytes of a
; disk containing an MBR partition table. Sector size 512 bytes is assumed.
; The Linux dd program can be used for installation.
; Note that installation may not be for novices, and that you should have
; the skills to recover from errors you may make. Also note that the
; boot manager may contain errors.
;
; Written by Svend Olaf Mikkelsen.
; SHA1 of program: 9825f44f8b035e1f0d0aa73b5f6b74b1689b23fe
; Verify that the SHA1 hash is correct before installing.
; Date of this source code version: April 17, 2017.
;
; The boot manager boots the active partition. If key 1, 2, 3 or 4 is pressed
; when a number sign prompt # is printed to the screen, the active partition is
; first changed to correspond to the value of key pressed. The prompt is
; present for 5 seconds.
;
; One feature was added: Pressing t before the partition number will
; boot the partition chosen without changing active partition. A t will
; be printed to the screen. Repeated pressing of t will toggle the choice, and
; print p on the screen when the active partition will be set.
;
; Another feature was added: The number of the current active partition
; is printed before the # sign. I no partition is active, a space is printed
; in stead.


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

    ; cs start       7900h       0h     0   256
    ; code location  7A00h     100h   256   512
    ; active sector  7C00h     300h   768   512
    ; MBR copy       7E00h     500h  1280   512
    ; remaining bss  8000h     700h  1792

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

    mbr_address equ 100h

%else

    mov ax, 0201h ; Read the MBR to buffer.
    mov cx, 1     ; cylinder, sector
    mov dx, 80h
    mov bx, buffer
    int 13h
    mov si, errorinvalid
    jc error

    mbr_address equ buffer

%endif

    ; We do not detect if there is more than one active partition.

    ; Find active partition, if any:
    mov cx, 4
    mov si, mbr_address + mbr.part1 + entry.bootflag    
nextentry:
    inc byte [prompt1]
    cmp byte [si], 80h    
    je .l1
    add si, 16
    loop nextentry
    mov byte [prompt1], ' '
.l1:

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
    jae .l2
    mov bx, dx
    jmp .l1
.l2:
    sub dx, [beginticks]
    cmp dx, 91
    jbe testforkeypress

    ; Load address of active boot sector to eax:
    mov cx, 4
    mov si, mbr_address + mbr.part1 + entry.bootflag
.l3:
    mov eax, [si + entry.relsector - entry.bootflag]
    cmp byte [si], 80h    
    je doboot
    add si, 16
    loop .l3
    ; No active partition.
    mov si, errorinvalid
    jmp error

keypress:
    mov ax, 00h
    int 16h

    cmp ax, 0231h
    jne .l2
    mov si, 0
    jmp .l6
.l2:
    cmp ax, 0332h
    jne .l3
    mov si, 16
    jmp .l6
.l3:
    cmp ax, 0433h
    jne .l4
    mov si, 32
    jmp .l6
.l4:
    cmp ax, 0534h
    jne .l5
    mov si, 48
    jmp .l6
.l5:
    ;cmp ax, 3920h  ; space bar
    cmp ax, 1474h  ; t
    jne starttimer
    xor byte [temporar], 4
    mov si, temporar
    call biosprint
    jmp starttimer

.l6:

    mov bx, mbr_address + mbr.part1 + entry.bootflag
    add bx, si
    mov eax, [si + mbr_address + mbr.part1 + entry.relsector]

    ; If entry chosen is empty then retry
    or eax, eax
    jne .l7
    jmp starttimer

.l7:
    mov si, 0
    mov cx, 4
.l8:
    mov byte [si + mbr_address + mbr.part1 + entry.bootflag], 0
    add si, 16
    loop .l8
    mov byte [bx], 80h

    cmp byte [temporar], 't'
    je doboot
    mov byte [prompt1], "0"
    push eax
    ; Write buffer to MBR
    mov ax, 0301h
    mov cx, 1
    mov dx, 80h
    mov bx, mbr_address
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
sectalign 1

errorinvalid    db 'Invalid table', 13, 10, 0
errorload       db 'Error loading OS', 13, 10, 0
errorsig        db 'Missing OS', 13, 10, 0
prompt          db  10, 10, 10, 10, 10, 10
prompt1         db  '0#',0
temporar        db 'p', 0


section .bss 
sectalign 1

reserved         resb 7e00h-7a00h-343

buffer           resb 512

packetsize       resw 1
numberofblocks   resw 1
bufferoffset     resw 1
buffersegment    resw 1
blocknumberlow   resd 1
blocknumberhigh  resd 1
beginticks       resd 1

