
if DEBUG_FORTH_MALLOC_HIGH
.mallocsize: db "Wants malloc >256",0
.mallocasize: db "MALLOC gives >256",0
.malloczero: db "MALLOC gives zero",0

malloc_guard_zerolen:
	push hl
	push de
	push af

	ld de, 0
        call cmp16
	jr nz, .lowalloz

	push hl
	push de
		ld hl, display_fb0
		ld (display_fb_active), hl
	call clear_display
	ld a, 0
	ld de, .malloczero
	call str_at_display
	call update_display
	call delay1s
	call delay1s
	ld a, 0
	ld (os_view_disable), a

	pop de
	pop hl

	

	CALLMONITOR
.lowalloz:


	pop af
	pop de
	pop hl
ret

malloc_guard_entry:
	push hl
	push de
	push af

 	or a      ;clear carry flag
	push hl
	ld de, 255
	sbc hl, de
	jr c, .lowalloc

	push de
		ld hl, display_fb0
		ld (display_fb_active), hl
	call clear_display
	ld a, 0
	ld de, .mallocsize
	call str_at_display
	call update_display
	call delay1s
	call delay1s
	ld a, 0
	ld (os_view_disable), a

	pop de
	pop hl

	

	CALLMONITOR
	jr .lowdone
.lowalloc:


	pop hl
.lowdone:	pop af
	pop de
	pop hl
ret

malloc_guard_exit:
	push hl
	push de
	push af

 	or a      ;clear carry flag
	push hl
	ld de, 255
	sbc hl, de
	jr c, .lowallocx

	push de
		ld hl, display_fb0
		ld (display_fb_active), hl
	call clear_display
	ld a, 0
	ld de, .mallocasize
	call str_at_display
	call update_display
	call delay1s
	call delay1s
	ld a, 0
	ld (os_view_disable), a
	pop de
	pop hl

	CALLMONITOR
	jr .lowdonex
.lowallocx:

	pop hl
.lowdonex:	pop af
	pop de
	pop hl
ret
endif

if MALLOC_2
; Z80 Malloc and Free Functions

; Malloc Function:
; Input:
;   HL: Size of block to allocate
; Output:
;   HL: Pointer to allocated memory block (NULL if allocation fails)

malloc:
	
if DEBUG_FORTH_MALLOC_HIGH
call malloc_guard_entry
endif




		if DEBUG_FORTH_MALLOC
			DMARK "mal"
			CALLMONITOR
		endif
    push af            ; Save AF register
    ld a, l            ; Load low byte of size into A
    or h               ; Check if size is zero
    jp z, malloc_exit  ; If size is zero, exit with NULL pointer

    ; Allocate memory
    ld hl, (heap_start) ; Load start of heap into HL
		if DEBUG_FORTH_MALLOC
			DMARK "ma1"
			CALLMONITOR
		endif
    call malloc_internal ; Call internal malloc function
    pop af             ; Restore AF register
if DEBUG_FORTH_MALLOC_HIGH
call malloc_guard_exit
call malloc_guard_zerolen
endif
    ret                ; Return

; Free Function:
; Input:
;   HL: Pointer to memory block to free
; Output:
;   None

free:
    push af            ; Save AF register
    ld a, l            ; Load low byte of pointer into A
    or h               ; Check if pointer is NULL
    jp z, free_exit    ; If pointer is NULL, exit

    ; Free memory
    ld hl, (heap_start) ; Load start of heap into HL
    call free_internal  ; Call internal free function
    pop af             ; Restore AF register
    ret                ; Return

; Internal Malloc Function:
; Input:
;   HL: Size of block to allocate
; Output:
;   HL: Pointer to allocated memory block (NULL if allocation fails)

malloc_internal:
    ld bc, 2           ; Number of bytes to allocate for management overhead
    add hl, bc         ; Add management overhead to requested size
    ex de, hl          ; Save total size in DE, and keep it in HL
		if DEBUG_FORTH_MALLOC
			DMARK "ma2"
			CALLMONITOR
		endif

    ; Search for free memory block
    ld de, (heap_end)  ; Load end of heap into DE
    ld bc, 0           ; Initialize counter

		if DEBUG_FORTH_MALLOC
			DMARK "ma2"
			CALLMONITOR
		endif
malloc_search_loop:
    ; Check if current block is free
    ld a, (hl)         ; Load current block's status (free or used)
    cp 0               ; Compare with zero (free)
    jr nz, malloc_skip_block_check  ; If not free, skip to the next block

    ; Check if current block is large enough
    ld a, (hl+1)       ; Load high byte of block size
    cp l               ; Compare with low byte of requested size
    jr nz, malloc_skip_block_check  ; If not large enough, skip to the next block

    ld a, (hl+2)       ; Load low byte of block size
    cp h               ; Compare with high byte of requested size
    jr c, malloc_skip_block_check   ; If not large enough, skip to the next block

    ; Mark block as used
    ld (hl), 0xFF      ; Set status byte to indicate used block

    ; Calculate remaining space in block
    ld bc, 0           ; Clear BC
    add hl, bc         ; Increment HL to point to start of data block
    add hl, de         ; HL = HL + DE (total size)
    ld bc, 1           ; Number of bytes to allocate for management overhead
    add hl, bc         ; Add management overhead to start of data block

    ; Save pointer to allocated block in HL
if DEBUG_FORTH_MALLOC_HIGH
			DMARK "ma5"
call malloc_guard_exit
call malloc_guard_zerolen
endif
    ret

malloc_skip_block_check:
    ; Move to the next block
    ld bc, 3           ; Size of management overhead
    add hl, bc         ; Move to the next block
    inc de             ; Increment counter

    ; Check if we have reached the end of heap
    ld a, e            ; Load low byte of heap end address
    cp (hl)            ; Compare with low byte of current address
    jr nz, malloc_search_loop  ; If not equal, continue searching
    ld a, d            ; Load high byte of heap end address
    cp 0               ; Check if it's zero (end of memory)
    jr nz, malloc_search_loop  ; If not zero, continue searching

    ; If we reached here, allocation failed
    xor a              ; Set result to NULL
