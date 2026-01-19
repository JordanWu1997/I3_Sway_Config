#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# vim: set fileencoding=utf-8
r"""
[ADD MODULE DOCUMENTATION HERE]

# ========================================================================== #
#  _  __   _   _                                          __        ___   _  #
# | |/ /  | | | |  Author: Jordan Kuan-Hsien Wu           \ \      / / | | | #
# | ' /   | |_| |  E-mail: jordankhwu@gmail.com            \ \ /\ / /| | | | #
# | . \   |  _  |  Github: https://github.com/JordanWu1997  \ V  V / | |_| | #
# |_|\_\  |_| |_|  Datetime: 2026-01-19 22:17:57             \_/\_/   \___/  #
#                                                                            #
# ========================================================================== #
"""

import os
import re
import subprocess


def get_nvidia_gpu():
    try:
        # Check if nvidia-smi exists and can see a GPU
        subprocess.check_output(['nvidia-smi', '-L'], stderr=subprocess.STDOUT)
        return True
    except:
        return False


def get_disks():
    # Filters for physical disks (sdX, nvmeXnX) excluding partitions
    disks = [
        d for d in os.listdir('/sys/block/')
        if re.match(r'sd[a-z]$|nvme[0-9]n[1-9]$', d)
    ]
    return sorted(disks)


def get_physical_networks():
    interfaces = []
    net_path = '/sys/class/net/'
    if not os.path.exists(net_path):
        return interfaces

    for iface in os.listdir(net_path):
        # Ignore virtual/docker interfaces and loopback
        if iface == 'lo' or 'docker' in iface or 'veth' in iface or 'br-' in iface:
            continue

        # Ensure it is a physical device and currently "up"
        operstate_path = os.path.join(net_path, iface, 'operstate')
        if os.path.exists(os.path.join(net_path, iface, 'device')):
            if os.path.exists(operstate_path):
                with open(operstate_path, 'r') as f:
                    if f.read().strip() == 'up':
                        interfaces.append(iface)
    return interfaces


