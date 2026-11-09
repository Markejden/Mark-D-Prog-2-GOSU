def generate_world(seed,width,height,ore_density,ore_rich)
    pos = [[0,1],[1,0],[-1,0],[0,-1]]
    node_pos = {}

    rng = Random.new(seed)
    ore_amount = (width*height*ore_density).ceil
    nodes = (ore_amount/100).ceil
    ore_amount -= nodes

    nodes.times do |i|
        node_pos[[rng.rand(-width..width),rng.rand(-height..height)]] = "MasterOre"
    end

    ore_amount.times do |i|
        skip = false
        while skip == false
            new_pos = node_pos.to_a.sample(1, random: rng).first.first
            diff = pos.sample(1, random: rng).first
            new_pos = [new_pos[0]+diff[0],new_pos[1]+diff[1]]

            skip = true unless node_pos.to_a.first.include?(new_pos)
        end
        node_pos[new_pos] = "Ore"
    end

    return node_pos
end