if DEBUG_FORTH_MALLOC_HIGH
			DMARK "ma6"
call malloc_guard_exit
call malloc_guard_zerolen
endif
    ret
malloc_exit:
if DEBUG_FORTH_MALLOC_HIGH
			DMARK "ma7"
call malloc_guard_exit
call malloc_guard_zerolen
endif
    ret

; Internal Free Function:
; Input:
;   HL: Pointer to memory block to free
; Output:
;   None

free_internal:
    ld de, (heap_start) ; Load start of heap into DE
    ld bc, 0            ; Initialize counter

free_search_loop:
    ; Check if current block contains the pointer
    ld a, l             ; Load low byte of pointer
    cp (hl+1)           ; Compare with high byte of current block's address
    jr nz, free_skip_block_check  ; If not equal, skip to the next block
    ld a, h             ; Load high byte of pointer
    cp (hl+2)           ; Compare with low byte of current block's address
    jr nz, free_skip_block_check  ; If not equal, skip to the next block

    ; Mark block as free
    ld (hl), 0          ; Set status byte to indicate free block
    ret                 ; Return

free_skip_block_check:
    ; Move to the next block
    ld bc, 3            ; Size of management overhead
    add hl, bc          ; Move to the next block
    inc de              ; Increment counter

    ; Check if we have reached the end of heap
    ld a, e             ; Load low byte of heap end address
    cp (hl)             ; Compare with low byte of current address
    jr nz, free_search_loop  ; If not equal, continue searching
    ld a, d             ; Load high byte of heap end address
    cp 0                ; Check if it's zero (end of memory)
    jr nz, free_search_loop  ; If not zero, continue searching

    ; If we reached here, pointer is not found in heap
    ret

free_exit:
    ret                 ; Return

; Define heap start and end addresses
;heap_start:    .dw 0xC000   ; Start of heap
;heap_end:      .dw 0xE000   ; End of heap

endif


if MALLOC_1



; from https://gist.github.com/tomstorey/947a8b084bad69391a4b2a1c5b6d69ca

;moved to firmware.asm
;heap_start        .equ  0x9000      ; Starting address of heap
;heap_size         .equ  0x0100      ; Number of bytes available in heap

;      .org 0
;      jp    main


;      .org  0x100
;main:
;      ld    HL, 0x8100
;      ld    SP, HL
;
;      call  heap_init
;
;      ; Make some allocations
;      ld    HL, 12
;      call  malloc            ; Allocates 0x9004
;
;      ld    HL, 12
;      call  malloc            ; Allocates 0x9014
;
;      ld    HL, 12
;      call  malloc            ; Allocates 0x9024
;
;      ; Free some allocations
;      ld    HL, 0x9014
;      call  free
;
;      ld    HL, 0x9004
;      call  free
;
;      ld    HL, 0x9024
;      call  free
;
;
;      halt


;------------------------------------------------------------------------------
;     heap_init                                                               :
;                                                                             :
; Description                                                                 :
;     Initialise the heap and make it ready for malloc and free operations.   :
;                                                                             :
;     The heap is maintained as a linked list, starting with an initial       :
;     "dummy block" of zero size which is mainly used to hold a pointer to    :
;     the first free block in the heap. Each block then points to the next    :
;     free block within the heap, and the free list ends at the first block   :
;     with a null pointer to the next free block.                             :
;                                                                             :
; Parameters                                                                  :
;     Inputs are compile-time only. Two defines which specify the starting    :
;     address of the heap and its size are required, along with a memory      :
;     allocation of 4 consecutive bytes which is used for a dummy block which :
;     principally stores a pointer to the first free block in the heap.       :
;                                                                             :
; Returns                                                                     :
;     Nothing                                                                 :
;------------------------------------------------------------------------------
heap_init:
      push  HL

      ; Initialise free list struct
      ld    HL, heap_start
      ld    (free_list), HL
      ld    HL, 0
      ld    (free_list+2), HL

      ; Insert first free block at bottom of heap, consumes entire heap
      ld    HL, heap_start+heap_size-4
      ld    (heap_start), HL        ; Next block (end of free list)
      ld    HL, heap_size-4
      ld    (heap_start+2), HL      ; Block size

      ; Insert end of free list block at top of heap - two null words will
      ; terminate the free list
      ld    HL, 0
      ld    (heap_start+heap_size-2), HL
      ld    (heap_start+heap_size-4), HL

      pop   HL

      ret


;------------------------------------------------------------------------------
;     malloc                                                                  :
;                                                                             :
; Description                                                                 :
;     Allocates the wanted space from the heap and returns the address of the :
;     first useable byte of the allocation.                                   :
;                                                                             :
;     Allocations can happen in one of two ways:                              :
;                                                                             :
;     1. A free block may be found which is the exact size wanted. In this    :
;        case the block is removed from the free list and retuedn to the      :
;        caller.                                                              :
;     2. A free block may be found which is larger than the size wanted. In   :
;        this case, the larger block is split into two. The first portion of  :
;        this block will become the requested space by the malloc call and    :
;        is returned to the caller. The second portion becomes a new free     :
;        block, and the free list is adjusted to maintain continuity via this :
;        newly created block.                                                 :
;                                                                             :
;     malloc does not set any initial value in the allocated space, the       :
;     caller is required to do this as required.                              :
;                                                                             :
;     This implementation of malloc uses the stack exclusively, and is        :
;     therefore re-entrant. But due to the Z80's lack of atomicity, it is     :
;     advisable to disable interrupts before calling malloc, and recommended  :
;     to avoid the use of malloc inside ISRs in general.                      :
;                                                                             :
;     NOTE: heap_init must be called before malloc and free can be used.      :
;                                                                             :
; Parameters                                                                  :
;     HL  Number of bytes wanted                                              :
;                                                                             :
; Returns                                                                     :
;     HL  Address of the first useable byte of the allocation                 :
;                                                                             :
; Flags                                                                       :
;     Z   Set if the allocation did not succeed, clear otherwise              :
;                                                                             :
; Stack frame                                                                 :
;       |             |                                                       :
;       +-------------+                                                       :
;       |     BC      |                                                       :
;       +-------------+                                                       :
;       |     DE      |                                                       :
;       +-------------+                                                       :
;       |     IX      |                                                       :
;       +-------------+                                                       :
;       |  prev_free  |                                                       :
;   +4  +-------------+                                                       :
;       |  this_free  |                                                       :
;   +2  +-------------+                                                       :
;       |  next_free  |                                                       :
;   +0  +-------------+                                                       :
;       |             |                                                       :
;                                                                             :
;------------------------------------------------------------------------------


