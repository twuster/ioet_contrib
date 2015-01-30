require "cord"
sh = require "stormsh"
s = require "starter"

-- start input and outputs
s.LED.start()
s.Button.start()
s.Buzz.start()

-- map button to LEDs
storm.io.watch_all(storm.io.FALLING, storm.io.D11, function () 
    s.wait_ms(5)
    s.LED.flashWithCount("red", 100, 2)
    s.Buzz.stop()
    s.Buzz.go(s.Buzz.periods["250Hz"])
    end)
storm.io.watch_all(storm.io.FALLING, storm.io.D10, function () 
    s.wait_ms(5)
    s.LED.flashWithCount("green", 100, 2)
    s.Buzz.stop()
    s.Buzz.go(s.Buzz.periods["500Hz"])
    end)
storm.io.watch_all(storm.io.FALLING, storm.io.D9, function () 
    s.wait_ms(5)
    s.LED.flashWithCount("blue", 100, 2)
    s.Buzz.stop()
    s.Buzz.go(s.Buzz.periods["1kHz"])
    end)

-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
