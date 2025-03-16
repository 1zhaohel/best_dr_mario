    .data
ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000

GRID:
    .space 4096 # 32 * 32 * 4
GRID_SIZE:
    .word 4096
DISPLAY_WIDTH:
    .word 32
DISPLAY_HEIGHT:
    .word 32
PIXEL_SIZE:
    .word 4

FRAMERATE:
    .word 180

# Border within the jar, inclusive
MIN_X:
    .word 0
MAX_X:
    .word 31
MIN_Y:
    .word 0
MAX_Y:
    .word 31
    
RED_COLOR:
    .word 0xff0000
YELLOW_COLOR:
    .word 0xffff00
BLUE_COLOR:
    .word 0x0000ff
BACKGROUND_COLOR:
    .word 0x000000


    .text
	.globl main

# Macro Definitions
    .macro SAVE_RA()
        sub $sp, $sp, 4
        sw $ra, 0($sp)
    .end_macro

    .macro RESTORE_RA()
        lw $ra, 0($sp)
        addi $sp, $sp, 4
    .end_macro


##############################################################################
# MAIN 
##############################################################################

main:
    jal generate_block
    jal reset_timer
    jal initialize_grid
    jal draw_grid
    
    j game_loop

##############################################################################
# INITIALIZATION
##############################################################################

end:
    jr $ra

end_restore_ra:
    RESTORE_RA()
    jr $ra

initialize_grid:
    la $t0, GRID            # Load grid address ($t0) into counter
    lw $t1, GRID_SIZE       # Lood grid size ($t1)
    add $t1, $t1, $t0       # Specify max index ($t1)
    lw $t2, PIXEL_SIZE      # Load pixel size ($t2)
    lw $t3, BACKGROUND_COLOR    # Load pixel color
    while_initialize_grid:
        bge $t0, $t1, end # end loop if counter ($t0) >= max index ($t1)
        sw $t3, 0($t0)      # Save color into grid index 
        add $t0, $t0, $t2   # Increment counter by pixel size
        j while_initialize_grid

draw_grid:
    la $t0, GRID            # Load grid address ($t0) into counter
    lw $t1, GRID_SIZE       # Lood grid size ($t1)
    add $t1, $t1, $t0       # Specify max index ($t1)
    lw $t2, PIXEL_SIZE      # Load pixel size ($t2)
    lw $t3, ADDR_DSPL       # Load display address ($t3) into counter
    while_draw_grid:
        bge $t0, $t1, end   # end loop if counter ($t0) >= max index ($t1)
        lw $t4, 0($t0)      # Load the color from the grid ($t4)
        sw $t4, 0($t3)      # Save color into display index 
        add $t0, $t0, $t2   # Increment grid counter by pixel size
        add $t3, $t3, $t2   # Increment display counter by pixel size
        j while_draw_grid

generate_block:
    # Save $ra (in main after generate_block) and restore after random_color
    SAVE_RA()
    
    lw $t0 DISPLAY_WIDTH
    li $t1 2
    div $t1, $t0, $t1       # Halve the display width into $t1
    subi $t0, $t1, 1        # Subtract 1 from $t1 into $t0
    # initialize half #1 starting coordinates
    move $s0, $t0
    lw $s1, MIN_Y
    # initialize half #1 starting color
    jal random_color
    move $s2, $v0
    # initialize half #2 starting coordinates
    move $s3, $t1
    lw $s4, MIN_Y
    # initialize half #2 starting color
    jal random_color
    move $s5, $v0
    
    # Restore $ra (in main after generate_block) after random_color
    RESTORE_RA()
    jr $ra

random_color:
    # Generate random number from (0, 1, 2)
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    beq $a0, 0, set_color_red
    beq $a0, 1, set_color_yellow
    beq $a0, 2, set_color_blue
    
    set_color_red:
        lw $v0, RED_COLOR
        jr $ra                  # Return to call in generate_block
    
    set_color_yellow:
        lw $v0, YELLOW_COLOR
        jr $ra                  # Return to call in generate_block
    
    set_color_blue:
        lw $v0, BLUE_COLOR
        jr $ra                  # Return to call in generate_block