malloc:

	SAVESP ON 1

	call malloc_code

	CHECKSP ON 1
	ret


malloc_code:
      push  BC
      push  DE
      push  IX
if DEBUG_FORTH_MALLOC_HIGH
call malloc_guard_entry
endif

		if DEBUG_FORTH_MALLOC
			DMARK "mal"
			CALLMONITOR
		endif
      ld    A, H                    ; Exit if no space requested
      or    L
      jp    Z, malloc_early_exit

;inc hl
;inc hl
;inc hl
;
;inc hl
;inc hl
;inc hl
;inc hl
;inc hl
;inc hl
;inc hl
;inc hl
;inc hl




		if DEBUG_FORTH_MALLOC
			DMARK "maA"
			CALLMONITOR
		endif
      ; Set up stack frame
      ex    DE, HL
      ld    HL, -6                  ; Reserve 6 bytes for stack frame
      add   HL, SP
      ld    SP, HL
      ld    IX, 0                   ; Use IX as a frame pointer
      add   IX, SP

      ; Setup initial state
      ld    HL, 4                   ; want must also include space used by block struct
      add   HL, DE

      ld    B, H                    ; Move want to BC
      ld    C, L

      ld    HL, free_list           ; Store prev_free ptr to stack
      ld    (IX+4), L
      ld    (IX+5), H

      ld    E, (HL)                 ; Store this_free ptr to stack
      inc   HL
      ld    D, (HL)
      ld    (IX+2), E
      ld    (IX+3), D
      ex    DE, HL                  ; this_free ptr into HL

		if DEBUG_FORTH_MALLOC
			DMARK "maB"
			CALLMONITOR
		endif
      ; Loop through free block list to find some space
malloc_find_space:
      ld    E, (HL)                 ; Load next_free ptr into DE
      inc   HL
      ld    D, (HL)

      ld    A, D                    ; Check for null next_free ptr - end of free list
      or    E
      jp    Z, malloc_no_space

      ld    (IX+0), E               ; Store next_free ptr to stack
      ld    (IX+1), D

      ; Does this block have enough space to make the allocation?
      inc   HL                      ; Load free block size into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)

      ex    DE, HL                  ; Check size of block against want
      or    A                       ; Ensure carry flag clear
      sbc   HL, BC
      push  HL                      ; Store the result for later (new block size)

      jp   Z, malloc_alloc_fit     ; Z means block size matches want - can allocate
      jr    NC, malloc_alloc_split  ; NC means block is bigger than want - can allocate

      ; this_free block is not big enough, setup ptrs to test next free block
      pop   HL                      ; Discard previous result

      ld    L, (IX+2)               ; Move this_free ptr into prev_free
      ld    H, (IX+3)
      ld    (IX+4), L
      ld    (IX+5), H

      ld    L, (IX+0)               ; Move next_free ptr into this_free
      ld    H, (IX+1)
      ld    (IX+2), L
      ld    (IX+3), H

		if DEBUG_FORTH_MALLOC
			DMARK "MA>"
			CALLMONITOR
		endif
      jr    malloc_find_space

      ; split a bigger block into two - requested size and remaining size
malloc_alloc_split:
		if DEBUG_FORTH_MALLOC
			DMARK "MAs"
			CALLMONITOR
		endif
      ex    DE, HL                  ; Calculate address of new free block
      dec   HL
      dec   HL
      dec   HL
      add   HL, BC

      ; Create a new block and point it at next_free
      ld    E, (IX+0)               ; Load next_free ptr into DE
      ld    D, (IX+1)

      ld    (HL), E                 ; Store next_free ptr into new block
      inc   HL
      ld    (HL), D

      pop   DE                      ; Store size of new block into new block
      inc   HL
      ld    (HL), E
      inc   HL
      ld    (HL), D

      ; Update this_free ptr to point to new block
      dec   HL
      dec   HL
      dec   HL

      ld    E, (IX+2)               ; Take a copy of current this_free ptr
      ld    D, (IX+3)

      ld    (IX+2), L               ; Store new block addr as this_free ptr
      ld    (IX+3), H

      ; Modify this_free block to be allocation
      ex    DE, HL
      xor   A                       ; Null the next block ptr of allocated block
      ld    (HL), A
      inc   HL
      ld    (HL), A

      inc   HL                      ; Store want size into allocated block
      ld    (HL), C
      inc   HL
      ld    (HL), B
      inc   HL
      push  HL                      ; Address of allocation to return

      jr    malloc_update_links

malloc_alloc_fit:
      pop   HL                      ; Dont need new block size, want is exact fit

		if DEBUG_FORTH_MALLOC
			DMARK "MAf"
			CALLMONITOR
		endif
      ; Modify this_free block to be allocation
      ex    DE, HL
      dec   HL
      dec   HL
      dec   HL

      xor   A                       ; Null the next block ptr of allocated block
      ld    (HL), A
      inc   HL
      ld    (HL), A

      inc   HL                      ; Store address of allocation to return
      inc   HL
      inc   HL
      push  HL

      ; Copy next_free ptr to this_free, remove allocated block from free list
      ld    L, (IX+0)               ; next_free to HL
      ld    H, (IX+1)

      ld    (IX+2), L               ; HL to this_free
      ld    (IX+3), H


