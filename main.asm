INCLUDE "hardware.inc"          ;include constants for hardware 
SECTION "Header", ROM0[$100]    ;start a new section called header and ahrd code it at address 100
    
    jp EnteryPoint              ;Jump to EnteryPoint Section

    ds $150 - @, 0              ;make room for gameboy header 
    
EnteryPoint:                     ;make a new label called EntryPoint
; DO NOT TURN LCD OFF OUTSIDE VBLANK COULD CAUSE DAMAGE
WaitVBlank:                     ;make a new label called wait for v blank 
    ld a, [rLY]                 ;load math registry (accumulator) with Y coordinate of the LCD scanline
    cp 144                      ;compares the value in the accumulator a with the value 144
                                ;   144 is VBlank period on the Game Boy
    jp c, WaitVBlank            ;jump to WaitVBlank if accumulator less that 
                                ;   c stands for carry 
                                ;   if cp 144 ended in a carrry a < 144
                                ;   this makes a loop until VBlank on 144 happens 
;turn lacd off after VBlank
ld a, 0                         ;Loading accumulator with zero 
ld [rLCDC], a                   ;Load the zero from teh accumulator to the LCD registry 
                                ; a value of zero indicates turning the lcd off
                                ; we turn the screen off to load new tiles to the screen 
;copy tile data
;It prepares a source address (DE) for the tile data,
;Sets a destination address (HL) where that data will be copied,
;And calculates the total size of the data to be copied (BC).
ld de, Tiles                    ;load the de regitry with everything from Tiles Label
                                ;   de serves as a pointer to Tile data 
ld hl, $9000                    ;load memory adress $9000 to hl register pair
                                ;   $9000 adress is the start of the background tile maps $00 
                                ;   this is setting up to load data to the background starting at $00
ld bc, TilesEnd - Tiles         ;copy the result of subtracting tiles end from tiles start to bc registry pair
                                ;   this effectivly gives us the size of data we are going to be working with 
                                ;   it is common to store size data in bc before a transfer of data 
;this actually copies the title data we prepped above 
;CopyTiles:              
    ;ld a, [de]                  ;load the title data into the accumlator to process 
    ;ld [hli], a                 ;load accumlator data to hl and increment by one
                                ;   incrementing by one ensure the next byte of data gets stored in the next address
    ;inc de                      ;increment de (move the pointer up the next byte)
    ;dec bc                      ;decrement bc subtract a byte from the total bits 
                                ;   this tracks how many bytes there are left to copy 
    ;ld a, b                     ;load the first byte of bc into the accumulator 
    ;or a, c                     ;do a logical or between b and c 
                                ;B || C if both are zero return 0 flag 
    ;jp nz, CopyTiles            ;if there is no zero flag keep coping data 
;functionize the above 
call Memcopy

;Copy the tilemap
    ld de, Tilemap              ;copy data from tilemap to de for storage
    ld hl, $9800                ;load hl with address $9800 the start of tilemap
    ld bc, TilemapEnd - Tilemap ;get the total size of tile mape 

;CopyTilemap:                    ;make a label called CopyTileMap
    ;ld a, [de]                  ;load the first byte of tilemap data 
    ;ld [hli], a                 ;write the tile data and move the piece of data  
    ;inc de                      ;move the pointer up to that next byte to be processesed 
    ;dec bc                      ;subtract this byte form teh total bytes 
    ;ld a, b                     ;load b byte to see if its zero
    ;or a, c                     ; checkif both b and c are zero
    ;jp nz, CopyTilemap          ;if the next byte is not zero process it 0
;functionize the above 
call Memcopy

    ; Copy the paddle tile
    ld de, Paddle
    ld hl, $8000
    ld bc, PaddleEnd - Paddle
;CopyPaddle:
    ;ld a, [de]
    ;ld [hli], a
    ;inc de
    ;dec bc
    ;ld a, b
    ;or a, c
    ;jp nz, CopyPaddle
;functionize the above 
call Memcopy

    ;clear OAMRAM (Object Attribute Memory) this is where sprites are stored 
    ;   must do this while the screen is off
    ld a, 0                     ;load zero into accumulator
    ld b, 160                   ;load b with 160 this is the total bytes of OAMRAM
    ld hl, _OAMRAM              ;load hl with oram address
