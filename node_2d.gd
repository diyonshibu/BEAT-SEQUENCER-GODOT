extends Node2D


#here i am declaring the size of my grid step
#number of columns
const STEPS = 16 #this is for how many step beats there are in the sequence
#number of rows
const TRACKS = 7 #how many samples can be loaded in the sequencer


#this is the grid array
var grid = []
#here i am declaring a variable that calculates the current step of where it is in the sequence
var current_step = 0  
#here i am using a boolean variable to check if the sequencer is playing or not
var is_playing = false 

#UI elements 
#here i am getting the steps grid 
@onready var steps_container = $UI/Steps
#here im getting the timer which controls the bpm 
@onready var timer = $Timer


#here i am getting the start/stop button which is used to pause the sequencer
@onready var start_button = $UI/StartStopButton
#here i am getting the bpm slider which is used to control the bpm (timer node)
@onready var bpm_slider = $UI/BPMSlider
#this is the label for the bpm slider
@onready var bpm_label = $UI/BPMLabel


# Audio samples
#here i am calling the neccessary samples for each instrument 
@onready var kick = $Kick #kick
@onready var snare = $Snare #snare
@onready var hihat = $HiHat #hihat
@onready var tom1 = $Tom1 #Tom1 
@onready var tom2 = $Tom2 #Tom2 
@onready var clap = $Clap #clap 
@onready var ride = $Ride #ride


#here im adding labels for the samples so you can see which samples are on which row
@onready var kick_label = $UI/KickLabel #kick
@onready var snare_label = $UI/SnareLabel #snare
@onready var hihat_label = $UI/HiHatLabel #hihart
@onready var tom1_label = $UI/Tom1Label #tom1
@onready var tom2_label = $UI/Tom2Label #ton2
@onready var clap_label = $UI/ClapLabel 
@onready var ride_label = $UI/RideLabel 


# here i am defining the colors for the grid rows
# this corosponds to the samples on each index of the array 
var colors = [
	Color(0.2, 0.6, 1.0), #kick
	Color(1.0, 0.9, 0.2), #snare
	Color(0.2, 1.0, 0.4), #hihat
	Color(1.0, 0.5, 0.2), #tom 1
	Color(0.8, 0.3, 0.9), #tom2 
	Color(1.0, 0.3, 0.3), #clap
	Color(0.3, 1.0, 1.0) #ride
]


#here im making an array called sounds to store all the audioplayers in a list
var sounds = []


func _ready():
	#here i am storing all the sound in the sounds array
	sounds = [kick, snare, hihat, tom1, tom2, clap, ride]

	
	create_grid() #creates the toggle buttons for the step sequencer
	set_bpm(120) #here i am setting the bpm to 120 as default
	#here i am connecting the timer to the playback function
	timer.timeout.connect(_on_timer_timeout)

	#here i am connecting the button to toggle playback which starts or pauses the grid
	start_button.pressed.connect(_on_start_stop)
	#here i am connecting the slider to change the bpm 
	bpm_slider.value_changed.connect(_on_bpm_changed)

	#here i am setting the value of the slider to be at 120 by default
	#i had already set the start value to be 120 in the inspector tool but it didn't properly work
	bpm_slider.value = 120
	#here i am setting the label for the bpm slider
	bpm_label.text = "BPM 120" #at the start by default the slider is going to show 120 bpm

	# here i am positioning the ui elements
	#i tried using full rect inside the inspector tool but didn't work out properly
	start_button.position = Vector2(100, 40) #position for the start stop button
	bpm_slider.position = Vector2(250, 40)#bpm slider
	bpm_slider.size.x = 200 #size of the slider
	bpm_label.position = Vector2(470, 40)#bpm label


#function to keep grid centred 
func _process(_delta):
	center_grid()


#here i am going to start building the step sequencers layout
func create_grid():
	#im using a for loop to iterate through the types of sampels 
	for t in range(TRACKS):
		#each time a different sample is found the grid appends a new row
		grid.append([])
		#here i am using a for loop to iterate through how many steps there are
		for s in range(STEPS):
			#each time there is a step it creates a new toogle button on the sequencr
			var btn = Button.new()
			
			#here im setting the button as a toggle button where it can be on/off
			btn.toggle_mode = true
			#this is defining the size of the buton
			btn.custom_minimum_size = Vector2(40, 40) 

			#this allocates which row the button belongs to
			btn.set_meta("track", t)
			
			#here i am adding the button to the ui 
			steps_container.add_child(btn)
			#and here im storing it in the grid array
			grid[t].append(btn)
			
			#here i am defining what should happen when the button is toggled
			#when the button is toggled it uodates its state and call the funtion 
			btn.toggled.connect(_on_step_toggled.bind(btn))
			update_button_style(btn)


