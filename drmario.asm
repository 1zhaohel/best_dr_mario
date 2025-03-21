################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Helen Zhao, 1010138995
# Student 2: Alan Su, 1010294209
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    60
# - Display height in pixels:   60
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data 
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# Colours
RED_COLOR:
    .word 0xff0000
YELLOW_COLOR:
    .word 0xffff00
BLUE_COLOR:
    .word 0x0000ff
LIGHT_BLUE:
    .word 0xADD8E6
BACKGROUND_COLOR:
    .word 0x000000
##############################################################################
# Mutable Data
##############################################################################
GRID:
    .space 14400 # 60 * 60 * 4
GRID_SIZE:
    .word 14400
DISPLAY_LENGTH:
    .word 60
PIXEL_SIZE:
    .word 4

JAR_LID_START:
    .word 812 # (60 * 3 + 23) * 4
JAR_LID_WIDTH: 
    .word 52 # 13 * 4
JAR_LID_END:
    .word 2064 # (60 * 8 + 36) * 4
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the grid
    jal initialize_grid
    # Initialize the jar
    jal initialize_jar_lid_left
    jal initialize_top_jar_left
    jal initialize_jar_left
    jal initialize_jar_bottom
    jal initialize_jar_right
    jal initialize_top_jar_right
    jal initialize_jar_lid_right
    # Draw background
    jal draw_grid
    
end:
    jr $ra

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
    
initialize_grid:
    la $t0, GRID                # Load grid address ($t0) into counter
    lw $t1, GRID_SIZE           # Load grid size ($t1)
    add $t1, $t1, $t0           # Specify max index ($t1)
    lw $t2, PIXEL_SIZE          # Load pixel size ($t2)
    lw $t3, BACKGROUND_COLOR    # Load background color      
    
    while_initialize_grid:
        bge $t0, $t1, end       # Exit loop if counter ($t0) >= max index ($t1)
        sw $t3, 0($t0)           # Save background color into grid index       
        add $t0, $t0, $t2        # Increment counter by pixel size
        j while_initialize_grid
    
initialize_jar_lid_left:
    lw $t3, LIGHT_BLUE           # Set jar colour
    la $t0, GRID                 # Reload grid address for $t0
    addi $t4, $t0, 2976          # Set max jar lid index
    addi $t0, $t0, 812           # Set jar start index
    j draw_vertical_line

initialize_top_jar_left:
    addi $t0, $t0, -308
    j draw_horizontal_line
    
initialize_jar_left:
    addi $t4, $t4, -68
    addi $t4, $t4, 10560
    addi $t0, $t0, -72
    j draw_vertical_line

initialize_jar_bottom:
    addi $t0, $t0, -240
    addi $t4, $t4, 188
    j draw_horizontal_line
    
initialize_jar_right:
    addi $t0, $t0, -10324
    j draw_vertical_line

initialize_top_jar_right:
    addi $t4, $t4, -10324
    addi $t0, $t0, -10628
    j draw_horizontal_line

initialize_jar_lid_right:
    addi $t0, $t0, -2472
    # addi $t4, $t4, -300
    j draw_vertical_line

draw_vertical_line:
    bge $t0, $t4, end      # $t0 is current pointer and $t4 is the end of the line
    sw $t3, 0($t0)
    addi $t0, $t0, 240        
    j draw_vertical_line

draw_horizontal_line:
    bge $t0, $t4, end      # $t0 is current pointer and $t4 is the end of the line
    sw $t3, 0($t0)
    addi $t0, $t0, 4
    j draw_horizontal_line
    
draw_grid:
    la $t0, GRID            # Load grid address ($t0) into counter
    lw $t1, GRID_SIZE       # Lood grid size ($t1)
    add $t1, $t1, $t0       # Specify max index ($t1)
    lw $t2, PIXEL_SIZE      # Load pixel size ($t2)
    lw $t3, ADDR_DSPL       # Load display address ($t3) into counter
    while_draw_grid:
        bge $t0, $t1, end  # Exit loop if counter ($t0) >= max index ($t1)
        lw $t4, 0($t0)      # Load the color from the grid ($t4)
        sw $t4, 0($t3)      # Save color into display index 
        add $t0, $t0, $t2   # Increment grid counter by pixel size
        add $t3, $t3, $t2   # Increment display counter by pixel size
        j while_draw_grid