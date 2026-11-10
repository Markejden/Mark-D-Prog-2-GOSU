require 'gosu'
require 'wisper'
require_relative 'entities'
require_relative 'modules'
require_relative 'world_gen'
require_relative 'world_process'

MIDDLE = [Gosu.screen_width/2, Gosu.screen_height/2] # kommer nog inte användas så mycket lägre
TILE = 16
WORLD = [200,200]
WORLD_HALF = [WORLD[0]*TILE/2.0, WORLD[1]*TILE/2.0]
WORLD_CENTER = [0.0, 0.0]
FONT = Gosu::Font.new(20)

class Window < Gosu::Window
  include Timedt
  include Common

  def initialize
    super MIDDLE[0]*2 , MIDDLE[1]*2
    Clock.reset

    self.caption = "Game"
    self.fullscreen = true

    Camera.reset
    Camera.center_on(*WORLD_CENTER)

    @text = []
    @grid = generate_world(rand(100.0),*WORLD,0.1,1)
    @prev_mouse = nil

    @world = World_instance.new
  end

  def update
    Clock.tick
    camera_shift()
    @world.update
  end
  
  def button_down(id)
    case id
      when Gosu::KB_1 then @world.selected_building = BaseTurret
      when Gosu::KB_2 then @world.selected_building = Wall
      when Gosu::MS_LEFT then @world.place_building(snap(*Camera.trans_worldpos(mouse_x, mouse_y)))
      when Gosu::MS_WHEEL_UP then Camera.zoom_to(mouse_x, mouse_y, 1.1)
      when Gosu::MS_WHEEL_DOWN then Camera.zoom_to(mouse_x, mouse_y, 0.9)

      when Gosu::KB_E then Camera.zoom_to(mouse_x, mouse_y, 1.4)
      when Gosu::KB_Q then Camera.zoom_to(mouse_x, mouse_y, 0.6)
      when Gosu::KB_ESCAPE then self.close!
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
    if button_down? Gosu::KB_W then Camera.y -= 20/Camera.zoom end
    if button_down? Gosu::KB_S then Camera.y += 20/Camera.zoom end
    if button_down? Gosu::KB_A then Camera.x -= 20/Camera.zoom end
    if button_down? Gosu::KB_D then Camera.x += 20/Camera.zoom end
    Camera.clamp_to(-WORLD_HALF[0], -WORLD_HALF[1], WORLD_HALF[0], WORLD_HALF[1])
  end

  def draw
    @world.draw
    Camera.shift do 
      draw_text()
      draw_world()
    end
  end

  def draw_world #denna var extremt buggad och alla zooms och spawns var offset
    @grid.each do |(tx, ty), type| #type används inte
      Gosu.draw_rect(tx*TILE,ty*TILE,TILE,TILE,Gosu::Color.rgba(255,50,100,100),-1)
    end
  end

  def draw_text
    text = @text + @world.text
    text.reject!{|txt|txt[3]<=-0.5}
    text.each do |txt|
      txt[3] -= dt
      txt[2] -= txt[3]
      FONT.draw_text(txt[0], txt[1], txt[2], 1, 1.0, 1.0,  Gosu::Color.rgba(255, 255, 255, (txt[3]+0.5)*170)) # *170 är 255/1.5
    end if @text
  end
end

Window.new.show