malloc_update_links:
      ; Update prev_free ptr to point to this_free
      ld    L, (IX+4)               ; prev_free ptr to HL
      ld    H, (IX+5)

      ld    E, (IX+2)               ; this_free ptr to DE
      ld    D, (IX+3)

      ld    (HL), E                 ; this_free ptr into prev_free
      inc   HL
      ld    (HL), D

		if DEBUG_FORTH_MALLOC
			DMARK "Mul"
			CALLMONITOR
		endif
      ; Clear the Z flag to indicate successful allocation
      ld    A, D
      or    E

      pop   DE                      ; Address of allocation
		if DEBUG_FORTH_MALLOC
			DMARK "MAu"
			CALLMONITOR
		endif

malloc_no_space:
      ld    HL, 6                   ; Clean up stack frame
      add   HL, SP
      ld    SP, HL

      ex    DE, HL                  ; Alloc addr into HL for return
		if DEBUG_FORTH_MALLOC
			DMARK "MAN"
			CALLMONITOR
		endif

malloc_early_exit:
		if DEBUG_FORTH_MALLOC
			DMARK "MAx"
			CALLMONITOR
		endif
      pop   IX
      pop   DE
      pop   BC

if DEBUG_FORTH_MALLOC_HIGH
call malloc_guard_exit
call malloc_guard_zerolen
endif
      ret


;------------------------------------------------------------------------------
;     free                                                                    :
;                                                                             :
; Description                                                                 :
;     Return the space pointed to by HL to the heap. HL must be an address as :
;     returned by malloc, otherwise the behaviour is undefined.               :
;                                                                             :
;     Where possible, directly adjacent free blocks will be merged together   :
;     into larger blocks to help ensure that the heap does not become         :
;     excessively fragmented.                                                 :
;                                                                             :
;     free does not clear or set any other value into the freed space, and    :
;     therefore its contents may be visible through subsequent malloc's. The  :
;     caller should clear the freed space as required.                        :
;                                                                             :
;     This implementation of free uses the stack exclusively, and is          :
;     therefore re-entrant. But due to the Z80's lack of atomicity, it is     :
;     advisable to disable interrupts before calling free, and recommended    :
;     to avoid the use of free inside ISRs in general.                        :
;                                                                             :
;     NOTE: heap_init must be called before malloc and free can be used.      :
;                                                                             :
; Parameters                                                                  :
;     HL  Pointer to address of first byte of allocation to be freed          :
;                                                                             :
; Returns                                                                     :
;     Nothing                                                                 :
;                                                                             :
; Stack frame                                                                 :
;       |             |                                                       :
;       +-------------+                                                       :
;       |     BC      |                                                       :
;       +-------------+                                                       :
;       |     DE      |                                                       :
;       +-------------+                                                       :
;       |     IX      |                                                       :
;       +-------------+                                                       :
;       |  prev_free  |                                                       :
;   +2  +-------------+                                                       :
;       |  next_free  |                                                       :
;   +0  +-------------+                                                       :
;       |             |                                                       :
;                                                                             :
;------------------------------------------------------------------------------
free:
      push  BC
      push  DE
      push  IX

      ld    A, H                    ; Exit if ptr is null
      or    L
      jp    Z, free_early_exit

      ; Set up stack frame
      ex    DE, HL
      ld    HL, -4                  ; Reserve 4 bytes for stack frame
      add   HL, SP
      ld    SP, HL
      ld    IX, 0                   ; Use IX as a frame pointer
      add   IX, SP

      ; The address in HL points to the start of the useable allocated space,
      ; but the block struct starts 4 bytes before this. Sub 4 to get the
      ; address of the block itself.
      ex    DE, HL
      ld    DE, -4
      add   HL, DE

      ; An allocated block must have a null next block pointer in it
      ld    A, (HL)
      inc   HL
      or    (HL)
      jp    NZ, free_done

      dec   HL

      ld    B, H                    ; Copy HL to BC
      ld    C, L

      ; Loop through the free list to find the first block with an address
      ; higher than the block being freed
      ld    HL, free_list

free_find_higher_block:
      ld    E, (HL)                 ; Load next ptr from free block
      inc   HL
      ld    D, (HL)
      dec   HL

      ld    (IX+0), E               ; Save ptr to next free block
      ld    (IX+1), D
      ld    (IX+2), L               ; Save ptr to prev free block
      ld    (IX+3), H

      ld    A, B                    ; Check if DE is greater than BC
      cp    D                       ; Compare MSB first
      jr    Z, $+4                  ; MSB the same, compare LSB
      jr    NC, free_find_higher_block_skip
      ld    A, C
      cp    E                       ; Then compare LSB
      jr    C, free_found_higher_block

free_find_higher_block_skip:
      ld    A, D                    ; Reached the end of the free list?
      or    E
      jp    Z, free_done

      ex    DE, HL

      jr    free_find_higher_block

free_found_higher_block:
      ; Insert freed block between prev and next free blocks
      ld    (HL), C                 ; Point prev free block to freed block
      inc   HL
      ld    (HL), B

      ld    H, B                    ; Point freed block at next free block
      ld    L, C
      ld    (HL), E
      inc   HL
      ld    (HL), D

      ; Check if the freed block is adjacent to the next free block
      inc   HL                      ; Load size of freed block into HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      ex    DE, HL

      add   HL, BC                  ; Add addr of freed block and its size

      ld    E, (IX+0)               ; Load addr of next free block into DE
      ld    D, (IX+1)

      or    A                       ; Clear the carry flag
      sbc   HL, DE                  ; Subtract addrs to compare adjacency
      jr    NZ, free_check_adjacent_to_prev

      ; Freed block is adjacent to next, merge into one bigger block
      ex    DE, HL                  ; Load next ptr from next block into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  HL                      ; Save ptr to next block for later

      ld    H, B                    ; Store ptr from next block into freed block
      ld    L, C
      ld    (HL), E
      inc   HL
      ld    (HL), D

      pop   HL                      ; Restore ptr to next block
      inc   HL                      ; Load size of next block into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  DE                      ; Save next block size for later

      ld    H, B                    ; Load size of freed block into HL
      ld    L, C
      inc   HL
      inc   HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      ex    DE, HL

      pop   DE                      ; Restore size of next block
      add   HL, DE                  ; Add sizes of both blocks
      ex    DE, HL

      ld    H, B                    ; Store new bigger size into freed block
      ld    L, C
      inc   HL
      inc   HL
      ld    (HL), E
      inc   HL
      ld    (HL), D

