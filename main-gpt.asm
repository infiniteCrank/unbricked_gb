INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ; Wait for VBlank to avoid turning the LCD off incorrectly
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ; Turn the LCD off for setup
    ld a, 0
    ld [rLCDC], a

    ; Copy tile data
    ld de, Tiles
    ld hl, $9000
    ld bc, TilesEnd - Tiles
    call Memcopy

    ; Copy tilemap
    ld de, Tilemap
    ld hl, $9800
    ld bc, TilemapEnd - Tilemap
    call Memcopy

    ; Copy paddle tile
    ld de, Paddle
    ld hl, $8000
    ld bc, PaddleEnd - Paddle
    call Memcopy

    ; Clear OAM
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; Initialize the paddle sprite in OAM
    ld hl, _OAMRAM
    ld a, 0     ; Y-Position of the sprite (adjust as needed)
    ld [hli], a ; OAM Y-Position

    ld a, 1     ; Tile index for paddle (make sure it matches the defined tile)
    ld [hli], a ; OAM Tile index

    ld a, 0     ; Attributes (palette number, Y-flip, priority)
    ld [hli], a ; OAM Attributes 

    ld a, 0     ; X-Position of the sprite (initially at 0)
    ld [hli], a ; OAM X-Position

    ; Turn the LCD on with background and sprite enabled
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; Initialize color palette
    ld a, %11100100
    ld [rBGP], a    ; Background palette
    ld a, %11100100
    ld [rOBP0], a   ; Object (sprite) palette

    ; Initialize global variables
    ld a, 0
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a

Main:
    ld a, [rLY]
    cp 144
    jp nc, Main  ; Wait until VBlank for sprite updates

WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

    ; Check the current keys every frame and move paddle
    call UpdateKeys

    ; Move the paddle left if the left button is pressed
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight ; If not pressed, check right button

Left:
    ; Move paddle left
    ld a, [_OAMRAM + 1] ; Read current Y-position from OAM
    dec a
    cp 15                ; Prevent moving off-screen
    jp z, Main           ; If at edge, do nothing
    ld [_OAMRAM + 1], a  ; Update paddle's Y-position
    jp Main              ; Loop back to main

CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, Main           ; If not pressed, exit

Right:
    ; Move paddle right
    ld a, [_OAMRAM + 1] ; Read current Y-position from OAM
    inc a
    cp 105               ; Prevent moving off-screen
    jp z, Main          ; If at edge, do nothing
    ld [_OAMRAM + 1], a  ; Update paddle's Y-position
    jp Main              ; Loop back to main

Tiles:
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322222
	dw `33322222
	dw `33322222
	dw `33322211
	dw `33322211
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222333
	dw `22222333
	dw `22222333
	dw `11222333
	dw `11222333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `22222222
	dw `20000000
	dw `20111111
	dw `20111111
	dw `20111111
	dw `20111111
	dw `22222222
	dw `33333333
	dw `22222223
	dw `00000023
	dw `11111123
	dw `11111123
	dw `11111123
	dw `11111123
	dw `22222223
	dw `33333333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `11001100
	dw `11111111
	dw `11111111
	dw `21212121
	dw `22222222
	dw `22322232
	dw `23232323
	dw `33333333
	; Paste your logo here:
    	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222211
	dw `22222211
	dw `22222211
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `11221111
	dw `11221111
	dw `11000011
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11222222
	dw `11222222
	dw `11222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222211
	dw `22222200
	dw `22222200
	dw `22000000
	dw `22000000
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11000011
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11000022
	dw `11222222
	dw `11222222
	dw `11222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222200
	dw `22222200
	dw `22222211
	dw `22222211
	dw `22221111
	dw `22221111
	dw `22221111
	dw `11000022
	dw `00112222
	dw `00112222
	dw `11112200
	dw `11112200
	dw `11220000
	dw `11220000
	dw `11220000
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22000000
	dw `22000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11110022
	dw `11110022
	dw `11110022
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22222211
	dw `22222211
	dw `22222222
	dw `11220000
	dw `11110000
	dw `11110000
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222
	dw `00000000
	dw `00111111
	dw `00111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222
	dw `11110022
	dw `11000022
	dw `11000022
	dw `00002222
	dw `00002222
	dw `00222222
	dw `00222222
	dw `22222222
	
TilesEnd:

Tilemap:
	db $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0A, $0B, $0C, $0D, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0E, $0F, $10, $11, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $12, $13, $14, $15, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $16, $17, $18, $19, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
TilemapEnd:

Paddle:
    dw `13333331
    dw `30000003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
PaddleEnd:

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length of bytes to copy
Memcopy:
    ld a, [de]    ; Load byte from source
    ld [hli], a   ; Store it to the destination
    inc de        ; Move to the next byte in source
    dec bc        ; Decrease the number of bytes left to copy
    ld a, b
    or a, c      ; Check if b or c is zero
    jp nz, Memcopy ; If not zero, repeat the copy
    ret

UpdateKeys:
    ; Poll half of the controller inputs
    ld a, P1F_GET_BTN
    call .onenibble
    ld b, a ; Store pressed buttons in B

    ; Poll the other half of the controller inputs
    ld a, P1F_GET_DPAD
    call .onenibble
    swap a ; Swap nibbles so we can check directions properly
    xor a, b ; Combine both states
    ld b, a  ; Keep pressed keys in B

    ; Release the controller
    ld a, P1F_GET_NONE
    ldh [rP1], a

    ; Combine with previous wCurKeys to make wNewKeys
    ld a, [wCurKeys]
    xor a, b         ; Get keys that changed state
    and a, b         ; Keep only keys that are now pressed
    ld [wNewKeys], a ; Store in new keys
    ld a, b          ; Update current keys
    ld [wCurKeys], a
    ret

.onenibble:
    ldh [rP1], a     ; Switch the key matrix
    call .knownret    ; Burn some cycles waiting for response
    ldh a, [rP1]     ; Read to ignore value while settling
    ldh a, [rP1]     ; Read again
    ldh a, [rP1]     ; Count this read
    or a, $F0        ; Set bits for unpressed keys
.knownret:
    ret               ; Return from subroutine

; Section for variables in WRAM
SECTION "Variable Storage", WRAM0
wFrameCounter: db 0      ; Frame counter variable
wCurKeys: db 0           ; Current key states
wNewKeys: db 0           ; New key states that changed