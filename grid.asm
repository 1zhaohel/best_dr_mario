    .data
ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000

# Grid and sizes
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

# Framerate and timing
FRAMERATE:
    .word 180
ANIMATION_MULTIPLIER:
    .word 2

# Area in jar within border, inclusive
MIN_X:
    .word 9
MAX_X:
    .word 50
MIN_Y:
    .word 9
MAX_Y:
    .word 56
LID_MIN_X:
    .word 24
LID_MAX_X:
    .word 35
LID_MIN_Y:
    .word 3

# Colors
RED_COLOR:
    .word 0xFF79C6
YELLOW_COLOR:
    .word 0xF1FA8C
BLUE_COLOR:
    .word 0x8BE9FD
JAR_COLOR:
    .word 0x6272A4
JAR_HIGHLIGHT_COLOR:
    .word 0xFFB86C
CLEAR_COLOR:
    .word 0xFFB86C
BACKGROUND_COLOR:
    .word 0x282A36


    .text
	.globl main

# Macro definitions
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
    # Initialize grid and start the game loop.
    
    jal generate_block
    jal reset_timer
    jal initialize_grid
    
    # Stat: Test virus code (TO BE DELETED)
    # li $a0, 31
    # li $a1, 55
    # lw $a2, RED_COLOR
    # jal set_virus
    
    # li $a0, 31
    # li $a1, 31
    # lw $a2, BLUE_COLOR
    # jal set_virus
    
    # jal is_virus
    # li $t0, 1
    # beq $v0, $t0, end_game
    
    # jal fall_cell

    # jal get_cell_orientation
    
    # End: Test virus code (TO BE DELETED)
    
    jal draw_jar
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
    # Initialize the grid by setting the color of all pixels to be the 
    # predefined BACKGROUND_COLOR.

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
    # Loop through each pixel in the grid and draw them to the display.
    
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
    # Generate a new 2x1 cell block at the middle top of the screen, 
    # with random colors the cells in each half.

    # Save $ra (in main after generate_block) and restore after random_color
    SAVE_RA()
    
    lw $t0 DISPLAY_WIDTH
    div $t1, $t0, 2         # Halve the display width into $t1
    lw $t2, CELL_SIZE
    div $t3, $t2, 2
    sub $t0, $t1, $t2       # Subtract CELL_SIZE from $t1 into $t0
    # Initialize half #1 starting coordinates
    move $s0, $t0
    add $s0, $s0, $t3       # To align with grid correctly
    lw $s1, MIN_Y
    add $s1, $s1, $t3       # To align with grid correctly
    # Initialize half #1 starting color
    jal random_color
    move $s2, $v0
    # Initialize half #2 starting coordinates
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
    # Generate a random color from RED_COLOR, YELLOW_COLOR, or 
    # BLUE_COLOR.
    # Returns:
    #   $v0: Randomly generated color

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
# JAR DRAWING
##############################################################################

draw_jar:
    # Draws the jar onto the grid, with the JAR_COLOR
    
    SAVE_RA()
    
    lw $a0, JAR_COLOR
    jal set_jar
    
    RESTORE_RA()
    jr $ra

highlight_jar:
    # Draws the jar onto the grid, with the CLEAR_COLOR
    
    SAVE_RA()
    
    lw $a0, JAR_HIGHLIGHT_COLOR
    jal set_jar
    
    RESTORE_RA()
    jr $ra

