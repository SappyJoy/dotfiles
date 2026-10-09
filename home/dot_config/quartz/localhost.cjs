// Quartz's server and its live-reload socket listen on every network interface, and
// Quartz has no option to change that. The fish function notes preloads this file
// (node --require), so they listen on this machine only.
const net = require("net")
const listen = net.Server.prototype.listen
net.Server.prototype.listen = function (port, ...rest) {
  // listen(port), listen(port, callback), listen(port, undefined, backlog, callback)
  if (typeof port === "number" && typeof rest[0] !== "string") {
    if (rest[0] === undefined) rest[0] = "127.0.0.1"
    else rest.unshift("127.0.0.1")
  }
  return listen.call(this, port, ...rest)
}
