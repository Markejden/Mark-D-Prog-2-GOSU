require_relative 'modules'
require_relative 'entities'
require_relative 'world_gen'

class WorldInstance
    include Timedt
    include Common

    TOWER_OPT = {
    BaseTurret =>{health: 50.0 },
    Wall=>{health: 200.0 }}

    attr_accessor :text, :selected_building
    attr_reader :enemies, :buildings
    def initialize
        @enemies = []
        @buildings = []
        @selected_building = BaseTurret

        @seed = Random.new_seed
        @grid = generate_world(@seed,0.05,1)
        @ore_img = nil
        build_ores

        @spawn_time = 0.0
        @text = []

        @score = 0 #temp för wisper tester
    end

    def update
        waves()
        entity_update()
        update_text()
    end

    def draw
        left = [Camera.x,-WORLD_HALF[0]].max
        top = [Camera.y,-WORLD_HALF[1]].max
        right = [Camera.x+(MIDDLE[0]*2)/Camera.zoom, WORLD_HALF[0]].min
        bottom = [Camera.y+(MIDDLE[1]*2)/Camera.zoom, WORLD_HALF[1]].min
        Camera.shift do 
            @enemies.each{|x|x.draw if visible?(x,left,top,right,bottom)}
            @buildings.each{|x|x.draw if visible?(x,left,top,right,bottom)}
            draw_grid(left,top,right,bottom)
            draw_world
        end
    end

    def visible?(obj, left, top, right, bottom, offset = TILE) #offset för att de inte ska gå från hide till show när de är i viewport
        pos = obj.pos
        pos && pos[0] > left - offset && pos[0] < right + offset && pos[1] > top - offset  && pos[1] < bottom + offset
    end

    def entity_update
        @enemies.each{|enemy|enemy.update(@buildings)}
        @enemies.reject!{|enemy|!enemy.alive || !enemy.exists?} # ta bort döda
        @buildings.each{|building|building.update(@enemies)} #skicka in enenmies för track closest
        @buildings.reject!{|building|!building.alive || !building.exists?}
    end

    def entity_died(entity)
        if entity.is_a?(BaseEnemy)
            @score += 10
            puts "Score: #{@score}"
        end
    end

    def entity_damaged(entity, damage)
        return unless entity.is_a?(BaseEnemy)
        @text << [damage.floor.to_s,entity.pos[0],entity.pos[1],1.0] unless entity.pos.nil?
    end

    def update_text
        @text.each{|x|x[3]-=dt;x[2]-=x[3]*dt}
        @text.reject!{|x|x[3]<=-0.5}
    end

    def place_building(mpos)
        # * här är en splat operator, dom är sjukt användbara
        #för calling, flattening, rester och collecting 
        #info på * och fler som typ & finns på https://www.ruby-lang.org/en/documentation/faq/4/
        #och https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html
        
        return if @buildings.any? {|t|t.pos==mpos} # säg nej till flera på samma ställe
        return if mpos[0].abs>WORLD_HALF[0] || mpos[1].abs>WORLD_HALF[1]
        
        building = @selected_building.new(TOWER_OPT[@selected_building][:health])

        building.subscribe(self)
        building.change_pos(mpos)
        @buildings << building
    end

    def remove_building(mpos)
        building = @buildings.select{|x|x.pos==mpos}.first
        return unless building
        building.change_pos(nil)
    end

    def waves
        @spawn_time += dt
        while @spawn_time >= 1.0
            enemy = BaseEnemy.new(100.0)
            enemy2 = FastEnemy.new(150.0)

            enemy.subscribe(self)
            enemy2.subscribe(self)
            enemy.spawnpos
            enemy2.spawnpos
            @enemies << enemy
            @enemies << enemy2
            @spawn_time -= 1.0
        end
    end

    def draw_grid(left,top,right,bottom)
        color = Gosu::Color.argb(0x20_ffffff)

        first_x = (left/TILE).floor*TILE
        first_y = (top/TILE).floor*TILE
        first_x.step(right, TILE) do |x|
            Gosu.draw_line(x, top, color, x, bottom, color, 0)
        end

        first_y.step(bottom, TILE) do |y|
            Gosu.draw_line(left, y, color, right, y, color, 0)
        end
    end

    def draw_world
        @ore_img.draw(-WORLD_HALF[0],-WORLD_HALF[1], -1, TILE,TILE)
    end

    def build_ores #mer på denna finns i min loggbok 2026-11-09
        w,h = WORLD
        half_w, half_h = w/2, h/2

        pixel = Array.new(w*h*4,0)
        @grid.each do |(tx, ty), type|
            col = tx + half_w
            row = ty + half_h
            i = (row*w + col)*4

            color = (type == :master_ore) ? [255,200,100,150] : [255, 50, 100, 100]
            pixel[i,4] = color
        end
        
        raw = Gosu::Image::BlobHelper.new(w, h, pixel.pack("C*"))
        @ore_img = Gosu::Image.new(raw, retro: true)
        #@ore_img = Gosu::Image.from_blob(w,h,pixel.pack("C*"))
        #jag hade tänkt att använda from_blob metoden men den använde antialiasing när bilden scaleades så den blev blurrig
        
        #dessa 2 linjer är de mest "advancerade" i programmet so far & tog längst tid att "hitta"
        #jag säger hitta för att koden fanns redan delvis i ruby filerna
        
        #mer på det finns i min loggbok 2026-11-09
    end
end
