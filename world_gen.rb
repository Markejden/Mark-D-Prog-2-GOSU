def generate_world(seed,width,height,ore_density,ore_rich)
    pos = [[0,1],[1,0],[-1,0],[0,-1]]
    half_w = width/2
    half_h = height/2
    node_pos = {}

    rng = Random.new(seed)
    ore_amount = (width*height*ore_density).ceil
    nodes = [(ore_amount/100).ceil,1].max #glömde att clampa node amount vilket gjorde att den ibland genererade 0
    ore_amount -= nodes

    nodes.times do |i|
        node_pos[[rng.rand(-half_w...half_w),rng.rand(-half_h...half_h)]] = "MasterOre" #tre punkter på rangen för exclusive
    end

    ore_amount.times do |i|
        loop do #använder loop do och break istället för while, kommer ge en finare struktur
            new_pos = node_pos.keys.sample(random: rng) #har läst lite mer documentation på arrays
            #har sett massa nya metoder så som transform_keys som kan bli användbara
            diff = pos.sample(random: rng) #tydligen om man har sample med en count så får man en array med den mängden element
            new_pos = [new_pos[0]+diff[0],new_pos[1]+diff[1]] # - så .sample(1) kommer inte fungera utan .first vilket jag stötte på innan
            bounds = new_pos[0].between?(-half_w, half_w-1) && new_pos[1].between?(-half_h, half_h-1) #-100 till 99
            
            next unless bounds && !node_pos.key?(new_pos) #.key? istället för .include?

            node_pos[new_pos] = "Ore"
            break
        end
    end
    p ore_amount
    p node_pos.length
    return node_pos
end
