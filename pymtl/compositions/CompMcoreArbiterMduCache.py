#=========================================================================
# CompMcoreArbiterCache.py
#=========================================================================

from pymtl                   import *
from pclib.ifcs              import InValRdyBundle, OutValRdyBundle

# BRGTC2 custom MemMsg modified for RISC-V 32

from ifcs                    import MemMsg, MduMsg

from proc.ProcPRTL           import ProcPRTL
from cache.BlockingCachePRTL import BlockingCachePRTL
from mdu.IntMulDivUnit       import IntMulDivUnit

from networks.Funnel         import Funnel
from networks.Router         import Router

class CompMcoreArbiterMduCache( Model ):

  def __init__( s, num_cores=4, mopaque_nbits=8, addr_nbits=32,
                   word_nbits=32, cacheline_nbits=128 ):
    s.explicit_modulename = "CompMcoreArbiterMduCache"

    #---------------------------------------------------------------------
    # Interface
    #---------------------------------------------------------------------

    s.proc_cache_ifc = MemMsg( mopaque_nbits, addr_nbits, word_nbits )
    s.cache_mem_ifc  = MemMsg( mopaque_nbits, addr_nbits, cacheline_nbits )
    s.proc_mdu_ifc   = MduMsg( 32, 8 )

    s.mngr2proc = InValRdyBundle [num_cores]( 32 )
    s.proc2mngr = OutValRdyBundle[num_cores]( 32 )

    s.imemreq  = OutValRdyBundle( s.cache_mem_ifc.req )
    s.imemresp = InValRdyBundle ( s.cache_mem_ifc.resp )

    s.dmemreq  = OutValRdyBundle( s.cache_mem_ifc.req )
    s.dmemresp = InValRdyBundle ( s.cache_mem_ifc.resp )

    # These ports are for statistics

    s.stats_en      = OutPort( 1 )
    s.commit_inst   = OutPort( num_cores )

    #---------------------------------------------------------------------
    # Components
    #---------------------------------------------------------------------

    s.icache = BlockingCachePRTL( 0 )

    s.net_ireq  = Funnel( num_cores, s.proc_cache_ifc.req )  # N cores - to - 1 cache
    s.net_iresp = Router( num_cores, s.proc_cache_ifc.resp )  # 1 cache - to - N cores

    s.dcache = BlockingCachePRTL( 0 )
    s.net_dreq  = Funnel( num_cores, s.proc_cache_ifc.req )  # N cores - to - 1 cache
    s.net_dresp = Router( num_cores, s.proc_cache_ifc.resp )  # 1 cache - to - N cores

    s.mdu = IntMulDivUnit( 32, 8 )
    s.net_mreq  = Funnel( num_cores, s.proc_mdu_ifc.req )  # N cores - to - 1 cache
    s.net_mresp = Router( num_cores, s.proc_mdu_ifc.resp )  # 1 cache - to - N cores

    s.proc = ProcPRTL[num_cores]( num_cores )

    #---------------------------------------------------------------------
    # Connections
    #---------------------------------------------------------------------

    # core id & mngr

    for i in xrange( num_cores ):
      s.connect( s.proc[i].core_id,  i )

      s.connect( s.mngr2proc[i], s.proc[i].mngr2proc )
      s.connect( s.proc2mngr[i], s.proc[i].proc2mngr )

    # instruction cache and network

    for i in xrange( num_cores ):
      # proc < net_ireq
      s.connect( s.proc[i].imemreq,  s.net_ireq.in_[i] )
      # net_iresp > proc
      s.connect( s.net_iresp.out[i], s.proc[i].imemresp )

    # nets <-> icache <-> imem

    s.connect( s.net_ireq.out,   s.icache.cachereq  )
    s.connect( s.icache.memreq,  s.imemreq )

    s.connect( s.net_iresp.in_,  s.icache.cacheresp )
    s.connect( s.icache.memresp, s.imemresp )

    # dcache and network

    for i in xrange( num_cores ):
      # proc < net_dreq
      s.connect( s.proc[i].dmemreq,  s.net_dreq.in_[i] )
      # net_dresp > proc
      s.connect( s.net_dresp.out[i], s.proc[i].dmemresp )

    s.connect( s.net_dreq.out,   s.dcache.cachereq  )
    s.connect( s.dcache.memreq,  s.dmemreq )

    s.connect( s.net_dresp.in_,  s.dcache.cacheresp )
    s.connect( s.dcache.memresp, s.dmemresp )

    # mdu and network

    for i in xrange( num_cores ):
      # proc < net_mreq
      s.connect( s.proc[i].mdureq,  s.net_mreq.in_[i] )
      # net_mresp > proc
      s.connect( s.net_mresp.out[i], s.proc[i].mduresp )

    s.connect( s.net_mreq.out,   s.mdu.req  )
    s.connect( s.net_mresp.in_,  s.mdu.resp )

    # statistics

    # core #0's stats_en is brought up to the top level

    s.connect( s.stats_en,  s.proc[0].stats_en  )

    for i in xrange( num_cores ):
      s.connect( s.proc[i].commit_inst, s.commit_inst[i] )

  #-----------------------------------------------------------------------
  # Line tracing
  #-----------------------------------------------------------------------

  def line_trace( s ):

    # This is staffs' line trace, which assume the processors are
    # instantiated in s.proc[], icaches in s.icache[], and the data cache
    # system is instantiated with the name dcache. You can add net to the
    # line trace.
    # Feel free to revamp it based on your need.

    trace = s.icache.line_trace()
    trace += ' [ ' + s.mdu.line_trace()      + ' ] '
    for i in xrange(len(s.proc)):
      trace += ' [ ' + s.proc[i].line_trace() + ' ] '
    return trace + s.dcache.line_trace()

