class Building
  attr_reader :health
  attr_accessor :pos
  def initialize(health)
    @health = health #todo
    @pos = nil
  end
end

class Turret < Building
  attr_accessor :aim_range
  def initialize(health)
    @turretsprite = Gosu::Image.new("resources/topdownturret.png") #https://toppng.com/free-image/turrets-top-down-turret-PNG-free-PNG-Images_188356
    @aim_range = 100
    @turretangle = 0
    super(health)
  end

  def update(dt, enemies)
    unless enemies.empty?
      closest_enemy = track_closest(enemies)
      return if sqrt((closest_enemy.pos[0] - @pos[0])**2  + (closest_enemy.pos[1] - @pos[1])**2) > 100
      @turretangle = Gosu.angle(@pos[0], @pos[1], closest_enemy.pos[0], closest_enemy.pos[1])
      closest_enemy.health -= 1
    end
  end

  def track_closest(enemies)
    closest = enemies.reduce do |ack,enemy|
      pos = enemy.pos
      dist = sqrt((pos[0] - @pos[0])**2  + (pos[1] - @pos[1])**2)
      sqrt((ack.pos[0] - @pos[0])**2  + (ack.pos[1] - @pos[1])**2) > dist ? ack = enemy : ack
    end
    #positions = enemies.map(&:pos)
    #closest = positions.compact.min_by {|x,y|sqrt((x - @pos[0])**2 + (y - @pos[1])**2)} #compact för att göra 2d array till 1d och min_by tar minsta i detta fall med par
    #return unless closest
    #dist = sqrt((closest[0] - @pos[0])**2 + (closest[1] - @pos[1])**2)
    #return if dist > @aim_range
    #@turretangle = Gosu.angle(@pos[0], @pos[1], closest[0], closest[1])
  end

  def draw
    @turretsprite.draw_rot(@pos[0],@pos[1],1,@turretangle, 0.5, 0.5, TILE.to_f/100, TILE.to_f/100) #sista fyra är midx,midy,sizex,sizey
  end
end

class Enemy
  attr_reader :type, :alive, :size, :speed
  attr_accessor :pos, :health

  def initialize(health,type)
    @health = health #todo
    @type = type #todo
    @size = 10
    @pos = nil
    @speed = 50
    @alive = true
  end

  def update(dt)
    if @health <= 0
      @alive = !@alive
    end
    @pos ||= [rand(0...MIDDLE[0]*2),rand(0...MIDDLE[1]*2)] # om tom
    aim_for(MIDDLE[0],MIDDLE[1], dt)
  end

  def aim_for(tx,ty,dt)
    dx = (tx - @pos[0]) #distans till target i xy led
    dy = (ty - @pos[1])
    dist = sqrt(dx**2 + dy**2) #hypotenusan av xy led
    if dist <= @speed * dt
      #@pos[0] = tx
      #@pos[1] = ty
      @alive = !@alive
    else
      @pos[0] += (dx / dist) * @speed * dt
      @pos[1] += (dy / dist) * @speed * dt
    end
  end

  def draw
    Gosu.draw_rect(@pos[0], @pos[1], @size, @size, Gosu::Color.argb(0xff_ffffff), z = 0) if @pos
  end
end