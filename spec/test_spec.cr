require "./spec_helper"
require "json"

IP = "localhost" # "ec2-52-91-166-123.compute-1.amazonaws.com"
PORT = "9765"

def send_command(auth, command, data, key = SecureRandom.urlsafe_base64(4))
  cmdline = [auth, command, key, data.to_s].join(" ").strip
  raw_command = "echo '#{cmdline}' | socat - tcp4-connect:#{IP}:#{PORT}"
  process_run(raw_command).strip
end

def process_run(cmd : String)
  io = MemoryIO.new
  Process.run(cmd, shell: true, output: io)
  output = io.to_s
end

describe "Cedis" do
  
  it "should atomically handle Integers" do
    auth = "17hf+"
    key = SecureRandom.urlsafe_base64(4)
    send_command(auth, "SETINT", "1", key).to_i.should eq(1)
    send_command(auth, "INCR", "", key)
    send_command(auth, "GETINT", "", key).to_i.should eq(2)
    send_command(auth, "INCR", "2", key)
    send_command(auth, "GETINT", "", key).to_i.should eq(4)
    send_command(auth, "INCR", "-2", key).to_i.should eq(2)
    send_command(auth, "GETINT", "", key).to_i.should eq(2)
    send_command(auth, "DECR", "-2", key).to_i.should eq(4)
    send_command(auth, "GETINT", "", key).to_i.should eq(4)
    send_command(auth, "DECR", "-2", key).to_i.should eq(6)
    send_command(auth, "GETINT", "", key).to_i.should eq(6)
  end

  it "should return OK for generic operations" do
    auth = "17hf+"
    # Random Key
    send_command(auth, "HCREATE", "").should eq("OK")
    send_command(auth, "LCREATE", "").should eq("OK")

    # Fixed Key
    key = SecureRandom.urlsafe_base64(4)
    send_command(auth, "HCREATE", "", key).should eq("OK")
    send_command(auth, "SET", "foo {\"bar\" : \"tax\" }", key).should eq("OK")
  end

  it "should return empty for invalid operations" do
    auth = "17hf+"
    send_command(auth, "GETINT", "", SecureRandom.urlsafe_base64(4)).should eq("")
    send_command(auth, "GET", "", SecureRandom.urlsafe_base64(4)).should eq("")
    send_command(auth, "BLAH", "", SecureRandom.urlsafe_base64(4)).should eq("")
    send_command(auth, "DECR", "", SecureRandom.urlsafe_base64(4)).should eq("")
    send_command(auth, "INCR", "", SecureRandom.urlsafe_base64(4)).should eq("")
    send_command(auth, "\"", "", SecureRandom.urlsafe_base64(4)).should eq("")
  end

  it "should atomically handle arrays" do
    data = [
      "{ \"foo\": \"bar\" }",
      "{ \"taz\": \"cookie\" }",
      "{ \"monkey\": \"duck\" }",
    ]
    auth = "17hf+"
    
    # Fixed Key
    key = SecureRandom.urlsafe_base64(4)
    send_command(auth, "LCREATE", "", key).should eq("OK")
    data.each do |row|
      send_command(auth, "LPUSH", row, key).should eq("OK")
    end
    results = send_command(auth, "LRANGE", "", key).should eq(data.inspect)
  end

  it "should atomically handle hashes" do
    auth = "17hf+"
    key = SecureRandom.urlsafe_base64(4)
    send_command(auth, "HCREATE", "", key).should eq("OK")
    send_command(auth, "SET", "blah { \"foo\": \"bar\" }", key).should eq("OK")
    send_command(auth, "SET", "zai { \"jjj\": \"hope\" }", key).should eq("OK")
    send_command(auth, "GET", "blah", key).should eq("{ \"foo\": \"bar\" }")
    output_string = send_command(auth, "GET", "blah", key)
    new_obj = Hash(String, String).new
    json_obj = JSON.parse(output_string)
    json_obj.each do |key, value|
      new_obj[key.to_s] = value.to_s
    end
    new_obj["foo"] = "bar2"
    send_command(auth, "SET", "blah #{new_obj.to_json}", key).should eq("OK")
    send_command(auth, "GET", "blah", key).should eq("{\"foo\":\"bar2\"}")

  end



end

