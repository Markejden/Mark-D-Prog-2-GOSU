require 'gosu'
require_relative 'entities'
require_relative 'modules'

MIDDLE = [320*2, 240*2]
TILE = 16

class Window < Gosu::Window
  include Timedt
  TOWER_OPT = {
  BaseTurret =>{health: 50.0 },
  Wall=>{health: 200.0 }}

  def initialize
    super MIDDLE[0]*2 , MIDDLE[1]*2
    Clock.reset

    self.caption = "Game"

    @enemies = []
    @buildings = []
    @selected_building = BaseTurret
    @grid = {}
    
    @prev_value = Gosu.milliseconds
    @spawn_time = 0.0
    @prev_mouse = nil
  end

  def update
    Clock.tick

    waves
    camera_shift

    @enemies.each{|enemy|enemy.update(@buildings)}
    @enemies.reject!{|enemy|!enemy.alive} # ta bort döda
    @buildings.each{|building|building.update(@enemies)} #skicka in enenmies för track closest
    @buildings.reject!{|building|!building.alive}
  end
  
  def button_down(id)
    case id
      when Gosu::KB_1 then @selected_building = BaseTurret
      when Gosu::KB_2 then @selected_building = Wall
      when Gosu::MS_LEFT then place_building
      when Gosu::MS_WHEEL_UP   then Camera.zoom_to(mouse_x, mouse_y, 1.1)
      when Gosu::MS_WHEEL_DOWN then Camera.zoom_to(mouse_x, mouse_y, 0.9)
    end
  end

  def camera_shift
    if Gosu.button_down? Gosu::MS_RIGHT
      if @prev_mouse
        Camera.x -= (mouse_x-@prev_mouse[0])/Camera.zoom
        Camera.y -= (mouse_y-@prev_mouse[1])/Camera.zoom 
      end
      @prev_mouse = [mouse_x, mouse_y]
    else
      @prev_mouse = nil
    end

    #Camera.x = Camera.x.clamp(-1000,1000)
    #Camera.y = Camera.y.clamp(-1000,1000)
  end

  def place_building
    pos = snap(*Camera.trans_worldpos(mouse_x, mouse_y)) #spän till grid
    # * här är en splat operator, dom är sjukt användbara
    #för calling, flattening, rester och collecting 
    #info på * och fler som typ & finns på https://www.ruby-lang.org/en/documentation/faq/4/
    #och https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html
    
    return if @buildings.any? {|t|t.pos==pos} # säg nej till flera på samma ställe
    
    building = @selected_building.new(TOWER_OPT[@selected_building][:health])

    building.change_pos(pos)
    @buildings << building
  end

  def waves
    @spawn_time += dt
    if @spawn_time >= 1.0
      enemy = BaseEnemy.new(100.0, "dynamic")
      enemy.spawnpos
      @enemies << enemy
      @spawn_time -= 1.0
    end
  end

  def snap(x, y)
    [(x/TILE).floor * TILE + TILE/2, (y/TILE).floor * TILE + TILE/2]
  end

  def draw
    Camera.shift do 
      @enemies.each(&:draw)
      @buildings.each(&:draw)
      grid
    end
  end

  def grid #måla gridlinjer
    color = Gosu::Color.argb(0x20_ffffff)
    bright = Camera.x + width / Camera.zoom
    bottomr = Camera.y + height / Camera.zoom
    first_x = (Camera.x/TILE).floor*TILE
    first_y = (Camera.y/TILE).floor*TILE
    first_x.step(bright, TILE) do |x|
      Gosu.draw_line(x, Camera.y, color, x, bottomr, color, 0)
    end

    first_y.step(bottomr, TILE) do |y|
      Gosu.draw_line(Camera.x, y, color, bright, y, color, 0)
    end
  end
end

Window.new.show
