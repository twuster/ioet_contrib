require "cord"
sh = require "stormsh"
s = require "starter"

-- start input and outputs
s.LED.start()
s.Button.start()

-- map button to LEDs
storm.io.watch_all(storm.io.FALLING, storm.io.D11, function () s.LED.flip("red") end)
storm.io.watch_all(storm.io.FALLING, storm.io.D9, function () s.LED.flip("green") end)
storm.io.watch_all(storm.io.FALLING, storm.io.D10, function () s.LED.flip("blue") end)

-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
