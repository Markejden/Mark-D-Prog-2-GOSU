module Targeting
  def closest_to(mid, target)
    target.min_by{|x|(x.pos[0]-mid[0])**2 + (x.pos[1] - mid[1])**2}
  end
end

class Entity
  attr_reader :alive, :start_health
  attr_accessor :pos, :health
  def initialize(health)
    @health = health
    @start_health = health
    @pos = nil
    @alive = true
  end

  def update(dt,enemies)
    @alive = false if @health <= 0
  end
end

class Turret < Entity
  include Targeting
  attr_accessor :aim_range
  def initialize(health)
    @sprite = Gosu::Image.new("resources/topdownturret.png") #https://toppng.com/free-image/turrets-top-down-turret-PNG-free-PNG-Images_188356
    @aim_range = 100
    @turret_angle = 0
    @turret_spin_speed = 6
    @damage = 80.0
    super
  end

  def update(dt, enemies)
    super
    return if enemies.empty?
    closest_enemy = closest_to(@pos, enemies)

    return unless closest_enemy
    return unless sqrt((closest_enemy.pos[0] - @pos[0])**2  + (closest_enemy.pos[1] - @pos[1])**2) < @aim_range
    target_angle = Gosu.angle(@pos[0], @pos[1], closest_enemy.pos[0], closest_enemy.pos[1])
    close_turn = Gosu.angle_diff(@turret_angle,target_angle)

    @turret_angle += close_turn.clamp(-@turret_spin_speed, @turret_spin_speed)
    closest_enemy.health -= @damage * dt if close_turn.abs < 5
  end

  def draw
    @sprite.draw_rot(@pos[0],@pos[1],1,@turret_angle, 0.5, 0.5, TILE.to_f/100, TILE.to_f/100) #sista fyra är midx,midy,sizex,sizey
  end
end

class Wall < Entity
    def initialize(health)
      @sprite = nil #todo
      super
    end

    def draw
      Gosu.draw_rect(@pos[0] - TILE/2, @pos[1]- TILE/2, TILE, TILE, Gosu::Color.argb(0xff_ffffff), 0)
    end
end

class Enemy < Entity
  include Targeting
  attr_reader :type, :alive, :speed
  attr_accessor :pos, :health, :size

  def initialize(health,type)
    @type = type
    @size = 10.0
    @speed = 50
    @damage = 50
    super(health)
  end

  def update(dt, buildings)
    super
    @pos ||= [rand(0...MIDDLE[0]*2),rand(0...MIDDLE[1]*2)] # om tom

    target = closest_to(@pos,buildings.select(&:alive))
    tx, ty = target ? target.pos : MIDDLE
    aim_for(tx, ty, dt, target)
  end

  def aim_for(tx,ty,dt,target=nil)
    dx = (tx - @pos[0]) #distans till target i xy led
    dy = (ty - @pos[1])
    dist = sqrt(dx**2 + dy**2) #hypotenusan av xy led
    if dist <= @speed * dt
      @pos[0] = tx
      @pos[1] = ty
      target.health -= @damage * dt if target
    else
      @pos[0] += (dx / dist) * @speed * dt
      @pos[1] += (dy / dist) * @speed * dt
    end
  end

  def draw
    return unless @pos
    Gosu.draw_rect(@pos[0]-@size/2, @pos[1]-@size/2, @size, @size, Gosu::Color.argb(0xff_ffffff), 0)
    ratio = [@health / @start_health.to_f, 0].max #clamp till över eller lika med 0
    Gosu.draw_rect(@pos[0]-@size/2, @pos[1] - ((@size/5)*4)-@size/2, @size * ratio, @size - ((@size/5)*4), Gosu::Color.argb(0xff_ff0000), 0)
  end
end