free_check_adjacent_to_prev:
      ; Check if the freed block is adjacent to the prev free block
      ld    L, (IX+2)               ; Prev free block ptr into HL
      ld    H, (IX+3)

      inc   HL                      ; Size of prev free block into DE
      inc   HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      dec   HL
      dec   HL
      dec   HL

      add   HL, DE                  ; Add prev block addr and size

      or    A                       ; Clear the carry flag
      sbc   HL, BC                  ; Subtract addrs to compare adjacency
      jr    NZ, free_done

      ; Freed block is adjacent to prev, merge into one bigger block
      ld    H, B                    ; Load next ptr from freed block into DE
      ld    L, C
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  HL                      ; Save freed block ptr for later

      ld    L, (IX+2)               ; Store freed block ptr into prev block
      ld    H, (IX+3)
      ld    (HL), E
      inc   HL
      ld    (HL), D

      pop   HL                      ; Restore freed block ptr
      inc   HL                      ; Load size of freed block into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  DE                      ; Save freed block size for later

      ld    L, (IX+2)               ; Load size of prev block into DE
      ld    H, (IX+3)
      inc   HL
      inc   HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)

      pop   HL                      ; Add sizes of both blocks
      add   HL, DE
      ex    DE, HL

      ld    L, (IX+2)               ; Store new bigger size into prev block
      ld    H, (IX+3)
      inc   HL
      inc   HL
      ld    (HL), E
      inc   HL
      ld    (HL), D

free_done:
      ld    HL, 4                   ; Clean up stack frame
      add   HL, SP
      ld    SP, HL

free_early_exit:
      pop   IX
      pop   DE
      pop   BC

      ret

; moved to firmware.asm
;
;free_list         .dw   0     ; Block struct for start of free list (MUST be 4 bytes)
;                  .dw   0


endif


if MALLOC_3
; https://gist.githubusercontent.com/tomstorey/947a8b084bad69391a4b2a1c5b6d69ca/raw/5a08fb30a480d98c0deb4a6afe2d48961cc8e9d9/z80_malloc.s
;heap_start        .equ  0x9000      ; Starting address of heap
;heap_size         .equ  0x0100      ; Number of bytes available in heap
;
 ;     .org 0
  ;    jp    main
;
;
 ;     .org  0x100
;main:
 ;     ld    HL, 0x8100
  ;    ld    SP, HL
;
;      call  heap_init

      ; Make some allocations
;      ld    HL, 12
;      call  malloc            ; Allocates 0x9004
;
 ;     ld    HL, 12
;      call  malloc            ; Allocates 0x9014

;      ld    HL, 12
;      call  malloc            ; Allocates 0x9024

      ; Free some allocations
;      ld    HL, 0x9014
;      call  free

;      ld    HL, 0x9004
;      call  free
;
;      ld    HL, 0x9024
;      call  free


 ;     halt


;------------------------------------------------------------------------------
;     heap_init                                                               :
;                                                                             :
; Description                                                                 :
;     Initialise the heap and make it ready for malloc and free operations.   :
;                                                                             :
;     The heap is maintained as a linked list, starting with an initial       :
;     "dummy block" of zero size which is mainly used to hold a pointer to    :
;     the first free block in the heap. Each block then points to the next    :
;     free block within the heap, and the free list ends at the first block   :
;     with a null pointer to the next free block.                             :
;                                                                             :
; Parameters                                                                  :
;     Inputs are compile-time only. Two defines which specify the starting    :
;     address of the heap and its size are required, along with a memory      :
;     allocation of 4 consecutive bytes which is used for a dummy block which :
;     principally stores a pointer to the first free block in the heap.       :
;                                                                             :
; Returns                                                                     :
;     Nothing                                                                 :
;------------------------------------------------------------------------------
heap_init:
      push  HL

      ; Initialise free list struct
      ld    HL, heap_start
      ld    (free_list), HL
      ld    HL, 0
      ld    (free_list+2), HL

      ; Insert first free block at bottom of heap, consumes entire heap
      ld    HL, heap_start+heap_size-4
      ld    (heap_start), HL        ; Next block (end of free list)
      ld    HL, heap_size-4
      ld    (heap_start+2), HL      ; Block size

      ; Insert end of free list block at top of heap - two null words will
      ; terminate the free list
      ld    HL, 0
      ld    (heap_start+heap_size-2), HL
      ld    (heap_start+heap_size-4), HL

      pop   HL

      ret


