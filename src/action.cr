class Action
  class DataStruct
    property created_at : Time

    def initialize
      @int_store = Int32.new(0)
      @hash_store = Hash(String, String).new
      @array_store = Array(String).new
      @created_at = Time.utc
    end

    def parse_as_int(raw_data : String) : Int32
      raw_data = 0 if raw_data.to_s.empty?

      return raw_data.to_i
    end

    def parse_as_string(raw_data : String) : String
      return raw_data
    end

    def parse_as_tuple(raw_data : String) : Tuple(String, String)
      data = raw_data.split(" ", 2)
      return Tuple(String, String).new(data[0], data[1])
    end

    def action(command : String, raw_data : String)
      return_value = ""

      case command
      when "LPUSH"
        @array_store << parse_as_string(raw_data)
        return_value = "OK"
      when "LRANGE"
        return_value = @array_store.inspect
      when "SETINT"
        @int_store = parse_as_int(raw_data)
        return_value = @int_store.to_s
      when "GETINT"
        return_value = @int_store.to_s
      when "EXISTS"
        return_value = @hash_store.has_key?(parse_as_string(raw_data)) ? "1" : "0"
      when "INCR"
        delta = parse_as_int(raw_data.to_s)
        delta = 1 if delta == 0
        @int_store += delta
        return_value = @int_store.to_s
      when "DECR"
        delta = parse_as_int(raw_data.to_s)
        delta = 1 if delta == 0
        @int_store -= delta
        return_value = @int_store.to_s
      when "SET"
        value = parse_as_tuple(raw_data)
        @hash_store[value[0]] = value[1] if value && value.size > 1
        return_value = "OK"
      when "GET"
        return_value = @hash_store[parse_as_string(raw_data)]
      end
      return return_value
    end
  end

  def initialize(debug : Bool)
    @debug = debug
    @primary_map = Hash(String, DataStruct).new
    watch
  end

  def process(data : Hash(String, String) | Nil) : String | Nil
    return_val = "OK"
    skip = false
    begin
      if data
        key = data["key"]?
        if data["command"] == "LCREATE"
          handle_list_create(data)
          skip = true
        elsif data["command"] == "SETINT"
          handle_int_create(data)
        elsif data["command"] == "HCREATE"
          handle_hash_create(data)
          skip = true
        end
        data_struct = @primary_map[key]?
        if data_struct
          action_val = data_struct.action(data["command"], data["raw_data"])
          return_val = action_val unless skip
        else
          puts "#{data["key"]} Not found, ignoring..."
          return_val = ""
        end
      end
    rescue ex
      return_val = ""
      puts ex.message
      puts ex.callstack
    end
    return return_val
  end

  def handle_list_create(data : Hash(String, String))
    @primary_map[data["key"]] = DataStruct.new
  end

  def handle_int_create(data : Hash(String, String))
    @primary_map[data["key"]] = DataStruct.new
  end

  def handle_hash_create(data : Hash(String, String))
    @primary_map[data["key"]] = DataStruct.new
  end

  def watch
    spawn do
      loop do
        @primary_map.reject! do |key, value|
          value.created_at < Time.utc - 1.day
        end
        sleep 60
      end
    end
  end
end
