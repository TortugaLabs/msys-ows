local nixio = require("nixio")

port = port or 4343
if arg then
  port = arg[1] or port
end

serv = nixio.socket("inet","stream")
assert(serv:bind(nil,port))

serv:listen(8)

while 1 do
  c = serv:accept()
  p = nixio.fork()
  if p == 0 then
    serv:close()
    nixio.dup(c, nixio.stdin)
    nixio.dup(c, nixio.stdout)
    nixio.dup(c, nixio.stderr)
    os.execute("*MUNIN CMD*")
    os.exit(0)
  else
    c:close()
  end
  repeat
    a = nixio.waitpid(-1,"nohang")
  until a  
end

