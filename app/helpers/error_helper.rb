module ErrorHelper
  class ApiError < Exception
    attr_accessor :options
    def initialize(msg, options={})
        self.options = options
        super(msg)
      end
  end
end