set_jar:
    # Draws the jar onto the grid with the specified color, based on the MIN_X, MIN_Y, MAX_X, and MAX_Y constants.
    # Args:
    #   $a0: color of the jar
    
    SAVE_RA()
    
    # Set jar color
    move $a2, $a0
    
    # Draw left side of jar
    lw $a0, MIN_X
    sub $a0, $a0, 1 
    lw $a1, MIN_Y
    sub $a1, $a1, 1
    lw $a3, MAX_Y
    sub $a3, $a1, $a3
    sub $a3, $a3, 2
    jal draw_line
    
    # Draw right side of jar
    lw $a0, MAX_X
    add $a0, $a0, 1 
    lw $a1, MIN_Y
    sub $a1, $a1, 1
    lw $a3, MAX_Y
    sub $a3, $a1, $a3
    sub $a3, $a3, 2
    jal draw_line
    
    # Draw bottom of jar
    lw $a0, MIN_X
    sub $a0, $a0, 1 
    lw $a1, MAX_Y
    add $a1, $a1, 1
    lw $a3, MAX_X
    sub $a3, $a3, $a0
    add $a3, $a3, 2
    jal draw_line
    
    # Draw left top of jar
    lw $a0, MIN_X
    sub $a0, $a0, 1 
    lw $a1, MIN_Y
    sub $a1, $a1, 1
    lw $a3, LID_MIN_X
    sub $a3, $a3, $a0
    # add $a3, $a3, 2
    jal draw_line
    
    # Draw right top of jar
    lw $a0, LID_MAX_X
    add $a0, $a0, 1 
    lw $a1, MIN_Y
    sub $a1, $a1, 1
    lw $a3, MAX_X
    sub $a3, $a3, $a0
    add $a3, $a3, 2
    jal draw_line
    
    # Draw left lid of jar
    lw $a0, LID_MIN_X
    sub $a0, $a0, 1 
    lw $a1, LID_MIN_Y
    sub $a1, $a1, 1
    lw $a3, MIN_Y
    sub $a3, $a1, $a3
    # sub $a3, $a3, 2
    jal draw_line
    
    # Draw right lid of jar
    lw $a0, LID_MAX_X
    add $a0, $a0, 1 
    lw $a1, LID_MIN_Y
    sub $a1, $a1, 1
    lw $a3, MIN_Y
    sub $a3, $a1, $a3
    # sub $a3, $a3, 2
    jal draw_line
    
    RESTORE_RA()
    jr $ra

draw_line:
    # Draws a vertical line from the specified coordinates to a length of a color.
    # Args:
    #   $a0: x-coordinate of the top left starting position
    #   $a1: y-coordinate of the top left starting position
    #   $a2: color of the line
    #   $a3: length of the line, in pixels, positive for a 
    #       horizontal line, negative for a vertical line
    
    blt $a3, 0, check_vertical_line
    li $t0, 1
    li $t1, 0
    j after_check_vertical_line
    check_vertical_line:
    li $t0, 0
    li $t1, 1
    sub $a3, $zero, $a3
    after_check_vertical_line:
    li $t2, 0                   # Initialize counter
    
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    sw $t2, 12($sp)
    
    while_draw_line:
        bge $t2, $a3, end_draw_line
        
        jal set_pixel
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        
        # Update coordinates
        add $a0, $a0, $t0
        add $a1, $a1, $t1
        
        # Increment counter
        add $t2, $t2, $t0
        add $t2, $t2, $t1
        sw $t2, 12($sp)
        
        j while_draw_line
    
    end_draw_line:
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra


##############################################################################
# GAME LOOP
##############################################################################
game_loop:
    # Game loop that repeatedly loops until the user quits or the game
    # ends.
    
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
    # Draw the block at the its currently set location.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s2: color of half #1 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    #   $s5: color of half #2 of the block
    
    SAVE_RA()

    # Draw new pixel position
    li $a0, 1
    jal draw_block
    
    RESTORE_RA()
    jr $ra

clear_block:
    # Clear the block from its currently set location.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block

    # Save $ra (in game_loop after clear_block) before draw_block
    SAVE_RA()
    
    # Remove old block position
    li $a0, 0
    jal draw_block
    
    # Restore $ra (in game_loop after clear_block) after draw_block
    RESTORE_RA()
    jr $ra

draw_block:
    # Draw or clear the block at the its currently set location.
    # Args:
    #   $a0: 0 to clear or 1 to draw the block
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s2: color of half #1 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    #   $s5: color of half #2 of the block
    
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
    # Attempt to read an inputted character from the bitmap without
    # blocking.

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
    # Move, rotate, quit, or otherwise do nothing based on the 
    # inputted character.
    # Args:
    #   $a0: full keyboard input
    
    lw $a0, 4($a0)                  # Load second word from keyboard
    
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
    # Quit the game and end the program.
    
	li $v0, 10                      # Quit gracefully
	syscall

