# `per2axi_res_channel.sv` 상세 분석

## 개요

`per2axi_res_channel`은 AXI master의 R/B 응답 채널을 peripheral interconnect의 response 채널로 변환합니다. read 응답이 들어오면 AXI 64-bit `r_data` 중 peripheral 요청 주소 bit 2에 맞는 32-bit lane을 선택해 `per_slave_r_rdata_o`로 반환합니다. write 응답이 들어오면 data 없이 response valid와 ID만 생성합니다. read data 채널이 write response 채널보다 우선순위가 높습니다.

## 블록 다이어그램

```mermaid
flowchart LR
    subgraph CTRL[Read request tracking]
      trans[trans_req_i / trans_id_i / trans_add_i]
      addbuf[s_read_add_buf\nID-indexed addr[2] storage]
      trans --> addbuf
    end

    subgraph AXI[AXI response side]
      rchan[R channel\nr_valid/r_data/r_id]
      bchan[B channel\nb_valid/b_id]
    end

    subgraph RES[per2axi_res_channel]
      lane[Read data lane select\naddr[2]=0: data[31:0]\naddr[2]=1: data[63:32]]
      arb[Response priority mux\nR has priority over B]
      idenc[Binary ID to one-hot\nper_slave_r_id_o[id]=1]
      ready[Ready gating\ndefault R/B ready=1\nselected opposite channel ready=0]
    end

    addbuf --> lane
    rchan --> lane
    rchan --> arb
    bchan --> arb
    lane --> arb
    arb --> idenc
    arb --> per[Peripheral response\nr_valid/r_opc/r_id/r_rdata]
    ready --> rready[axi_master_r_ready_o]
    ready --> bready[axi_master_b_ready_o]
```

## 파라미터

| 파라미터 | 기본값 | 설명 |
| --- | --- | --- |
| `PER_ADDR_WIDTH` | 32 | peripheral 주소 폭입니다. 이 모듈에서는 포트 폭 정합용 성격이 강합니다. |
| `PER_ID_WIDTH` | 5 | peripheral response one-hot ID 폭 및 `s_read_add_buf` 폭입니다. |
| `AXI_ADDR_WIDTH` | 32 | read request 주소 저장 입력 폭입니다. |
| `AXI_DATA_WIDTH` | 64 | AXI R data 폭입니다. RTL은 하위/상위 32-bit lane을 선택합니다. |
| `AXI_USER_WIDTH` | 6 | AXI user 폭입니다. 현재 동작에는 사용되지 않습니다. |
| `AXI_ID_WIDTH` | 3 | AXI binary ID 폭입니다. |

## 주요 포트 그룹

### Peripheral response 출력

* `per_slave_r_valid_o`: AXI R 또는 B 응답을 peripheral response로 내보낼 때 1입니다.
* `per_slave_r_opc_o`: 현재 항상 0입니다. AXI `resp` 값은 opcode로 반영되지 않습니다.
* `per_slave_r_id_o`: AXI ID를 one-hot 위치로 변환한 response ID입니다.
* `per_slave_r_rdata_o`: read 응답일 때 선택된 32-bit read data입니다. write 응답일 때는 기본값 0입니다.

### AXI R/B 입력 및 ready 출력

* R 채널 valid가 1이면 read response를 peripheral 쪽으로 전달합니다.
* B 채널 valid가 1이면 write response를 peripheral 쪽으로 전달합니다.
* R과 B가 동시에 valid이면 R을 우선 처리하고 B ready를 0으로 내려 B 응답을 보류합니다.
* B만 valid이면 R ready를 0으로 내려 R 응답을 보류합니다.

### Request tracking 입력

* `trans_req_i`: request 채널에서 read AR이 발행될 때 1입니다.
* `trans_id_i`: read transaction의 AXI ID입니다.
* `trans_add_i`: read transaction의 주소입니다. bit 2만 내부 버퍼에 저장됩니다.

## 내부 신호

| 신호 | 폭 | 설명 |
| --- | --- | --- |
| `s_per_slave_r_data` | 32 bit | AXI R data에서 선택된 peripheral read data입니다. |
| `s_read_add_buf` | `PER_ID_WIDTH` bit | AXI ID별 read 주소 bit 2 저장소입니다. |

## 동작 상세

### Response arbitration 및 ready 제어

기본값은 다음과 같습니다.

* `per_slave_r_valid_o = 0`
* `per_slave_r_opc_o = 0`
* `per_slave_r_id_o = 0`
* `per_slave_r_rdata_o = 0`
* `axi_master_r_ready_o = 1`
* `axi_master_b_ready_o = 1`

그 다음 우선순위에 따라 처리합니다.

1. `axi_master_r_valid_i=1`이면 read response를 출력합니다.
   * `per_slave_r_valid_o=1`
   * `per_slave_r_id_o[axi_master_r_id_i]=1`
   * `per_slave_r_rdata_o=s_per_slave_r_data`
   * `axi_master_b_ready_o=0`으로 설정하여 B 채널을 받지 않습니다.
2. R valid가 없고 `axi_master_b_valid_i=1`이면 write response를 출력합니다.
   * `per_slave_r_valid_o=1`
   * `per_slave_r_id_o[axi_master_b_id_i]=1`
   * `axi_master_r_ready_o=0`으로 설정하여 R 채널을 받지 않습니다.

### Read 주소 bit 저장

`trans_req_i=1`인 클록에서 `s_read_add_buf[trans_id_i] <= trans_add_i[2]`를 수행합니다. 따라서 response가 나중에 도착해도 AXI ID를 사용해 원 read 주소의 32-bit lane 정보를 복원할 수 있습니다.

### Read data lane 선택

| 저장된 `s_read_add_buf[axi_master_r_id_i]` | 반환 데이터 |
| --- | --- |
| 0 | `axi_master_r_data_i[31:0]` |
| 1 | `axi_master_r_data_i[63:32]` |

## 설계상 유의점

* `axi_master_r_resp_i`와 `axi_master_b_resp_i`는 포트로 입력되지만 현재 peripheral opcode나 별도 에러 신호로 변환되지 않습니다. `per_slave_r_opc_o`는 항상 0입니다.
* `axi_master_r_last_i`, `axi_master_r_user_i`, `axi_master_b_user_i`도 이 모듈 내부의 response 생성에는 사용되지 않습니다. 마지막 beat 추적은 상위 `per2axi_busy_unit` 연결에서 수행됩니다.
* `s_read_add_buf`는 ID별 bit 하나만 저장하므로 같은 AXI ID로 여러 read가 outstanding되고 주소 bit 2가 다르면 뒤 요청이 앞 요청의 lane 정보를 덮어쓸 수 있습니다. 설계는 ID별 outstanding read가 순차적이거나 같은 ID 재사용이 안전하게 제한된다는 전제를 둡니다.
* R 채널 우선순위가 있으므로 R/B 동시 valid 상황에서는 B 응답이 한 사이클 이상 지연될 수 있습니다.

## 의사 코드

```text
on reset:
  read_addr_bit2_by_id = 0

on each clock:
  if trans_req:
    read_addr_bit2_by_id[trans_id] = trans_add[2]

selected_read_data =
  read_addr_bit2_by_id[r_id] ? r_data[63:32] : r_data[31:0]

r_ready = 1
b_ready = 1
per_valid = 0
per_id = 0
per_rdata = 0
per_opc = 0

if r_valid:
  per_valid = 1
  per_id[r_id] = 1
  per_rdata = selected_read_data
  b_ready = 0
else if b_valid:
  per_valid = 1
  per_id[b_id] = 1
  r_ready = 0
```