def generate_config():
    # STATIC HEADER (Lines 1-107 of your original config)
    header = """-- vim: ts=4 sw=4 noet ai cindent syntax=lua
--[[
Conky, a system monitor, based on torsmo
Any original torsmo code is licensed under the BSD license
All code written since the fork of torsmo is licensed under the GPL
Please see COPYING for details
Copyright (c) 2004, Hannu Saransaari and Lauri Hakkarainen
Copyright (c) 2005-2012 Brenden Matthews, Philip Kovacs, et. al. (see AUTHORS)
All rights reserved.
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]
conky.config = {

-- Window Settings --
	own_window = true,
	own_window_argb_value = 64,
	own_window_argb_visual = true,
	own_window_class = 'Conky',
	own_window_transparent = false,
	own_window_title = 'i3_conky_system',
	own_window_type = 'override',

-- Position --
	alignment = 'top_right',
	gap_x = 30,
	gap_y = 30,
	minimum_width = 240,
	maximum_width = 240,

-- Font --
	use_xft = true,
	xftalpha = 1.0,
	font = 'DroidSanMono Nerd Font:bold:size=9',
	uppercase = false,
	use_spacer = 'none',
	extra_newline = false,

-- Graphical --
	default_color = '#953515',
	color1 = '#bfbfbf',
	color2 = '#953515',
	color3 = '#D94922',
	own_window_colour = '#010101',
	default_outline_color = '#FFFFFF',
	default_shade_color = '#000000',
	border_width = 1,
	stippled_borders = 0,
	draw_borders = false,
	draw_graph_borders = true,
	draw_outline = false,
	draw_shades = true,

-- Miscellanous --
	background = true,
	cpu_avg_samples = 2,
	no_buffers = true,
	out_to_console = false,
	out_to_stderr = false,
	update_interval = 1.0,
	show_graph_scale = false,
	show_graph_range = false,
	double_buffer = true,

};

conky.text = [[
${color3}${hr 2}
${voffset 55}${alignc}${image ~/.config/i3/share/ubuntu_logo_darkbackground.png -p 0,+19 -s 240x75}
${voffset 10}${color3}${hr 2}
${voffset 5}${alignc}${color3}${font DroidSanMono Nerd Font:bold:size=11}[Information]${font}${voffset 5}
${voffset 5}${color2}Kernel ${alignr}${color1}${kernel}
${color2}Local Hostname ${alignr}${color1}${nodename}
${color2}Machine Uptime ${alignr}${color1}${uptime}
${voffset 5}${alignc}${color3}${font DroidSanMono Nerd Font:bold:size=11}[Processor]${font}${voffset 5}
${alignc}${color1}${exec cat /proc/cpuinfo 2> /dev/null | grep 'model name' | sed -e 's/model name.*: //'| uniq | awk -F ' CPU ' '{print $1,$2}'}${font}
${color2}Temp. / Fan ${alignr}${color1}${exec sensors | grep 'Package id' | awk '{print $4}'} / ${alignr}${color1}${exec sensors | grep 'cpu_fan' | awk '{print $2}'} RPM
${color2}Usage / Freq. ${alignr}${color1}${cpu} % / ${alignr}${color1}${exec awk '/cpu MHz/{i++}i==1{printf "%.f",$4; exit}' /proc/cpuinfo} MHz
${color2}Processes (Running) ${alignr}${color1}${processes} (${running_processes})
${color2}Threads (Running) ${alignr}${color1}${threads} (${running_threads})
${voffset -5}${color2}${hr 1}
${color2}CPU-Top ${alignr}${color1}CPU	${alignr}MEM
${voffset -5}${color2}${hr 1}
${color2}${top name 1} ${alignr}${color1}${top cpu 1}	${alignr}${top mem 1}
${color2}${top name 2} ${alignr}${color1}${top cpu 2}	${alignr}${top mem 2}
${color2}${top name 3} ${alignr}${color1}${top cpu 3}	${alignr}${top mem 3}
${color2}${top name 4} ${alignr}${color1}${top cpu 4}	${alignr}${top mem 4}
${color2}${top name 5} ${alignr}${color1}${top cpu 5}	${alignr}${top mem 5}
${voffset 5}${alignc}${color3}${font DroidSanMono Nerd Font:bold:size=11}[Memory]${font}${voffset 5}
${color2}Memory ${alignr}${color1} ${mem} / ${memmax}
${color2}Swap ${alignr}${color1} ${swap} / ${swapmax}
${voffset -5}${color2}${hr 1}
${color2}MEM-Top ${alignr}${color1}CPU	${alignr}MEM
${voffset -5}${color2}${hr 1}
${color2}${top_mem name 1} ${alignr}${color1}${top_mem cpu 1}	${alignr}${top_mem mem 1}
${color2}${top_mem name 2} ${alignr}${color1}${top_mem cpu 2}	${alignr}${top_mem mem 2}
${color2}${top_mem name 3} ${alignr}${color1}${top_mem cpu 3}	${alignr}${top_mem mem 3}
${color2}${top_mem name 4} ${alignr}${color1}${top_mem cpu 4}	${alignr}${top_mem mem 4}
${color2}${top_mem name 5} ${alignr}${color1}${top_mem cpu 5}	${alignr}${top_mem mem 5}"""

    # 1. DYNAMIC GRAPHICS SECTION
    graphics = "\n${voffset 5}${alignc}${color3}${font DroidSanMono Nerd Font:bold:size=11}[Graphics]${font}${voffset 5}"
    if get_nvidia_gpu():
        graphics += "\n${alignc}${color1}${exec lspci | grep -i VGA | awk -F 'controller: ' '{print $2}' | cut -d '(' -f 1}${font}"
        graphics += "\n${color2}GPU ${alignr}${color1}${execi 5 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits}%"
        graphics += "\n${color2}Mem ${alignr}${color1}${execi 5 nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits} MiB / ${execi 5 nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits} MiB"
        graphics += "\n${color2}Temp ${alignr}${color1}${execi 5 nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits}°C"
        graphics += "\n${color2}Clock ${alignr}${color1}${execi 5 nvidia-smi --query-gpu=clocks.gr --format=csv,noheader,nounits} MHz / ${execi 5 nvidia-smi --query-gpu=clocks.max.gr --format=csv,noheader,nounits} MHz"
    else:
        # Fallback for Intel/Integrated Graphics using /sys/class/drm/
        # graphics += "\n${alignc}${color1}${exec lspci | grep -i VGA | cut -d ':' -f3}${font}"
        graphics += "\n${alignc}${color1}${exec lspci | grep -i VGA | cut -d '(' -f1}${font}"
        graphics += "\n${color2}Clock ${alignr}${color1}${exec cat /sys/class/drm/card1/gt_cur_freq_mhz} / ${exec cat /sys/class/drm/card1/gt_max_freq_mhz} MHz"

    # 2. DYNAMIC DISK SECTION
    disk_header = "\n${voffset 5}${alignc}${color3}${font DroidSanMono Nerd Font:bold:size=11}[Disk]${font}${voffset 5}"
    disk_usage = "\n${color2}Disk Usage ${alignr}${color1}${fs_used /home} / ${fs_size /home}"
    disk_io = "\n${voffset -5}${color2}${hr 1}\n${color2}Disk IO ${alignr}${color1}Speed\n${voffset -5}${color2}${hr 1}"
    disk_lines = []
    for d in get_disks():
        disk_lines.append(
            f"${{color2}}{d} ${{alignr}}${{color1}}R ${{diskio_read /dev/{d}}}/s W ${{diskio_write /dev/{d}}}/s"
        )

    # 3. DYNAMIC NETWORK SECTION
    net_header = "\n${voffset 5}${alignc}${color3}${font DroidSanMono Nerd Font:bold:size=11}[Network]${font}${voffset 5}${color1}"
    ext_ip = "\n${color2}External IP ${alignr}${color1}${execi 3600 curl -s ipinfo.io/ip}"
    gw_ip = "\n${color2}Gateway IP ${alignr}${color1}${gw_ip}"

    net_details = []
    for iface in get_physical_networks():
        # Labeling logic
        label = "Wifi" if iface.startswith('w') else "Ethe"
        # Conky built-in addr handles internal IPv4 [cite: 14, 27]
        net_details.append(
            f"${{color2}}Internal IP ({label}) ${{alignr}}${{color1}}${{addr {iface}}}"
        )

    net_speed_table = "\n${voffset -5}${color2}${hr 1}\n${color2}Network ${alignr}${color1}Speed			${alignr} Usage\n${voffset -5}${color2}${hr 1}"

    net_speeds = []
    for iface in get_physical_networks():
        label = "Wifi" if iface.startswith('w') else "Ethe"
        net_speeds.append(
            f"${{color2}}{label}-Dw ${{alignr}}${{color1}}${{downspeed {iface}}}/s   ${{alignr}}${{totaldown {iface}}}"
        )
        net_speeds.append(
            f"${{color2}}{label}-Up ${{alignr}}${{color1}}${{upspeed {iface}}}/s   ${{alignr}}${{totalup {iface}}}"
        )

    # COMBINE ALL
    full_text = (header + graphics + disk_header + disk_usage + disk_io +
                 "\n" + "\n".join(disk_lines) + net_header + ext_ip + gw_ip +
                 "\n" + "\n".join(net_details) + net_speed_table + "\n" +
                 "\n".join(net_speeds) + "\n${voffset 0}" + "\n]]")

    print(full_text)


if __name__ == "__main__":
    generate_config()