rotate:
    # Attempt to rotate the block based on its current
    # orientation.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    
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
    # Attempt to rotate the block from being angled to the right to 
    # being angled downwards.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    
    SAVE_RA()

    lw $t0, CELL_SIZE
    li $a0, 0
    add $a1, $zero, $t0
    jal rotate_block
    
    j end_restore_ra

rotate_six_to_nine:
    # Attempt to rotate the block from being angled to downards to 
    # being angled to the left.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block

    SAVE_RA()
    
    lw $t0, CELL_SIZE
    sub $a0, $zero, $t0
    li $a1, 0
    jal rotate_block
    
    j end_restore_ra

rotate_nine_to_twelve:
    # Attempt to rotate the block from being angled to to the left to 
    # being angled upwards.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block

    SAVE_RA()
    
    lw $t0, CELL_SIZE
    li $a0, 0
    sub $a1, $zero, $t0
    jal rotate_block
    
    j end_restore_ra

rotate_twelve_to_three:
    # Attempt to rotate the block from being angled upwards to 
    # being angled to the right.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    add $a0, $zero, $t0
    li $a1, 0
    jal rotate_block
    
    j end_restore_ra

rotate_block:
    # Attempt to rotate half #2 of the block based on the arguments
    # that specify where the cell should be moved to. This will not
    # rotate the block if it would cause a collision with filled
    # space or the border.
    # Args:
    #   $a0: CELL_SIZE to rotate right, -CELL_SIZE to rotate left, 
    #       0 otherwise
    #   $a1: CELL_SIZE to rotate down, -CELL_SIZE to rotate up, 
    #       0 otherwise
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    # Returns:
    #   $v0: 0 if not rotated, 1 if successfully rotated

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
    # Attempt to move the block to the left.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    
    SAVE_RA()
    
    lw $t0, CELL_SIZE
    sub $a0, $zero, $t0
    li $a1, 0
    jal move_block
    
    j end_restore_ra

move_down:
    # Attempt to move the block to down, and place it on a succesful
    # movement.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block

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
    # Attempt to move the block to the right.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block

    SAVE_RA()
    
    lw $t0, CELL_SIZE
    add $a0, $zero, $t0
    li $a1, 0
    jal move_block
    
    j end_restore_ra

move_block:
    # Attempt to move the block based on the arguments that specify
    # where the block should be moved. This will not move the block if 
    # it would cause a collision with filled space or the border.
    # Args:
    #   $a0: CELL_SIZE if going right, -CELL_SIZE if going left, 
    #       0 otherwise
    #   $a1: CELL_SIZE if going down, -CELL_SIZE if going up, 
    #       0 otherwise
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    # Returns:
    #   $v0: 0 if not moved, 1 if successfully moved

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
    
pixel_in_border:
    # Check whether the specified coordinates is outside or in the
    # borders or not, without factoring in any movement.
    # Args:
    #   $a0: x-coordinate of pixel
    #   $a1 = y-coordinate of pixel
    # Returns:
    #   $v0: 0 if no collision, 1 if collision with border
    
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
    

get_cell_collision:
    # Checks whether the specified cell coordinates will have a
    # collision with the border or a filled space, based on the 
    # specified movement.
    # Args:
    #   $a0: CELL_SIZE if going right, -CELL_SIZE if going left, 
    #       0 otherwise
    #   $a1: CELL_SIZE if going down, -CELL_SIZE if going up, 
    #       0 otherwise
    #   $a2: x-coordinate of cell
    #   $a3: y-coordinate of cell
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    # Returns:
    #   $v0 = 0 if no collision, $v0 = 1 if collision
    
    SAVE_RA()
    
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

get_block_collision:
    # Checks whether the block will have a collision with the border
    # or a filled space, based on the specified movement.
    # Args:
    #   $a0: CELL_SIZE if going right, -CELL_SIZE if going left, 
    #       0 otherwise
    #   $a1: CELL_SIZE if going down, -CELL_SIZE if going up, 
    #       0 otherwise
    #   $a2: x-coordinate of cell
    #   $a3: y-coordinate of cell
    # Returns:
    #   $v0 = 0 if no collision, $v0 = 1 if collision
    
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
    # Reset the timer back to 0.
    
    li $s6, 0
    
    jr $ra

