#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/method_maker'

module Summer
    class CalledAbstractMethodError < RuntimeError
        attr :method_name, :in_class

        def initialize m, c
            @method_name = m
            @in_class = c
        end
    end
end

class Module
    def abstract_method_1 method
        define_method method do
            raise Summer::CalledAbstractMethodError.new(method, self.class),
                "Abstract method #{self.class}##{method} called"
        end
    end

    def abstract_self_method_1 method
        class << self
            self
        end.instance_eval do
            define_method method do
                raise Summer::CalledAbstractMethodError.new(method, self),
                    "Abstract self method #{self}##{method} called"
            end
        end
    end

    # Define a method that, when called, raises a CalledAbstractMethodError.
    # Useful for making it obvious that people who do subclassing are expected
    # to implement something.
    method_maker :abstract_method

    # Define a self method that, when called, raises a CalledAbstractMethodError.
    # Useful for making it obvious that people who do subclassing are expected
    # to implement something.
    method_maker :abstract_self_method
end

