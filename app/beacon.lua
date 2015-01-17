
require "cord" -- scheduler / fiber library

local sock = storm.net.udpsocket(100, function(payload, from, port)
    print (string.format("Got a message from %s port %d",from,port))
    print ("Payload: ", payload)
end)

local count = 0
storm.os.startPeriodic(5*storm.os.SECOND, function()
    storm.net.sendto(sock, string.format("0x%04 says count=%d", storm.os.nodeid(), count), "ff02::1", 100)
    end
)


cord.enter_loop() -- start event/sleep loop