increment_timer:
    # Increments the timer by 1, and tick it if it reaches the
    # maximum.
    # Args:
    #   $s6: timer

    SAVE_RA()
    
    lw $t0, FRAMERATE
    addi $s6, $s6, 1
    
    la $ra after_tick_timer
    beq $s6, $t0, tick_timer
    
    after_tick_timer:
    
    RESTORE_RA()
    jr $ra

tick_timer:
    # Move the block down and reset the timer finishes a cycle.
    
    SAVE_RA()
    
    jal reset_timer
    jal move_down
    
    RESTORE_RA()
    jr $ra

pause_tick:
    # Pause the game until the timer completes a full cycle, depending
    # on the ANIMATION_MULTIPLIER, and redraw the grid after the tick. 
    SAVE_RA()
    
    jal reset_timer
    while_pause_tick:
        lw $t0, FRAMERATE
        lw $t1, ANIMATION_MULTIPLIER
        mult $t0, $t0, $t1
        beq $s6, $t0, end_pause_tick
        addi $s6, $s6, 1
        jal draw_grid
        j while_pause_tick
    
    end_pause_tick:
    jal reset_timer
    RESTORE_RA()
    jr $ra
    

##############################################################################
# GRID GETTER/SETTER
##############################################################################

set_cell:
    # Draw the cell with the at the specified coordinates, with the 
    # specified color, and orientation, depending on the CELL_SIZE.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    #   $a2: color of the cell
    #   $a3: 0 for all borders, 3 for no right border, 6 for no bottom
    #       border, 9 for no left border, 12 for no top border
    
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
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Set middle
    lw $a2, BACKGROUND_COLOR
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

set_virus:
    # Draw the virus with the specified coordinates, with the specified 
    # color depending on the CELL_SIZE.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    #   $a2: color of the cell
    
    # Calculate half of cell size
    lw $t6, CELL_SIZE
    div $t6, $t6, 2
    
    # Save $ra, $a0, $a1
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
    
    # Set top right
    add $a0, $a0, $t6
    sub $a1, $a1, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Set middle left
    sub $a0, $a0, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    
    # Set middle right
    add $a0, $a0, $t6
    jal set_pixel
    
    lw $a0, 4($sp)
    
    # Set bottom middle
    add $a1, $a1, $t6
    jal set_pixel
    
    lw $a1, 8($sp)
    
    # Set middle
    jal set_pixel
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

get_pixel:
    # Get the pixel at the specified coordinates in the grid.
    # Args:
    #   $a0: x-coordinate of the pixel
    #   $a1: y-coordinate of the pixel
    # Returns:
    #   $v0: color of the pixel
    
    # Save $ra before calling coord_to_idx
    SAVE_RA()
    
    jal coord_to_idx
    
    lw $v0, 0($v0)          # Load the value at the grid index into $v0
    
    # Restore $ra after returning from coord_to_idx
    RESTORE_RA()
    jr $ra

set_pixel:
    # Set the pixel at the specified coordinates in the grid.
    # Args:
    #   $a0: x-coordinate of the pixel
    #   $a1: y-coordinate of the pixel
    #   $a2: color of the pixel
    
    # Save $ra before calling coord_to_idx
    SAVE_RA()
    
    jal coord_to_idx
    
    sw $a2, 0($v0)          # Store the value of $a2 at the address in $t0
    
    # Restore $ra after returning from coord_to_idx
    RESTORE_RA()
    jr $ra

get_cell:
    # Return the color of the cell with the at the specified 
    # coordinates, using the color of the top-left corner of the cell.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    # Returns:
    #   $v0: color of the cell
    
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

