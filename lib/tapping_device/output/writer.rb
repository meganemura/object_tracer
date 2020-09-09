class TappingDevice
  module Output
    class Writer
      def initialize(options, output_block)
        @options = options
        @output_block = output_block
      end

      def write!(payload)
        raise NotImplementedError
      end

      private

      def generate_output(payload)
        @output_block.call(PayloadWrapper.new(payload), @options)
      end
    end
  end
end