ClearOam:                       ;define a new label ClearOam
    ld [hli], a                 ;load zero into the hl slot and move up one slot
    dec b                       ;decrement the total by a byte 
    jp nz, ClearOam             ;if b is not zero zero out the next byte 

    ;draw a object to the screen
    ;   the object’s top-left pixel lies 128 pixels from the top of the screen, and 16 from its left. 
    ;   The tile ID and attributes are both set to 0.
    ld hl, _OAMRAM              ;loads the address of the Object Attribute Memory (OAM) into the register pair HL
                                ;   The OAM is where sprite information is stored
                                ;   includes attributes such as position, tile number, and other settings 
                                ;   needed to display sprites on the screen.
                                ;   each object in OAM is 4 bytes, in the order Y, X, Tile ID, Attributes.
    ld a, 128 + 16              ;loads 144 into accumulator 
                                ;   The value 128 generally indicates that the sprite is a 16x16 tile 
                                ;   as this is the y cordinate plus a 16 pixel offset
    ld [hli], a                 ;   load the y cordinate and move to the x slot
    ld a, 16 + 8                ;loads 24 into the accumulator 0
                                ;   this is the x cordinate plus an 8 pixel offset
    ld [hli], a                 ;load the X cordinate into HL and move to Tile Id 
    ld a, 0                     ;load zero into accumulator
    ld [hli], a                 ;set title id to zero 
    ld [hli], a                 ;set attributes to zero 

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON ;first turn the lcd on then enable the background 
    ld [rLCDC], a               ; write the constants to the lcd 

    ; During the first (blank) frame, initialize display registers
    ld a, %11100100             ;each bit represents a specific attribute for how tiles will be rendered on the screen
                                ;   Bit 7: Reserved (always set to 0)
                                ;   Bit 6: Flags if the palette can be used (0 = off, 1 = on)
                                ;   Bit 5: Specifies the color encoding, affecting how colors are applied
                                ;   Bits 4-0: Define the actual color number for the palette entries
    ld [rBGP], a                ;stores the value currently in the accumulator (A) into the Background Palette Register (rBGP).
                                ;   By loading it with the value 11100100, sets up the initial color palette for BG
    ;enables the sprite palette and sets its initial color configuration
    ld a, %11100100             ;see above what each bit means 
    ld [rOBP0], a               ;load 11100100 into the Object Palette 0 register, 
                                ;   denoted by rOBP0. The rOBP0 register is responsible for controlling the color 
                                ;   attributes for the first sprite palette bank on the Game Boy

    ; Initialize global variables
    ld a, 0
    ld [wFrameCounter], a       ;set wFrameCounter to zero

Main:                           ;infinite game loop

    ; Wait until it's *not* VBlank
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

    ;Every 15 frames (a quarter of a second), run the following code
    ld a, [wFrameCounter]       ;the next few line sum up to wFrameCounter ++
    inc a
    ld [wFrameCounter], a
    cp a, 15                    ;check to see if wFrameCounter is 15
    jp nz, Main                 ;if its not go bac to main

    ; Reset the frame counter back to 0
    ld a, 0
    ld [wFrameCounter], a

    ; Move the paddle one pixel to the right.
    ;ld a, [_OAMRAM + 1]
    ;inc a
    ;ld [_OAMRAM + 1], a

    jp Main

;below is the graphics data for the game dw `01230123 ; This is equivalent to `db $55,$33`
;rgbasm -o main.o main.asm  - this builds the rom
;rgblink -o unbricked.gb main.o - this fills the holes 
;rgbfix -v -p 0xFF unbricked.gb - this makes the header 

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

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret

UpdateKeys:
  ; Poll half the controller
  ld a, P1F_GET_BTN
  call .onenibble
  ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

  ; Poll the other half
  ld a, P1F_GET_DPAD
  call .onenibble
  swap a ; A3-0 = unpressed directions; A7-4 = 1
  xor a, b ; A = pressed buttons + directions
  ld b, a ; B = pressed buttons + directions

  ; And release the controller
  ld a, P1F_GET_NONE
  ldh [rP1], a

  ; Combine with previous wCurKeys to make wNewKeys
  ld a, [wCurKeys]
  xor a, b ; A = keys that changed state
  and a, b ; A = keys that changed to pressed
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rP1], a ; switch the key matrix
  call .knownret ; burn 10 cycles calling a known ret
  ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
  ldh a, [rP1]
  ldh a, [rP1] ; this read counts
  or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
  ret

; this allows access to RAM
SECTION "Counter", WRAM0

;create a global variable wFrameCounter to count frames 
wFrameCounter: db

;variables for player input
SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

