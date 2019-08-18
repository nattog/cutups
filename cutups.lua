local rec = 0.5
local pre = 0.5
local fade_time = 0.1
local metro_time = 1.0 
local positions = {0,0,0,0}

local rate = 1.0
local fader = 0.5
local offset = 0

filepath = "audio/tehn/mancini1.wav"
file = "/home/we/dust/" .. filepath
filename = string.sub(filepath, filepath:match'^.*()/' + 1)
local file_ch, file_dur, file_sr = audio.file_info(filepath)
local file_length = file_dur / file_sr
local length = file_length

function split(s, delimiter)
    result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
      table.insert(result, match)
    end
    return result
  end

function update_file_info(fp)
  return audio.file_info(filepath)
end

function update_file()
  softcut.buffer_clear()
  softcut.buffer_read_mono(file,0,0,-1,1,1)
  filepath = string.sub(file, 15)
  filename = string.sub(filepath, filepath:match'^.*()/' + 1)
  file_ch, file_dur, file_sr = audio.file_info(filepath)
  file_length = file_dur / file_sr
  cuts = cutup(true, file_length)
  length = file_length
  params:clear()
  init()
end

local m = metro.init()

function update_positions(i,pos)
  positions[i] = pos
  if positions[i] < cuts[1] then
    if math.random() > 0.75 then
      positions[i] = cuts[1]
      softcut.loop_start(1, cuts[1])
      softcut.loop_end(1, cuts[2])
    end
  elseif positions[i] > cuts[1] then
    if math.random() > 0.75 then
      positions[i] = 0
      softcut.loop_start(1, 0)
      softcut.loop_end(1, cuts[1])
    end
  end
  redraw()
end

function rand_real(a, b)
    return a + (b - a) * math.random()
end

function cutup(is_random, fl)
  local cuts = {}

  if is_random then
    cuts[1] = rand_real(0, fl)
    cuts[2] = rand_real(cuts[1], fl)
  end
  
  return cuts
end
    

function init()
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  
  params:add_file("Add file: ", "Add file " .. filename)
  params:set_action("Add file: ", function(x) 
    file = x 
    update_file()
    end
    )

  m.time = metro_time
  softcut.buffer_clear()
  softcut.buffer_read_mono(file,0,0,-1,1,1)
  cuts = cutup(true, file_length)
  
  softcut.enable(1,1)
  softcut.buffer(1,1)
  softcut.level(1,1.0)
  softcut.loop(1,1) -- voice, 1 = loop
  softcut.loop_start(1,0)
  softcut.loop_end(1,cuts[1])
  softcut.position(1,0)
  
  softcut.play(1,1)
  softcut.fade_time(1,0.25)
  softcut.fade_time(2,fade_time)
  softcut.phase_quant(1,1.0 / 30)
  softcut.phase_quant(2,1.0 / 30)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()
  m:start()
  redraw()
end


function key(n,z)
  if z == 1 then
    if n == 1 then
      k1h = true
    end
    if n == 3 then
      if not k1h then
        rate = clamp(rate+0.2,-4,4)
      else
        cuts = cutup(true, length)
      end
    elseif n == 2 then
      rate = clamp(rate-0.2,-4,4)
    end
    softcut.rate(1,rate)
    softcut.loop_start(1,offset)
    softcut.loop_end(1,offset+length)
  elseif z == 0 then
    if n == 1 then
      k1h = false
    end
  end
  redraw()
end

function enc(n,d)
  -- fader
  if n==1 then
    fader = clamp(fader+d/100,0,1)
  end
  -- offset
  if n==2 then
    offset = clamp(offset+d / 100 ,0, length)
  end
  -- length
  if n==3 then
    length = clamp(length+d /100 ,0.25, file_dur / file_sr)
  end
  softcut.rate(1,rate)
  softcut.loop_start(1,offset)
  softcut.loop_end(1,offset+length)
  softcut.level(1, fader)
  redraw()
end

function redraw()
  screen.clear()
  
  local pad = 10
  local screenx = 128
  local screeny = 64
  local screenc = screenx/2
  local width = screenx - (2*pad)
  local y = screeny*0.5
  
  -- Marker
  
  -- Fader
  screen.move(pad,y-pad)
  screen.text(string.format("%.2f",fader))
  -- Rate
  screen.move(screenx-pad,y-pad)
  screen.text_right(string.format("%.2f",rate))
  
  -- Offset
  screen.move(pad,y+pad+5)
  screen.text(string.format("%.2f",offset))
  -- Length
  screen.move(screenx-pad,y+pad+5)
  screen.text_right(string.format("%.2f",offset+length))
  -- Position
  screen.move(screenc,y+pad+5)
  screen.text_center(string.format("%.2f",positions[1]))
  
  screen.level(2)
  
  -- Background
  screen.move(pad,y)
  screen.line(pad + width,y)
  screen.stroke()
  screen.level(15)
  
  local limit = 5
  local seek_from = (offset/limit) * width
  local seek_to = ((offset+length)/limit) * width
  local seek_at = clamp((positions[1]/limit) * width,seek_from,seek_to)
  screen.move(seek_from+pad,y)
  screen.line(seek_to+pad,y)
  
  screen.move(seek_at+pad,y-2)
  screen.line(seek_at+pad,y+3)

  screen.stroke()
  screen.update()
end

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end
