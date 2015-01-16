function printf(s,...)
   return io.write(s:format(...))
end

function pptable(t)
  for k,v in pairs(t) do
    print (k,v)
  end
end

function pparray(a)
   printf("%d:%d[",bounds(a))
   for i,v in pairs(a) do
      printf("%s ",v)
   end
   printf("]\n")
end


function ppmat(m)
   printf("%d:%d[",bounds(m))
   for i = 1, #m do
      pparray(m[i])
   end
   printf("]\n")
end

function bounds(a)
   local v
   local first,v = next(a)
   local last = first
   local n,v = next(a,first)
   while n do
      last = n
      n,v = next(a,n)
   end
   return first,last
end