##############################################################################
# GAME LOOP
##############################################################################
game_loop:
    jal clear_block
    jal keyboard_input
    jal increment_timer
    jal update_block
    jal draw_grid
    
    j game_loop

##############################################################################
# DRAWING/CLEARING BLOCK
##############################################################################

update_block:
    SAVE_RA()

    # Draw new pixel position
    li $a0, 1
    jal draw_block
    
    RESTORE_RA()
    jr $ra

clear_block:
    # Save $ra (in game_loop after clear_block) before draw_block
    SAVE_RA()
    
    # Remove old block position
    li $a0, 0
    jal draw_block
    
    # Restore $ra (in game_loop after clear_block) after draw_block
    RESTORE_RA()
    jr $ra

draw_block:
    # $a0 = 0 to clear, otherwise draw
    
    move $t0, $a0
    
    # Save $ra and $t0 before set_pixel
    sub $sp, $sp, 8
    sw $ra, 4($sp)
    sw $t0, 0($sp)
    
    # Half #1
    move $a0, $s0                   # Load the x-coordinate ($s0) into $a0
    move $a1, $s1                   # Load the y-coordinate ($s1) into $a1
    beqz $t0, clear_color_1         # If input ($a0) is 0, set color to background color
    move $a2, $s2                   # Load pixel color ($s2) into $a2
    j draw_half_1
    clear_color_1:
        lw $a2, BACKGROUND_COLOR
    draw_half_1:
        jal set_pixel                   # Draw the pixel at the x and y-coordinate
    
    # Restore $t0 after set_pixel
    lw $t0, 0($sp)
    
    # Half #2
    move $a0, $s3                   # Load the x-coordinate ($s3) into $a0
    move $a1, $s4                   # Load the y-coordinate ($s4) into $a1
    beqz $t0, clear_color_2         # If input ($a0) is 0, set color to background color
    move $a2, $s5                   # Load pixel color ($s5) into $a2
    j draw_half_2
    clear_color_2:
        lw $a2, BACKGROUND_COLOR
    draw_half_2:
        jal set_pixel                   # Draw the pixel at the x and y-coordinate
    
    # Restore $ra after set_pixel
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

##############################################################################
# KEYBOARD MOVEMENT
##############################################################################

keyboard_input:
    # Save $ra (in main after keyboard_input)
    SAVE_RA()
    
    li $v0, 32                      # Load system call to read character
    li $a0, 1                       # Specify file descriptor (stdin)
    syscall                         # Read a character
                                    
    lw $a0, ADDR_KBRD               # Load base address for keyboard ($t0)
    lw $t1, 0($a0)                  # Load first word from keyboard ($t1)
    beq $t1, 1, handle_input        # If key pressed (first word is 1), handle key press
    
    after_handle_input:
    
    # Restore $ra (in main after keyboard_input)
    RESTORE_RA()
    jr $ra

handle_input:
    # $a0 = full keyboard input
    
    lw $a0, 4($a0)                  # Load second word from keyboard
    
    li $v0, 1                      # Set output
    syscall                         # Print inputted character ($a0)
    
    la $ra, after_move_block
    
    beq $a0, 113, end_game          # Check if the key q was pressed
    
    beq $a0, 119, rotate            # Check if the key w was pressed
    beq $a0, 97, move_left          # Check if the key a was pressed
    beq $a0, 115, move_down         # Check if the key s was pressed
    beq $a0, 100, move_right        # Check if the key d was pressed
    
    beq $a0, 107, rotate            # Check if the key k was pressed
    beq $a0, 104, move_left         # Check if the key h was pressed
    beq $a0, 106, move_down         # Check if the key j was pressed
    beq $a0, 108, move_right        # Check if the key l was pressed
    
    after_move_block:
    
    j after_handle_input

end_game:
	li $v0, 10                      # Quit gracefully
	syscall

