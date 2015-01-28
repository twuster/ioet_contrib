require "cord"
sh = require "stormsh"
s = require "starter"
s.LED.start()
s.Button.start()

-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
