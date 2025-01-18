include "hardware.inc"  ; Include hardware definitions so we can use nice names for things

; Define a section that starts at the point the bootrom execution ends
SECTION "Start", ROM0[$0100]
    jp EntryPoint       ; Jump past the header space to our actual code

    ds $150-@, 0        ; Allocate space for RGBFIX to insert our ROM header by allocating
                        ;  the number of bytes from our current location (@) to the end of the
                        ;  header ($150)

EntryPoint:
    di                  ; Disable interrupts as we won't be using them
    ld sp, $e000        ; Set the stack pointer to the end of WRAM

    ; Turn off the LCD when it's safe to do so (during VBlank)
.waitVBlank
    ldh a, [rLY]        ; Read the LY register to check the current scanline
    cp SCRN_Y           ; Compare the current scanline to the first scanline of VBlank
    jr c, .waitVBlank   ; Loop as long as the carry flag is set
    ld a, 0             ; Once we exit the loop we're safely in VBlank
    ldh [rLCDC], a      ; Disable the LCD (must be done during VBlank to protect the LCD)

    ; Copy our tile to VRAM
    ld hl, TileData     ; Load the source address of our tiles into HL
    ld de, _VRAM        ; Load the destination address in VRAM into DE
    ld b, 16            ; Load the number of bytes to copy into B (16 bytes per tile)
.copyLoop
    ld a, [hl]          ; Load a byte from the address HL points to into the register A
    ld [de], a          ; Load the byte in the A register to the address DE points to
    inc hl              ; Increment the source pointer in HL
    inc de              ; Increment the destination pointer in DE
    dec b               ; Decrement the loop counter in B
    jr nz, .copyLoop    ; If B isn't zero, continue looping

    ; Setup the two object palettes
    ld a, %11100100     ; Define a 4-shade palette from darkest (11) to lightest (00)
    ldh [rOBP0], a      ; Set the onject palette 0

    ; Set the attributes for a two sprites in OAMRAM
    ld hl, _OAMRAM      ; Load the destination address in OAMRAM into HL

    ; The first sprite is in the top-left corner of the screen and uses the "normal" palette
    ld a, 16            ; Load the value 16 into the A register
    ld [hli], a         ; Set the Y coordinate (plus 16) for the sprite in OAMRAM, increment HL
    sub 8               ; Subtract 8 from the value stored in A and store the result in A
    ld [hli], a         ; Set the X coordinate (plus 8) for the sprite in OAMRAM, increment HL
    ld a, 0             ; Load the tile index 0 into the A register
    ld [hli], a         ; Set the tile index for the sprite in OAMRAM, increment HL
    ld [hli], a         ; Set the attributes (flips and palette) for the sprite in OAMRAM, increment HL

    ; Zero the Y coordinates of the remaining entries to avoid garbage sprites
    xor a               ; XOR A with itself, which sets A to zero (and affects the flags)
                        ; Note: This is 1 cycle faster and 1 byte smaller than `ld a, 0`
    ld b, OAM_COUNT - 2 ; Load B with the number of loops, which is the total OAM count minus one
.oamClearLoop
    ld [hli], a         ; Set the Y coordinate of this entry to zero, increment HL
    inc l               ; Increment L to advance HL (three times)
    inc l               ; Note: Since OAMRAM is from $FE00->$FE9F we can safely increment
    inc l               ;  only the L register and HL will stay a valid pointer
    dec b               ; Decrement the loop counter in B
    jr nz, .oamClearLoop; If B isn't zero, continue looping

    ; Combine flag constants defined in hardware.inc into a single value with logical ORs and load it into A
    ; Note that some of these constants (LCDCF_BGOFF, LCDCF_OBJ8, LCDCF_WINOFF) are zero, but are included for clarity
    ld a, LCDCF_ON | LCDCF_BGOFF | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_WINOFF
    ldh [rLCDC], a      ; Enable and configure the LCD to show the background

    ; Initialize global variables
    ld a, 0
    ld [wFrameCounter], a       ;set wFrameCounter to zero
    ld [wCurKeys], a
    ld [wNewKeys], a

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
    ; Check the current keys every frame and move left or right.
    call UpdateKeys

    ; First, check if the left button is pressed.
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:
    ; Move the paddle one pixel to the left.
    ld a, [_OAMRAM + 1]
    dec a
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 15
    jp z, Main
    ld [_OAMRAM + 1], a
    jp Main

; Then check the right button.
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, Main
Right:
    ; Move the paddle one pixel to the right.
    ld a, [_OAMRAM + 1]
    inc a
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 105
    jp z, Main
    ld [_OAMRAM + 1], a
    jp Main

    jp Main

TileData:
.ball ; For the ball tile we'll use a more verbose syntax so you can see how the tile is built
    dw `13333331
    dw `30000003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000

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