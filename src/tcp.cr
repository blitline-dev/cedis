require "openssl" ifdef !without_openssl
require "socket"
require "./processor.cr"
require "./action.cr"
require "json"
require "signal"

class Tcp
  TOTAL_FIBERS = 40
  MAX_LENGTH = 5_000_000

  def initialize(@host : String, @port : Int32, @debug : Bool, @debug_type : Int32)
		@connections = 0
    @version = ENV["CL_VERSION"]? || "0.0.0.0?"
    @processor = Processor.new
    @action = Action.new(@debug)
  end

  def get_socket_data(socket : TCPSocket) 
    data = nil
    begin
      data = socket.gets
      socket.flush
      puts data.to_s if @debug_type == 1
    rescue ex
      if @debug
        puts ex.inspect_with_backtrace 
        puts "From Socket Address:" + socket.remote_address.to_s if socket.remote_address
      end
    end
    return data
  end

	def reader(socket : TCPSocket, processor : Processor)
  	data = get_socket_data(socket).to_s.strip

    if data == "stats"
      p "Stats"
      stats_response(socket)
      return
    end

    if data == "PING"
      socket.puts("PONG")
    end

    puts "Recieved: #{data}" if @debug
		if data && data.size > 5 && data.size < MAX_LENGTH
			begin
	  	  formatted_data = processor.process(data)
        result = @action.process(formatted_data)
        if result
          socket.puts(result)
        else
          socket.puts("OK")
        end
			rescue ex
				p ex.message
				p "DataErr:#{data}"
 	    end
      socket.flush
    else
      p "Data too big! #{data[0..20]}" if data
	  end
	end

  def stats_response(socket : TCPSocket)
    data = {
      "version" : @version,
      "debug" : @debug,
      "connections" : @connections,
      "port" :  @port,
      "available" : TOTAL_FIBERS
    }
    socket.puts(data.to_json)
  end

	def spawn_listener(socket_channel : Channel)
		TOTAL_FIBERS.times do
      spawn do
        loop do
          begin
            socket = socket_channel.receive
            socket.read_timeout = 1
  					@connections += 1
            reader(socket, @processor)
            socket.close
  					@connections -= 1
          rescue ex
            p "Error in spawn_listener"
            p ex.message
          end
        end
      end
    end
  end

  def listen
		ch = build_channel
		server = TCPServer.new(@host, @port)
    server.tcp_nodelay = true
    server.sync = true
    
		spawn_listener(ch)
		loop do
  		socket = server.accept
  		ch.send socket
		end
  end

  def build_channel
    Channel(TCPSocket).new
  end


end

