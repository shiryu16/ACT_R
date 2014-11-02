ACT-R Model for Trust in Automation Task instructions
 Jorge Zuniga and Greg Trafton
	jorge.zng@gmail.com

This readme explains the functions used in order to run the model of the task as well as the overall process that all iterations of the model go through. 

Functions for Testing and Running the model: 

(experiment TPR FPR (:trials 10))
	Experiment takes the true positive rate (TPR) and False Positive Rate (FPR) as required parameters. TPR and FPR are the rate at which the automation alerts the user
	to switch to the cart. The keyword :trials is how many trials to run and is set to a default of 10 trials for testing purposes. 
	
(param-explore TPR FPR participants-per-condition)
	This function has no default values. 
	It takes the intended True positive Rate (hit rate) as well as the False Positive Rate (false alarm) and the number of participants per condition. 
	It then runs the model enough times to iterate over all the combinations of the parameter space as defined by the let statement. 
		It currently iterates over a list of :egs values, 
		a list of utlity rewards for critical trials (red-reward), 
		a list of utility rewards for non-critical trials (blue-reward), 
		and finally the number of participants-per-condition. 
	More parameters can be added if a new loop is added to the code nested with the other 4. Make sure to keep the number of participants per condition as the deepest level of the nested loop. 
	
(do-explore ppt-per-condition)
	This function takes number of participants. 
	It then runs 4 param-explore statements
		It uses the TPR and FPR that was used in experiments 1,2,3 of the trust in automation task. 
			Those levels are 91/15, 85/10, 75/5, and 67/3. 
	
	
	
General process the model goes through

Setting up the environment: 
	First two windows are generated. 
	then the relevant information is put on the windows, a button in each as well as a textbox which changes in the information it contains. 
	The model starts focus on the "drill window" but can switch to the "cart" window by clicking the button. 
		The textbox in the drill window is stationary, however in the actual trust task, this box moves randomly throughout the screen. 

		
Trials: 
	Trials follow a specific sequence of events, this is defined in the code in the experiment function. 
	The sequence of events is as follows: 
	1. A filler is generated -- this turns the text in window 2 blue
	2. The model runs-full-time for a period of 7-10 seconds (this emulates the task which has a filler that runs for 7-10 seconds)
	3. At the end of the filler period a trial type is decided -- based on the TPR and FPR -- and then the text in "cart" window changes to reflect the trial
	4. The model runs-full-time for 8-12 seconds. This timing also emulates the trust task. 
		The process then repeats. 
		
Model: 
	The model first attends to the text in the center box in "drill" window, moves visual attention, then the mouse to the center box. 
	Attention will remain in that location until either the model "hears" the alarm, or it decides to switch-with-no-alarm. 
	The model then moves visual attention to the button, then moves the mouse and finally clicks the button. 
	Clicking the button changes the model's focus to the "cart" window
	Attention the moves to the center text which will be either "bluebox" or "redbox" (and either of those colors in the visicon)
	based on which color the text is the model will either be reward for it's behavior or receive a negative reward (essentially punished) 
	After the model figures out the color of the box, it then switches back using hte same procedure to click the button and move attention back to the box in the "drill" window. 
	"rinse and repeat" 
	