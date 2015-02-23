require "cord"
sh = require "stormsh"

-- Announcement code
ipaddr = storm.os.getipaddr()
announcement_port = 1525
invocation_port = 1526
phone_port = 1527
waiting_for_return = false
waiting_for_temp = false

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
		print("Got response from: ", from)
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
			end
			-- print current services table
			for i,j in pairs(services) do
				print(i,j)
			end
	end)

-- socket listening on invocation port
isock = storm.net.udpsocket(invocation_port,
	function(payload, from, port)
		-- get the service name
		print ("invoked 1")
		local unpacked = storm.mp.unpack(payload)
		if (waiting_for_return) then
			print(unpacked)
			if (waiting_for_temp) then
				print("sending to phone")
				sendToPhone(unpacked)
				waiting_for_temp = false
			end
			waiting_for_return = false
			return
		end
		local s_name = unpacked[1]
		print(unpacked)
		print("service: ", s_name)
		if s_name == "printString" then
			print("inside print stirng")
			rtn = svc_stdout(from, port, unpacked[2][1])
			sendInvokeMessage(rtn, port, from)
		elseif s_name == "getNow" then
			rtn = svc_getNow()
			sendInvokeMessage(rtn, port, from)
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
	waiting_for_return = true
	storm.net.sendto(isock, storm.mp.pack(msg), address, port)
end

psock = storm.net.udpsocket(phone_port,
		function(payload, from, port)
			print (payload)
			print (port)
			print (from)
		end)

function sendPhoneMessage(msg, port, address)	
	print("second")
	storm.net.sendto(psock, msg, address, port)
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


function invokeLEDFunction(name, params) 
	local msg = {name, params}
	sendInvokeMessage(msg, invocation_port, "fe80::8e3a:e3ff:fe4c:1157")
end

function sendToPhone(msg)
	print('sending to phone')
	sendPhoneMessage(msg, phone_port, "2001:470:4956:1:8e3a:e3ff:fe4c:1157")
	--sendPhoneMessage(msg, phone_port, "2001:470:4956:2:212:6d02::3016")
	

	--sendPhoneMessage(msg, phone_port, "2001:470:4956:1:105c:58eb:317a:c340")
--	sendPhoneMessage(msg, phone_port, "2001:470:4956:1:82e6:50ff:fe0e:89c4")
	--sendPhoneMessage(msg, phone_port, "2001:470:4956:1:82e6:50ff:fe0e:89c4")
	--sendPhoneMessage(msg, phone_port, "2607:f140:400:a008:8e3a:e3ff:fe4c:1157")
	--sendPhoneMessage(msg, phone_port, "2001:470:1f04:5f2::2")
end

function sendPeriodically(msg)
	storm.os.invokePeriodically(storm.os.MILLISECOND *1000, sendToPhone, msg)
end

function requestTemp()
	invokeFunction('getDisp', {})
	waiting_for_temp = true
end

function setReminder(msg)
	invokeFunction('writeDisp', {msg})
end

sh.start()
cord.enter_loop()