coord_to_idx:
    # Convert the specified coordinates into the correspnding memory
    # index in the grid. 
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    # Returns:
    #   $v0: corresponding index in the grid
    
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
    # Return the orientation of both halves of the block, depending on
    # their locations.
    # Args:
    #   $s0: x-coordinate of half #1 of the block
    #   $s1: y-coordinate of half #2 of the block
    #   $s3: x-coordinate of half #2 of the block
    #   $s4: y-coorindate of half #2 of the block
    # Returns:
    #   $v0: orientation of half #1
    #   $v1: orientation of half #2
    #   The orientation is 3 if facing right, 6 if facing down, 
    #       9 if facing down, 12 if facing up, and 0 otherwise
    
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
    # Return the coordinates of the linked cell, or return the same
    # coordinates that were specified of there is no linked cell, 
    # based on the orientation of cell at the specified coordinates.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    # Returns:
    #   $v0: x-coordinate of the linked cell
    #   $v1: y-coordinate of the linked cell
    
    SAVE_RA()
    
    jal get_cell_orientation
    lw $t0, CELL_SIZE
    
    bne $v0, 3, skip_right_cell_orientation
    add $v0, $a0, $t0
    add $v1, $a1, 0
    j end_restore_ra
    skip_right_cell_orientation:
    
    bne $v0, 6, skip_down_cell_orientation
    add $v0, $a0, 0
    add $v1, $a1, $t0
    j end_restore_ra
    skip_down_cell_orientation:
    
    bne $v0, 9, skip_left_cell_orientation
    sub $v0, $a0, $t0
    add $v1, $a1, 0
    j end_restore_ra
    skip_left_cell_orientation:
    
    bne $v0, 12, skip_bottom_cell_orientation
    add $v0, $a0, 0
    sub $v1, $a1, $t0
    j end_restore_ra
    skip_bottom_cell_orientation:
    
    move $v0, $a0
    move $v1, $a1
    j end_restore_ra

get_cell_orientation:
    # Return the orientation of the cell based on which direction it
    # is facing.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    # Returns:
    #   $v0: orientation of the cell
    #   The orientation is 3 if facing right, 6 if facing down, 
    #       9 if facing down, 12 if facing up, and 0 otherwise
    
    # Save $ra, $a0, $a1
    sub $sp, $sp, 36
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    # Ignore cell if virus
    jal is_virus
    li $t0, 1
    bne $v0, $t0, after_check_get_cell_orientation
    li $v0, 0
    j after_get_cell_orientation
    
    after_check_get_cell_orientation:
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    jal get_cell
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    move $t0, $v0
    sw $t0, 12($sp)             # Save the cell's color
    
    lw $t1, CELL_SIZE
    div $t1, $t1, 2
    sw $t1, 16($sp)             # Save half the cell's size
    
    # $t2 = x-offset to border, $t3 = y-offset to next border
    # $t4 = associated return value
    
    # Right oriented
    add $t2, $zero, $t1
    add $t3, $zero, $zero
    li $t4, 3
    jal check_cell_orientation
    
    # Down oriented
    add $t2, $zero, $zero
    add $t3, $zero, $t1
    li $t4, 6
    jal check_cell_orientation
    
    # Left oriented
    sub $t2, $zero, $t1
    add $t3, $zero, $zero
    li $t4, 9
    jal check_cell_orientation
    
    # Up oriented
    add $t2, $zero, $zero
    sub $t3, $zero, $t1
    li $t4, 12
    jal check_cell_orientation
    
    li $v0, 0
    j after_get_cell_orientation
    
    check_cell_orientation:
        sw $ra, 20($sp)
        sw $t2, 24($sp)
        sw $t3, 28($sp)
        sw $t4, 32($sp)
        
        add $a0, $a0, $t2
        add $a1, $a1, $t3
        jal get_pixel
        lw $a0, 4($sp)
        lw $a1, 8($sp)
        lw $t0, 12($sp)
        lw $t1, 16($sp)
        lw $t2, 24($sp)
        lw $t3, 28($sp)
        lw $t4, 32($sp)
        # If border pixel's color is not equal to the rest of the cell, this is its orientation
        beq $v0, $t0, after_check_cell_orientation
        move $v0, $t4
        j after_get_cell_orientation
        
        after_check_cell_orientation:
        lw $ra, 20($sp)
        jr $ra
    
    after_get_cell_orientation:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 36
    jr $ra
    
    
##############################################################################
# GRID SIMULATION
##############################################################################

simulate_grid:
    # Simulate the grid's reaction once a block is placed down, 
    # clearing cells and simulating cell falling until no more
    # cells need to be cleared.
    
    SAVE_RA()
    
    while_simulate_grid:
        jal clear_lines
        beq $v0, 0, end_simulate_grid
        # jal pause_tick
        jal fall_blocks
        j while_simulate_grid
    
    end_simulate_grid:
    
    RESTORE_RA()
    jr $ra

