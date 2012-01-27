# The Location entity
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/movement_strategy'

module Motel

# FIXME Motel locations need concurrent access protection, add here (?)

# A Location defines an optional parent location and the x,y,z
# cartesian  coordinates of the location relative to that parent.
# If parent is not specified x,y,z are ignored and this location
# is assumed to be the 'center' of the system to which it belongs
# Also is related to a movable object defining the parameters
# of the locations movement 
class Location

   # id of location and parent, and coordinates relative to that parent
   attr_accessor :id, :x, :y, :z, :parent_id

   # handle to parent location and array of children
   attr_accessor :parent, :children

   # movement strategy which location move in accordance to
   attr_accessor :movement_strategy

   # array of callbacks to be invoked on movement
   attr_accessor :movement_callbacks

   # Array of callbacks to be invoked on proximity
   attr_accessor :proximity_callbacks

   # a generic association which this location can belong to
   attr_accessor :entity

   def initialize(args = {})
      # default to the stopped movement strategy
      @movement_strategy = MovementStrategies::Stopped.instance
      @movement_callbacks = []
      @proximity_callbacks = []
      @children = []

      @x = nil
      @y = nil
      @z = nil

      [:id, :parent_id, :x, :y, :z, :parent, :movement_strategy].each { |key|
        inst_attr = ('@' + key.to_s).to_sym
        if args.has_key? key
          instance_variable_set(inst_attr, args[key])
        elsif args.has_key? key.to_s
          instance_variable_set(inst_attr, args[key.to_s])
        end
      }
      @parent.children.push self unless @parent.nil? || @parent.children.include?(self)
   end

   # update this location's attributes to match other's set attributes
   def update(location)
      @x = location.x unless location.x.nil?
      @y = location.y unless location.y.nil?
      @z = location.z unless location.z.nil?
      @movement_strategy = location.movement_strategy unless location.movement_strategy.nil?
      @parent = location.parent unless location.parent.nil?
      @parent_id = location.parent_id unless location.parent_id.nil?
   end

   # return this locations coordinates in an array
   def coordinates
     [@x, @y, @z]
   end

   # return this location's root location
   def root
     return self if parent.nil?
     return parent.root
   end

   # traverse all chilren recursively, calling block for each
   def traverse_descendants(&bl)
      children.each { |child|
         bl.call child
         child.traverse_descendants &bl
      }
   end

   # return sum of the x values of this location and all its parents,
   # eg the absolute 'x' of the location
   def total_x
     return 0 if parent.nil?
     return parent.total_x + x
   end

   # return sum of the y values of this location and all its parents
   # eg the absolute 'y' of the location
   def total_y
     return 0 if parent.nil?
     return parent.total_y + y
   end

   # return sum of the z values of this location and all its parents
   # eg the absolute 'z' of the location
   def total_z
     return 0 if parent.nil?
     return parent.total_z + z
   end

   # return the distance between this location and specified other
   def -(location)
     dx = x - location.x
     dy = y - location.y
     dz = z - location.z
     Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)
   end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :x => x, :y => y, :z => z, :parent_id => parent_id}
     }.to_json(*a)
   end

   def self.json_create(o)
     new(o['data'])
   end

end

end # module Motel
