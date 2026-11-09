require_relative 'modules'

class World_instance
    include Timedt
    include Common

    TOWER_OPT = {
    BaseTurret =>{health: 50.0 },
    Wall=>{health: 200.0 }}

    attr_accessor :text, :selected_building
    attr_reader :enemies
    def initialize
        @enemies = []
        @buildings = []
        @selected_building = BaseTurret

        @spawn_time = 0.0
        @text = []

        @score = 0 #temp för wisper tester
    end

    def update
        waves()
        entity_update()
    end

    def draw
        Camera.shift do 
            @enemies.each(&:draw)
            @buildings.each(&:draw)
            draw_grid()
        end
    end

    def entity_update
        @enemies.each{|enemy|enemy.update(@buildings)}
        @enemies.reject!{|enemy|!enemy.alive && !enemy.exists?} # ta bort döda
        @buildings.each{|building|building.update(@enemies)} #skicka in enenmies för track closest
        @buildings.reject!{|building|!building.alive}
    end

    def entity_died(entity)
        if entity.is_a?(BaseEnemy)
            @score += 10
            puts "Score: #{@score}"
        end
    end

    def entity_damaged(entity, damage)
        return unless entity.is_a?(BaseEnemy)
        @text << [damage.floor.to_s,entity.pos[0],entity.pos[1],1.0]
    end

    def place_building(mpos)
        # * här är en splat operator, dom är sjukt användbara
        #för calling, flattening, rester och collecting 
        #info på * och fler som typ & finns på https://www.ruby-lang.org/en/documentation/faq/4/
        #och https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html
        
        return if @buildings.any? {|t|t.pos==mpos} # säg nej till flera på samma ställe
        
        building = @selected_building.new(TOWER_OPT[@selected_building][:health])

        building.subscribe(self)
        building.change_pos(mpos)
        @buildings << building
    end

    def waves
        @spawn_time += dt
        if @spawn_time >= 1.0
            enemy = BaseEnemy.new(100.0)

            enemy.subscribe(self)
            enemy.spawnpos
            @enemies << enemy
            @spawn_time -= 1.0
        end
    end

    def draw_grid
        color = Gosu::Color.argb(0x20_ffffff)
        bright = Camera.x + MIDDLE[0]*2 / Camera.zoom
        bottomr = Camera.y + MIDDLE[1]*2 / Camera.zoom
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
