    .data
ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000

GRID:
    .space 14400 # 60 * 60 * 4
GRID_SIZE:
    .word 14400
DISPLAY_WIDTH:
    .word 60
DISPLAY_HEIGHT:
    .word 60
PIXEL_SIZE:
    .word 4
CELL_SIZE:
    .word 3
CLEAR_LENGTH:
    .word 4

FRAMERATE:
    .word 180

# Border within the jar, inclusive
MIN_X:
    .word 0
MAX_X:
    .word 59
MIN_Y:
    .word 0
MAX_Y:
    .word 59
    
RED_COLOR:
    .word 0xFF79C6
YELLOW_COLOR:
    .word 0xF1FA8C
BLUE_COLOR:
    .word 0x8BE9FD
BACKGROUND_COLOR:
    .word 0x282A36


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
        bge $t0, $t1, end   # End loop if counter ($t0) >= max index ($t1)
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
        bge $t0, $t1, end   # End loop if counter ($t0) >= max index ($t1)
        lw $t4, 0($t0)      # Load the color from the grid ($t4)
        sw $t4, 0($t3)      # Save color into display index 
        add $t0, $t0, $t2   # Increment grid counter by pixel size
        add $t3, $t3, $t2   # Increment display counter by pixel size
        j while_draw_grid

generate_block:
    # Save $ra (in main after generate_block) and restore after random_color
    SAVE_RA()
    
    lw $t0 DISPLAY_WIDTH
    div $t1, $t0, 2         # Halve the display width into $t1
    lw $t2, CELL_SIZE
    div $t3, $t2, 2
    sub $t0, $t1, $t2       # Subtract CELL_SIZE from $t1 into $t0
    # initialize half #1 starting coordinates
    move $s0, $t0
    add $s0, $s0, $t3       # To align with grid correctly
    lw $s1, MIN_Y
    add $s1, $s1, $t3       # To align with grid correctly
    # initialize half #1 starting color
    jal random_color
    move $s2, $v0
    # initialize half #2 starting coordinates
    move $s3, $t1
    add $s3, $s3, $t3       # To align with grid correctl
    lw $s4, MIN_Y
    add $s4, $s4, $t3       # To align with grid correctly
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
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    
    jal get_block_orientation
    
    sw $v0, 8($sp)
    sw $v1, 12($sp)
    
    
    # Restore $t0 after get_block_orientation
    lw $t0, 4($sp)
    
    # Half #1
    move $a0, $s0                   # Load the x-coordinate ($s0) into $a0
    move $a1, $s1                   # Load the y-coordinate ($s1) into $a1
    move $a3, $v0                   # Load the orientation into $a3
    beqz $t0, clear_color_1         # If input ($a0) is 0, set color to background color
    move $a2, $s2                   # Load pixel color ($s2) into $a2
    j draw_half_1
    clear_color_1:
        lw $a2, BACKGROUND_COLOR
    draw_half_1:
        jal set_cell                   # Draw the pixel at the x and y-coordinate
    
    # Restore $t0 after set_pixel
    lw $t0, 4($sp)
    lw $v0, 8($sp)
    lw $v1, 12($sp)
    
    # Half #2
    move $a0, $s3                   # Load the x-coordinate ($s3) into $a0
    move $a1, $s4                   # Load the y-coordinate ($s4) into $a1
    move $a3, $v1                   # Load the orientation into $a3
    beqz $t0, clear_color_2         # If input ($a0) is 0, set color to background color
    move $a2, $s5                   # Load pixel color ($s5) into $a2
    j draw_half_2
    clear_color_2:
        lw $a2, BACKGROUND_COLOR
    draw_half_2:
        jal set_cell                   # Draw the pixel at the x and y-coordinate
    
    # Restore $ra after set_pixel
    lw $ra, 0($sp)
    addi $sp, $sp, 16
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
    
    jal get_block_orientation
    
    la $ra, after_rotate_block
    
    # Half #2 is to the right of half #1
    beq $v0, 3, rotate_three_to_six
    
    # Half #2 is below half #1
    beq $v0, 6, rotate_six_to_nine
    
    # Half #2 is to the left of half #1
    beq $v0, 9, rotate_nine_to_twelve
    
    # Half #2 is above half #1
    beq $v0, 12, rotate_twelve_to_three
    
    after_rotate_block:
    
    RESTORE_RA()
    jr $ra

