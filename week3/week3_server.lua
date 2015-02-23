require "cord"
sh = require "stormsh"
TEMP = require "temp"
LCD = require "lcd"

require("storm") 

lcdWords = "Wear Sunglasses" 
tempValue = 0 

lcd = nil

function tempSetup()
	temp = TEMP:new()
	cord.new(function() temp:init() end)
	tempValue = getTemp();	
end 

function lcdSetup()
	lcd = LCD:new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4) 
	updateLCD() 
end

function updateLCD()
	cord.new(function() lcd:init(2,1) lcd:clear() lcd:setBackColor(0,0,255)
	lcd:writeString(string.format("%d degrees ",tempValue))
	lcd:setCursor(2,0) lcd:writeString( lcdWords)
	end)
end  


function getTemp() 
	cord.new(function() tempValue = temp:getTemp() end)
	print("this is temp:",tempValue) 

	return tempValue; 
end 
tempSetup()
lcdSetup()
-- Announcement code
ipaddr = storm.os.getipaddr()
announcement_port = 1525
invocation_port = 1526

-- table of services
--services = {}

-- create an announcement
announcement = {
	id="wassup",
	getTemp= { s="getTemp", desc= "get the current temp"}, 
	getDisp = { s="getDisp", desc= "get text on LCD Disp"}, 
	writeDisp= { s ="writeDisp", desc= "write to LCD Disp"}, 
}

-- create client socket
csock = storm.net.udpsocket(announcement_port,
	function(payload, from, port)

	end) 

isock = storm.net.udpsocket(invocation_port,
	function(payload, from, port)
		-- get the service name
		local unpacked = storm.mp.unpack(payload)
		local s_name = unpacked[1]
		print(unpacked)
		print("service: ", s_name)
		if s_name == "getTemp" then
			local rtn = getTemp() -- * 9 / 5 + 32
			print(rtn) 
			sendMsg(rtn, port, from) 
		elseif s_name == "writeDisp" then 
			lcdWords = unpacked[2][1]
			updateLCD()
			rtn = string.format("Display says: %s", lcdWords)  
			sendMsg(rtn,port,from) 
		elseif s_name == "getDisp" then 
			rtn = string.format("%d:%s", tempValue, lcdWords) 
			sendMsg(rtn,port,from)		
		else
			print("Unsupported service")
		end
	end) 

-- get ip and addresses associated with a service
function getMapping(service)
	if services[service] then
		return services[service]
	else
		print("No such service stored")
	end

end

-- checks if a table contains an element
function contains(table, element)
	for idx, elem in pairs(table) do
		if elem == element then
			return true
		end
	end
	return false
end


-- sends a message through a port
function sendMsg(msg, port, address)
	storm.net.sendto(csock, storm.mp.pack(msg), address, port)
	
end


-- periodically send out our services
if sendHandle == nil then
	sendHandle = storm.os.invokePeriodically(2000*storm.os.MILLISECOND, sendMsg, announcement, announcement_port, "ff02::1")
end

sh.start()
cord.enter_loop()
