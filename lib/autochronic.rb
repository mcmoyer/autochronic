require 'activerecord'
require 'chronic'

module ActiveRecord
  module AttributeMethods
    module ClassMethods
      def define_write_method_for_time_zone_conversion(attr_name)
        method_body = <<-EOV
          def #{attr_name}=(time)
            unless time.acts_like?(:time)
              time = time.is_a?(String) ? (Chronic.parse(time) || Time.zone.parse(time)) : time.to_time rescue time
            end
            time = time.in_time_zone rescue nil if time
            write_attribute(:#{attr_name}, time)
          end
        EOV
        evaluate_attribute_method attr_name, method_body, "#{attr_name}="
      end
    end
  end
end

class ActiveRecord::ConnectionAdapters::Column
  class << self
    def string_to_date_with_chronic(string)
      result = string_to_date_without_chronic(string)
      return result if result
      
      parsed = Chronic.parse(string)
      parsed and parsed.to_date
    end
    alias_method_chain :string_to_date, :chronic
    
    def string_to_time_with_chronic(string)
      result = string_to_time_without_chronic(string)
      return result if result
      
      Chronic.parse(string)
    end
    alias_method_chain :string_to_time, :chronic
  end
end