;------------------------------------------------------------------------------
;     malloc                                                                  :
;                                                                             :
; Description                                                                 :
;     Allocates the wanted space from the heap and returns the address of the :
;     first useable byte of the allocation.                                   :
;                                                                             :
;     Allocations can happen in one of two ways:                              :
;                                                                             :
;     1. A free block may be found which is the exact size wanted. In this    :
;        case the block is removed from the free list and retuedn to the      :
;        caller.                                                              :
;     2. A free block may be found which is larger than the size wanted. In   :
;        this case, the larger block is split into two. The first portion of  :
;        this block will become the requested space by the malloc call and    :
;        is returned to the caller. The second portion becomes a new free     :
;        block, and the free list is adjusted to maintain continuity via this :
;        newly created block.                                                 :
;                                                                             :
;     malloc does not set any initial value in the allocated space, the       :
;     caller is required to do this as required.                              :
;                                                                             :
;     This implementation of malloc uses the stack exclusively, and is        :
;     therefore re-entrant. But due to the Z80's lack of atomicity, it is     :
;     advisable to disable interrupts before calling malloc, and recommended  :
;     to avoid the use of malloc inside ISRs in general.                      :
;                                                                             :
;     NOTE: heap_init must be called before malloc and free can be used.      :
;                                                                             :
; Parameters                                                                  :
;     HL  Number of bytes wanted                                              :
;                                                                             :
; Returns                                                                     :
;     HL  Address of the first useable byte of the allocation                 :
;                                                                             :
; Flags                                                                       :
;     Z   Set if the allocation did not succeed, clear otherwise              :
;                                                                             :
; Stack frame                                                                 :
;       |             |                                                       :
;       +-------------+                                                       :
;       |     BC      |                                                       :
;       +-------------+                                                       :
;       |     DE      |                                                       :
;       +-------------+                                                       :
;       |     IX      |                                                       :
;       +-------------+                                                       :
;       |  prev_free  |                                                       :
;   +4  +-------------+                                                       :
;       |  this_free  |                                                       :
;   +2  +-------------+                                                       :
;       |  next_free  |                                                       :
;   +0  +-------------+                                                       :
;       |             |                                                       :
;                                                                             :
;------------------------------------------------------------------------------
malloc:
      push  BC
      push  DE
      push  IX

      ld    A, H                    ; Exit if no space requested
      or    L
      jp    Z, malloc_early_exit

      ; Set up stack frame
      ex    DE, HL
      ld    HL, -6                  ; Reserve 6 bytes for stack frame
      add   HL, SP
      ld    SP, HL
      ld    IX, 0                   ; Use IX as a frame pointer
      add   IX, SP

      ; Setup initial state
      ld    HL, 4                   ; want must also include space used by block struct
      add   HL, DE

      ld    B, H                    ; Move want to BC
      ld    C, L

      ld    HL, free_list           ; Store prev_free ptr to stack
      ld    (IX+4), L
      ld    (IX+5), H

      ld    E, (HL)                 ; Store this_free ptr to stack
      inc   HL
      ld    D, (HL)
      ld    (IX+2), E
      ld    (IX+3), D
      ex    DE, HL                  ; this_free ptr into HL

      ; Loop through free block list to find some space
malloc_find_space:
      ld    E, (HL)                 ; Load next_free ptr into DE
      inc   HL
      ld    D, (HL)

      ld    A, D                    ; Check for null next_free ptr - end of free list
      or    E
      jp    Z, malloc_no_space

      ld    (IX+0), E               ; Store next_free ptr to stack
      ld    (IX+1), D

      ; Does this block have enough space to make the allocation?
      inc   HL                      ; Load free block size into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)

      ex    DE, HL                  ; Check size of block against want
      or    A                       ; Ensure carry flag clear
      sbc   HL, BC
      push  HL                      ; Store the result for later (new block size)

      jr    Z, malloc_alloc_fit     ; Z means block size matches want - can allocate
      jr    NC, malloc_alloc_split  ; NC means block is bigger than want - can allocate

      ; this_free block is not big enough, setup ptrs to test next free block
      pop   HL                      ; Discard previous result

      ld    L, (IX+2)               ; Move this_free ptr into prev_free
      ld    H, (IX+3)
      ld    (IX+4), L
      ld    (IX+5), H

      ld    L, (IX+0)               ; Move next_free ptr into this_free
      ld    H, (IX+1)
      ld    (IX+2), L
      ld    (IX+3), H

      jr    malloc_find_space

      ; split a bigger block into two - requested size and remaining size
malloc_alloc_split:
      ex    DE, HL                  ; Calculate address of new free block
      dec   HL
      dec   HL
      dec   HL
      add   HL, BC

      ; Create a new block and point it at next_free
      ld    E, (IX+0)               ; Load next_free ptr into DE
      ld    D, (IX+1)

      ld    (HL), E                 ; Store next_free ptr into new block
      inc   HL
      ld    (HL), D

      pop   DE                      ; Store size of new block into new block
      inc   HL
      ld    (HL), E
      inc   HL
      ld    (HL), D

      ; Update this_free ptr to point to new block
      dec   HL
      dec   HL
      dec   HL

      ld    E, (IX+2)               ; Take a copy of current this_free ptr
      ld    D, (IX+3)

      ld    (IX+2), L               ; Store new block addr as this_free ptr
      ld    (IX+3), H

      ; Modify this_free block to be allocation
      ex    DE, HL
      xor   A                       ; Null the next block ptr of allocated block
      ld    (HL), A
      inc   HL
      ld    (HL), A

      inc   HL                      ; Store want size into allocated block
      ld    (HL), C
      inc   HL
      ld    (HL), B
      inc   HL
      push  HL                      ; Address of allocation to return

      jr    malloc_update_links

malloc_alloc_fit:
      pop   HL                      ; Dont need new block size, want is exact fit

      ; Modify this_free block to be allocation
      ex    DE, HL
      dec   HL
      dec   HL
      dec   HL

      xor   A                       ; Null the next block ptr of allocated block
      ld    (HL), A
      inc   HL
      ld    (HL), A

      inc   HL                      ; Store address of allocation to return
      inc   HL
      inc   HL
      push  HL

      ; Copy next_free ptr to this_free, remove allocated block from free list
      ld    L, (IX+0)               ; next_free to HL
      ld    H, (IX+1)

      ld    (IX+2), L               ; HL to this_free
      ld    (IX+3), H


malloc_update_links:
      ; Update prev_free ptr to point to this_free
      ld    L, (IX+4)               ; prev_free ptr to HL
      ld    H, (IX+5)

      ld    E, (IX+2)               ; this_free ptr to DE
      ld    D, (IX+3)

      ld    (HL), E                 ; this_free ptr into prev_free
      inc   HL
      ld    (HL), D

      ; Clear the Z flag to indicate successful allocation
      ld    A, D
      or    E

      pop   DE                      ; Address of allocation

malloc_no_space:
      ld    HL, 6                   ; Clean up stack frame
      add   HL, SP
      ld    SP, HL

      ex    DE, HL                  ; Alloc addr into HL for return

malloc_early_exit:
      pop   IX
      pop   DE
      pop   BC

      ret


