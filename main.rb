require 'gosu'
require_relative 'entities'
include Math
#include Gosu , kan användas men har den inte för att göra det mer tydligt

MIDDLE = [320*2, 240*2]
TILE = 16

class Window < Gosu::Window
  def initialize
    super MIDDLE[0]*2 , MIDDLE[1]*2
    self.caption = "Game"

    @enemies = []
    @turrets = []
    
    @prev_value = Gosu.milliseconds
    @dt = 0.0
    @spawn_time = 0.0

  end

  def update
    time = Gosu.milliseconds
    @dt = (time - @prev_value) / 1000.0 #deltatid
    @prev_value = time
    #OBS! alla speed variabler ska gångras med dt

    waves

    @enemies.each{|enemy|enemy.alive ? enemy.update(@dt) : @enemies.delete(enemy)} # ta bort döda
    @turrets.each{|turret|turret.update(@dt, @enemies)} #skicka in enenmies för track closest

    def button_down(id)
      if id == Gosu::MS_LEFT
        pos = snap(mouse_x, mouse_y) #spän till grid
        return if @turrets.any? {|t|t.pos==pos} # säg nej till flera på samma ställe

        turret = Turret.new(10)
        turret.pos = pos
        @turrets << turret
      end
    end

  end
  
  def waves
    @spawn_time += @dt
    if @spawn_time >= 1.0
      @enemies << Enemy.new(100, "dynamic")
      @spawn_time -= 1.0
    end
  end

  def snap(x, y)
    [(x/TILE).floor * TILE + TILE/2, (y/TILE).floor * TILE + TILE/2]
  end

  def draw
    @enemies.each(&:draw)
    @turrets.each(&:draw)
    grid
  end

  def grid #måla gridlinjer
    color = Gosu::Color.argb(0x20_ffffff)
    (width/TILE + 1).times do |i|
      x=i*TILE
      Gosu.draw_line(x, 0, color, x, height, color, 0)
    end

    (height/TILE + 1).times do |i|
      y=i*TILE
      Gosu.draw_line(0, y, color, width, y, color, 0)
    end
  end
end

Window.new.show
