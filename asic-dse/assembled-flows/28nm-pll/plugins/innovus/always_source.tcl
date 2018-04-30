#=========================================================================
# always_source.tcl
#=========================================================================
# This plug-in script is called from all Innovus flow scripts after
# loading setup.tcl.

#-------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------

# Function to snap to track pitch

proc snapToTrackPitch {x} {
  global t_pitch
  return [expr [tcl::mathfunc::ceil [expr $x / $t_pitch] ] *  $t_pitch]
}

#-------------------------------------------------------------------------
# Floorplan variables
#-------------------------------------------------------------------------

set t_pitch 0.10; # Pitch between m2 tracks (track pitch)
set r_pitch 0.90; # Pitch between power rails (standard cell height)

# Set the floorplan to 120um x 120um in 28nm
#
# - Julian's original 16nm design was 67.2um x 67.2um

set core_width  130
set core_height 130

# Power ring

set pwr_net_list {VDD VSS}; # List of Power nets

# Power ring metal width and spacing

set p_ring_width   2.4; # Arbitrary and temporary!
set p_ring_spacing 1.2; # Arbitrary and temporary!

# Core bounding box margins

set core_margin_t [expr ([llength $pwr_net_list] * ($p_ring_width + $p_ring_spacing)) + $p_ring_spacing]
set core_margin_b [expr ([llength $pwr_net_list] * ($p_ring_width + $p_ring_spacing)) + $p_ring_spacing]
set core_margin_r [expr ([llength $pwr_net_list] * ($p_ring_width + $p_ring_spacing)) + $p_ring_spacing]
set core_margin_l [expr ([llength $pwr_net_list] * ($p_ring_width + $p_ring_spacing)) + $p_ring_spacing]