rotate_three_to_six:
    SAVE_RA()

    lw $t0, CELL_SIZE
    li $a0, 0
    add $a1, $zero, $t0
    jal rotate_block
    
    j end_restore_ra

rotate_six_to_nine:
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    sub $a0, $zero, $t0
    li $a1, 0
    jal rotate_block
    
    j end_restore_ra

rotate_nine_to_twelve:
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    li $a0, 0
    sub $a1, $zero, $t0
    jal rotate_block
    
    j end_restore_ra

rotate_twelve_to_three:
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    add $a0, $zero, $t0
    li $a1, 0
    jal rotate_block
    
    j end_restore_ra

rotate_block:
    # Half #2 of block: $a0 = 1*CELL_SIZE if going right, $a0 = -1*CELL_SIZE if going left, $a1 = 1*CELL_SIZE if going down, $a1 = -1*CELL_SIZE if going up
    # $v0 = 0 if not rotated, $v0 = 1 if rotated

    # Save $ra, $a0, $a1
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)

    # Rotate if block doesn't collide
    move $a2, $s0
    move $a3, $s1
    jal get_cell_collision
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
    
    lw $t0, CELL_SIZE
    sub $a0, $zero, $t0
    li $a1, 0
    jal move_block
    
    j end_restore_ra

move_down:
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    li $a0, 0
    add $a1, $zero, $t0
    jal move_block
    # Place if block doesn't move
    beq $v0, 0, place_down_block
    jal reset_timer                     # OPTIONAL: Reset the timer on move down there's no double move downs?
    j end_restore_ra
    
    place_down_block:
        jal update_block
        jal simulate_grid
        jal generate_block
        
        j end_restore_ra

move_right:
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    add $a0, $zero, $t0
    li $a1, 0
    jal move_block
    
    j end_restore_ra

move_block:
    # $a0 = 1*CELL_SIZE if going right, $a0 = -1*CELL_SIZE if going left, $a1 = 1*CELL_SIZE if going down
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
    

get_cell_collision:                # Factors in movement
    # $a0 = 1 if going right, $a0 = -1 if going left, $a1 = 1 if going down
    # $a2 = $s0 or $s3, $a3 = $s1 or $s4
    # $v0 = 0 if no collision, $v0 = 1 if collision
    
    SAVE_RA()
    
    # Half of block collision
    add $a0, $a2, $a0
    add $a1, $a3, $a1
    jal pixel_in_border
    beq $v0, 1, has_pixel_collision
    jal get_cell
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
    jal get_cell_collision
    beq $v0, 1, has_block_collision
    
    # Restore $a0, $a1
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Half #2
    move $a2, $s3
    move $a3, $s4
    jal get_cell_collision
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

set_cell:
    # $a0 = x-coordinate, $a1 = y-coordinate, $a2 = color
    # $a3 = 0 if all borders, $a3 = 3 if no right border, $a3 = 6 if no bottom border, $a3 = 9 if no left border, $a3 = 12 if no top border
    
    # Calculate half of cell size
    lw $t6, CELL_SIZE
    div $t6, $t6, 2
    
    # Save $ra, $a0, $a1, $t0
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    # Set top left
    sub $a0, $a0, $t6
    sub $a1, $a1, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Set top middle
    beq $a3, 12, skip_set_top_border
    sub $a1, $a1, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    skip_set_top_border:
    
    # Set top right
    add $a0, $a0, $t6
    sub $a1, $a1, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Set middle left
    beq $a3, 9, skip_set_left_border
    sub $a0, $a0, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    skip_set_left_border:
    
    # Set middle right
    beq $a3, 3, skip_set_right_border
    add $a0, $a0, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    skip_set_right_border:
    
    # Set bottom left
    sub $a0, $a0, $t6
    add $a1, $a1, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Set bottom middle
    beq $a3, 6, skip_set_bottom_border
    add $a1, $a1, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    skip_set_bottom_border:
    
    # Set bottom right
    add $a0, $a0, $t6
    add $a1, $a1, $t6
    jal set_pixel
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

