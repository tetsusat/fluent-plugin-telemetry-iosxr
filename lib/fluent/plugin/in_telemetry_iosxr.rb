require 'fluent/input'
require 'socket'
require 'json'

module Fluent
  class TelemetryInput < Input
    Fluent::Plugin.register_input('telemetry_iosxr', self)

    helpers :server

    config_param :bind, :string, :default => '0.0.0.0'
    config_param :port, :integer, :default => 5432
    config_param :delete_nested, :bool, :default => false

    def configure(conf)
      super
    end

    def start
      super
      @hdr_parsed = false
      @buffer = ""
      @hdr_buffer = ""
      server_create(:in_telemetry_server, @port, bind: @bind, proto: :tcp) do |data, sock|
        receive_data(sock.remote_host, data)
      end
    end
    def shutdown
      super
    end

    protected

    def receive_data(host, data)
      log.info "receive data ..."
      if @hdr_parsed == false
        # Do I need to consider the case the header is in separate receive data?
        @hdr_buffer << data[0..11]
        @remaining_len = hdr_parse()
        @hdr_buffer = ""
        data = data[12..-1] # remove header
        @hdr_parsed = true
      end
      if data.length <= @remaining_len
        @buffer << data
        @remaining_len -= data.length
        if @remaining_len == 0
          data_parse()
          @buffer = ""  # reset
          @hdr_parsed = false
        end
      else # this happens when received data in fluentd tcp server contains multi telemetry messages.
        @buffer << data[0..@remaining_len-1]
        data_parse()
        @buffer = ""  # reset
        @hdr_parsed = false
        receive_data(host, data[@remaining_len..-1])
      end
    end
    def hdr_parse()
      log.info "parse telemetry header ..."
      msg_type = @hdr_buffer[0..1].unpack("n")[0]
      msg_encap = @hdr_buffer[2..3].unpack("n")[0]
      msg_hdr_ver = @hdr_buffer[4..5].unpack("n")[0]
      msg_flag = @hdr_buffer[6..7].unpack("n")[0]
      msg_len = @hdr_buffer[8..11].unpack("N")[0]
      log.info "msg_type=#{msg_type} msg_encap=#{msg_encap} msg_hdr_ver=#{msg_hdr_ver} msg_flag=#{msg_flag} msg_len=#{msg_len}"
      return msg_len
    end
    def data_parse()
      log.info "parse telemetry data ..."
      obj = JSON.parse(@buffer)
      tag = obj['encoding_path']
      es = MultiEventStream.new
      for data in obj['data_json']
        time = data['timestamp'] / 1000
        obj = data['keys'].merge(data['content'])
        record = nil
        if @delete_nested
          record = obj.reject { |k,v| v.is_a? Array }
        else
          record = obj
        end
        es.add(time, record)
      end
      router.emit_stream(tag, es)
    end
  end
end