##############################################################################
# CLEARING LINES
##############################################################################

clear_lines:
    # Unlink, then clear all the cells that form a line of length
    # equal or longer than CLEAR_LENGTH along a row or column, and
    # return the total number of cells cleared from both clearing both
    # rows and columns.
    # Returns:
    #   $v0 = number of blocks cleared from both rows and columns
    
    sub $sp, $sp, 8
    sw $ra, 0($sp)
    
    # Clear rows
    li $a0, 0
    jal clear_loop
    
    sw $v0, 4($sp)
    
    # Clear columns
    li $a0, 1
    jal clear_loop
    
    lw $t0, 4($sp)
    add $v0, $v0, $t0
    
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra

clear_loop:
    # Unlink, then clear all cells that form a line of length
    # equal or longer than CLEAR_LENGTH along rows or columns,
    # depending on the specified input, and return the number
    # of cells cleared.
    # Args:
    #   $a0: 0 to clear row lines, 1 to clear column lines
    # Returns:
    #   $v0 = number of blocks cleared from rows or from columns

    SAVE_RA()
    
    lw $t2, CELL_SIZE           # Specify stride length ($t2) for the index
    div $t3, $t2, 2
    lw $t0, MAX_X
    sub $t0, $t0, $t3
    lw $t1, MAX_Y
    sub $t1, $t1, $t3           # Specify index ($t0, $t1) at the center of the last cell within border
    
    li $t3, 0                   # Specify color counter
    lw $t4, BACKGROUND_COLOR    # Specify current color
    
    li $t6, 0                   # Specify cleared cell counter
    
    sub $sp, $sp, 44
    sw $a0, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    sw $t2, 12($sp)
    sw $t3, 16($sp)
    sw $t4, 20($sp)
    sw $t6, 32($sp)
    
    while_clear_loop:
        beq $a0, 0, check_end_row_clear_loop
        beq $a0, 1, check_end_column_clear_loop
        j after_check_end_clear_loop
        
        check_end_row_clear_loop:
        lw $t5, MIN_X
        lw $t6, MIN_Y
        blt $t1, $t6, end_clear_loop
        blt $t0, $t5, reset_clear_loop
        j after_check_end_clear_loop
        
        check_end_column_clear_loop:
        lw $t5, MIN_X
        lw $t6, MIN_Y
        blt $t0, $t5, end_clear_loop
        blt $t1, $t6, reset_clear_loop
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
        lw $t6, 32($sp)
        
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
                sw $a0, 32($sp)
                sw $a1, 36($sp)
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
                sw $a0, 32($sp)
                sw $a1, 36($sp)
                j after_check_mark_clear_color
                
                after_check_mark_clear_color:
                
                jal highlight_jar
                jal pause_tick
                lw $a0, 32($sp)
                lw $a1, 36($sp)
                lw $t0, 4($sp)
                lw $t1, 8($sp)
                lw $t2, 12($sp)
                lw $t3, 16($sp)
                lw $t4, 20($sp)
                lw $t5, 28($sp)
                lw $t6, 32($sp)
                
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
                lw $t6, 32($sp)
                
                sub $t3, $t3, 1
                sw $t3, 16($sp)
                
                add $t6, $t6, 1
                sw $t6, 32($sp)
                
                jal draw_jar
                jal pause_tick
                lw $a0, 0($sp)
                lw $t0, 4($sp)
                lw $t1, 8($sp)
                lw $t2, 12($sp)
                lw $t3, 16($sp)
                lw $t4, 20($sp)
                lw $t5, 28($sp)
                lw $t6, 32($sp)
                
                j while_mark_clear_color
            
            after_mark_clear_color:
            lw $ra, 24($sp)
            jr $ra
        
        after_clear_color_counter:
        
        beq $a0, 0, check_increment_row_clear_counter
        beq $a0, 1, check_increment_column_clear_counter
        j after_check_increment_clear_counter
        
        check_increment_row_clear_counter:
        sub $t0, $t0, $t2
        sw $t0, 4($sp)
        j after_check_increment_clear_counter
        
        check_increment_column_clear_counter:
        sub $t1, $t1, $t2
        sw $t1, 8($sp)
        j after_check_increment_clear_counter
        
        after_check_increment_clear_counter:
        
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
            div $t2, $t2, 2
            lw $t0, MAX_X
            sub $t0, $t0, $t2
            lw $t2, 12($sp)
            sw $t0, 4($sp)
            sub $t1, $t1, $t2
            sw $t1, 8($sp)
            j after_check_reset_clear_loop
            
            check_reset_column_clear_loop:
            div $t2, $t2, 2
            lw $t1, MAX_Y
            sub $t1, $t1, $t2
            lw $t2, 12($sp) 
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
    
    lw $t6, 32($sp)
    move $v0, $t6
    
    addi $sp, $sp, 44
    
    j end_restore_ra

