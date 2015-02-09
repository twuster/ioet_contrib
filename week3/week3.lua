require "cord"
sh = require "stormsh"

-- Announcement code
ipaddr = storm.os.getipaddr()
announcement_port = 1525
invocation_port = 1526

-- table of services
services = {}


-- create an announcement
announcement = {
	id="wassup",
	setRlyA={ s="setBool", desc= "red LED" },
	setRlyB={ s="setBool", desc= "green LED" },
	setRlyC={ s="setBool", desc= "blue LED" },
}

-- create client socket
csock = storm.net.udpsocket(announcement_port,
	function(payload, from, port)
		-- store payload into our services table
		print("Got response: %s", payload)
                local unpacked = storm.mp.unpack(payload)
		for k,v in pairs(unpacked) do 
			print("service: key: %s value: %s", k,v)
			id = nil
			if k ~= "id" then
				-- If not id, map the id and address to the services
				if services[k] then
					services[k][id] = from
				else
					services[k] = {id= from}
				end
			else
				-- store the id
				id = k
			end
			for ke, va in pairs(services) do
				print("saved: ", ke, va)
			end
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


-- sends a message through a port
function sendMessage(msg, port)
	-- TODO: include time
	-- msg["time"] = storm.os.now(storm.os.SHIFT_0)
	
	-- print("send: ", storm.mp.pack(msg))
	storm.net.sendto(csock, storm.mp.pack(msg), "ff02::1", port)
	
end

-- periodically send out our services
if sendHandle == nil then
	sendHandle = storm.os.invokePeriodically(2000*storm.os.MILLISECOND, sendMessage, announcement, announcement_port)
end

-- service invocation function
function invokeFunction(name, params) 
	local msg = {name, params}
	sendMessage(storm.mp.pack(msg), invocation_port)
end

sh.start()
cord.enter_loop()


