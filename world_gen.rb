def generate_world(seed,ore_density,ore_rich)
    pos = [[0,1],[1,0],[-1,0],[0,-1]]
    half_w = WORLD[0]/2
    half_h = WORLD[1]/2
    node_pos = {}
    positions = []

    rng = Random.new(seed)
    ore_amount = (WORLD[0]*WORLD[1]*ore_density).ceil
    nodes = [(ore_amount/100).ceil,1].max #glömde att clampa node amount vilket gjorde att den ibland genererade 0
    ore_amount -= nodes

    nodes.times do
        new_pos = [rng.rand(-half_w...half_w),rng.rand(-half_h...half_h)]
        node_pos[new_pos] = :master_ore #tre punkter på rangen för exclusive
        positions << new_pos
    end

    ore_amount.times do
        loop do #använder loop do och break istället för while, kommer ge en finare struktur
            new_pos = positions.sample(random: rng) #har läst lite mer documentation på arrays
            #har sett massa nya metoder så som transform_keys som kan bli användbara
            diff = pos.sample(random: rng) #tydligen om man har sample med en count så får man en array med den mängden element
            new_pos = [new_pos[0]+diff[0],new_pos[1]+diff[1]] # - så .sample(1) kommer inte fungera utan .first vilket jag stötte på innan
            bounds = new_pos[0].between?(-half_w, half_w-1) && new_pos[1].between?(-half_h, half_h-1) #-100 till 99
            
            next unless bounds && !node_pos.key?(new_pos) #.key? istället för .include?

            node_pos[new_pos] = :ore
            positions << new_pos
            break
        end
    end
    return node_pos
end
