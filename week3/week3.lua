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
	printString={ s="", desc= "prints a string" },
	getNow={ s="getNumber", desc= "get the current time"},
}

-- create client socket
csock = storm.net.udpsocket(announcement_port,
	function(payload, from, port)
		-- store payload into our services table
		print("Got response: %s", payload)
                local unpacked = storm.mp.unpack(payload)
		-- if we receive an announcement
		--if port == announcement_port then
			local id = unpacked["id"]
			for k,v in pairs(unpacked) do 
				--print("service: key: value: ", k,v)
				if k ~= "id" then
					-- If not id, map the id and address to the services
					if services[k] then
						if not contains(services[k], id) then
							table.insert(services[k], id)
						end		
					else
						local t = {}
						table.insert(t, id)
						services[k] = t
					end
				end
				--[[for ke, va in pairs(services) do
					print("saved: ", ke, va)
				end]]--
			end
		-- if we receive a service invocation
		--[[elseif port == invocation_port then
			-- get the service name
			print ("invoked 1")
			local s_name = unpacked[1]
			print("service: ", s_name)
			if s_name == "printString" then
				print("inside print stirng")
				rtn = svc_stdout(from, port, unpacked[2][1])
				sendMessage(rtn, port, from)
			elseif s_name == "getNow" then
				rtn = svc_getNow()
				sendMessage(rtn, port, from)
			else
				print("Unsupported service")
			end	
		end]]--
	end)

isock = storm.net.udpsocket(invocation_port,
	function(payload, from, port)
		-- get the service name
		print ("invoked 1")
		local unpacked = storm.mp.unpack(payload)
		local s_name = unpacked[1]
		print(unpacked)
		print("service: ", s_name)
		if s_name == "printString" then
			print("inside print stirng")
			rtn = svc_stdout(from, port, unpacked[2][1])
			sendMessage(rtn, port, from)
		elseif s_name == "getNow" then
			rtn = svc_getNow()
			sendMessage(rtn, port, from)
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

-- our service functions
function svc_stdout(from_ip, from_port, msg)
  	print (string.format("[STDOUT] (ip=%s, port=%d) %s", from_ip, from_port, msg))
end

function svc_getNow()
	return storm.os.now(storm.os.SHIFT_0)
end

-- sends a message through a port
function sendMessage(msg, port, address)
	-- TODO: include time
	-- msg["time"] = storm.os.now(storm.os.SHIFT_0)
	
	-- print("send: ", storm.mp.pack(msg))
	storm.net.sendto(csock, storm.mp.pack(msg), address, port)
	
end

function sendInvokeMessage(msg, port, address)
	storm.net.sendto(isock, storm.mp.pack(msg), address, port)
end

-- periodically send out our services
if sendHandle == nil then
	sendHandle = storm.os.invokePeriodically(2000*storm.os.MILLISECOND, sendMessage, announcement, announcement_port, "ff02::1")
end

-- service invocation function
function invokeFunction(name, params) 
	local msg = {name, params}
	sendInvokeMessage(msg, invocation_port, "ff02::1")
end

sh.start()
cord.enter_loop()