rotate:
    SAVE_RA()
    
    la $ra, after_rotate_block
    
    # Half #2 is to the right of half #1
    subi $t0, $s3, 1
    beq $s0, $t0, rotate_three_to_six
    # Half #2 is below half #1
    subi $t1, $s4, 1
    beq $s1, $t1, rotate_six_to_nine
    # Half #2 is to the left of half #1
    addi $t0, $s3, 1
    beq $s0, $t0, rotate_nine_to_twelve
    # Half #2 is above half #1
    addi $t1, $s4, 1
    beq $s1, $t1, rotate_twelve_to_three
    
    after_rotate_block:
    
    RESTORE_RA()
    jr $ra

rotate_three_to_six:
    SAVE_RA()
    
    li $a0, 0
    li $a1, 1
    jal rotate_block
    
    j end_restore_ra

rotate_six_to_nine:
    SAVE_RA()
    
    li $a0, -1
    li $a1, 0
    jal rotate_block
    
    j end_restore_ra

rotate_nine_to_twelve:
    SAVE_RA()
    
    li $a0, 0
    li $a1, -1
    jal rotate_block
    
    j end_restore_ra

rotate_twelve_to_three:
    SAVE_RA()
    
    li $a0, 1
    li $a1, 0
    jal rotate_block
    
    j end_restore_ra

rotate_block:
    # Half #2 of block: $a0 = 1 if going right, $a0 = -1 if going left, $a1 = 1 if going down, $a1 = -1 if going up
    # $v0 = 0 if not rotated, $v0 = 1 if rotated

    # Save $ra, $a0, $a1
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)

    # Rotate if block doesn't collide
    move $a2, $s0
    move $a3, $s1
    jal get_pixel_collision
    beq $v0, 0, do_rotate_block
    li $v0, 0
    j end_rotate_block
    
    do_rotate_block:
        # Restore $a0, $a1
        lw $a0, 4($sp)
        lw $a1, 8($sp)
        
        # Rotate half #2
        add $s3, $s0, $a0
        add $s4, $s1, $a1
        
        li $v0, 1
    
    end_rotate_block:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra
    

move_left:
    SAVE_RA()
    
    li $a0, -1
    li $a1, 0
    jal move_block
    
    j end_restore_ra

move_down:
    SAVE_RA()
    
    li $a0, 0
    li $a1, 1
    jal move_block
    # Place if block doesn't move
    beq $v0, 0, place_down_block
    j end_restore_ra
    
    place_down_block:
        jal update_block
        jal generate_block
        
        j end_restore_ra

move_right:
    SAVE_RA()
    
    li $a0, 1
    li $a1, 0
    jal move_block
    
    j end_restore_ra

move_block:
    # $a0 = 1 if going right, $a0 = -1 if going left, $a1 = 1 if going down
    # $v0 = 0 if not moved, $v0 = 1 if moved

    # Save $ra, $a0, $a1
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    # Move if block doesn't collide
    jal get_block_collision
    beq $v0, 0, do_move_block
    li $v0, 0
    j end_move_block
    
    do_move_block:
        # Restore $a0, $a1
        lw $a0, 4($sp)
        lw $a1, 8($sp)
        
        # Move block
        add $s0, $s0, $a0
        add $s1, $s1, $a1
        add $s3, $s3, $a0
        add $s4, $s4, $a1
        
        li $v0, 1
    
    end_move_block:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra
    
    

##############################################################################
# COLLISION DETECTION
##############################################################################
    
pixel_in_border:               # Not factoring in movement
    # $a0 = x-coordinate, $a1 = y-coordinate
    # $v0 = 0 if no collision, $v0 = 1 if collision
    
    # Collision with at top border
    lw $t0, MIN_Y
    blt $a1, $t0, had_pixel_in_border
    
    # Collision with left border
    lw $t0, MIN_X
    blt $a0, $t0, had_pixel_in_border
    
    # Collision with bottom border
    lw $t0, MAX_Y
    bgt $a1, $t0, had_pixel_in_border
    
    # Collision with right border
    lw $t0, MAX_X
    bgt $a0, $t0, had_pixel_in_border
    
    li $v0, 0
    j end
    
    had_pixel_in_border:
        li $v0, 1
        j end
    

