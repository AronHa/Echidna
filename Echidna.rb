#!/usr/bin/env ruby
#
# Echidna
# Aron Harder
# Created 2015/05/06
#
require 'tk'
require_relative 'Map.rb'

$root = TkRoot.new(:title => 'Echidna') #Start TK

floor = TkPhotoImage.new(:file => "pics/floor.gif")
wall = TkPhotoImage.new(:file => "pics/wall.gif")

puts "Please wait, loading map"
$map = Map.new(20)
m = $map.map
canvas = TkCanvas.new(:height=>1200,:width=>1200).pack()

startx = 15#(canvas.width/2)#-($map[0].length/2.0)*25
starty = 10#(canvas.height/2)#-($map.length/2.0)*19+19

pics = []
m[0].length.times do |z|
  i = 0
  j = z
  t = 0
  while i+t < m.length && j-(2*t) >= 0
    tile = m[i+t][j-(2*t)]
    if tile == "#"
      pics.push TkcImage.new(canvas,startx+(13*(j-2*t)),starty+(14*(i+t))+(j-2*t)*7,:image=>wall,:anchor=>'s')
    elsif tile == "."
      pics.push TkcImage.new(canvas,startx+(13*(j-2*t)),starty+(14*(i+t))+(j-2*t)*7,:image=>floor,:anchor=>'s')
    end
    t+=1
  end
end
m.each_with_index do |row,i|
  (2).times do |z|
    t = 0
    j = row.length-((1-z).abs)
    while i+t < m.length && j-(2*t) >= 0
      tile = m[i+t][j-(2*t)]
      if tile == "#"
        pics.push TkcImage.new(canvas,startx+(13*(j-2*t)),starty+(14*(i+t))+(j-2*t)*7,:image=>wall,:anchor=>'s')
      elsif tile == "."
        pics.push TkcImage.new(canvas,startx+(13*(j-2*t)),starty+(14*(i+t))+(j-2*t)*7,:image=>floor,:anchor=>'s')
      end
      t+=1
    end
  end
end

$root.bind("Any-Key-Down", proc {
  pics.each do |i|
    i.move(0,-50)
  end
})
$root.bind("Any-Key-Up", proc {
  pics.each do |i|
    i.move(0,50)
  end
})
$root.bind("Any-Key-Right", proc {
  pics.each do |i|
    i.move(-50,0)
  end
})
$root.bind("Any-Key-Left", proc {
  pics.each do |i|
    i.move(50,0)
  end
})

Tk.mainloop()
