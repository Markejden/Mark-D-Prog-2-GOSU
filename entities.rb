require_relative 'modules'

class Entity
  include Timedt
  include Wisper::Publisher
  attr_reader :alive, :start_health, :health, :pos
  def initialize(health)
    @health = health
    @start_health = health
    @pos = nil
    @alive = true
  end

  def change_health(hpdiff)
    return unless @alive

    old_health = @health
    @health = (@health + hpdiff).clamp(0, @start_health)

    if @health != old_health
      broadcast(:entity_damaged, self, hpdiff)
    end

    if @health <= 0
      @alive = false
      broadcast(:entity_died, self)
    end
  end

  def change_pos(pos)
    @pos = pos
  end

  def update(enemies)
    @alive = false if @health <= 0
  end

  def exists? = !@pos.nil?

  def alive? = @alive
end

class BaseTurret < Entity
  include Targeting
  attr_reader :aim_range
  def initialize(health)
    @sprite = Gosu::Image.new("resources/topdownturret.png") #https://toppng.com/free-image/turrets-top-down-turret-PNG-free-PNG-Images_188356
    @aim_range = 100
    @turret_angle = 0
    @turret_spin_speed = 6
    @damage = 80.0
    @reload_time = 1.0
    @aim_spread = 5
    super
  end

  def update(enemies)
    super
    @reload_time -= dt
    enemy_tracking(enemies)
  end

  def turret_fire(angle, closest_enemy)
    return unless angle.abs < @aim_spread
    return unless @reload_time <= 0
    @reload_time = 1.0
    closest_enemy.change_health(-@damage)
  end

  def enemy_tracking(enemies)
    return if enemies.empty?
    closest_enemy = closest_to(@pos, enemies)
    return unless closest_enemy
    return unless closest_enemy.exists?
    return unless closest_enemy.alive?

    return unless Gosu.distance(@pos[0], @pos[1], closest_enemy.pos[0], closest_enemy.pos[1]) < @aim_range

    target_angle = Gosu.angle(@pos[0], @pos[1], closest_enemy.pos[0], closest_enemy.pos[1])
    close_turn = Gosu.angle_diff(@turret_angle,target_angle)

    @turret_angle += close_turn.clamp(-@turret_spin_speed, @turret_spin_speed)

    return unless able_to_fire(close_turn.abs < 5)
    
    turret_fire(close_turn, closest_enemy)
  end

  def draw
    return unless exists?
    @sprite.draw_rot(@pos[0],@pos[1],1,@turret_angle, 0.5, 0.5, TILE.to_f/100, TILE.to_f/100) #sista fyra är midx,midy,sizex,sizey
  end
end

class Wall < Entity
  def initialize(health)
    @sprite = nil #todo
    super
  end

  def draw
    return unless exists?
    Gosu.draw_rect(@pos[0] - TILE/2, @pos[1]- TILE/2, TILE, TILE, Gosu::Color.argb(0xff_ffffff), 0)
  end
end

class BaseEnemy < Entity
  include Targeting
  attr_reader :alive, :speed, :health, :size, :pos

  def initialize(health)
    @size = 10.0
    @speed = 50
    @damage = 50
    super(health)
  end

  def update(buildings)
    super
    return unless @pos
    target = closest_to(@pos,buildings.select(&:alive))
    tx, ty = target ? target.pos : MIDDLE
    aim_for(tx, ty, target)
  end

  def aim_for(tx,ty,target=nil)
    speed = @speed * dt

    if Gosu.distance(@pos[0], @pos[1], tx, ty) <= speed
      @pos[0] = tx
      @pos[1] = ty
      target.change_health(-@damage * dt) if target
    else
      angle = Gosu.angle(@pos[0], @pos[1], tx, ty)
      @pos[0] += Gosu.offset_x(angle,speed)
      @pos[1] += Gosu.offset_y(angle,speed)
    end
  end

  def spawnpos
    @pos ||= [rand(0...MIDDLE[0]*2),rand(0...MIDDLE[1]*2)] # om tom
  end

  def draw
    return unless exists?
    Gosu.draw_rect(@pos[0]-@size/2, @pos[1]-@size/2, @size, @size, Gosu::Color.argb(0xff_ffffff), 0)
    ratio = [@health / @start_health.to_f, 0].max #clamp till över eller lika med 0
    Gosu.draw_rect(@pos[0]-@size/2, @pos[1] - ((@size/5)*4)-@size/2, @size * ratio, @size - ((@size/5)*4), Gosu::Color.argb(0xff_ff0000), 0)
  end
end