get_pixel_collision:                # Factors in movement
    # $a0 = 1 if going right, $a0 = -1 if going left, $a1 = 1 if going down
    # $a2 = $s0 or $s3, $a3 = $s1 or $s4
    # $v0 = 0 if no collision, $v0 = 1 if collision
    
    SAVE_RA()
    
    # Half of block collision
    add $a0, $a2, $a0
    add $a1, $a3, $a1
    jal pixel_in_border
    beq $v0, 1, has_pixel_collision
    jal get_pixel
    lw $t0, BACKGROUND_COLOR
    bne $v0, $t0, has_pixel_collision
    
    li $v0, 0
    j end_restore_ra
    
    has_pixel_collision:
        li $v0, 1
        j end_restore_ra

get_block_collision:            # Factors in movement
    # $a0 = 1 if going right, $a0 = -1 if going left, $a1 = 1 if going down
    # $v0 = 0 if no collision, $v0 = 1 if collision
    
    # Save $ra, $a0, $a1
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    # Half #1
    move $a2, $s0
    move $a3, $s1
    jal get_pixel_collision
    beq $v0, 1, has_block_collision
    
    # Restore $a0, $a1
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Half #2
    move $a2, $s3
    move $a3, $s4
    jal get_pixel_collision
    beq $v0, 1, has_block_collision
    
    li $v0, 0
    j end_get_block_collision
    
    has_block_collision:
        li $v0, 1
        j end_get_block_collision
    
    end_get_block_collision:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

##############################################################################
# TIMER
##############################################################################

reset_timer:
    li $s6, 0
    
    jr $ra

increment_timer:
    SAVE_RA()
    
    lw $t0, FRAMERATE
    addi $s6, $s6, 1
    
    la $ra after_tick_timer
    beq $s6, $t0, tick_timer
    
    after_tick_timer:
    
    RESTORE_RA()
    jr $ra

tick_timer:
    SAVE_RA()
    
    jal reset_timer
    jal move_down
    
    RESTORE_RA()
    jr $ra


##############################################################################
# GRID GETTER/SETTER
##############################################################################

set_pixel:
    # $a0 = x-coordinate, $a1 = y-coordinate, $a2 = color
    
    # Save $ra before calling coord_to_idx
    SAVE_RA()
    
    jal coord_to_idx
    
    move $t0, $v0           # Move the returned index to $t0
    sw $a2, 0($t0)          # Store the value of $a2 at the address in $t0
    
    # Restore $ra after returning from coord_to_idx
    RESTORE_RA()
    jr $ra

get_pixel:
    # $a0 = x-coordinate, $a1 = y-coordinate
    # $v0 = color of the pixel at the x and y-coordinates
    
    # Save $ra before calling coord_to_idx
    SAVE_RA()
    
    jal coord_to_idx
    
    move $t0, $v0           # Move the returned index to $t0
    lw $v0, 0($t0)          # Load the value at the grid index into $v0
    
    # Restore $ra after returning from coord_to_idx
    RESTORE_RA()
    jr $ra

coord_to_idx:   # Converts x and y-coordinates to the corresponding memory index in the grid
    # $a0 = x-coordinate, $a1 = y-coordinate
    # $v0 = index in display or grid
    
    la $t0, GRID       # Load base address for the grid ($t0)
    
    lw $t1, DISPLAY_WIDTH   # Load the display width ($t1)
    lw $t2, DISPLAY_HEIGHT  # Load the display height ($t2) (not needed)
    lw $t3, PIXEL_SIZE      # Load pixel size/integer length
    
    mult $t4, $a0, $t3      # x-offset ($t4): Multiply x-coordinate ($s0) by pixel size ($t3)
    mult $t5, $a1, $t1      # Convert y-coordinate into length using display width ($t1) 
    mult $t5, $t5, $t3      # y-offset ($t5): Multiply y-coordinate length ($s5) by pixel size ($t3)
    
    add $t0, $t0, $t4       # Add the x-offset ($t4) into the address
    add $t0, $t0, $t5       # Add the y-offset ($t5) into the address
    
    move $v0, $t0
    
    jr $ra      