;------------------------------------------------------------------------------
;     free                                                                    :
;                                                                             :
; Description                                                                 :
;     Return the space pointed to by HL to the heap. HL must be an address as :
;     returned by malloc, otherwise the behaviour is undefined.               :
;                                                                             :
;     Where possible, directly adjacent free blocks will be merged together   :
;     into larger blocks to help ensure that the heap does not become         :
;     excessively fragmented.                                                 :
;                                                                             :
;     free does not clear or set any other value into the freed space, and    :
;     therefore its contents may be visible through subsequent malloc's. The  :
;     caller should clear the freed space as required.                        :
;                                                                             :
;     This implementation of free uses the stack exclusively, and is          :
;     therefore re-entrant. But due to the Z80's lack of atomicity, it is     :
;     advisable to disable interrupts before calling free, and recommended    :
;     to avoid the use of free inside ISRs in general.                        :
;                                                                             :
;     NOTE: heap_init must be called before malloc and free can be used.      :
;                                                                             :
; Parameters                                                                  :
;     HL  Pointer to address of first byte of allocation to be freed          :
;                                                                             :
; Returns                                                                     :
;     Nothing                                                                 :
;                                                                             :
; Stack frame                                                                 :
;       |             |                                                       :
;       +-------------+                                                       :
;       |     BC      |                                                       :
;       +-------------+                                                       :
;       |     DE      |                                                       :
;       +-------------+                                                       :
;       |     IX      |                                                       :
;       +-------------+                                                       :
;       |  prev_free  |                                                       :
;   +2  +-------------+                                                       :
;       |  next_free  |                                                       :
;   +0  +-------------+                                                       :
;       |             |                                                       :
;                                                                             :
;------------------------------------------------------------------------------
free:
      push  BC
      push  DE
      push  IX

      ld    A, H                    ; Exit if ptr is null
      or    L
      jp    Z, free_early_exit

      ; Set up stack frame
      ex    DE, HL
      ld    HL, -4                  ; Reserve 4 bytes for stack frame
      add   HL, SP
      ld    SP, HL
      ld    IX, 0                   ; Use IX as a frame pointer
      add   IX, SP

      ; The address in HL points to the start of the useable allocated space,
      ; but the block struct starts 4 bytes before this. Sub 4 to get the
      ; address of the block itself.
      ex    DE, HL
      ld    DE, -4
      add   HL, DE

      ; An allocated block must have a null next block pointer in it
      ld    A, (HL)
      inc   HL
      or    (HL)
      jp    NZ, free_done

      dec   HL

      ld    B, H                    ; Copy HL to BC
      ld    C, L

      ; Loop through the free list to find the first block with an address
      ; higher than the block being freed
      ld    HL, free_list

free_find_higher_block:
      ld    E, (HL)                 ; Load next ptr from free block
      inc   HL
      ld    D, (HL)
      dec   HL

      ld    (IX+0), E               ; Save ptr to next free block
      ld    (IX+1), D
      ld    (IX+2), L               ; Save ptr to prev free block
      ld    (IX+3), H

      ld    A, B                    ; Check if DE is greater than BC
      cp    D                       ; Compare MSB first
      jr    Z, $+4                  ; MSB the same, compare LSB
      jr    NC, free_find_higher_block_skip
      ld    A, C
      cp    E                       ; Then compare LSB
      jr    C, free_found_higher_block

free_find_higher_block_skip:
      ld    A, D                    ; Reached the end of the free list?
      or    E
      jp    Z, free_done

      ex    DE, HL

      jr    free_find_higher_block

free_found_higher_block:
      ; Insert freed block between prev and next free blocks
      ld    (HL), C                 ; Point prev free block to freed block
      inc   HL
      ld    (HL), B

      ld    H, B                    ; Point freed block at next free block
      ld    L, C
      ld    (HL), E
      inc   HL
      ld    (HL), D

      ; Check if the freed block is adjacent to the next free block
      inc   HL                      ; Load size of freed block into HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      ex    DE, HL

      add   HL, BC                  ; Add addr of freed block and its size

      ld    E, (IX+0)               ; Load addr of next free block into DE
      ld    D, (IX+1)

      or    A                       ; Clear the carry flag
      sbc   HL, DE                  ; Subtract addrs to compare adjacency
      jr    NZ, free_check_adjacent_to_prev

      ; Freed block is adjacent to next, merge into one bigger block
      ex    DE, HL                  ; Load next ptr from next block into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  HL                      ; Save ptr to next block for later

      ld    H, B                    ; Store ptr from next block into freed block
      ld    L, C
      ld    (HL), E
      inc   HL
      ld    (HL), D

      pop   HL                      ; Restore ptr to next block
      inc   HL                      ; Load size of next block into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  DE                      ; Save next block size for later

      ld    H, B                    ; Load size of freed block into HL
      ld    L, C
      inc   HL
      inc   HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      ex    DE, HL

      pop   DE                      ; Restore size of next block
      add   HL, DE                  ; Add sizes of both blocks
      ex    DE, HL

      ld    H, B                    ; Store new bigger size into freed block
      ld    L, C
      inc   HL
      inc   HL
      ld    (HL), E
      inc   HL
      ld    (HL), D

free_check_adjacent_to_prev:
      ; Check if the freed block is adjacent to the prev free block
      ld    L, (IX+2)               ; Prev free block ptr into HL
      ld    H, (IX+3)

      inc   HL                      ; Size of prev free block into DE
      inc   HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      dec   HL
      dec   HL
      dec   HL

      add   HL, DE                  ; Add prev block addr and size

      or    A                       ; Clear the carry flag
      sbc   HL, BC                  ; Subtract addrs to compare adjacency
      jr    NZ, free_done

      ; Freed block is adjacent to prev, merge into one bigger block
      ld    H, B                    ; Load next ptr from freed block into DE
      ld    L, C
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  HL                      ; Save freed block ptr for later

      ld    L, (IX+2)               ; Store freed block ptr into prev block
      ld    H, (IX+3)
      ld    (HL), E
      inc   HL
      ld    (HL), D

      pop   HL                      ; Restore freed block ptr
      inc   HL                      ; Load size of freed block into DE
      ld    E, (HL)
      inc   HL
      ld    D, (HL)
      push  DE                      ; Save freed block size for later

      ld    L, (IX+2)               ; Load size of prev block into DE
      ld    H, (IX+3)
      inc   HL
      inc   HL
      ld    E, (HL)
      inc   HL
      ld    D, (HL)

      pop   HL                      ; Add sizes of both blocks
      add   HL, DE
      ex    DE, HL

      ld    L, (IX+2)               ; Store new bigger size into prev block
      ld    H, (IX+3)
      inc   HL
      inc   HL
      ld    (HL), E
      inc   HL
      ld    (HL), D

