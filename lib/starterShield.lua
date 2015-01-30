----------------------------------------------
-- Starter Shield Module
--
-- Provides a module for each resource on the starter shield
-- in a cord-based concurrency model
-- and mapping to lower level abstraction provided
-- by storm.io @ toolchains/storm_elua/src/platform/storm/libstorm.c
----------------------------------------------

require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
----------------------------------------------
-- Shield module for starter shield
----------------------------------------------
local shield = {}

----------------------------------------------
-- LED module
-- provide basic LED functions
----------------------------------------------
local LED = {}

LED.pins = {["blue"]="D2",["green"]="D3",["red"]="D4",["red2"]="D5"}
LED.status = {["blue"]=0, ["green"]=0, ["red"]=0, ["red2"]=0}
LED.handles = {["blue"]=nil, ["green"]=nil, ["red"]=nil, ["red2"]=nil}

LED.start = function()
-- configure LED pins for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D2,
		     storm.io.D3,
		     storm.io.D4,
		     storm.io.D5)
end

LED.stop = function()
-- configure pins to a low power state
end

-- LED color functions
-- These should rarely be used as an active LED burns a lot of power
LED.on = function(color)
   storm.io.set(1,storm.io[LED.pins[color]])
   LED.status[color] = 1
end
LED.off = function(color)
   storm.io.set(0,storm.io[LED.pins[color]])
   LED.status[color] = 0 
end

-- Flash an LED pin for a period of time
--    unspecified duration is default of 10 ms
--    this is dull for green, but bright for read and blue
--    assumes cord.enter_loop() is in effect to schedule filaments
-- We return the periodic task, color pair so that it can be stopped later
LED.flash=function(color,duration)
   if duration == nil then
      duration = 10
   end
   LED.handles[color] = storm.os.invokePeriodically(duration*storm.os.MILLISECOND, 
   function()
	    LED.flip(color)
   end)
end

LED.flashWithCount=function(color,duration, count)
   local count = count *2
   if duration == nil then
      duration = 10
   end
   LED.handles[color] = storm.os.invokePeriodically(duration*storm.os.MILLISECOND, 
   function()
	    if count and count > 0 then
		    LED.flip(color)
	 	    count = count -1
	    else
   		    LED.stopFlash(color)
	    end
   end)
end



-- Given a task and color tuple, it stops that led from flashing
LED.stopFlash = function(color)
    storm.os.cancel(LED.handles[color])
    storm.io.set(0,storm.io[LED.pins[color]])
end

-- Flips the status of an LED between on and off
LED.flip = function(color)
    if LED.status[color]==1 then
	    LED.off(color)
    else
	    LED.on(color)
	end
end
----------------------------------------------
-- Buzz module
-- provide basic buzzer functions
----------------------------------------------
local Buzz = {}
Buzz.status = 0
Buzz.task = nil
Buzz.killed = 0
Buzz.TENTHMS = storm.os.MILLISECOND / 10
Buzz.delays = {["5kHz"]=1, ["2.5kHz"]=2, ["1kHz"]=5, ["500Hz"]=10, ["250Hz"]=20}

Buzz.start = function()
	storm.io.set_mode(storm.io.OUTPUT, storm.io.D6)
end

Buzz.go = function(delay)
	if delay == nil then
      		delay = 10
    end
    Buzz.task = storm.os.invokePeriodically(delay*Buzz.TENTHMS, 
    function()
	    if Buzz.killed ~=1 then
		    Buzz.flip()
	    else
		    Buzz.killed = 0
	    end
    end)
    Buzz.task = r
end

Buzz.flip = function()
	storm.io.set(1-Buzz.status, storm.io.D6)
	Buzz.status = 1- Buzz.status
end

Buzz.stop = function()
	Buzz.killed = 1
	if Buzz.task then
		storm.os.cancel(Buzz.task)
		storm.io.set(0, storm.io.D6)
	end
	Buzz.task = nil
end

----------------------------------------------
-- Button module
-- provide basic button functions
----------------------------------------------
local Button = {}
local button_map = {storm.io.D9, storm.io.D10, storm.io.D11}

Button.start = function() 
   storm.io.set_mode(storm.io.INPUT, button_map[1], button_map[2], button_map[3])
   storm.io.set_pull(storm.io.PULL_UP, button_map[1])
   storm.io.set_pull(storm.io.PULL_UP, button_map[2])
   storm.io.set_pull(storm.io.PULL_UP, button_map[3])
end

-- Get the current state of the button
-- can be used when poling buttons
Button.pressed = function(button) 
   return storm.io.get(button_map[button]) == 0
end

-------------------
-- Button events
-- each registers a call back on a particular transition of a button
-- valid transitions are:
--   FALLING - when a button is pressed
--   RISING - when it is released
--   CHANGE - either case
-- Only one transition can be in effect for a button
-- must be used with cord.enter_loop
-- none of these are debounced.
-------------------
Button.whenever = function(button, transition, action)
   storm.io.watch_all(transition, button, action)
end

Button.when = function(button, transition, action)
   storm.io.watch_single(transition, button, action)
end

Button.wait = function(button)
   cord.await(storm.io.watch_single, storm.io.FALLING, button_map[button])
end

----------------------------------------------
shield.LED = LED
shield.Buzz = Buzz
shield.Button = Button
return shield


