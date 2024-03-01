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

; moved to firmware.asm
;
;free_list         .dw   0     ; Block struct for start of free list (MUST be 4 bytes)
;                  .dw   0

