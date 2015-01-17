----------------------------------------------
-- Starter Shield Module
--
-- Provides a module for each resource on the starter shield
-- in a cord-based concurrency model
----------------------------------------------

require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library


----------------------------------------------
-- LED module
-- provide basic LED functions
----------------------------------------------
local LED = {}

LED.start = function()
-- configure LED pins for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D2)
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D3)
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D4)
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D5)
end

LED.stop = function()
-- configure pins to a low power state
end

-- LED color functions get set the LED or set it to a binary state
-- with no arg or nil, returns the current state unchanged
-- otherwise sets state and returns it
-- These should rarely be used in isolation as an active LED 
--- burns a lot of power

LED.blue = function(state) return LED.getset("D2",state) end
LED.green = function(state) return LED.getset("D3",state) end
LED.red = function(state) return LED.getset("D4",state) end

LED.getset = function(pin, state)
   if (state == nil) then return storm.io.get(storm.io[pin])
   elseif (state==0) then storm.io.set(0,storm.io[pin]); return state
   else storm.io.set(1,storm.io[pin]); return state
   end
end

-- Strobe an LED pin for a period of time
--    unspecified duration is default of 50 ms
--    this is dull for green, but bright for read and blue
--    assumes cord.enter_loop() is in effect to schedule filaments
LED.blueStrobe = function(duration) LED.strobe("D2",duration) end
LED.greenStrobe = function(duration) LED.strobe("D3",duration) end
LED.redStrobe = function(duration) LED.strobe("D4",duration) end

LED.strobe=function(pin,duration)
   duration = duration or 50
   storm.io.set(1,storm.io[pin])
   storm.os.invokeLater(duration*storm.os.MILLISECOND,
			function() 
			   storm.io.set(0,storm.io[pin]) 
			end)
end

LED.display = function (val)
   if (val   % 2 == 1) then LED.blue(1) else LED.blue(0) end
   if (val/2 % 2 == 1) then LED.green(1) else LED.green(0) end
   if (val/4 % 2 == 1) then LED.red(1) else LED.red(0) end
end

----------------------------------------------
-- Buzz module
-- provide basic buzzer functions
----------------------------------------------
local Buzz = {}

Buzz.run = nil
Buzz.go = function()
-- configure buzzer pin for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D6)
   Buzz.run = true
   cord.new(function()
	       while Buzz.run do
		  storm.io.set(1,storm.io.D6)
		  cord.yield()
		  storm.io.set(0,storm.io.D6)	       
		  cord.yield()
	       end
	    end)
end

Buzz.stop = function()
   Buzz.run = false
-- configure pins to a low power state
end


----------------------------------------------
-- Shield module for starter shield
----------------------------------------------
local shield = {}

shield.LED = LED
shield.Buzz = Buzz
return shield
