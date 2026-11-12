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
      @pos = nil
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

  RETARGET_TIME = 0.1

  SPRITE_PATH = "resources/topdownturret.png"
  def self.sprite = @sprite ||= Gosu::Image.new(SPRITE_PATH)

  def initialize(health)
    @aim_range = 100
    @turret_angle = 0
    @turret_spin_speed = 300
    @damage = 80.0
    @reload_time = 1.0
    @aim_spread = 5
    @target = nil
    @retarget_timer = 0.0 #ingen rand behövs då det redan är offset av timing då man klickar ut buildingen
    super
  end

  def update(enemies)
    super
    return unless exists? && alive?
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
    @retarget_timer -= dt
    target_gone = @target && !(@target.alive? && @target.exists?)

    if @retarget_timer <= 0 || target_gone
      @target = closest_to(@pos, enemies)
      @retarget_timer = RETARGET_TIME
    end
    return unless @target

    return unless (@target.pos[0] - @pos[0])**2 + (@target.pos[1] - @pos[1])**2 < @aim_range * @aim_range
    #ingen gosu::distance då den räknar med roten ur vilket är mycket långsammare för ett värde man bara ska jämföra

    target_angle = Gosu.angle(@pos[0], @pos[1], @target.pos[0], @target.pos[1])
    close_turn = Gosu.angle_diff(@turret_angle,target_angle)

    @turret_angle += close_turn.clamp(-@turret_spin_speed * dt, @turret_spin_speed * dt)
    
    turret_fire(close_turn, @target)
  end

  def draw
    return unless exists?
    BaseTurret.sprite.draw_rot(@pos[0],@pos[1],1,@turret_angle, 0.5, 0.5, TILE.to_f/100, TILE.to_f/100) #sista fyra är midx,midy,sizex,sizey
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
  attr_reader :speed, :size
  RETARGET_TIME = 0.3

  def initialize(health)
    @size = 10.0
    @speed = 50
    @damage = 50
    @target = nil
    @retarget_timer = rand * RETARGET_TIME #rand för att sprida ut timings för när algoritmen körs
    super(health)
  end

  def update(buildings)
    super
    return unless @pos

    @retarget_timer -= dt
    target_gone = @target && !(@target.alive? && @target.exists?)
    if @retarget_timer <= 0 || target_gone
      @target = closest_to(@pos,buildings)
      @retarget_timer = RETARGET_TIME
    end

    tx, ty = @target ? @target.pos : WORLD_CENTER
    aim_for(tx, ty, @target)
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
    @pos ||= begin #begin tillåter multiline expressions i en tilldelning, som en diskret funktion ungefär
      angle = rand(360.0)
      [Gosu.offset_x(angle,WORLD_HALF[0]*0.9), Gosu.offset_y(angle,WORLD_HALF[1]*0.9)]
    end
  end

  def draw
    return unless exists?
    Gosu.draw_rect(@pos[0]-@size/2, @pos[1]-@size/2, @size, @size, Gosu::Color.argb(0xff_ffffff), 0)
    return unless Camera.zoom > 1.5
    ratio = [@health / @start_health.to_f, 0].max #clamp till över eller lika med 0
    Gosu.draw_rect(@pos[0]-@size/2, @pos[1] - ((@size/5)*4)-@size/2, @size * ratio, @size - ((@size/5)*4), Gosu::Color.argb(0xff_ff0000), 0)
  end
end

class FastEnemy < BaseEnemy
  def initialize(health)
    super(health)
    @size = 15.0
    @speed = 100
  end
end

class SquadLeaderEnemy < BaseEnemy
  def initialize(health)
    super(health)
    
  end
end