free_done:
      ld    HL, 4                   ; Clean up stack frame
      add   HL, SP
      ld    SP, HL

free_early_exit:
      pop   IX
      pop   DE
      pop   BC

      ret


;      .org 0x8000
;
;free_list         .dw   0     ; Block struct for start of free list (MUST be 4 bytes)
 ;                 .dw   0

endif


if MALLOC_4

; My memory allocation code. Very very simple....
; allocate space under 250 chars

heap_init:
	; init start of heap as zero
	; 

	ld hl, heap_start
	ld a, 0
	ld (hl), a      ; empty block
	inc hl
	ld a, 0
	ld (hl), a      ; length of block
	; write end of list
	inc hl
	ld a,(hl)
	inc hl
	ld a,(hl)
	

	; init some malloc vars

	ld hl, 0
	ld (free_list), hl       ; store last malloc location

	ld hl, free_list+3      ; flag for 'free' being used and force a rescan for reuse of block 
	ld a, 0
	ld (hl), a


	ld hl, heap_start
	; 
	 
	ret


;    free block marker
;    requested size 
;    pointer to next block
;    ....
;    next block marker


; TODO add a flag that is reset on use of free. if flag is reset then start scan from start of heap otherwise use last location
;


malloc: 
	push de
	push bc
	push af

	; hl space required
	
	ld c, l    ; hold space   (TODO only a max of 255)

;	inc c     ; TODO BUG need to fix memory leak on push str
;	inc c
;	inc c
;	inc c
;	inc c
;	inc c
;	inc c



	; start at heap if a free has been issued so we can reclaim it otherwise continue from last time

	ld a, (free_list+3)
	cp 0
	jr z, .contheap

	ld hl, (free_list)     ; get last alloc
		if DEBUG_FORTH_MALLOC_INT
			DMARK "mrs"
			CALLMONITOR
		endif
	jr .startalloc

.contheap:
	ld hl, heap_start

.startalloc:

		if DEBUG_FORTH_MALLOC_INT
			DMARK "mym"
			CALLMONITOR
		endif
.findblock:
		if DEBUG_FORTH_MALLOC_INT
			DMARK "mmf"
			CALLMONITOR
		endif

	ld a,(hl) 
	; if byte is zero then clear to use

	cp 0
	jr z, .foundemptyblock

	; if byte is not clear
	;     then byte is offset to next block

	inc hl
	ld a, (hl) ; get size
.nextblock:	inc hl
		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl
;	inc hl  ; move past the store space
;	inc hl  ; move past zero index 

	; TODO detect no more space

	push hl
	ld de, heap_end
	call cmp16
	pop hl
	jr nc, .nospace

	jr .findblock

.nospace: ld hl, 0
	jp .exit


.foundemptyblock:	
		if DEBUG_FORTH_MALLOC_INT
			DMARK "mme"
			CALLMONITOR
		endif

; TODO has block enough space if reusing???

	; 

; see if this block has been previously used
	inc hl
	ld a, (hl)
	dec hl
	cp 0
	jr z, .newblock

		if DEBUG_FORTH_MALLOC_INT
			DMARK "meR"
			CALLMONITOR
		endif

; no reusing previously allocated block

; is it smaller than previously used?
	
	inc hl    ; move to size
	ld a, c
	sub (hl)        ; we want c < (hl)
	dec hl    ; move back to marker
        jr z, .findblock

	; update with the new size which should be lower

        ;inc  hl   ; negate next move. move back to size 

.newblock:
	; need to be at marker here

		if DEBUG_FORTH_MALLOC_INT
			DMARK "meN"
			CALLMONITOR
		endif


	ld a, c

	ld (free_list+3), a	 ; flag resume from last malloc 
	ld (free_list), hl    ; save out last location


	;inc a     ; space for length byte
	ld (hl), a     ; save block in use marker

	inc hl   ; move to space marker
	ld (hl), a    ; save new space

	inc hl   ; move to start of allocated area
	
;	push hl     ; save where we are - 1 

;	inc hl  ; move past zero index 
	; skip space to set down new marker

	; provide some extra space for now

	inc a    ; actual is one fewer than bytes requested. correct if zero index is taken into account
	inc a
	inc a

	push hl   ; save where we are in the node block

	call addatohl

	; write linked list point

	pop de     ; get our node position
	ex de, hl

	ld (hl), e
	inc hl
	ld (hl), d

	inc hl

	; now at start of allocated data so save pointer

	push hl

	; jump to position of next node and setup empty header in DE

	ex de, hl

;	inc hl ; move past end of block

	ld a, 0
	ld (hl), a   ; empty marker
	inc hl
	ld (hl), a   ; size
	inc hl 
	ld (hl), a   ; ptr
	inc hl
	ld (hl), a   ; ptr


	pop hl

		if DEBUG_FORTH_MALLOC_INT
			DMARK "mmr"
			CALLMONITOR
		endif

.exit:
	pop af
	pop bc
	pop de 
	ret




free: 
	push hl
	push af
	; get address in hl

		if DEBUG_FORTH_MALLOC_INT
			DMARK "fre"
			CALLMONITOR
		endif
	; data is at hl - move to block count
	dec hl
	dec hl    ; get past pointer
	dec hl

	ld a, (hl)    ; need this for a validation check

	dec hl    ; move to block marker

	; now check that the block count and block marker are the same 
        ; this checks that we are on a malloc node and not random memory
        ; OK a faint chance this could be a problem but rare - famous last words!

	ld c, a
	ld a, (hl)   

	cp c
	jr nz, .freeignore      ; not a valid malloc node in use so dont break anything

	; yes good chance we are on a malloc node

	ld a, 0     
	ld (hl), a   ; mark as free

	ld (free_list+3), a	 ; flag reuse of existing block on next malloc

.freeignore: 

	pop af
	pop hl

	ret



endif

; eof