get_pixel:
    # $a0 = x-coordinate, $a1 = y-coordinate
    # $v0 = color of the pixel at the x and y-coordinates
    
    # Save $ra before calling coord_to_idx
    SAVE_RA()
    
    jal coord_to_idx
    
    lw $v0, 0($v0)          # Load the value at the grid index into $v0
    
    # Restore $ra after returning from coord_to_idx
    RESTORE_RA()
    jr $ra

set_pixel:
    # $a0 = x-coordinate, $a1 = y-coordinate, $a2 = color
    
    # Save $ra before calling coord_to_idx
    SAVE_RA()
    
    jal coord_to_idx
    
    sw $a2, 0($v0)          # Store the value of $a2 at the address in $t0
    
    # Restore $ra after returning from coord_to_idx
    RESTORE_RA()
    jr $ra

get_cell:                  # Gets top left pixel
    # $a0 = x-coordinate, $a1 = y-coordinate
    # $v0 = color of the cell at the x and y-coordinates
    
    # Save $ra before calling coord_to_idx
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    div $t0, $t0, 2
    sub $a0, $a0, $t0
    sub $a1, $a1, $t0
    
    jal get_pixel
    
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

get_block_orientation:
    # $v0 = orientation of half #1, $v1 = orientation of half #2
    
    lw $t2, CELL_SIZE
    
    # Half #2 is to the right of half #1
    sub $t0, $s3, $t2
    bne $s0, $t0, skip_right_block_orientation
    li $v0, 3
    li $v1, 9
    jr $ra
    skip_right_block_orientation:
    
    # Half #2 is below half #1
    sub $t1, $s4, $t2
    bne $s1, $t1, skip_bottom_block_orientation
    li $v0, 6
    li $v1, 12
    jr $ra
    skip_bottom_block_orientation:
    
    # Half #2 is to the left of half #1
    add $t0, $s3, $t2
    bne $s0, $t0, skip_left_block_orientation
    li $v0, 9
    li $v1, 3
    jr $ra
    skip_left_block_orientation:
    
    # Half #2 is above half #1
    add $t1, $s4, $t2
    bne $s1, $t1, skip_top_block_orientation
    li $v0, 12
    li $v1, 6
    jr $ra
    skip_top_block_orientation:
    
    jr $ra

get_linked_cell:
    # $a0 = x-coordinate of cell, $a1 = y-coordinate of cell
    # $v0 = x-coordinate of linked cell, $v1 = y-coordinate of linked cell
    
    # Save $ra, $a0, $a1
    sub $sp, $sp, 32
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    jal get_cell
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    move $t0, $v0
    sw $t0, 12($sp)             # Save the cell's color
    
    lw $t1, CELL_SIZE
    sw $t1, 16($sp)             # Save the cell's size
    
    # $t2 = x-offset to next cell, $t3 = y-offset to next cell
    
    # add $a0, $a0, $t1
    add $t2, $zero, $t1
    add $t3, $zero, $zero
    jal check_linked_cell
    
    # add $a1, $a1, $t1
    add $t2, $zero, $zero
    add $t3, $zero, $t1
    jal check_linked_cell
    
    # sub $a0, $a0, $t1
    sub $t2, $zero, $t1
    add $t3, $zero, $zero
    jal check_linked_cell
    
    # sub $a1, $a1, $t1
    add $t2, $zero, $zero
    sub $t3, $zero, $t1
    jal check_linked_cell
    
    j after_get_linked_cell
    
    check_linked_cell:
        sw $ra, 20($sp)
        sw $t2, 24($sp)
        sw $t3, 28($sp)
        
        div $t4, $t2, 2
        div $t5, $t3, 2
        add $a0, $a0, $t4
        add $a1, $a1, $t5
        jal get_pixel
        lw $a0, 4($sp)
        lw $a1, 8($sp)
        lw $t0, 12($sp)
        lw $t1, 16($sp)
        lw $t2, 24($sp)
        lw $t3, 28($sp)
        beq $v0, $t0, after_check_linked_cell
        add $v0, $a0, $t2
        add $v1, $a1, $t3
        j after_get_linked_cell
        
        after_check_linked_cell:
        lw $ra, 20($sp)
        jr $ra
    
    after_get_linked_cell:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 32
    jr $ra
    
    
