#http://www.redblobgames.com/grids/hexagons/
class Map
  attr_accessor(:map)
  def initialize(rooms)
    @rooms = rooms #The number of rooms in the map
    @map = [] #The map
    (5*rooms).times do #Fill in the map with empty spaces
      @map.push []
      (5*rooms).times do #These 5* are arbitrary
        @map[-1].push " "
      end
    end
    generate_map() #Generate the map
  end
  def generate_map() #Version 5.0
    $rooms = [] #The center coords of every room
    tries = 0 #The number of attempts made to make a room
    while $rooms.length < @rooms
      if tries > 1000 #Stop trying if it seems impossible to fit another room
        break
      end
      randx = rand(@map[0].length) #rand coords, at the center of new room
      randy = rand(@map.length)
      x = randx #Turn axial coords into cubic coords
      z = randy
      y = -randx-randy

      r = make_room(x,y,z) #Make the room
      if r == true #If the room was successfully made
        $rooms.push([x,y,z]) #Push the coords onto $rooms
        tries = 0 #Reset the tries
      end
      tries += 1
    end

    center = [0.0,0.0,0.0] #Find the center, the average of the rooms
    $rooms.each do |r|
      center[0]+=r[0]
      center[1]+=r[1]
      center[2]+=r[2]
    end
    center.collect!{ |a| a/$rooms.length }
    $rooms.sort_by!{ |a| distance(a,center) } #Sort by distance from center

    groups = [] #Form the rooms into groups so we can connect every room
    $rooms.each do |r|
      groups.push [r]
    end

    while groups.length > 1 #While not every room is connected
      new_groups = [] #The next iteration of groups
      groups.each_with_index do |g,i| #Connect each group to the next closest
        bool = true #Test for adding group to new_groups
        new_groups.each do |ng|
          bool = false if ng.include?(g[0])
        end
        new_groups.push(g.clone) if bool #Add group if it's not in new_groups

        array = [] #The distances between the rooms in the group and those out
        g.each do |r|
          groups.each do |g2|
            next if g == g2
            g2.each do |r2|
              array.push [distance(r,r2),r,r2]
            end
          end
        end
        array = array.sort_by{ |a| a[0] } #Find the closest room out of group
        connect(array[0][1],array[0][2]) #Connect the closest rooms

        n = new_groups.find{ |a| a.include?(array[0][1]) } #Combine the groups
        f = new_groups.find{ |a| a.include?(array[0][2]) }
        if f == nil #f isn't in new_groups yet, find it in groups
          f = groups.find{ |a| a.include?(array[0][2]) }
        end
        if n != f #If it isn't already in the group
          f.each do |i|
            n.push(i)
          end
          new_groups.delete(f) #Prevent group2 from being in new_groups twice
        end
      end
      groups = new_groups
    end

    #If two rooms are close together but a long "walk", connect them
    bool = true
    while bool #While rooms are still being connected
      bool = false
      w = walk($rooms[0][0],$rooms[0][1],$rooms[0][2]) #Find the walking dists
      $rooms.each_with_index do |r,i| #Check for close-but-far rooms
        $rooms.each_with_index do |s,j|
          if (w[i]-w[j]).abs > 2*distance(r,s) #2* is arbitrary
            bool = true
            connect(r,s)
            break
          end
        end
        break if bool
      end
    end
  end

  def connect(r1,r2) #Connect two rooms with a corridor
    #Draw corridors
    num = distance(r1,r2)
    for j in 0..num #Do sampling along a line to find where the hexes should be
      hexx = (r1[0] + (r2[0]-r1[0])*(1.0/num)*j)
      hexy = (r1[1] + (r2[1]-r1[1])*(1.0/num)*j)
      hexz = (r1[2] + (r2[2]-r1[2])*(1.0/num)*j)
      hex_coords = hex_round([hexx,hexy,hexz]) #Round floats to nearest hex
      @map[hex_coords[2]][hex_coords[0]] = "."

      dirs = [[1,-1,0],[0,-1,1],[-1,0,1],[-1,1,0],[0,1,-1],[1,0,-1]]
      dirs.each do |d| #Add walls
        @map[hex_coords[2]+d[2]][hex_coords[0]+d[0]] = "#" if @map[hex_coords[2]+d[2]][hex_coords[0]+d[0]] == " "
      end
    end
  end

  def walk(x,y,z) #Find the walking distance between all the rooms (breadth-first search)
    dirs = [[1,-1,0],[0,-1,1],[-1,0,1],[-1,1,0],[0,1,-1],[1,0,-1]]
    dists = []
    $rooms.length.times { dists.push -1 } #Fill dists with -1
    tiles = [[x,y,z,0]] #Contains the distances
    visited = [[x,y,z]] #Used to track which tiles we've been to already
    tiles.each do |i| #Breadth-first
      if $rooms.include?(i[0..2]) #If we're at a room, add a distance
        dists[$rooms.index(i[0..2])] = i[3]
      end
      dirs.each do |j| #Go out from the tile we're on
        coords = [i[0]+j[0],i[1]+j[1],i[2]+j[2]]
        if ! visited.include?(coords) && @map[coords[2]][coords[0]] == "." #If it's a floor tile we haven't been to yet
          visited.push(coords.clone) #Need a clone because we change coords
          coords.push(i[3]+1) #Add the distance
          tiles.push(coords)
        end
      end
    end
    return dists #The distance to the rooms
  end

  def make_room(x,y,z) #Makes a room
    dirs = [[1,-1,0],[0,-1,1],[-1,0,1],[-1,1,0],[0,1,-1],[1,0,-1]]

    #type = rand(2)+1
    type = 1 #Only 1 type of room at the moment
    if type == 1 #Hexagonal Room

      size = rand(4)+3 #random "radius" from 3 to 6

      if z-size < 0 #Top corner is off the map
        return false
      elsif z+size >= @map.length #Bottom corener is off the map
        return false
      elsif x+size >= @map[0].length #Right edge is off the map
        return false
      elsif x-size < 0 #Left Edge is off the map
        return false
      end

      fits = true #Whether the room fits in the proposed place
      (size+1).times do |i| #Make rings until we're at the radius
        newx = x #The starting tile coords
        newy = y+i
        newz = z-i
        if @map[newz][newx] != " " && @map[newz][newx] != "#"
          fits = false #Doesn't fit if there's something there already
        end
        dirs.each do |d| #Go in each direction to make a ring
          i.times do |j| #Go i times in each direction for appropriate ring size
            newx+=d[0]
            newy+=d[1]
            newz+=d[2]
            if @map[newz][newx] != " " && @map[newz][newx] != "#"
              fits = false #Doesn't fit if there's something there
            end
          end
        end
        if ! fits
          break #If it doesn't fit, no need to keep checking
        end
      end
      if ! fits
        return false #If it doesn't fit, return false
      end

      (size+1).times do |i| #Make the room on the map
        newx = x #The coords for the first tile of each ring
        newy = y+i
        newz = z-i
        if i == size #If we're at radius, build a wall
          @map[newz][newx] = "#"
        else #Otherwise, build a floor tile
          @map[newz][newx] = "."
        end
        dirs.each do |d| #Go in each direction to make a ring
          i.times do |j| #Go i times to make a ring of appropriate size
            newx+=d[0]
            newy+=d[1]
            newz+=d[2]
            if i == size #If we're at the radius, build a wall
              @map[newz][newx] = "#"
            else #Otherwise, build a floor tile
              @map[newz][newx] = "."
            end
          end
        end
      end

      return true #Return true, we successfully made a room

    #elsif type == 2 #Not used yet
    end
  end

  #Manhatten distance between tiles
  def distance(a,b)
    dist = ((a[0]-b[0]).abs + (a[1]-b[1]).abs + (a[2]-b[2]).abs)/2
    return dist
  end

  #Rounds [x,y,z] to the nearest hexagon
  def hex_round(a)
    x = a[0].round #Round each point
    y = a[1].round
    z = a[2].round

    x_diff = (x-a[0]).abs #Find the differences
    y_diff = (y-a[1]).abs
    z_diff = (z-a[2]).abs
    if x_diff > y_diff && x_diff > z_diff #If x_diff is biggest, the x coordinate may be incorrect, so find it from y and z coords
      x = -y-z
    elsif y_diff > z_diff #If y_diff is biggest, change y coord
      y = -x-z
    else #If z_diff is biggest, change z coord
      z = -x-y
    end

    return [x,y,z] #Return the rounded coords
  end
end
