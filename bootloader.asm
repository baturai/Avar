org 0x7C00
use16

boot:
    cli                     ; Kesmeleri kapat
    xor ax, ax              ; Segmentleri sıfırla
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00          ; Yığın adresini ayarla

 call enable_a20
    ; Amaç: Kernel'i diskten belleğe yüklemek
    mov ah, 0x02            ; Disk okuma fonksiyonu
    mov al, 2               ; Okunacak sektör sayısı
    mov ch, 0               ; Silindir 0
    mov dh, 0               ; Kafa 0
    mov cl, 2               ; Sektör 2
    
    mov bx, 0x1000          ; Kernel'in yükleneceği adres (0x1000:0x0000)
    mov es, bx
    xor bx, bx
    
    int 0x13                ; Disk kesmesini çağır
    jc disk_hata            ; Hata varsa atla

    ; Amaç: 32-bit Korumalı Moda geçiş yapmak
    lgdt [gdt_descriptor]   ; GDT tablosunu yükle

    mov eax, cr0
    or eax, 1               ; Korumalı mod bitini aç
    mov cr0, eax

 
 db 0x66
 jmp far [kernel_pointer]

disk_hata:
    mov si, hata_mesaji
    call yazdir_metin
    cli
    hlt
    jmp $

yazdir_metin:
    mov ah, 0x0E          ; BIOS teletype fonksiyonu
.dongu:
    lodsb                 
    test al, al           
    jz .bitti             
    int 0x10              
    jmp .dongu
.bitti:
    ret

hata_mesaji db 13, 10, "[ FATAL ERROR: DISK READ MELTDOWN - 0xA0 ]", 13, 10, "WWW.HANMECH.COM.TR", 13, 10, 0
kernel_pointer:
    dd 0x10000      ; 4 baytlık 32-bit offset
    dw 0x08         ; 2 baytlık segment seçici (selector)


; Amaç: Bellek segment sınırlarını tanımlamak
gdt_start:
    dq 0                    ; Null descriptor

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

enable_a20:
  in al, 0x92
  test al, 2
  jnz .a20_zaten_acik
  or al,2
  and al, 0xFE
  out 0x92, al

a20_zaten_acik:
    ret

rb 510 - ($-$$)
dw 0xAA55