##############################################################################
# GRID SIMULATION
##############################################################################

simulate_grid:
    SAVE_RA()
    
    jal clear_lines
    
    RESTORE_RA()
    jr $ra

clear_lines:
    SAVE_RA()
    
    # Clear rows
    li $a0, 0
    jal clear_loop
    
    # Clear columns
    li $a0, 1
    jal clear_loop
    
    RESTORE_RA()
    jr $ra

clear_loop:
    # $a0 = 0 to clear row lines, $a0 = 1 to clear column lines

    SAVE_RA()
    
    lw $t2, CELL_SIZE           # Specify stride length ($t2) for the index
    lw $t0, DISPLAY_WIDTH
    sub $t0, $t0, $t2
    add $t0, $t0, 1
    lw $t1, DISPLAY_HEIGHT
    sub $t1, $t1, $t2
    add $t1, $t1, 1             # Specify index ($t0, $t1) at the center of the last cell in the grid
    
    li $t3, 0                   # Specify color counter
    lw $t4, BACKGROUND_COLOR    # Specify current color
    
    sub $sp, $sp, 32
    sw $a0, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    sw $t2, 12($sp)
    sw $t3, 16($sp)
    sw $t4, 20($sp)
    
    while_clear_loop:
        beq $a0, 0, check_end_row_clear_loop
        beq $a0, 1, check_end_column_clear_loop
        j after_check_end_clear_loop
        
        check_end_row_clear_loop:
        blt $t1, 0, end_clear_loop
        blt $t0, 0, reset_clear_loop
        j after_check_end_clear_loop
        
        check_end_column_clear_loop:
        blt $t0, 0, end_clear_loop
        blt $t1, 0, reset_clear_loop
        j after_check_end_clear_loop
        
        after_check_end_clear_loop:
        move $a0, $t0
        move $a1, $t1
        jal get_cell
        
        lw $a0, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        lw $t4, 20($sp)
        
        lw $t5, BACKGROUND_COLOR
        beq $v0, $t5, reset_clear_color_counter       # Reset color counter if no block at index
        beq $t4, $t5, start_clear_color_counter       # Start color counter if current color is background
        bne $v0, $t4, start_clear_color_counter       # Start color counter if block at index is difference from current color 
                                                    # Otherwise, increment color counter
        add $t3, $t3, 1
        sw $t3, 16($sp)
        j after_clear_color_counter
        
        start_clear_color_counter:                    # Start the color counter at 1
            la $ra, after_start_clear_color_counter
            lw $t5, CLEAR_LENGTH
            move $t4, $v0
            sw $t4, 20($sp)
            bge $t3, $t5, mark_clear_color            # Mark the clear if found more than CLEAR_LENGTH in a clear
            
            after_start_clear_color_counter:
            li $t3, 1
            sw $t3, 16($sp)
            
            j after_clear_color_counter
        
        reset_clear_color_counter:                    # Reset the color counter to 0
            la $ra, after_reset_clear_color_counter
            lw $t5, CLEAR_LENGTH
            lw $t4, BACKGROUND_COLOR
            sw $t4, 20($sp)
            bge $t3, $t5, mark_clear_color            # Mark the clear if found more than CLEAR_LENGTH in a clear
            
            after_reset_clear_color_counter:
            li $t3, 0
            sw $t3, 16($sp)
            
            j after_clear_color_counter
        
        mark_clear_color:
            sw $ra, 24($sp)
            
            while_mark_clear_color:
                ble $t3, 0, after_mark_clear_color
                
                lw $t5, CELL_SIZE
                mult $t5, $t3, $t5
                
                beq $a0, 0, check_mark_row_clear_color
                beq $a0, 1, check_mark_column_clear_color
                j after_check_mark_clear_color
                
                check_mark_row_clear_color:
                add $t5, $t0, $t5                   # Coordinate of the block to be marked
                sw $t5, 28($sp)
                move $a0, $t5
                move $a1, $t1
                jal unlink_block                    # Unlink block in line
                lw $t1, 8($sp)
                lw $t5, 28($sp)
                move $a0, $t5
                move $a1, $t1
                j after_check_mark_clear_color
                
                check_mark_column_clear_color:
                add $t5, $t1, $t5                   # Coordinate of the block to be marked
                sw $t5, 28($sp)
                move $a0, $t0
                move $a1, $t5
                jal unlink_block                    # Unlink block in line
                lw $t0, 4($sp)
                lw $t5, 28($sp)
                move $a0, $t0
                move $a1, $t5
                j after_check_mark_clear_color
                
                after_check_mark_clear_color:
                lw $a2, BACKGROUND_COLOR
                li $a3, 0
                jal set_cell                        # Clear cell in line
                lw $a0, 0($sp)
                lw $t0, 4($sp)
                lw $t1, 8($sp)
                lw $t2, 12($sp)
                lw $t3, 16($sp)
                lw $t4, 20($sp)
                lw $t5, 28($sp)
                
                sub $t3, $t3, 1
                sw $t3, 16($sp)
                
                j while_mark_clear_color
            
            after_mark_clear_color:
            lw $ra, 24($sp)
            jr $ra
        
        after_clear_color_counter:
        
        beq $a0, 0, check_row_clear_color_counter
        beq $a0, 1, check_column_clear_color_counter
        j after_check_clear_color_counter
        
        check_row_clear_color_counter:
        sub $t0, $t0, $t2
        sw $t0, 4($sp)
        j after_check_clear_color_counter
        
        check_column_clear_color_counter:
        sub $t1, $t1, $t2
        sw $t1, 8($sp)
        j after_check_clear_color_counter
        
        after_check_clear_color_counter:
        
        j while_clear_loop
        
        reset_clear_loop:
            la $ra, after_reset_clear_loop
            lw $t5, CLEAR_LENGTH
            bge $t3, $t5, mark_clear_color            # Mark the clear if found more than CLEAR_LENGTH in a clear
            
            after_reset_clear_loop:
            beq $a0, 0, check_reset_row_clear_loop
            beq $a0, 1, check_reset_column_clear_loop
            j after_check_reset_clear_loop
            
            check_reset_row_clear_loop:
            lw $t0, DISPLAY_WIDTH
            sub $t0, $t0, $t2
            add $t0, $t0, 1       
            sw $t0, 4($sp)
            sub $t1, $t1, $t2
            sw $t1, 8($sp)
            j after_check_reset_clear_loop
            
            check_reset_column_clear_loop:
            lw $t1, DISPLAY_HEIGHT
            sub $t1, $t1, $t2
            add $t1, $t1, 1       
            sw $t1, 8($sp)
            sub $t0, $t0, $t2
            sw $t0, 4($sp)
            j after_check_reset_clear_loop
            
            after_check_reset_clear_loop:
            li $t3, 0
            lw $t4, BACKGROUND_COLOR
            sw $t3, 16($sp)
            sw $t4, 20($sp)
            j while_clear_loop
    
    end_clear_loop:
    
    addi $sp, $sp, 32
    
    j end_restore_ra


unlink_block:
    # $a0 = x-coordinate of a block's half's cell, $a1 = y-coordinate of a block's half's cell  
    
    # Save $ra, $a0, $a1, $t0
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    jal get_linked_cell
    move $a0, $v0
    move $a1, $v1
    jal unlink_cell
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    jal unlink_cell
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

unlink_cell:
    # $a0 = x-coordinate of cell, $a1 = y-coordinate of cell
    
    # Save $ra, $a0, $a1, $t0
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    jal get_cell
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    move $a2, $v0
    li $a3, 0
    jal set_cell
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra