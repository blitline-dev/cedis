require "./tcp.cr"

port = ENV["CL_TCP_PORT"]? || "9765"
stats_port = ENV["CL_STATS_TCP_PORT"]? || "9777"
listen = ENV["CL_LISTEN"]? || "0.0.0.0"
debug = ENV["CL_DEBUG"]?.to_s == "true"

debug_type = 0
if ENV["CL_DEBUG_TYPE"]? && ENV["CL_DEBUG_TYPE"].to_i > 0
  debug_type = ENV["CL_DEBUG_TYPE"].to_i
end


puts "Starting tcp server"
puts "TCP listening on #{listen}:#{port}"
puts "Logging TCP-IN" if debug_type == 1
server = Tcp.new(listen, port.to_i, debug, debug_type)
server.listen()

