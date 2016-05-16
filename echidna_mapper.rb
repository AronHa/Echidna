#!/usr/bin/env ruby
require 'tk'

zoom = 3
tiles = [] #Will contain all the tiles
root = TkRoot.new(:title => 'Hex Mapper') #Start TK
floor = TkPhotoImage.new(:file => "pics/floor.gif") #Hex1
wall = TkPhotoImage.new(:file => "pics/wall.gif") #Hex2
hex1 = TkPhotoImage.new().copy(floor,:zoom=>[zoom,zoom])
hex2 = TkPhotoImage.new().copy(wall,:zoom=>[zoom,zoom])
label = TkLabel.new(root,:text=> "x y").pack() #Used for debugging
canvas = TkCanvas.new(:height=>800,:width=>800).pack()
canvas.bind("Motion",proc{ |e| label.text = "#{e.x} #{e.y}" }) #debugging

#Pull x and y in from command line, and sanitize
x = ARGV[0].to_i
y = ARGV[1].to_i
if x < 1
  x = 10
end
if y < 1
  y = 10
end

#TODO: These starting coords are not quite accurate
startx = (canvas.width/2)-((x.to_f/2)*12)*zoom
starty = (canvas.height/2)-(((y.to_f/2)*13)+(((x-x%2)/2%2)*7))*zoom

for i in 0..y-1
  t = 0
  for j in 0..x-1
    tiles.push TkcImage.new(canvas,startx+13*j*zoom,starty+((14*i)+(t*7))*zoom,:image=>hex2,:anchor=>'center')
    t = (t+1)%2
  end
end
#TODO: Click and drag
#TODO: Draw lines
tiles.each do |i|
  i.bind("Button, ButtonRelease",proc{
    if i.image == hex1
      i.image = hex2
    else
      i.image = hex1
    end
  })
end

root.bind("Any-Key-Left",proc{
  tiles.each { |i| i.move(13*zoom,0) }
})
root.bind("Any-Key-Right",proc{
  tiles.each { |i| i.move(-13*zoom,0) }
})
root.bind("Any-Key-Up",proc{
  tiles.each { |i| i.move(0,14*zoom) }
})
root.bind("Any-Key-Down",proc{
  tiles.each { |i| i.move(0,-14*zoom) }
})

Tk.mainloop()