#this is the function used to update the button when toggled 
func update_button_style(btn): #passing the btn input
	#this gets the meta data from the button 
	#each button could be from either track 0-6 
	var track = btn.get_meta("track")
	#here i am using the tracks index to asaign the correct color 
	var base = colors[track]

	#here i am creating a new object to customise the ui
	var style = StyleBoxFlat.new()
	style.bg_color = base #background color


	#here i am styling the border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.BLACK #used to set the border color 

	#once the button is pressed and toggled it makes the button brighter 
	if btn.button_pressed:
		#this is so that you can see which steps are enabled in the sequence
		style.bg_color = base.lightened(0.5)

	#btn styling 
	#styling for when the btn is in its normal state
	btn.add_theme_stylebox_override("normal", style)
	#for when the button is toggled / pressed
	btn.add_theme_stylebox_override("pressed", style)
	#on hover state
	btn.add_theme_stylebox_override("hover", style)

#boolean function to check if the button is toggled or not
func _on_step_toggled(_pressed, btn):
	#if the boolean returns true it calls the button styling function
	update_button_style(btn)


func _on_timer_timeout():
	#this runs all the audio and visual 
	play_step()
	#used to iterate through the steps and loop back 
	current_step = (current_step + 1) % STEPS

#main sequenceer function
func play_step():
	#here i am using a for loop to iterate through each sample (rows)
	for t in range(TRACKS):
		#im nesting the for loop so that s will loop through each index of step (0-15)
		for s in range(STEPS):
			#check buttons state at specific position in grid 
			var btn = grid[t][s]
			
			#used to refresh the buttons style when the playhead moves along the grid
			update_button_style(btn)
			
			#checks if the column is the correct play position
			if s == current_step:
				#here im getting the current visual style of the button
				var style = btn.get_theme_stylebox("normal")
				#makes the current step brighter
				#this is to highlight where the playhead is at in the sequence grid
				style.bg_color = style.bg_color.lightened(0.2)
				btn.add_theme_stylebox_override("normal", style)

		#checking if the audio sample exists
		#had a few issues without this which caused some crashes
		#also checks if the grid step is toggled
		if sounds[t] != null and grid[t][current_step].button_pressed:
			sounds[t].play() #plays the sound for that sample at that specific grid position

#function for the start stop button 
func _on_start_stop(): #this is triggered when the start stop button is pressed
	#by default the sequencer runs on start
	is_playing = !is_playing

	#here im just using some if statemenst to check the state of the btn
	if is_playing:
		start_button.text = "Stop"
		timer.start()
	else:
		start_button.text = "Start"
		timer.stop()

#this is the function to change the bpm valie
func _on_bpm_changed(value):
	set_bpm(value)
	#here i am manipulating the string to update the value of the bpm while slide changes
	bpm_label.text = "BPM: " + str(int(value)) 

#here i am making a function to convert the bpm value to the timer speed
func set_bpm(bpm):
	#this is the formula to convert the bpm to timer speed
	timer.wait_time = 60.0 / bpm / 4.0
	
#here i am useing a function and passing in the track variable as a parameter
func get_base_color(track):
	#and i am returninhg the track color for each track index
	return colors[track]


#here i am using a function to centre the step sequencer
func center_grid():
	#here it gets the viewport rect size
	var screen_size = get_viewport_rect().size
	#this gets the size of the sequencer
	var grid_size = steps_container.size

	#in order to keep the sequecer centred im minusing the screen size by the grid size and dividing it by two 
	#to make sure both the left and right sides are equel.
	var grid_pos = (screen_size - grid_size) / 2
	#this moves the sequencer to the centre position
	steps_container.position = grid_pos


	var row_height = grid_size.y / TRACKS
	#this positions the labels to the left of the sequencer. 
	var label_x = grid_pos.x - 80

	#here i am using an array to store the labels 
	var labels = [
		kick_label, snare_label, hihat_label,
		tom1_label, tom2_label, clap_label, ride_label
	]

#here i am using a for loop 
	for i in range(TRACKS):
		#if any of the indexs in the label array is null then the label position
		#this prevents a crash if label is missing 
		#when i was developing and i didnt have all the labels setup the program crashed
		if labels[i] != null:
			#this is used to move the label down each row 
			labels[i].position = Vector2(label_x, grid_pos.y + row_height * i + 10)
			
