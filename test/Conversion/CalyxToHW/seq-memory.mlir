// RUN: circt-opt %s -lower-calyx-to-hw | FileCheck %s

// CHECK-LABEL: hw.module @main
// CHECK: %mem_addr0 = sv.wire : !hw.inout<i3>
// CHECK-NEXT: %[[ADDR_RD:.*]] = sv.read_inout %mem_addr0 : !hw.inout<i3>
// CHECK: %mem_clk = sv.wire : !hw.inout<i1>
// CHECK-NEXT: %[[CLK_RD:.*]] = sv.read_inout %mem_clk : !hw.inout<i1>
// CHECK: %mem_reset = sv.wire : !hw.inout<i1>
// CHECK-NEXT: %[[RESET_RD:.*]] = sv.read_inout %mem_reset : !hw.inout<i1>
// CHECK: %mem_content_en = sv.wire : !hw.inout<i1>
// CHECK-NEXT: %[[CONTENT_EN_RD:.*]] = sv.read_inout %mem_content_en : !hw.inout<i1>
// CHECK: %mem_write_en = sv.wire : !hw.inout<i1>
// CHECK-NEXT: %[[WRITE_EN_RD:.*]] = sv.read_inout %mem_write_en : !hw.inout<i1>
// CHECK: %mem_write_data = sv.wire : !hw.inout<i32>
// CHECK-NEXT: %[[WRITE_DATA_RD:.*]] = sv.read_inout %mem_write_data : !hw.inout<i32>
// CHECK-NEXT: %[[SEQ_CLK:.*]] = seq.to_clock %[[CLK_RD]]
// CHECK-NEXT: %[[MEM:.*]] = seq.hlmem @mem %[[SEQ_CLK]], %[[RESET_RD]] : <8xi32>
// CHECK-NEXT: %[[READ:.*]] = seq.read %[[MEM]][%[[ADDR_RD]]] rden %[[CONTENT_EN_RD]] {latency = 1 : i64} : !seq.hlmem<8xi32>
// CHECK-NEXT: %[[EFFECTIVE_WE:.*]] = comb.and %[[CONTENT_EN_RD]], %[[WRITE_EN_RD]] : i1
// CHECK-NEXT: seq.write %[[MEM]][%[[ADDR_RD]]] %[[WRITE_DATA_RD]] wren %[[EFFECTIVE_WE]] {latency = 1 : i64} : !seq.hlmem<8xi32>
// CHECK-NEXT: %false = hw.constant false
// CHECK-NEXT: %[[DONE_REG:.*]] = seq.compreg sym @mem_done_reg %[[CONTENT_EN_RD]], %[[SEQ_CLK]] reset %[[RESET_RD]], %false : i1
module attributes {calyx.entrypoint = "main"} {
  calyx.component @main(%addr: i3, %clk: i1 {clk}, %reset: i1 {reset}, %go: i1 {go}) -> (%out: i32, %done: i1 {done}) {
    %mem.addr0, %mem.clk, %mem.reset, %mem.content_en, %mem.write_en, %mem.write_data, %mem.read_data, %mem.done = calyx.seq_mem @mem <[8] x 32> [3] : i3, i1, i1, i1, i1, i32, i32, i1
    %c0_i32 = hw.constant 0 : i32
    calyx.wires {
      calyx.assign %mem.addr0 = %addr : i3
      calyx.assign %mem.clk = %clk : i1
      calyx.assign %mem.reset = %reset : i1
      calyx.assign %mem.content_en = %go : i1
      calyx.assign %mem.write_en = %go : i1
      calyx.assign %mem.write_data = %c0_i32 : i32
      calyx.assign %out = %mem.read_data : i32
      calyx.assign %done = %mem.done : i1
    }
    calyx.control {}
  }
}
