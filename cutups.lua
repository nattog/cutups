local rec = 0.5
local pre = 0.5
local fade_time = 0.1
local metro_time = 1.0 
local positions = {0,0,0,0}

local rate = 1.0
local fader = 0.5
local offset = 0
threshold = 0.06
local is_loop_end = false


filepath = "audio/tehn/mancini1.wav"
file = "/home/we/dust/" .. filepath
filename = string.sub(filepath, filepath:match'^.*()/' + 1)
local file_ch, file_dur, file_sr = audio.file_info(filepath)
local file_length = file_dur / file_sr
local length = file_length
active_loop = 1

cuts = {
  {start_location = 0, 
  end_location = length
  }
}

local pieces = 1

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

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
  pieces = 2
  for i=1, pieces do
    cuts[i] = cutup(file_length, i)
  end
  length = file_length
  params:clear()
  init()
end

local m = metro.init()

function set_loop(pos, loops, d)
  d = 1 or d
  if pos == #loops then
    pos = 1
  else
    pos = pos + d
  end
  return pos
end

function set_loop_start_location(start_loc, end_loc, change)
  return clamp(start_loc + change / 10, 0, end_loc - 0.01)
end

function set_loop_end_location(start_loc, end_loc, change, full_file_length)
  return clamp(end_loc + change / 10, start_loc + 0.01, full_file_length)
end

function set_sc_loop_start(buffer, loops, selection)
  return softcut.loop_start(buffer, loops[selection].start_location)
end

function set_sc_loop_end(buffer, loops, selection)
  return softcut.loop_end(buffer, loops[selection].end_location)
end

function update_positions(i,pos)
  positions[i] = pos
  if pos < cuts[active_loop].start_location then
    softcut.position(i, cuts[active_loop].start_location)
  end
  if pos > cuts[active_loop].end_location then
    softcut.position(i, cuts[active_loop].start_location)
  end
  difference = math.abs(positions[i] - cuts[active_loop].end_location)
  if difference < threshold then
    print('end of loop ' .. active_loop, string.format("%.2f",cuts[active_loop].end_location))
  end
  redraw()
end

function rand_real(a, b)
    return a + (b - a) * math.random()
end

function cutup(fl, index)
  -- start_loc = rand_real(0, fl)
  -- end_loc = rand_real(start_loc, fl)
  return {start_location = 0, end_location = length}
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
  for i=1, pieces * 2 do
    cuts[#cuts + 1] = cutup(file_length, i)
  end
  
  softcut.enable(1,1)
  softcut.buffer(1,1)
  softcut.level(1,1.0)
  softcut.loop(1,1) -- voice, 1 = loop
  softcut.loop_start(1,cuts[active_loop].start_location)
  softcut.loop_end(1,cuts[active_loop].end_location)
  softcut.position(1,0)
  softcut.play(1,1)
  softcut.fade_time(1,fade_time)
  softcut.phase_quant(1, 0.1)
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
        rate = clamp(rate+0.1,-4,4)
      else
        pieces = pieces * 2
        for i=1, pieces, 1 do
          cuts[#cuts + 1] = cutup(file_length, i)
        end
      end
    elseif n == 2 then
      rate = clamp(rate-0.2,-4,4)
    end
    softcut.rate(1,rate)
    
  elseif z == 0 then
    if n == 1 then
      k1h = false
    end
  end
  redraw()
end

function enc(n,d)
  if not k1h then
    -- fader
    if n==1 then
      fader = clamp(fader+d/10,0,1)
    end
    -- offset
    if n==2 then
      offset = clamp(offset+d / 10 ,0, length)
    end
    -- length
    if n==3 then
      length = clamp(length+d /10 ,0.25, file_dur / file_sr)
    end
  else
    if n == 1 then 
      active_loop = set_loop(active_loop, cuts, d)
      set_sc_loop_start(1, cuts, active_loop)
      set_sc_loop_end(1, cuts, active_loop)
      softcut.position(1, cuts[active_loop].start_location)
    end
    if n == 2 then
      cuts[active_loop].start_location = set_loop_start_location(cuts[active_loop].start_location, cuts[active_loop].end_location, d)
      set_sc_loop_start(1, cuts, active_loop)
    end
    if n == 3 then
      cuts[active_loop].end_location = set_loop_end_location(cuts[active_loop].start_location, cuts[active_loop].end_location, d, length)
      set_sc_loop_end(1, cuts, active_loop)
    end
  end
  softcut.rate(1,rate)
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
  screen.move(pad, pad)
  screen.text(active_loop)
  screen.move(pad * 2, pad)
  screen.text(string.format("%.2f", cuts[active_loop].start_location))
  screen.move(pad * 4, pad)
  screen.text(string.format("%.2f", cuts[active_loop].end_location))
  
  -- Volume
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
  
  local limit = length
  local seek_from = (offset/limit) * width
  local seek_to = ((offset+length)/limit) * width
  local seek_at = clamp((positions[1]/limit) * width,seek_from,seek_to)
  local loop_st = ((offset + cuts[active_loop].start_location) / limit) * width
  local loop_end = ((offset + cuts[active_loop].end_location) / limit) * width
  screen.move(seek_from+pad,y)
  screen.line(seek_to+pad,y)
  
  screen.move(seek_at+pad,y-2)
  screen.line(seek_at+pad,y+3)
  
  
  screen.move(loop_st+pad,y-4)
  screen.line(loop_st+pad,y+4)
  screen.move(loop_end+pad,y-4)
  screen.line(loop_end+pad,y+4)

  screen.stroke()
  screen.update()
end

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end

function max(t, fn)
    if #t == 0 then return nil, nil end
    local key, value = 1, t[1]
    for i = 2, #t do
        if fn(value, t[i]) then
            key, value = i, t[i]
        end
    end
    return key, value
end