unlink_block:
    # Unlinks both halves of the block at the specified coordinates,
    # making them each half an individual cell without an orientation.
    # Args:
    #   $a0: x-coordinate of the block's half's cell
    #   $a1: y-coordinate of the block's half's cell  
    
    # Save $ra, $a0, $a1, $t0
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    jal get_linked_cell
    move $a0, $v0
    move $a1, $v1
    li $a2, 0
    jal unlink_cell
    
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    li $a2, 1
    jal unlink_cell
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

unlink_cell:
    # Unlinks the cell at the specified coordinates, by redrawing
    # it without an orientation.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    #   $a2: 0 to unlink with the cell's color, 1 to unlink with CLEAR_COLOR
    
    # Save $ra, $a0, $a1, $t0
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $a2, 12($sp)
    
    jal get_cell
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    lw $a2, 12($sp)
    li $a3, 0
    beq $a2, 1, clear_color_unlink_cell
    move $a2, $v0
    jal set_cell
    j after_unlink_cell
    
    clear_color_unlink_cell:
    lw $a2, CLEAR_COLOR
    jal set_cell
    
    after_unlink_cell:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra

##############################################################################
# FALLING BLOCKS
##############################################################################

fall_blocks:
    # Animate the blocks falling until there are no more floating
    # blocks that can fall, pausing for a tick after each movement.
    
    SAVE_RA()
    
    li $v0, -1                      # Initialize number of blocks fallen to != 0 so fall_loop runs at least once
    while_fall_blocks:
        beq $v0, 0, end_restore_ra
        
        la $ra, after_pause_tick
        bne $v0, -1, pause_tick     # Don't pause on the first check
        after_pause_tick:
        
        jal fall_loop
        
        j while_fall_blocks

fall_loop:
    # Move each cell or block that has an empty space below it down
    # by CELL_SIZE, starting from the bottom, and return the number
    # of cells that have moved.
    # Returns:
    #   $v0: number of cells that moved down

    SAVE_RA()
    
    lw $t2, CELL_SIZE           # Specify stride length ($t2) for the index
    div $t3, $t2, 2
    lw $t0, MAX_X
    sub $t0, $t0, $t3
    lw $t1, MAX_Y
    sub $t1, $t1, $t3           # Specify index ($t0, $t1) at the center of the last cell within border
    
    li $t3, 0                   # Specify fallen cell counter
    
    sub $sp, $sp, 16
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    
    while_fall_loop:
        lw $t5, MIN_X
        lw $t6, MIN_Y
        blt $t1, $t6, end_fall_loop
        blt $t0, $t5, reset_fall_loop
        
        move $a0, $t0
        move $a1, $t1
        jal fall_cell
        lw $t0, 0($sp)
        lw $t1, 4($sp)
        lw $t2, 8($sp)
        lw $t3, 12($sp)
        
        add $t3, $t3, $v0
        sw $t3, 12($sp)
        
        sub $t0, $t0, $t2
        sw $t0, 0($sp)
        
        j while_fall_loop
        
        reset_fall_loop:
            div $t2, $t2, 2
            lw $t0, MAX_X
            sub $t0, $t0, $t2
            lw $t2, 8($sp)
            sw $t0, 0($sp)
            sub $t1, $t1, $t2
            sw $t1, 4($sp)
            j while_fall_loop
    
    end_fall_loop:
    
    move $v0, $t3
    
    addi $sp, $sp, 16
    
    j end_restore_ra

