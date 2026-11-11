require 'gosu'
#Gosu.enable_undocumented_retrofication # för att inte få blurriga linjer på bilder
#jag har valt att inte använda den då jag hitta en workaround (se build_ores i world_process)
#hittade absolut ingen documentation på den (som namnet antyder) utan på forumet från en post 2011 https://www.libgosu.org/cgi-bin/mwf/topic_show.pl?tid=384
require 'wisper'
require_relative 'entities'
require_relative 'modules'
require_relative 'world_gen'
require_relative 'world_process'

SCREEN = [Gosu.screen_width,Gosu.screen_height]
MIDDLE = [SCREEN[0]/2,SCREEN[1]/2] # kommer nog inte användas så mycket lägre
TILE = 16
WORLD = [SCREEN[0]/6,SCREEN[1]/6]
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

    @prev_mouse = nil
    @mouse_timer = 0

    @world = WorldInstance.new
  end

  def update
    Clock.tick
    sequence_inputs()
    @world.update
  end
  
  def button_down(id)
    case id
      when Gosu::KB_1 then @world.selected_building = BaseTurret
      when Gosu::KB_2 then @world.selected_building = Wall
      #when Gosu::MS_LEFT then @world.place_building(snap(*Camera.trans_worldpos(mouse_x, mouse_y)))
      when Gosu::MS_WHEEL_UP then Camera.zoom_to(mouse_x, mouse_y, 1.1)
      when Gosu::MS_WHEEL_DOWN then Camera.zoom_to(mouse_x, mouse_y, 0.9)

      when Gosu::KB_E then Camera.zoom_to(mouse_x, mouse_y, 1.4)
      when Gosu::KB_Q then Camera.zoom_to(mouse_x, mouse_y, 0.6)
      when Gosu::KB_ESCAPE then self.close!
    end
  end

  def sequence_inputs
    if Gosu.button_down? Gosu::MS_LEFT
      @mouse_timer += 1
      @mouse_timer = @mouse_timer.clamp(0,10)
      if @mouse_timer >= 6 then camera_shift end
    else
      if !(@mouse_timer == 0) && @mouse_timer < 10
        @world.place_building(snap(*Camera.trans_worldpos(mouse_x, mouse_y)))
      end
      @mouse_timer = 0
      @prev_mouse = nil
    end
    if button_down? Gosu::MS_RIGHT then @world.remove_building(snap(*Camera.trans_worldpos(mouse_x, mouse_y))) end

    if button_down? Gosu::KB_W then Camera.y -= 20/Camera.zoom end
    if button_down? Gosu::KB_S then Camera.y += 20/Camera.zoom end
    if button_down? Gosu::KB_A then Camera.x -= 20/Camera.zoom end
    if button_down? Gosu::KB_D then Camera.x += 20/Camera.zoom end

    Camera.clamp_to(-WORLD_HALF[0], -WORLD_HALF[1], WORLD_HALF[0], WORLD_HALF[1])
  end

  def camera_shift
    if @prev_mouse
      Camera.x -= (mouse_x-@prev_mouse[0])/Camera.zoom
      Camera.y -= (mouse_y-@prev_mouse[1])/Camera.zoom 
    end
      @prev_mouse = [mouse_x, mouse_y]
  end

  def draw
    @world.draw
    Camera.shift do 
      draw_text()
    end
  end

  def draw_text
    @world.text.each do |text, x, y, lifetime|
      opac = ((lifetime + 0.5) * 170).clamp(0, 255).to_i
      FONT.draw_text(text, x, y, 1, 1.0, 1.0, Gosu::Color.rgba(255, 255, 255, opac))
    end
  end
end

Window.new.show
