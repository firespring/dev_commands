# Core Object class for ruby
class Object
  # Returns "true" if the object is a boolean
  def boolean?
    is_a?(TrueClass) || is_a?(FalseClass)
  end
end
