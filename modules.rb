module Clock
  extend self 
  #samma som att skriva self. som prefix för alla funktioner
  #även samma som class << self
  attr_reader :dt
  def reset
    @prev = Gosu.milliseconds
    @dt = 0.0
  end

  def tick
    now = Gosu.milliseconds
    @dt = (now - @prev) / 1000.0
    @prev = now
  end
end

module Camera
  extend self
  attr_accessor :x, :y, :zoom

  @x = 0.0
  @y = 0.0
  @zoom = 1.0

  def reset
    @x = 0.0
    @y = 0.0
    @zoom = 1.0
  end

  def shift(&block)
    Gosu.scale(@zoom, @zoom) do
      Gosu.translate(-@x, -@y){block.call} #eller yield, då ska &block bort också
    end
  end

  def zoom_to(mx, my, amp)
    wx, wy = trans_worldpos(mx, my)
    @zoom = (@zoom*amp).clamp(0.25,4.0) #gånger för att det inte ska bli ojämnt, clamp för att zoomen inte ska fly världen
    @x = wx - mx/@zoom
    @y = wy - my/@zoom
  end

  def trans_worldpos(scalex, scaley)
    [scalex/@zoom + @x,scaley/@zoom + @y]
  end
end

module Targeting
  def closest_to(mid, target)
    target.min_by do |x|
      next unless x.pos
      (x.pos[0]-mid[0])**2 + (x.pos[1] - mid[1])**2
    end
  end
end
#anledningen till att inte ha self på dessa är för att skydda namespace för
#klasser och funktioner som inte använder dem
#det är även för att de inte behövs delas, worldpos, camera och tid behöver delas
#mellan alla filer och funktioner medan så som dessa bara behöver en privat instans
module Timedt
    def dt = Clock.dt
end