can_fall_cell:
    # Check whether the cell at the specified coordinates is able
    # to move down and if there are no collisions with filled
    # spaces or borders. If there is no cell, return 0.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    # Returns:
    #   $v0: 0 if cell cannot move down, 1 if cell can move down
    
    # Save $ra, $a0, $a1
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)

    # Check 1: Ignore cell if background
    jal get_cell
    lw $t0, BACKGROUND_COLOR
    bne $v0, $t0, after_check1_can_fall_cell
    li $v0, 0
    j end_can_fall_cell
    
    after_check1_can_fall_cell:
    # Check 2: Ignore cell if virus
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    jal is_virus
    li $t0, 1
    bne $v0, $t0, after_check2_can_fall_cell
    li $v0, 0
    j end_can_fall_cell
    
    after_check2_can_fall_cell:
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    
    # Move if cell doesn't collide
    move $a2, $a0
    move $a3, $a1
    li $a0, 0
    lw $a1, CELL_SIZE
    jal get_cell_collision
    beq $v0, 0, do_can_fall_cell
    li $v0, 0
    j end_can_fall_cell
    
    do_can_fall_cell:
    li $v0, 1
    
    end_can_fall_cell:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

fall_cell:
    # Attempt to move the cell at the specified coordinates downwards,
    # and returns whether or not it was successful. If there is no
    # cell, return 0.
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    # Returns: 
    #   $v0 = 0 if not moved, $v0 = 1 if moved successfully

    # Save $ra, $a0, $a1
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    # Check if other half of cell can also fall
    jal get_cell_orientation
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    beq $v0, 3, check_left_can_fall_cell
    beq $v0, 9, check_right_can_fall_cell
    j after_check_half_can_fall_cell
    
    check_left_can_fall_cell:
    # Left half can only fall if right half of cell has already fallen
    lw $t0, CELL_SIZE
    add $a0, $a0, $t0
    jal get_cell
    lw $t1, BACKGROUND_COLOR
    beq $v0, $t1, do_fall_cell
    j skip_do_fall_cell
    
    check_right_can_fall_cell:
    # Right half can only fall if both cells can fall
    jal get_linked_cell
    move $a0, $v0
    move $a1, $v1
    jal can_fall_cell
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    beq $v0, 0, skip_do_fall_cell
    
    after_check_half_can_fall_cell:
    
    jal can_fall_cell
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    beq $v0, 0, skip_do_fall_cell
    
    do_fall_cell:
        # Get cell color
        lw $a0, 4($sp)
        lw $a1, 8($sp)
        jal get_cell
        
        # Draw new cell
        move $a2, $v0
        lw $a0, 4($sp)                      # Update to new x and y-coordinates
        lw $a1, 8($sp)
        jal get_cell_orientation
        move $a3, $v0
        lw $t0, CELL_SIZE
        add $a1, $a1, $t0
        jal set_cell
        
        # Clear old cell position
        lw $a0, 4($sp)
        lw $a1, 8($sp)
        lw $a2, BACKGROUND_COLOR
        li $a3, 0
        jal set_cell
        
        li $v0, 1
        j end_fall_cell
    
    skip_do_fall_cell:
    li $v0, 0
    
    end_fall_cell:
    
    # Restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra
    
is_virus:
    # Return whether or not the cell specified at the given coordinate 
    # is a virus or not. 
    # Args:
    #   $a0: x-coordinate of the cell
    #   $a1: y-coordinate of the cell
    # Returns: 
    #   $v0 = 0 if cell is not a virus, $v0 = 1 if cell is a virus
    
    # Save $ra before calling get_pixel
    SAVE_RA()
    
    jal get_pixel # Color of pixel is stored in $v0
    lw $t0, BACKGROUND_COLOR
    
    # Compare pixel color with background color
    beq $v0, $t0, not_virus 
    li $v0, 1 
    j end_check_is_virus
    
    not_virus:
        li $v0, 0
    
    end_check_is_virus:
        # Restore $ra after returning from get_pixel
        RESTORE_RA()
        jr $ra
    