class Processor
  alias StringOrNil = String | Nil
  @backup_auth : StringOrNil

  def initialize
    reload
  end

  def reload
    env_auth = ENV["AUTH_CODE"]? || "17hf+"
    split_auth = env_auth.split("|")
    @auth = split_auth[0] as String
    @backup_auth = split_auth.size > 1 ? split_auth[1] : nil
  end

  def process(data : String) : Hash(String, String) | ::Nil
    begin
      if data
        hash = split_data(data)
        return hash
      end
    rescue ex
      puts "Couldn't parse data...#{data}"
      puts ex.message
      puts ex.callstack
    end
    return nil
  end

  def split_data(data : String) : Hash(String, String)
    results = Hash(String, String).new
    split_data = data.split(' ', 4)
    auth = split_data[0].strip
    command = split_data[1].strip
    key = split_data[2].strip
    raw_data = ""
    raw_data = split_data[3].strip if split_data.size > 3

    unless @auth == auth
      unless @backup_auth == auth
        puts "Illegal Auth #{auth}"
      end
    end

    results["command"] = command
    results["key"] = key
    results["raw_data"] = raw_data
    return results
  end


end
