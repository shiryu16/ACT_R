;start task

(defvar *trial* nil)
(defvar *drill-window* nil)
(defvar *cart-window* nil)
(defvar *response* nil)
(defvar *box* nil)
(defvar *number-of-CT* 0)
(defvar *sound-played* 0)
(defvar *switch-to-sound* 0)
(defvar *switch-to-nosound* 0)
(defvar *ans* 0)
(defvar *bll* 0)

;

(defun create-windows ()
; ; ; ; make a window1
	(setf *drill-window* (open-exp-window "Drill"	:width 500 :height 500))
	(setf *cart-window* (open-exp-window "Cart" :width 500 :height 500))
	; draw 2 buttons one in the center with no action and one in the corner that switches to second window
	(add-button-to-exp-window :window *drill-window* :action #'switch-to-cart-window)
	 (add-text-to-exp-window :window *drill-window* :text "moving box" :x 250 :y 250)
 ; make another window2
	 ; button 2 corner
	(add-button-to-exp-window :window *cart-window* :action #'switch-to-drill-window)
	; focus window1
	(install-device *drill-window*)
	(proc-display)
)
; ; ;this function selects which window the model should be interacting with
; ; ;it is used by the corner buttons
(defun switch-to-cart-window (button)
	(select-exp-window *cart-window*)
	(install-device *cart-window*)
	(format t "		switch to cart clicked ~%")
	(proc-display :clear t)
	;count the type of switch behavior
	(cond
		((eql *sound-played* 1) (setf *switch-to-sound* (+ *switch-to-sound* 1)))
		((eql *sound-played* 0) (setf *switch-to-nosound* ( + *switch-to-nosound* 1)))
	)
)

(defun switch-to-drill-window (button)
	(setf *sound-played* 0)
	(select-exp-window *drill-window*)
	(install-device *drill-window*)
	(proc-display :clear t)
	(format t "		switch to drill clicked ~%")
)
;Call filler function when the spacebar is pressed
(defmethod rpm-window-key-event-handler ((win rpm-window) key)
	(setf *response* (string key))
	(if (equal *response* " ") (filler)) ;if the space bar is pressed, the filler function is called
	;if i implement a points system this function should also either take away or reward extra points.
)

;sets filler in the second window
(defun filler ()
		(when  (not(null *box*))  (remove-items-from-exp-window *box* :window *cart-window*))
		(setf *box* (add-text-to-exp-window :window *cart-window*
							:text "fillerbox" :color "blue"
							:x 250 :y 250))
	
	;(proc-display :clear t) no need to process the display for fillers
	(setf *trial* nil)
	(format t "filler ~S ~%" *trial*) ;testing string to make sure the filler runs and what the trial variable is at the time. 
)

;decision on trial type
(defun trial-type (TPR FPR)
	;critical or not
	(if (> (act-r-random 100) 50) (setf *trial* "non-crit") (setf *trial* "critical"))
	;decide on whethr to sound the cue
	(cond ((and (equal *trial* "critical")(< (act-r-random 100) TPR)) 
									(new-tone-sound 2000 .5 )
									(setf *sound-played* 1)
									(format t "sound played-"))
			((and(equal *trial* "non-crit") (< (act-r-random 100) FPR))
									(new-tone-sound 1000 .5 )
									(setf *sound-played* 1)
									(format t "sound played-"))
	)
	(format t "trial computed ~S ~%" *trial*)
*trial*	
)
;this function set a new trial text on the second window, 
;the call to trial-type plays the sound and decides the trial type
(defun new-trial (TPR FPR)
	(when  (not(null *box*))  (remove-items-from-exp-window *box* :window *cart-window*))
	(progn 
		(trial-type TPR FPR) ; decide what kind of trial and play sound
		;based on trial type the color of the text in window2 changes 
		(cond (	(equal *trial* "critical") 
					(setf *box* (add-text-to-exp-window :window *cart-window* :text "redbox" :color "red" :x 250 :y 250))
					(setf *number-of-CT* (+ *number-of-CT* 1))				
				) 
			  (	(equal *trial* "non-crit") 
					(setf *box*(add-text-to-exp-window :window *cart-window* :text "bluebox" :color "blue":x 250 :y 250))
				)
			)
	)
)

(defun reset-environment ()
(setf *trial* nil)
(setf *drill-window* nil)
(setf *cart-window* nil)
(setf *response* nil)
(setf *box* nil)
(setf *number-of-CT* 0)
(setf *sound-played* 0)
(setf *switch-to-sound* 0)
(setf *switch-to-nosound* 0)
)
	
;experiment takes the true positive rate (TPR) and False Positive Rate (FPR) as required parameters. TPR and FPR are the rate at which the automation alerts the user
;to switch to the cart. The keyword :trials is how many trials to run. 
(defun experiment (TPR FPR &key (trials 10))
	(reset)
	(reset-environment)
	(create-windows)
	;set everything to the the starting position
	(start-hand-at-mouse)
	(set-cursor-position 100 100)

	(dotimes (i trials)
		(filler)
		(run-full-time (+ 6 (act-r-random 4))) ;run for 7-10 seconds
		(new-trial TPR FPR) ;(proc-display) inside the function
		(run-full-time (+ 7 (act-r-random 5))) ;run trial for 7-12 seconds
	)
	(display-results trials FPR TPR)	
)

(defun display-results (trials FPR TPR)
	;(format t "~%Trials: ~S TPR: ~S FPR: ~S ~%" trials TPR FPR)
	;(format t "Critical Trials: ~S ~%" *number-of-CT*)
	;(format t "Switches after alarm: ~S ~%" *switch-to-sound*)
	;(format t "Switches with NO alarm: ~S ~%" *switch-to-nosound*)
	;this next function writes so that the variables are comma separated and go into a csv with labeled header row
	(format t "~S,~S,~S,~S,~S,~S,~S,~S,~S~%" trials *number-of-CT* *switch-to-sound* *switch-to-nosound* TPR FPR *egs* *red_reward* *blue_reward*)
)

(defun param-explore (TPR FPR participants-per-condition)
	(with-open-file (*standard-output* "C:/Users/Shiryum/Documents/GitHub/ACT_R/Instance_Learning.csv" :direction :output :if-exists :append :if-does-not-exist :create)
	;instead of the following line it is easier in order to chain these to just create a csv file manually with the header rows  
	;and named as the output file at the specified location
	;(format t "Trials,CT,Switches_to_sound,switch-to-no-sound,TPR,FPR,EGS,RED_REWARD")
	
	(let ((ans-list '(.5))
        ;(alpha-list '(.0001))
        (bll '(2 4 6 8))
		;(blue-reward '(-2 -4 -6 -8))
		)

        ;(fname nil))
;    (setq fname "~/Documents/models/vigilance/outputfiles/outputfile.8.25.11.csv")
    ;(setq fname (string (concat "~/Documents/models.from.viz/vigilance/outputfiles/outputfile." (get-universal-time) ".csv")))
    ;(writeToFile fname (format nil "subj, Period1, Period2, Period3, Period4, Nothing, egs, ut, signal.reward, alpha~%"))
	(dolist (*ans* ans-list)
		(dolist (*bll* bll)
			;(dolist (*blue_reward* blue-reward)
				(dotimes (i participants-per-condition)
					(reload) ;; to get global variables set properly 
					(suppress-warnings(experiment TPR FPR :trials 150))))))
))

(clear-all)

(define-model trust
;this model is different from the previous model in that it uses the retrieval buffer to learn the appropriate behaviour instead of using the reward system

;note that utility learning is off. :ol optimized learning
(sgp :show-focus t :esc t :ul nil :ncnar t)  
;these parementes have to be commented out when doing param-explore runs. 
(sgp :ans 0.5 :bll 0.8 :rt -3)

(sgp :v t :trace-detail low :ult nil)

;;;paremeters needed for the parameter exploration sessions
;;These are for rewards 
;(spp-fct (list 'box-is-red :reward *red_reward*))
;(spp-fct (list 'box-is-blue :reward *blue_reward*))

;these are for subsymbolic
(sgp-fct (list
;            :alpha *alpha*
            :ans *ans*)
			:bll *bll*)
;           :ut *ut*)))

;possible chunks
(chunk-type goal state)
(chunk-type prev-action action outcome)

;initial chunks
(add-dm
(find isa chunk) (tracking isa chunk)(switching isa chunk)
(attending isa chunk) (clicking isa chunk) (respond isa chunk)
(wait isa chunk) (switch isa chunk)
;I pre-created chunks for the possible outcomes of certain actions. This is theoretically valid as participants go into the main task having been trained on the possible outcomes
(outcomeWR isa prev-action action wait outcome red)
(outcomeWB isa prev-action action wait outcome blue)
(outcomeSR isa prev-action action switch outcome red)
(outcomeSB isa prev-action action switch outcome blue)
(goal isa goal state find)
)

;attend center item
(p find-center
	=goal>
		isa		goal
		state 	find
	=visual-location>
		isa 	visual-location
	==>
	=goal>
		state 	attending
	+visual-location>
		isa visual-location
		screen-x highest
		screen-y highest
)

;moves attention to the center box for drill tracking, but also moves mouse to the location of the box.
;it also tries to remember previous behaviors that resulted in a red box
(p attend-center
	=goal>
		isa		goal
		state 	attending
	=visual-location>
		isa 	visual-location
		color	black
	-	screen-x lowest
	?visual>
		state	free
	?manual>
		state	free
	==>
	=goal>
		state	tracking
	+visual>
		isa 	move-attention
		screen-pos	=visual-location
	+manual>
		isa		move-cursor
		loc		=visual-location	
	+visual-location>
		isa		visual-location
		kind	oval
	+retrieval>
		isa		prev-action
		outcome	red
	+temporal>
		isa		time
)	

(p attend-to-respond
	=goal>
		isa		goal
		state 	attending
	=visual-location>
		isa 	visual-location
	-	color	black
	-	screen-x lowest
	?visual>
		state	free
	?manual>
		state	free
	==>
	=goal>
		state	respond
	+visual>
		isa 	move-attention
		screen-pos	=visual-location
	+manual>
		isa		move-cursor
		loc		=visual-location	
	+visual-location>
		isa		visual-location
		kind	oval

)	

;wait for alarm - and move attention to button if something is heard
(p heard-alarm
	=goal>
		isa 	goal
		state	tracking
	=aural-location>
		isa      audio-event
    ?aural>
		state    free
	?visual>
		state	free
	=visual-location>
		isa		visual-location
		kind	oval
	==>
	=goal>
		state	switching
	+aural>
		isa		sound
		event	=aural-location
	+visual>
		isa		move-attention
		screen-pos	=visual-location
	+imaginal>
		isa		prev-action
		action	wait
	-temporal>
	
)

;move attention to the button even though no alarm has been heard
;only if the action it has previously remembered was to switch
;it generates a new instance of a previous action
(p	switch-with-no-sound
	=goal>
		isa 	goal
		state	tracking
	=visual>
		isa		text
		color	black
	=visual-location>
		isa		visual-location
		kind	oval
	?manual>
		state	free
	?aural-location>
		state	free
		buffer	empty
	=retrieval>
		isa		prev-action
		action	switch
	=temporal>
		isa		time
	>=	ticks	40
	==>
	=goal>
		state	switching
	+visual>
		isa		move-attention
		screen-pos	=visual-location
	+imaginal>
		isa		prev-action
		action	switch
	-temporal>
)
;(spp switch-with-no-sound :u 0)

;the model decies to wait for an alarm 
;only if the action it has previously remembered was to wait
;it then resets the timer and waits again for a period of time. It starts a new retrieval in order to make a new decision about whether or not to wait. 
;this has the potential side effect of over-emphasizing the activation of the waiting chunks. 
 (p wait-for-alarm
	=goal>
		isa 	goal
		state	tracking
	=visual>
		isa		text
		color	black
	=visual-location>
		isa		visual-location
		kind	oval
	?manual>
		state	free
	?aural-location>
		state	free
	=retrieval>
		isa		prev-action
		action	wait
	=temporal>
		isa		time
	>=	ticks	40
	==>
	=goal>
	=visual>
	=visual-location>
	+retrieval>
		isa		prev-action
		outcome red
	+temporal>
		isa 	time
)
;(spp wait-for-alarm :u 5)
;(spp wait-for-alarm :reward 2.2)

;switch windows
(p	move-mouse
	=goal>
		isa		goal
		state	switching
	?manual>
		state	free
	=visual>
		isa		oval
	==>
	=goal>
		state	clicking
	+manual>
		isa		move-cursor
		object	=visual
	=visual>
)

(p click-button
	=goal>
		isa 	goal
		state	clicking
	=visual>
		isa		oval
	?manual>
		state	free
	?imaginal>
		state	free
	==>
	=goal>
		state	find
	+manual>
		isa		click-mouse
	-aural>
)
;check "box" color
;productions to find the center should be recycled
;new productions are needed to evaluate color of box
;press spacebar if it is red
;but note the outcome of your "action" 
(p box-is-red
	=goal>
		isa		goal
		state	respond
	=visual>
		isa		text
		color	"red"
	?manual>
		state 	free
	=visual-location>
		isa		visual-location
		kind	oval
	=imaginal>
		isa		prev-action
	==>
	=goal>
		state	switching
	+manual>
		isa		press-key
		key		"space"
	+visual>
		isa		move-attention
		screen-pos	=visual-location
	=imaginal>
		outcome red
	-imaginal>
)
;(spp box-is-red :reward 11)
;just switch back if it's blue
;but note the outcome of your "action" 
(p waited-and-blue
	=goal>
		isa		goal
		state	respond
	=visual>
		isa		text
		color	"blue"
	=visual-location>
		isa		visual-location
		kind	oval
	=imaginal>
		isa		prev-action
		action 	wait
	?manual>
		state	free
	==>
	=goal>
		state	switching
	+visual>
		isa		move-attention
		screen-pos	=visual-location
	=imaginal>
		action	switch
		outcome	red
	-imaginal>
)
(p switched-and-blue
	=goal>
		isa		goal
		state	respond
	=visual>
		isa		text
		color	"blue"
	=visual-location>
		isa		visual-location
		kind	oval
	=imaginal>
		isa		prev-action
		action 	switch
	?manual>
		state	free
	==>
	=goal>
		state	switching
	+visual>
		isa		move-attention
		screen-pos	=visual-location
	=imaginal>
		action	wait
		outcome	red
	-imaginal>
)
;(spp box-is-blue :reward 0)

(goal-focus goal)
)